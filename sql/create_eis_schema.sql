create schema if not exists eis;

drop table if exists eis.inspected;

create table eis.inspected as (
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
   left  join semantic.entities
   on outcome_date <@ daterange(start_time, end_time)
   --where entity_id = 2379
)
select
a.entity_id, outcome_date,
case when
inspection is null then FALSE
else TRUE
end as outcome
from active_entities as a
left join semantic.events as e 
on a.entity_id = e.entity_id and a.outcome_date = e.date
);

create index inspected_entity_ix on eis.inspected (entity_id);
create index inspected_outcome_date_ix on eis.inspected(outcome_date desc nulls last);
create index inspected_outcome_ix on eis.inspected(outcome);

create index inspected_entity_date_ix on eis.inspected(entity_id, outcome_date);
create index inspected_date_entity_ix on eis.inspected(outcome_date, entity_id);

drop table if exists eis.active_facilities;

create table eis.active_facilities as (
select
distinct
entity_id, 
'active'::VARCHAR  as state, 
start_time, 
coalesce(end_time, current_date) as end_time
from semantic.entities
);
