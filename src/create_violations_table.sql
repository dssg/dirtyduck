drop table if exists violations;

create table violations as
       select inspection::int  as entity_id,
              date as outcome_date,
              zip,
              risk,
              type as inspection_type,
              facility_type,
              license_num::varchar as license,
              dba_name as business_name,
              aka_name as aka,
              results,
              case
                   when left(results, 4) = 'Pass' then FALSE
                   else TRUE
              end as outcome,
              (regexp_matches(violation[1],'^(\d+)\.'))[1]::varchar as violation_type ,
              violation[1] as violation_description,
              violation[2] as violation_comment
       from
                     (
       select
              inspection,
              date, zip, risk, facility_type, dba_name, aka_name, results, license_num, type,
              regexp_split_to_array(regexp_split_to_table(violations, '\| '),'- Comments') as violation
        from inspections
        where lower(results) !~ '.*business*.'
       ) b;
