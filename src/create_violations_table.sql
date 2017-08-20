drop table if exists cleaned.violations;

create table cleaned.violations as (
select inspection,
btrim(tuple[1]) as violation_code,
btrim(tuple[2]) as violation_description,
btrim(tuple[3]) as violation_comment from
(
select
inspection,
regexp_split_to_array(
regexp_split_to_table(violations, '\|'),
'\.|- Comments:') as tuple
from inspections
where results in ('Fail', 'Pass', 'Pass w/ Conditions')
) as t
)
