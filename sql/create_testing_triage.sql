create schema if not exists triage;

drop table if exists triage.test;

create table triage.test as (
select
inspection, -- event
entity_id,
facility_type,
type as inspection_type, risk, -- variables
violations, -- json array of variables
date, location, zip_code -- spatio temporal dimensions
from semantic.events
where entity_id = 9581
)

drop table if exists triage.outcomes_9581;

create table triage.outcomes_9581 as (
select 
entity_id, 
date as outcome_date, 
(result = 'fail') as outcome
from semantic.events
where entity_id = 9581
);
