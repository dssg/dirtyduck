create schema if not exists testing_triage;

drop table if exists testing_triage.events;

create table testing_triage.events as (
select
event_id, 
entity_id,
facility_type,
result,
type as inspection_type, risk, -- variables
violations, -- json array of variables
date, location, zip_code -- spatio temporal dimensions
from semantic.events
where entity_id in (9582, 10854)
)

drop table if exists testing_triage.outcomes;

create table testing_triage.outcomes as (
select 
entity_id, 
date as outcome_date, 
(result = 'fail') as outcome
from testing_triage.events
);
