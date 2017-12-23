create schema if not exists semantic;

drop table if exists semantic.entities cascade;

create table semantic.entities as (

with entities_date as (

  select
  --distinct on (license_num, facility, facility_aka, facility_type, address)
  license_num,
  facility,
  facility_aka,
  facility_type,
  address,
  zip_code,
  location,
  min(date) over (partition by license_num, facility, facility_aka, address) as start_time,
  max(case when
  result in ('out of business', 'business not located')
  then
  date
  else
  NULL
  end) over (partition by license_num, facility, facility_aka, address) as end_time
  from cleaned.inspections

)

select distinct
   dense_rank() over (w) as entity_id,
   license_num,
   facility,
   facility_aka,
   facility_type,
   address,
   zip_code,
   location,
   start_time,
   end_time
from entities_date
   window w as (order by license_num, facility, facility_aka, facility_type, address)
);


-- Adding some indices

create index entities_license_num_ix on semantic.entities (license_num);
create index entities_facility_ix on semantic.entities (facility);
create index entities_facility_type_ix on semantic.entities (facility_type);
create index entities_zip_code_ix on semantic.entities (zip_code);

-- Spatial index
create index entities_location_gix on semantic.entities using gist (location);

create index entities_license_num_facility_type_ix on semantic.entities (license_num, facility_type);

drop table if exists semantic.events cascade;

create table semantic.events as (

select i.inspection, type, i.license_num, facility_type, zip_code, city,
       i.date, risk, result, location,
jsonb_agg(
    jsonb_build_object(
        'code', v.code,
        'severity', v.severity,
	'description', v.description,
	'comment', v.comment
	)
order  by code
) as violations
from cleaned.inspections as i
inner join
cleaned.violations as v
on i.inspection = v.inspection
group by i.inspection, type, i.license_num, facility_type, zip_code, city, i.date, risk, result, location
);

-- Add some indices
create index events_inspection_ix on semantic.events (inspection);
create index events_type_ix on semantic.events (type);
create index events_date_ix on semantic.events(date desc nulls last);
create index events_license_num_ix on semantic.events (license_num);
create index events_facility_type_ix on semantic.events  (facility_type);
create index events_zip_code_ix on semantic.events  (zip_code);

-- Spatial index
create index events_location_gix on semantic.events using gist (location);

-- JSONB indices
create index events_violations on semantic.events using gin(violations);
create index events_violations_json_path on semantic.events using gin(violations jsonb_path_ops);

create index events_inspection_license_zip_code_date on semantic.events (inspection desc nulls last, license_num, zip_code, date desc nulls last);
