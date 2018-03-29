create schema if not exists inspections_randomized;

create temp table inspections_outcomes as (
select inspection, entity_id, date,
   (result = 'fail') as failed,
   (result = 'fail' and
       ('serious' = ANY(array_agg(obj ->> 'severity')) or 'critical' = ANY(array_agg(obj ->> 'severity')))
   ) as failed_major_violation
from
   (select inspection, entity_id, date, result, jsonb_array_elements(violations::jsonb) as obj from semantic_randomized.events)
as t1
group by inspection, entity_id, date, result
);


drop table if exists inspections_randomized.failed;

create table inspections_randomized.failed as (
select
entity_id,
date as outcome_date,
failed as outcome
from inspections_outcomes
);


drop table if exists inspections_randomized.failed_major_violation;

create table inspections_randomized.failed_major_violation as (
select
entity_id,
date as outcome_date,
failed_major_violation as outcome
from inspections_outcomes
);

drop table if exists inspections_randomized.active_facilities;

create table inspections_randomized.active_facilities as (
select
distinct
entity_id, 'active'::VARCHAR  as state, start_time, coalesce(end_time, '2020-12-31'::date) as end_time
from semantic_randomized.entities
);
