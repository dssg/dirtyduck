drop table if exists cleaned.violations cascade;

create table cleaned.violations as (
select
inspection,
license_num as entity_id, -- This is a requirement of triage
date as knowledge_date,
btrim(tuple[1]) as violation_code,
btrim(tuple[2]) as violation_description,
btrim(tuple[3]) as violation_comment from
(
select
inspection,
license_num,
date,
regexp_split_to_array(
regexp_split_to_table(coalesce(violations, '.- Comments:'), '\|'),   -- We don't want to loose inspections
'\.|- Comments:') as tuple
from inspections
where results in ('Fail', 'Pass', 'Pass w/ Conditions') and license_num is not null
) as t
)
