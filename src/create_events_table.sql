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

-- Add some indexes
create index events_inspection_ix on semantic.events (inspection);
create index events_type_ix on semantic.events (type);
create index events_date_ix on semantic.events(date desc null last);
create index events_license_num_ix on semantic.events (license_num);
create index events_facility_type_ix on semantic.events  (facility_type);
create index events_zip_code_ix on semantic.events  (zip_code);

create index events_location_gix on semantic.events using gist (location);

create index events_violation_severity_idx on semantic.events using btree ((violations ->> 'severity'));
create index events_violation_code_idx on semantic.events using btree ((violations ->> 'code'));


drop table if exists semantic.entities cascade;

create table semantic.entities as (
select distinct license_num, facility_type, location
from cleaned.inspections
);

create index entities_license_num_ix on semantic.entities (license_num);
create index entities_facility_type_ix on semantic.entities (facility_type);
create index entities_location_gix on semantic.entities using gist (location);

create index entities_license_num_facility_type_ix on semantic.entities (license_num, facility_type);
create index entities_license_num_location_ix on semantic.entities (license_num, location);
create index entities_facility_type_location_ix on semantic.entities (facility_type, location);
create index entities_license_num_facility_type_location_ix on semantic.entities (license_num desc, facility_type desc, location);
