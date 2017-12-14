drop table if exists semantic.events cascade;

create table semantic.events as (

select i.inspection, type, i.license_num, facility_type, zip_code, city,
       i.date, risk, result,
json_agg(
    json_build_object(
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
group by i.inspection, type, i.license_num, facility_type, zip_code, city, i.date, risk, result
)
