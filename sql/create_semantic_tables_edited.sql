create schema if not exists semantic;

drop table if exists semantic_randomized.entities cascade;

create table semantic_randomized.entities as (

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
  from cleaned_randomized.inspections

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
create index entities_ix on semantic_randomized.entities (entity_id);

create index entities_license_num_ix on semantic_randomized.entities (license_num);
create index entities_facility_ix on semantic_randomized.entities (facility);
create index entities_facility_type_ix on semantic_randomized.entities (facility_type);
create index entities_zip_code_ix on semantic_randomized.entities (zip_code);

-- Spatial index
create index entities_location_gix on semantic_randomized.entities using gist (location);

create index entities_full_key_ix on semantic_randomized.entities (license_num, facility, facility_aka, facility_type, address);

drop table if exists semantic_randomized.events cascade;

create table semantic_randomized.events as (

with entities as (
  select * from semantic_randomized.entities
),

inspections as (
select
i.inspection, i.type, i.date, i.risk, i.result,
i.license_num, i.facility, i.facility_aka, i.facility_type, i.address, i.zip_code, i.location,
jsonb_agg(
    jsonb_build_object(
        'code', v.code,
        'severity', v.severity,
	'description', v.description,
	'comment', v.comment
	)
order  by code
) as violations
from cleaned_randomized.inspections as i
inner join
cleaned_randomized.violations as v
on i.inspection = v.inspection
group by
i.inspection, i.type, i.license_num, i.facility, i.facility_aka, i.facility_type, i.address, i.zip_code, i.location,
i.date, i.risk, i.result
)

select
i.inspection, e.entity_id, i.type, i.date, i.risk, i.result,
e.facility_type, e.zip_code, e.location,
i.violations
from entities as e
inner join
inspections as i
using (license_num, facility, facility_aka, facility_type, address, zip_code)

);

-- Add some indices
create index events_entity_ix on semantic_randomized.events (entity_id);
create index events_inspection_ix on semantic_randomized.events (inspection);
create index events_type_ix on semantic_randomized.events (type);
create index events_date_ix on semantic_randomized.events(date desc nulls last);
create index events_facility_type_ix on semantic_randomized.events  (facility_type);
create index events_zip_code_ix on semantic_randomized.events  (zip_code);

-- Spatial index
create index events_location_gix on semantic_randomized.events using gist (location);

-- JSONB indices
create index events_violations on semantic_randomized.events using gin(violations);
create index events_violations_json_path on semantic_randomized.events using gin(violations jsonb_path_ops);

create index events_inspection_entity_zip_code_date on semantic_randomized.events (inspection desc nulls last, entity_id, zip_code, date desc nulls last);
