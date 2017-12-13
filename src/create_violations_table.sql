drop table if exists cleaned.violations cascade;

create table cleaned.violations as (
select
inspection,
license_num, -- This is a requirement of triage
date,
btrim(tuple[1]) as code,
btrim(tuple[2]) as description,
btrim(tuple[3]) as comment,
(case
  when btrim(tuple[1]) = '' then NULL
  when btrim(tuple[1])::int between 1 and 14 then 'critical'
  when btrim(tuple[1])::int between 15 and 29  then 'serious'
  else 'minor'
end
) as severity from
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
