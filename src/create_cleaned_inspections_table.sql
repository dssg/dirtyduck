drop table if exists cleaned.inspections ;

create table cleaned.inspections as (
select
inspection,
btrim(results) as results,
license_num,
dba_name as facility,
aka_name as facility_aka,
facility_type,
substring(risk from '\((.+)\)') as risk,
address,
zip as zip_code,
btrim(upper(city)) as city,
btrim(upper(type)) as type,
date,
extract(year from date) as year,
extract(month from date) as month,
extract(isodow from date) as day_of_week, -- Monday: 1 ... Sunday: 7
case
when extract(isodow from date) in (6,7) then TRUE
else FALSE
end as is_weekend,
extract(week from date) as week_of_year,
extract(quarter from date) as quarter,
ST_SetSRID(ST_MakePoint(longitude, latitude),4326) as location
from inspections
where results in ('Fail', 'Pass', 'Pass w/ Conditions')
)
