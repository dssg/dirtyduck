drop table if exists cleaned.inspections cascade;

create table cleaned.inspections as (
select
inspection,
btrim(lower(results)) as result,
license_num,
btrim(lower(dba_name)) as facility,
btrim(lower(aka_name)) as facility_aka,
btrim(lower(facility_type)) as facility_type,
lower(substring(risk from '\((.+)\)')) as risk,
btrim(lower(address)) as address,
zip as zip_code,
btrim(lower(city)) as city,
substring(btrim(lower(type)) from 'canvass|task force|complaint|food poisoning|consultation|license') as type,
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
where results in ('Fail', 'Pass', 'Pass w/ Conditions') and license_num is not null
)
