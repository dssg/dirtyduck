create table violations as
select inspection_id, (regexp_matches(violation[1],'^(\d+)\.'))[1]::int as violation_type ,
violation[1] as violation_description,
violation[2] as violation_comment from
(
SELECT inspection_id, regexp_split_to_array(regexp_split_to_table(violations, '\| '),'- Comments') as violation
FROM inspections 

) b;
