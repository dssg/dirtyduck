create schema if not exists eis_randomized;

drop table if exists eis_randomized.inspected;

create table eis_randomized.inspected as (
 with dates as (
    select days::date as outcome_date
    from
    generate_series(
       '2015-01-01'::date,
       current_date, '1 day'::interval) days
),
active_entities as (
   select entity_id, outcome_date
   from dates d
   left  join semantic_randomized.entities
   on outcome_date <@ daterange(start_time, end_time)
)

select
a.entity_id, outcome_date,
case when
inspection is null then FALSE
else TRUE
end as outcome
from active_entities as a
left join semantic_randomized.events as e 
on a.entity_id = e.entity_id and a.outcome_date = e.date
);

create index inspected_entity_ix on eis_randomized.inspected (entity_id);
create index inspected_outcome_date_ix on eis_randomized.inspected(outcome_date desc nulls last);
create index inspected_outcome_ix on eis_randomized.inspected(outcome);

create index inspected_entity_date_ix on eis_randomized.inspected(entity_id, outcome_date);
create index inspected_date_entity_ix on eis_randomized.inspected(outcome_date, entity_id);

drop table if exists eis_randomized.active_facilities;

create table eis_randomized.active_facilities as (
select
distinct
entity_id, 
'active'::VARCHAR  as state, 
start_time, 
coalesce(end_time, current_date) as end_time
from semantic_randomized.entities
);
