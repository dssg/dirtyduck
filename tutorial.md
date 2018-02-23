- [Description of the problem to solve](#orgf45f2ba)
- [What do you need for this tutorial?](#org6c658f9)
- [Infrastructure](#orgeeb18b0)
- [What's next?](#orgf913eee)
- [Data preparation](#org07e2883)
  - [Downloading](#org3a392fb)
  - [Loading data to the database](#org4d74bf9)
  - [For the impatient](#org11ee3cf)
  - [Transforming (and cleaning) the data](#org880de9c)
    - [Rationale](#orge150381)
    - [Some documentation](#org8b5b55e)
    - [Reality check](#org059e6ed)
    - [Cleaning](#org55ef1af)
  - [Add semantics&#x2026;](#orga474fac)
    - [Entities table](#org850e3e2)
  - [Events table](#orge26ffab)
- [What's next?](#org1882d4b)
- [Exploring the Data](#org3834f0c)
- [What's next?](#orgd1cc719)
- [Triage](#org8bfe42b)
  - [Triage interface](#org75d5e95)
    - [A tale of two Tables](#org01e5396)
    - [Experiment's configuration file](#org2ff2505)
  - [Machine learning governance: The `RESULTS` schema](#orgc78f810)
    - [What are all the results tables about?](#org81c7a35)
  - [Audition](#orgbc67b02)
  - [Post-modeling](#org3bb503d)
- [What's next?](#orgccb7cc6)
- [Problem description](#orgbfd5b70)
- [Creating the labels](#org4380b2e)
- [Modeling using Machine Learning](#org7ecb94f)
  - [Creating a simple experiment](#org7541dce)
  - [Defining a baseline](#org5db3fbe)
  - [A more advanced experiment](#org0d2a8fb)
- [What's next?](#org8651d21)
- [Problem description](#org84553b0)
- [Creating the labels](#orgd3ffda1)
- [Modeling using Machine Learning](#org84b5cfc)
  - [Creating a simple Experiment](#org5b55703)
    - [Temporal configuration](#org2e724de)
    - [Features](#org7ca350d)
    - [Algorithm and hyperparameters](#org5032498)
  - [How can I pick the best one?](#org22db263)
- [Postmodeling](#orgd6b042f)
- [What's next?](#orgb72701c)
- [Notes](#org52bf477)
  - [A neat trick](#orgd2fb903)


<a id="orgf45f2ba"></a>

# Description of the problem to solve

The [Chicago's Food Inspections data set](https://data.cityofchicago.org/Health-Human-Services/Food-Inspections/4ijn-s7e5) is well know, and it has been used in several examples around the web (e.g. [here](https://chicago.github.io/food-inspections-evaluation/), [here](https://youtu.be/lyDLAutA88s) or [here](https://youtu.be/1dKonIT-Yak))

In this tutorial, we have two different goals: (1) an **Early Intervention System** or **EIS** and (2) **prioritize inspections**, the entity in which we are interested in both cases is the *facility*.

In the **EIS**, as a facility owner or manager, we want to predict if the facility under our control is at *risk* of been inspected in the following period of time.

In the **inspections prioritization**, we want to generate a list of facilities which are *likely* to have some **critical** o **serious** violation *given that* they are inspected.

Both problems are under the umbrella of the *supervised machine learning* problems. That means that we must need examples that specify the **outcome** in which are interested (in the ML jargon this is called a *label*).

The **outcome** is what differ between those two projects. For **EIS** the outcome is **inspected**, for **Inspections**, the outcome is **major violation found**.

The first scenario, is the following: you work for the Chicago's government, and you try to prioritize your resources (i.e. your inspection workforce), since they are limited. So, you will use the data (the same data set, remember) for answering the next question:

> Which X facilities are likely to violate some rule in the following Y period of time?

In this case maybe you are interested not in all the violations but in the more grave.

We will use the *same* data set, second, we will be the restaurant's owner, and we want to know:

> Will my restaurant be inspected in the *next X period of time?*

Where \(X\) could be 1 month, 1 week, 1 year, etc.

Knowing the answer to this question, allows you (as the restaurant's owner) to be prepared and take the pertinent actions.


<a id="org6c658f9"></a>

# What do you need for this tutorial?

[Docker](http://www.docker.com) and [Docker Compose](https://docs.docker.com/compose/) installed. That's it. Use the links for installing instructions.


<a id="orgeeb18b0"></a>

# Infrastructure

Besides data, in most of the data science projects you will need some other tools, for example a place to store the data (a database management system or **DBMS**), a way for putting your model to work (an **API**) and a interface for looking the performace of your trained models (for this tutorial we are proposing [tyra](https://github.com/dssg/tyra) and supporting software for postmodeling analysis)

We are proving a little script for managing all the infrastructure in a (hopefully) transparent way.

Before creating the infrastructure, change the string `your_password` for something else in the file `infrastructure/food_db/.env_example`

    POSTGRES_DB=food
    POSTGRES_HOST=0.0.0.0
    POSTGRES_USER=food_user
    POSTGRES_DB=food
    POSTGRES_PORT=5434
    POSTGRES_PASSWORD=your_password
    
    UID=1000
    GID=1000

Then, change the name of the file to `.env`.

Next run the following command

```shell
    ./tutorial.sh
```

Usage: ./tutorial.sh {start|stop|build|rebuild|run|logs|status|destroy|all|}

OPTIONS: -h|help Show this message start stop rebuild status destroy -t|triage -a|all

INFRASTRUCTURE: All the infrastructure needed is turned on! $ ./tutorial.sh start

Check the status of the containers: $ ./tutorial.sh status

Stop the tutorial's infrastructure: $ ./tutorial.sh stop

Destroy all the resources related to the tutorial: $ ./tutorial.sh destroy

Infrastructure logs: $ ./tutorial.sh -l

EXPERIMENTS: NOTE: The following commands assume that "sample\_experiment\_config.yaml" is located inside triage/experiment\_config directory

Run one experiment: $ ./tutorial.sh -t &#x2013;config\_file sample\_experiment\_config.yaml run

Validate experiment configuration file: $ ./tutorial.sh -t &#x2013;config\_file sample\_experiment\_config.yaml validate

Show experiment's temporal cross-validation blocks: $ ./tutorial.sh -t &#x2013;config\_file sample\_experiment\_config.yaml show\_temporal\_blocks

Triage help: $ ./tutorial.sh -t &#x2013;help

We need to create the infrastructure so, `start` it

    ./tutorial.sh start

This will take some minutes the first time.

You can check that everything is running smoothly with `status`

```shell
    ./tutorial.sh status
    :
```

Name Command State Ports

---

food\_db docker-entrypoint.sh postgres Up 0.0.0.0:5434->5432/tcp

The environment is composed (no pun intended) by three pieces: a `postgresql` database called `food_db`, a container that executes `triage` experiments and finally `bastion`, which includes a Login to the docker container called `bastion` using `postgresql` client (so you can interact with the database) and a full `python` environment (so you can code or modify the things that we will discuss in this tutorial). The idea is that you don't need to install anything in your laptop.

For accessing to the `postgresql` client type:

    ./tutorial.sh bastion

You will see something like:

    root@485373fb3c64:/$

The number surely will be different (i.e. not `485373fb3c64`).

Now the database is running, its named `food_db`, the single table in there named `inspections`

Let's check the `schema` of `inspections` table, first, type the next command to connect to the database

    psql ${FOOD_DB_URL}

and then, type the following command:

```sql
    \d raw.inspections
```

| Table "raw.inspections" |                   |           |
|----------------------- |----------------- |--------- |
| Column                  | Type              | Modifiers |
| inspection              | character varying | not null  |
| dba\_name               | character varying |           |
| aka\_name               | character varying |           |
| license\_num            | numeric           |           |
| facility\_type          | character varying |           |
| risk                    | character varying |           |
| address                 | character varying |           |
| city                    | character varying |           |
| state                   | character varying |           |
| zip                     | character varying |           |
| date                    | date              |           |
| type                    | character varying |           |
| results                 | character varying |           |
| violations              | character varying |           |
| latitude                | numeric           |           |
| longitude               | numeric           |           |
| location                | character varying |           |

Now, you can disconnect from the database typing `\q`

**NOTE**: If you want to clean your laptop of all this, you should type `./tutorial.sh destroy`. But don't to that now!

Well, you are all set now. Let's start now.


<a id="orgf913eee"></a>

# What's next?

Continue to [Preparing your data](data_preparation.md).

**NOTE** At least is explicity said the contrary, you should run all the following commands inside `bastion`.


<a id="org07e2883"></a>

# Data preparation


<a id="org3a392fb"></a>

## Downloading

```sh
     curl "https://data.cityofchicago.org/api/views/4ijn-s7e5/rows.csv?accessType=DOWNLOAD" > data/inspections.csv
```

We can check the size of the data set,

```sh
     ls -lh /data
```

total 189M -rw-rw-r&#x2013; 1 1000 1000 189M Feb 15 02:45 inspections.csv

And the (apparent) total number of rows

```shell
     wc -l inspections.csv
```

401071 inspections.csv


<a id="org4d74bf9"></a>

## Loading data to the database

Assuming that you are already inside `bastion`, run the following

```sh
     psql ${FOOD_DB_URL} -c 'select count(*) from raw.inspections'
```

count

---

0 (1 row)

(If you are connected to the database, you could just type `select count(*) from raw.inspections`

```sh
     psql ${FOOD_DB_URL} -c "\copy raw.inspections FROM '/data/inspections.csv' WITH HEADER CSV"
```

    COPY 164983

This is different to the number of rows that we calculated previously. The reason is that the columns `violations` contains several lines in some examples. But don't worry, the previous command took care about that.

Let's glimpse the data

```sh
     psql ${FOOD_DB_URL} -c 'select * from raw.inspections limit 1'
```

```org
    inspection |           dba_name           |           aka_name           | license_num | facility_type |      risk       |       address       |  city   | state |  zip  |    date    |   type    | results |                                                                                                                                                                                                                                                                                                                                             violations                                                                                                                                                                                                                                                                                                                                              |     latitude      |     longitude      |                location                 
   ------------+------------------------------+------------------------------+-------------+---------------+-----------------+---------------------+---------+-------+-------+------------+-----------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------+--------------------+-----------------------------------------
    2144907    | DUNKIN DONUTS/BASKIN ROBBINS | DUNKIN DONUTS/BASKIN ROBBINS |     2437220 | Restaurant    | Risk 2 (Medium) | 11525 S HALSTED ST  | CHICAGO | IL    | 60628 | 2018-02-13 | Complaint | Pass    | 38. VENTILATION: ROOMS AND EQUIPMENT VENTED AS REQUIRED: PLUMBING: INSTALLED AND MAINTAINED - Comments: REPAIR LEAKING FAUCET ON 3-COMPARTMENT SINK IN ICE CREAM PREP AREA. | 35. WALLS, CEILINGS, ATTACHED EQUIPMENT CONSTRUCTED PER CODE: GOOD REPAIR, SURFACES CLEAN AND DUST-LESS CLEANING METHODS - Comments: CLEAN INTERIOR OF VENTILATION HOOD ABOVE OVEN. | 33. FOOD AND NON-FOOD CONTACT EQUIPMENT UTENSILS CLEAN, FREE OF ABRASIVE DETERGENTS - Comments: CLEAN INTERIOR AND EXTERIOR OF ALL PREP COOLERS AND FREEZERS. | 41. PREMISES MAINTAINED FREE OF LITTER, UNNECESSARY ARTICLES, CLEANING  EQUIPMENT PROPERLY STORED - Comments: STORE MOP HEAD UPRIGHT TO PREVENT INSECT BREDING. | 41.68424992938432 | -87.64198089690963 | (41.68424992938432, -87.64198089690963)
   (1 row)

```

Ok, now you have some data! But still, we need to munging it to be able to use it in our Machine learning task.


<a id="org11ee3cf"></a>

## For the impatient

If you want to skip all the cleansing and transformation you can execute the following:

```sh
psql ${FOOD_DB_URL} < /sql/create_cleaned_inspections_table.sql

psql ${FOOD_DB_URL} < /sql/create_violations_table.sql

psql ${FOOD_DB_URL} < /sql/create_semantic_tables.sql
```

CREATE SCHEMA DROP TABLE SELECT 164178 DROP TABLE SELECT 618060 CREATE SCHEMA DROP TABLE SELECT 34812 CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX DROP TABLE SELECT 141721 CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX CREATE INDEX

If everything works, you should end with two new schemas: `cleaned` and `semantic`.

You could check that (from `psql`) With

```sql
\dn
```

| List of schemas |            |
|--------------- |---------- |
| Name            | Owner      |
| cleaned         | food\_user |
| postgis         | food\_user |
| public          | postgres   |
| raw             | food\_user |
| semantic        | food\_user |

If you want to do a little of EDA go to [Knowing your data](data_exploration.md) or if you are really impatient go straight to [Introduction to triage](triage_intro.md).

If you change your mind, continue reading.


<a id="org880de9c"></a>

## Transforming (and cleaning) the data


<a id="orge150381"></a>

### Rationale

For tackling a Machine Learning problem you need to identify the **entities** of your problem domain, and if your problem involves time, how those entities change over time, i.e. which **events** happened to that entity or which **events** where acted by the entity in question.

We will materialize that conceptualization in two different tables, one for entities and one for events, we will name those tables as `entities` and `events` respectively.

The entity is the **facility**, and the events that happen to that entity are the **inspections**.

The table `entities` should contain an unique identifier for the entity, some data specific for that entity (like name, age, status). The `events` table will include data related to the description of the inspection, but don't forget the two most important attributes of an event: its spatial position and its temporal location.

Before starting the cleaning, you should know one of the golden rules -that will make your life easier:

> *You must not change your original data*

The reason for this is, if you make some mistake, or if you want to try a different thing you will always can go back to the beginning and start over.

The transformation "road" that we will take in this tutorials that fulfills the golden rule is as follows:

1.  We put an exact copy of or data in the `raw` schema.
2.  We will apply some simple transformations that will clean our data and we will store that version on the `cleaned` schema.
3.  We will organize the data semantically in two unnormalized tables: `events` and `entities` in the `semantic` schema.
4.  Then We need to fulfill some `triage` idiosyncrasies, and create some other tables and store them in the schema `triage`.
5.  Finally, `triage` will take over, and it will create the schema `results`.


<a id="org8b5b55e"></a>

### Some documentation

The Chicago's food inspection dataset has some documentation located [here](https://data.cityofchicago.org/api/assets/BAD5301B-681A-4202-9D25-51B2CAE672FF?download=true). From it, we can make sense about the column's meaning, and the process that generates the data.

The meaning of interesting columns is the following according to the Documentation

1.  **Risk category of facility** (`risk`)

    > Each establishment is categorized as to its risk of adversely affecting the public’s health, with 1 being the highest and 3 the lowest. The frequency of inspection is tied to this risk, with risk 1 establishments inspected most frequently and risk 3 least frequently.

2.  **Inspection type** (`type`)

    > An inspection can be one of the following types: canvass, the most common type of inspection performed at a frequency relative to the risk of the establishment; consultation, when the inspection is done at the request of the owner prior to the opening of the establishment; complaint, when the inspection is done in response to a complaint against the establishment; license, when the inspection is done as a requirement for the establishment to receive its license to operate; suspect food poisoning, when the inspection is done in response to one or more persons claiming to have gotten ill as a result of eating at the establishment (a specific type of complaint- based inspection); task-force inspection, when an inspection of a bar or tavern is done. Re-inspections can occur for most types of these inspections and are indicated as such.

3.  **Results** (`results`)

    > An inspection can pass, pass with conditions or fail. Establishments receiving a ‘pass’ were found to have no critical or serious violations (violation number 1-14 and 15-29, respectively). Establishments receiving a ‘pass with conditions’ were found to have critical or serious violations, but these were corrected during the inspection. Establishments receiving a ‘fail’ were found to have critical or serious violations that were not correctable during the inspection. An establishment receiving a ‘fail’ does not necessarily mean the establishment’s licensed is suspended. Establishments found to be out of business or not located are indicated as such.

4.  **Violations** (`violations`)

    > An establishment can receive one or more of 45 distinct violations (violation numbers 1-44 and 70). For each violation number listed for a given establishment, the requirement the establishment must meet in order for it to NOT receive a violation is noted, followed by a specific description of the findings that caused the violation to be issued.
    
    From this definitions, we can deduct the following claims:
    
    1.  *risk* is related to the frequency of inspections of type *canvass*.
    2.  *consultation* is a compulsory inspections *before* the facility opens (so we can remove it from the data), the same happens with *license*.
    3.  *complaint* and *suspect food poisoning* inspections are triggered by the people, *consultation* is triggered by the owner of the facility.
    4.  *task-force* occurs against bar or taverns.
    5.  **Critical violations** are coded between `1-14`, **serious violations** between `15-29`. So, we can assume that the violations code `30` and onward are *minor* violations.
    6.  The description of the violation is actually what **wasn't** found, the comment are the steps that the facility should take in order of not receive the violation.
    7.  They are only three possible results of the inspection (plus the fact that the facility was not located or out of business).
    
    All the other columns should be self-explanatory.


<a id="org059e6ed"></a>

### Reality check

Let's check that we have **only** three different classifications for the `risk` of the Facility :

**NOTE** Execute this in `psql` inside the container `bastion`.

```sql
  select risk, count(*) from raw.inspections group by risk order by count(*) desc
```

| risk            | count  |
|--------------- |------ |
| Risk 1 (High)   | 115550 |
| Risk 2 (Medium) | 33922  |
| Risk 3 (Low)    | 15426  |
| [NULL]          | 65     |
| All             | 20     |

Ok, two more: `All` and `NULL` for a grand total of **5**. What about `types` of inspections?

```sql
  select count(distinct type) from raw.inspections
```

| count |
|----- |
| 108   |

Wow, we got **108** types of inspections instead of **5**.

Which are those types? How bad is it?

```sql
select type, count(*) from raw.inspections group by type order by count(*) desc limit 10
```

| type                     | count |
|------------------------ |----- |
| Canvass                  | 87871 |
| License                  | 21119 |
| Canvass Re-Inspection    | 17010 |
| Complaint                | 14979 |
| License Re-Inspection    | 7598  |
| Complaint Re-Inspection  | 6123  |
| Short Form Complaint     | 6066  |
| Suspected Food Poisoning | 735   |
| Consultation             | 667   |
| License-Task Force       | 605   |

This columns will require also cleaning. Finally, let's look `results` (should be 3)

```sql
  select results, count(*) from raw.inspections group by results order by count(*) desc
```

| results              | count |
|-------------------- |----- |
| Pass                 | 96686 |
| Fail                 | 31939 |
| Pass w/ Conditions   | 15625 |
| Out of Business      | 14743 |
| No Entry             | 4877  |
| Not Ready            | 1052  |
| Business Not Located | 61    |

Ok, disheartening. But, that is the reality of *real* data. We will try to clean this mess.


<a id="org55ef1af"></a>

### Cleaning

Let's see the data to figure out how we need to be transform it. We will concentrate at first in all columns except `violations`, we will deal with that later, since is more complex.

First, we will remove superfluous spaces and will transform the columns `type, results, dba_name, aka_name, facility_type, address, city` to lower case, also, we will clean `risk` keeping only the description (e.g. **high** instead of **Risk 1 (High)**).

We still need to clean the column `type` (it contains several more variations instead of the **seven** mentioned in the documentation: *canvass*, *complaint*, *license*, *re-inspection*, *task-force*, *consultation* and *suspect food poisoning*). For simplicity, we will use *regular expressions* and we will ignore *re-inspection*.

For the column `risk` , we will impute as `high` all the `NULL` and `All` values.

As we have seen (and we will continue see that) through all this tutorial, *data is always messy*, for example, in the column `dba_name` we have several different spellings: `SUBWAY` and `Subway`, `MCDONALDS` and `MC DONALD'S`, `DUNKIN DONUTS/BASKIN ROBBINS` and `DUNKIN DONUTS / BASKIN ROBBINS`, etc.

We could try a very simple cleaning strategy: convert all the names to lowercase, remove the trailing spaces, remove the apostrophe "`'"` and remove the spaces around "`/`". The problem with this approach is that we will be fixing the names that we just saw, but there are several other nuances down that list. Another approach is use [soundex](https://www.postgresql.org/docs/current/static/fuzzystrmatch.html), but that will (potentially) create a lot of mismatches. The real workaround is apply some *machine learning* to *deduplicate* the entities (This problem is related to the process of *deduplication* and there is another tutorial for that that uses anothe DSaPP tool: `pgdedup`). We wont follow that path here, we will stick with first alternative.

Let's move to the spatial columns (`state, city, zip, latitude, longitude`).

All the rows in the data should be from **Ilinois**, let's check that

```sql
select state, count(*) from raw.inspections group by state
```

| state  | count  |
|------ |------ |
| IL     | 164963 |
| [NULL] | 20     |

Ok, almost, We will assume that the `NULL` values are actually `IL` (We will impute them). Moving on the next spatial column, We expect that all the values in the column `city` are Chicago:

```sql
select lower(city) as city, count(*) from raw.inspections group by lower(city) order by count(*) desc limit 10
```

| city              | count  |
|----------------- |------ |
| chicago           | 164609 |
| [NULL]            | 146    |
| cchicago          | 42     |
| schaumburg        | 20     |
| maywood           | 16     |
| elk grove village | 12     |
| chicagochicago    | 9      |
| chestnut street   | 8      |
| evanston          | 8      |
| inactive          | 8      |

There are 140-ish rows with `NULL` values and forty-ish rows with the value `cchicago`, some more down the list, we got even `chicagochicago`. The rest value are different counties, but all of them are near to Chicago. We will ignore this column (or equivalently, we will assume that all the records are from Chicago.

The zip code has a similar `NULL` problem:

```sql
select count(*) from raw.inspections where zip is null or btrim(zip) = ''
```

| count |
|----- |
| 72    |

We could attempt to remove this `NULLs` using the location point or using similar names of restaurants, but for this tutorial we will remove them.

We will convert the coordinates latitude and longitude to a `Point`.

Continuing with the cleaning, we will drop the columns `state`, `latitude`, `longitude` (since these are (now) redundant, because the `Point` object). We will remove the column `city` since almost everything happens in Chicago (this is the Chicago's food inspection data set anyway).

Recap, we are keeping two columns related to the spatial location of the events: the administrative one (`zip_code`) and the exact point of the facility (`location`).

As a final step in the cleaning we will change the name of the columns for explicit or better names(e.g `results -> result, dba_name -> facility`, etc).

We will create a new `schema` called `cleaned`. The objective of this schema is twofold: keep our raw data as-is and store our assumptions and cleaning decisions separated from the raw in a schema that *semantically* is transmitting the information: "this is our clean data".

```sql
  create schema if not exists cleaned;
```

Then, we will create our mini **ETL** with our cleaning decisions:

```sql
drop table if exists cleaned.inspections cascade;

create table cleaned.inspections as (
with cleaned as (
select
inspection,
btrim(lower(results)) as result,
license_num,
btrim(lower(dba_name)) as facility,
btrim(lower(aka_name)) as facility_aka,
case when
facility_type is null then 'unknown'
else btrim(lower(facility_type))
end as facility_type,
lower(substring(risk from '\((.+)\)')) as risk,
btrim(lower(address)) as address,
zip as zip_code,
substring(
btrim(lower(regexp_replace(type, 'liquor', 'task force', 'gi')))
from 'canvass|task force|complaint|food poisoning|consultation|license|tag removal') as type,
date,
ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) as location
from raw.inspections
where zip is not null  -- removing NULL zip codes
)

select * from cleaned where type is not null
);
```

You could execute this code using (if you are not connected to the database):

```sh
psql ${FOOD_DB_URL} < /sql/create_cleaned_inspections_table.sql
```

SELECT 164178

Or, if you are connected to the database

    \i /code/create_cleaned_inspections_table.sql

```sql
 select count(inspection) from cleaned.inspections;
```

| count  |
|------ |
| 164178 |

Let's look closer the column `violations`:

```sql
select string_to_array(violations, '|') as violations_array from raw.inspections limit 1
```

| violations\_array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| {"38. VENTILATION: ROOMS AND EQUIPMENT VENTED AS REQUIRED: PLUMBING: INSTALLED AND MAINTAINED - Comments: REPAIR LEAKING FAUCET ON 3-COMPARTMENT SINK IN ICE CREAM PREP AREA. "," 35. WALLS, CEILINGS, ATTACHED EQUIPMENT CONSTRUCTED PER CODE: GOOD REPAIR, SURFACES CLEAN AND DUST-LESS CLEANING METHODS - Comments: CLEAN INTERIOR OF VENTILATION HOOD ABOVE OVEN. "," 33. FOOD AND NON-FOOD CONTACT EQUIPMENT UTENSILS CLEAN, FREE OF ABRASIVE DETERGENTS - Comments: CLEAN INTERIOR AND EXTERIOR OF ALL PREP COOLERS AND FREEZERS. "," 41. PREMISES MAINTAINED FREE OF LITTER, UNNECESSARY ARTICLES, CLEANING  EQUIPMENT PROPERLY STORED - Comments: STORE MOP HEAD UPRIGHT TO PREVENT INSECT BREDING."} |

Note that this column is structured in the following form:

-   If there are several violations reported, those violations will be separated by `'|'`
-   Every violation begins with a code and a description
-   Every violation could have **comments**, those comments appear after the string `- Comments:`

We will take that observations in account and create a new table called `cleaned.violations` to store

-   inspection
-   code
-   description
-   comments

```sql
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
   from raw.inspections
   where results in ('Fail', 'Pass', 'Pass w/ Conditions') and license_num is not null
   ) as t
   );
```

This code is in `/sql/create_violations_table.sql`, you can execute this as before.

If everything worked correctly you should be able to run the following code:

```sql
  select
  case when grouping(severity) = 1 then 'TOTAL' else severity end as severity,
  count(*) from cleaned.violations
  group by rollup (severity)
```

| severity | count  |
|-------- |------ |
| TOTAL    | 618060 |
| minor    | 487294 |
| [NULL]   | 12908  |
| critical | 38944  |
| serious  | 78914  |

As a last step, we should create from the cleaned tables the `entities` and `events` table.


<a id="orga474fac"></a>

## Add semantics&#x2026;


<a id="org850e3e2"></a>

### Entities table

The `entities` table should uniquely identify the entities and contain the attributes that describes the entity.

We could hope that `license_num` is the way to go for uniquely identify the facility, let's confirm this with some queries.

We will beging with the following query: *What are the top 5 licenses with more inspections?*

```sql
    select
    license_num, count(*) as total_inspections,
    coalesce(count(*) filter (where result = 'fail'), 0)
    as total_failures
    from cleaned.inspections
    group by license_num
    order by total_inspections desc
    limit 5;
```

| license\_num | total\_inspections | total\_failures |
|------------ |------------------ |--------------- |
| 0            | 420                | 111             |
| 1354323      | 192                | 1               |
| 14616        | 172                | 30              |
| 1574001      | 80                 | 4               |
| 1974745      | 59                 | 3               |

This looks weird, let's investigate a little about the `license_num` = `0`.

```sql
  select
  facility_type, count(*) as total_inspections,
  coalesce(count(*) filter (where result = 'fail'), 0)
  as total_failures
  from cleaned.inspections
  where license_num=0
  group by  facility_type
  order by total_inspections desc
  limit 10
```

| facility\_type  | total\_inspections | total\_failures |
|--------------- |------------------ |--------------- |
| restaurant      | 101                | 43              |
| special event   | 61                 | 8               |
| unknown         | 43                 | 10              |
| shelter         | 31                 | 6               |
| navy pier kiosk | 30                 | 4               |
| church          | 28                 | 3               |
| grocery store   | 16                 | 7               |
| church kitchen  | 14                 | 6               |
| private school  | 11                 | 1               |
| long term care  | 9                  | 1               |

Most of these are related to *special events*, *churchs*, *festivals* etc. But, What about the `restaurants` which have `license_num` = `0`?

```sql
  select
  license_num, facility, address, count(*) as total_inspections,
  coalesce(count(*) filter (where result = 'fail'), 0)
  as total_failures
  from cleaned.inspections
  where license_num=0
  and facility_type = 'restaurant'
  group by  license_num, facility, address
  order by total_inspections desc
  limit 10
```

| license\_num | facility                        | address               | total\_inspections | total\_failures |
|------------ |------------------------------- |--------------------- |------------------ |--------------- |
| 0            | british airways                 | 11601 w touhy ave     | 5                  | 1               |
| 0            | rib lady 2                      | 4203 w cermak rd      | 4                  | 3               |
| 0            | unlicensed                      | 7559 n ridge blvd     | 3                  | 1               |
| 0            | nutricion familiar              | 3000 w 59th st        | 3                  | 1               |
| 0            | taqueria la capital             | 3508 w 63rd st        | 3                  | 1               |
| 0            | herbalife                       | 6214 w diversey ave   | 3                  | 2               |
| 0            | las quecas                      | 2500 s christiana ave | 3                  | 1               |
| 0            | la michoacana                   | 4346 s california ave | 3                  | 1               |
| 0            | mrs. t's southern fried chicken | 3343 n broadway       | 3                  | 1               |
| 0            | vinces pizzeria & taqueria, inc | 1527 w devon ave      | 3                  | 1               |

We conclude that we can't use the `license_num` as the unique identifier.

If we go back to the columns of the table, we could try with the column `license_num` (assume that one license represents one establishment) and the column `address` (assume that one restaurant is in one place).

```sql
  select
  count(distinct license_num) as total_licenses,
  count(distinct facility) as total_facilities,
  count(distinct address) as total_addresses
  from cleaned.inspections
```

| total\_licenses | total\_facilities | total\_addresses |
|--------------- |----------------- |---------------- |
| 33557           | 24867             | 17061            |

We were expecting (naively) that we should get 1 `license_num` per `facility` per `address`, but it wasn't the case. This could be mean that several facilities share the name (e.g. Subway or Mc Donalds) or the license; another explanation is that several facilities share the same address, as the facilities at the stadium or the airport.

We will decide to use the combination of `license_num`, `facility`, `facility_aka`, `facility_type` and `address` to identify a facility:

```sql
select
license_num, facility, facility_type, facility_aka, address , count(*)
from cleaned.inspections
group by license_num, facility, facility_type, facility_aka, address
order by count(*) desc, facility, facility_aka, address, license_num, facility_type
limit 10
```

| license\_num | facility                     | facility\_type | facility\_aka            | address                 | count |
|------------ |---------------------------- |-------------- |------------------------ |----------------------- |----- |
| 1490035      | mcdonald's                   | restaurant     | mcdonald's               | 6900 s lafayette ave    | 46    |
| 1596210      | food 4 less midwest #552     | grocery store  | food 4 less              | 7030 s ashland ave      | 44    |
| 1142451      | jewel food  store # 3345     | grocery store  | jewel food  store # 3345 | 1224 s wabash ave       | 41    |
| 1302136      | mcdonald's                   | restaurant     | mcdonald's               | 70 e garfield blvd      | 40    |
| 1476553      | pete's produce               | grocery store  | pete's produce           | 1543 e 87th st          | 40    |
| 2083833      | mariano's fresh market #8503 | grocery store  | mariano's fresh market   | 333 e benton pl         | 38    |
| 1000572      | jewel food store #3030       | grocery store  | jewel food store #3030   | 7530 s stony island ave | 37    |
| 60184        | taqueria el ranchito         | restaurant     | taqueria el ranchito     | 2829 n milwaukee ave    | 37    |
| 1884255      | food 4 less                  | grocery store  | food 4 less              | 4821 w north ave        | 36    |
| 9154         | jimmy g's                    | restaurant     | jimmy g's                | 307 s kedzie ave        | 36    |

What attributes we want to add to the `entities` table? We should add all the attributes that describe the entity and doesn't depend on the event and are atemporal. Therefore we will add `zip_code`, `location` and some data about when this facility got their license or if this is still open. We will add `start_time, end_time`. These columns will be important because we won't wnat to do predictions on entities that aren't active. We will use the following definition

> A facility is active from their opening as a businness until it closes

We don't have this type of date directly in our data source, so we will use as an interval between the earliest date in the data source and the latest date **or** the greater data in which the **result** of the inspection was `out of business` or `business not located`.

```sql

create schema if not exists semantic;

drop table if exists semantic.entities cascade;

create table semantic.entities as (

with entities_date as (

  select
  license_num,
  facility,
  facility_aka,
  facility_type,
  address,
  zip_code,
  location,
  min(date) over (partition by license_num, facility, facility_aka, address) as start_time,
  max(case when
  result in ('out of business', 'business not located')
  then
  date
  else
  NULL
  end) over (partition by license_num, facility, facility_aka, address) as end_time
  from cleaned.inspections

)

select distinct
   dense_rank() over (w) as entity_id,
   license_num,
   facility,
   facility_aka,
   facility_type,
   address,
   zip_code,
   location,
   start_time,
   end_time
from entities_date
   window w as (order by license_num, facility, facility_aka, facility_type, address)
);


-- Adding some indices
create index entities_ix on semantic.entities (entity_id);

create index entities_license_num_ix on semantic.entities (license_num);
create index entities_facility_ix on semantic.entities (facility);
create index entities_facility_type_ix on semantic.entities (facility_type);
create index entities_zip_code_ix on semantic.entities (zip_code);

-- Spatial index
create index entities_location_gix on semantic.entities using gist (location);

create index entities_full_key_ix on semantic.entities (license_num, facility, facility_aka, facility_type, address);

```

Note that we add a *unique* identifier (`entity_id`) to this table

```sql
select count(*) from semantic.entities
```

| count |
|----- |
| 34812 |


<a id="orge26ffab"></a>

## Events table

We are ready for creating our events table. This table will describe the data related to the inspection. We also add columns from the facility inspected that will simplify the creation of *features* for our machine learning models.

```sql

drop table if exists semantic.events cascade;

create table semantic.events as (

with entities as (
  select * from semantic.entities
),

inspections as (
select
i.inspection, i.type, i.date, i.risk, i.result,
i.license_num, i.facility, i.facility_aka, i.facility_type, i.address, i.zip_code, i.location,
jsonb_agg(
    jsonb_build_object(
        'code', v.code,
        'severity', v.severity,
	'description', v.description,
	'comment', v.comment
	)
order  by code
) as violations
from cleaned.inspections as i
inner join
cleaned.violations as v
on i.inspection = v.inspection
group by
i.inspection, i.type, i.license_num, i.facility, i.facility_aka, i.facility_type, i.address, i.zip_code, i.location,
i.date, i.risk, i.result
)

select
i.inspection, e.entity_id, i.type, i.date, i.risk, i.result,
e.facility_type, e.zip_code, e.location,
i.violations
from entities as e
inner join
inspections as i
using (license_num, facility, facility_aka, facility_type, address, zip_code)

);

-- Add some indices
create index events_entity_ix on semantic.events (entity_id);
create index events_inspection_ix on semantic.events (inspection);
create index events_type_ix on semantic.events (type);
create index events_date_ix on semantic.events(date desc nulls last);
create index events_facility_type_ix on semantic.events  (facility_type);
create index events_zip_code_ix on semantic.events  (zip_code);

-- Spatial index
create index events_location_gix on semantic.events using gist (location);

-- JSONB indices
create index events_violations on semantic.events using gin(violations);
create index events_violations_json_path on semantic.events using gin(violations jsonb_path_ops);

create index events_inspection_entity_zip_code_date on semantic.events (inspection desc nulls last, entity_id, zip_code, date desc nulls last);

```

Our semantic data looks like:

```sql
select * from semantic.events limit 1
```

| inspection | entity\_id | type    | date       | risk | result | facility\_type | zip\_code | location                                           | violations                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---------- |---------- |------- |---------- |---- |------ |-------------- |--------- |-------------------------------------------------- |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1343315    | 1          | canvass | 2013-06-06 | low  | fail   | newsstand      | 60623     | 0101000020E6100000B005FE6352EE55C09053AD5BF3ED4440 | [{"code": "18", "comment": "THERE ARE OVER 40 RAT DROPPINGS AND THREE ACTIVE RODENT HOLES INSIDE THE ESTABLISHMENT, NO PEST CONTROL SERVICE", "severity": "serious", "description": "NO EVIDENCE OF RODENT OR INSECT OUTER OPENINGS PROTECTED/RODENT PROOFED, A WRITTEN LOG SHALL BE MAINTAINED AVAILABLE TO THE INSPECTORS"}, {"code": "19", "comment": "NO PRIVATE GARBAGE SERVICE, GARBAGE IS PUT INTO THE CITY CANS, OBTAIN A PRIVATE GARBAGE SERVICE", "severity": "serious", "description": "OUTSIDE GARBAGE WASTE GREASE AND STORAGE AREA; CLEAN, RODENT PROOF, ALL CONTAINERS COVERED"}, {"code": "24", "comment": "THE 2-COMPARTMENT SINK IS DAMAGED, UNSANITARY AND INOPPERABLE, INSTALL A THREE COMPARTMENT SINK TO CITY CODE,", "severity": "serious", "description": "DISH WASHING FACILITIES: PROPERLY DESIGNED, CONSTRUCTED, MAINTAINED, INSTALLED, LOCATED AND OPERATED"}, {"code": "26", "comment": "THERE IS NO EXPOSED HAND SINK IN THE FOOD SERVICE AREA OR ANYWHERE ELSE, INSTALL AN EXPOSED HAND SINK", "severity": "serious", "description": "ADEQUATE NUMBER, CONVENIENT, ACCESSIBLE, PROPERLY DESIGNED AND INSTALLED"}, {"code": "34", "comment": "THE FLOORS ARE FILTHY, CLEAN THE FLOORS FROM CORNER TO CORNER", "severity": "minor", "description": "FLOORS: CONSTRUCTED PER CODE, CLEANED, GOOD REPAIR, COVING INSTALLED, DUST-LESS CLEANING METHODS USED"}, {"code": "35", "comment": "THE WALLS ARE CRUMBLING, REPAIR THE WALLS SO THEY ARE SANITARY", "severity": "minor", "description": "WALLS, CEILINGS, ATTACHED EQUIPMENT CONSTRUCTED PER CODE: GOOD REPAIR, SURFACES CLEAN AND DUST-LESS CLEANING METHODS"}] |

```sql
select * from semantic.entities limit 1
```

| entity\_id | license\_num | facility              | facility\_aka | facility\_type | address        | zip\_code | location                                           | start\_time | end\_time |
|---------- |------------ |--------------------- |------------- |-------------- |-------------- |--------- |-------------------------------------------------- |----------- |--------- |
| 1          | 0            | 16th street newsstand | j.g.'s foods  | newsstand      | 3934 w 16th st | 60623     | 0101000020E6100000B005FE6352EE55C09053AD5BF3ED4440 | 2013-06-06  | [NULL]    |


<a id="org1882d4b"></a>

# What's next?

Now it is a good time for [Invest time knowing your data](data_exploration.md) this will pay out when you try to do feature engineering.


<a id="org3834f0c"></a>

# Exploring the Data

*Inspections time series*

*Number of facilities across time*

*Inspections on unique facilities across time*

*Which is the spatial distribution of Inspections?*

```sql
select
zip_code,
count(*) as total_inspections,
coalesce(count(*) filter (where result = 'fail'), 0)
as total_failures
from semantic.events
group by zip_code
order by total_inspections desc
limit 10
```

| zip\_code | total\_inspections | total\_failures |
|--------- |------------------ |--------------- |
| 60614     | 5290               | 1241            |
| 60647     | 4848               | 1054            |
| 60657     | 4822               | 1086            |
| 60611     | 4559               | 759             |
| 60622     | 4537               | 1144            |
| 60618     | 4236               | 739             |
| 60608     | 4123               | 995             |
| 60639     | 3801               | 926             |
| 60607     | 3733               | 844             |
| 60625     | 3657               | 833             |

```ipython
%matplotlib inline


import matplotlib as plt
import pandas as pd
import numpy as np

import seaborn as sns
sns.set_style("whitegrid")

df=pd.DataFrame(table, columns=['zip_code', 'total_inspections', 'total_failures'], dtype=np.int32)

sns.barplot(x="zip_code", y="total_inspections",  data=df, color="salmon", saturation=0.5)

```



<matplotlib.axes.\_subplots.AxesSubplot at 0x7f967aeb7080> <matplotlib.figure.Figure at 0x7f967aed9940> ![img](ipython-inline-images/ob-ipython-0b4f14ad004d5e920d6db571bd32525c.png)

*Which is the temporal distribution of the inspections?*

```sql
select
extract(year from date) as year, extract(month from date) as month,
count(*) as total_inspections,
coalesce(count(*) filter (where result = 'fail'), 0)
as total_failures
from semantic.events
group by rollup(year, month)
order by year asc, month asc
limit 10
```

| year | month | total\_inspections | total\_failures |
|---- |----- |------------------ |--------------- |
| 2010 | 1     | 1143               | 273             |
| 2010 | 2     | 1284               | 280             |
| 2010 | 3     | 1363               | 310             |
| 2010 | 4     | 1356               | 378             |
| 2010 | 5     | 1478               | 356             |
| 2010 | 6     | 1667               | 413             |
| 2010 | 7     | 1238               | 353             |
| 2010 | 8     | 1515               | 396             |
| 2010 | 9     | 1599               | 406             |
| 2010 | 10    | 1611               | 414             |

The number of inspections per month and the number of failed inspections seem to be more or less constant.

```sql
  select
  code,
  description,
  severity,
  count(*) as total
  from cleaned.violations
  group by code, description, severity
  order by total desc
  limit 10
```

| code | description                                                                                                                            | severity | total |
|---- |-------------------------------------------------------------------------------------------------------------------------------------- |-------- |----- |
| 34   | FLOORS: CONSTRUCTED PER CODE, CLEANED, GOOD REPAIR, COVING INSTALLED, DUST-LESS CLEANING METHODS USED                                  | minor    | 78383 |
| 35   | WALLS, CEILINGS, ATTACHED EQUIPMENT CONSTRUCTED PER CODE: GOOD REPAIR, SURFACES CLEAN AND DUST-LESS CLEANING METHODS                   | minor    | 69637 |
| 33   | FOOD AND NON-FOOD CONTACT EQUIPMENT UTENSILS CLEAN, FREE OF ABRASIVE DETERGENTS                                                        | minor    | 69117 |
| 38   | VENTILATION: ROOMS AND EQUIPMENT VENTED AS REQUIRED: PLUMBING: INSTALLED AND MAINTAINED                                                | minor    | 59218 |
| 32   | FOOD AND NON-FOOD CONTACT SURFACES PROPERLY DESIGNED, CONSTRUCTED AND MAINTAINED                                                       | minor    | 58874 |
| 41   | PREMISES MAINTAINED FREE OF LITTER, UNNECESSARY ARTICLES, CLEANING  EQUIPMENT PROPERLY STORED                                          | minor    | 37471 |
| 18   | NO EVIDENCE OF RODENT OR INSECT OUTER OPENINGS PROTECTED/RODENT PROOFED, A WRITTEN LOG SHALL BE MAINTAINED AVAILABLE TO THE INSPECTORS | serious  | 29709 |
| 36   | LIGHTING: REQUIRED MINIMUM FOOT-CANDLES OF LIGHT PROVIDED, FIXTURES SHIELDED                                                           | minor    | 28606 |
| 40   | REFRIGERATION AND METAL STEM THERMOMETERS PROVIDED AND CONSPICUOUS                                                                     | minor    | 17463 |
| 30   | FOOD IN ORIGINAL CONTAINER, PROPERLY LABELED: CUSTOMER ADVISORY POSTED AS NEEDED                                                       | minor    | 17414 |

This looks weird, the top most "violation" is not an actual violation. We will repeat the query, we will group by the `results`

```sql
  with inspections_violations as (
  select
  i.inspection, i.result,
  v.code
  from cleaned.inspections as i inner join cleaned.violations as v
  using(inspection)
  )


  select code, result,
  count(code) as count
  from inspections_violations
  group by rollup(code, result)
  order by count desc
  limit 10
```

| code   | result | count  |
|------ |------ |------ |
| [NULL] | [NULL] | 608557 |
| 34     | [NULL] | 78234  |
| 35     | [NULL] | 69508  |
| 33     | [NULL] | 68978  |
| 38     | [NULL] | 59085  |
| 32     | [NULL] | 58764  |
| 34     | pass   | 50751  |
| 33     | pass   | 44834  |
| 35     | pass   | 44455  |
| 38     | pass   | 37577  |

**NOTE**: You could also split between, *major violation found* and *minor violation found*, but we will keep this simple for the moment.

*How often change the risk in a facility?*

```sql
  select
  entity_id, risk || '->' || previous_risk as changes,
  count(*)
  from
  (
  select date, entity_id, risk, lag(risk) over w as previous_risk
  from semantic.events
  window w as (partition by entity_id order by date asc)
  ) as t
  where (risk <>  previous_risk)
  group by entity_id, risk || '->' || previous_risk
  order by  count(*) desc, entity_id
```

| entity\_id | changes   | count |
|---------- |--------- |----- |
| 17949      | high->low | 1     |
| 33725      | high->low | 1     |

Mmmm, it seems that there aren't a lot of changes in the `risk` classification of a facility.

*What are the top 5 locations with more inspections?*

```sql
  select
  address, count(*) as total_inspections,
  coalesce( count(*) filter (where result = 'fail'), 0)
  as total_failures
  from cleaned.inspections
  group by address
  order by total_inspections desc
  limit 5;
```

| address           | total\_inspections | total\_failures |
|----------------- |------------------ |--------------- |
| 11601 w touhy ave | 2020               | 257             |
| 5700 s cicero ave | 405                | 54              |
| 324 n leavitt st  | 363                | 86              |
| 500 w madison st  | 356                | 69              |
| 131 n clinton st  | 310                | 34              |


<a id="orgd1cc719"></a>

# What's next?

Well, with the data in place, it is time to know [the inner workings of `triage`](triage_intro.md).


<a id="org8bfe42b"></a>

# Triage

Predictive analytics projects require the coordination of many different tasks, such as feature generation, classifier training, evaluation, and list generation. These tasks are complicated in their own right, but in addition have to be combined in different ways throughout the course of the project.

`Triage` aims to provide interfaces to these different phases of a project, such as an Experiment. Each phase is defined by configuration specific to the needs of the project, and an arrangement of core data science components that work together to produce the output of that phase.

The domain problems that `triage` had in mind are (1) early warning systems / early intervention systems and (2) prioritization of resources for inspections.

`Triage` was created to facilitate the creation of supervised learning models, in particular classification models with an strong temporal component in the data.

The temporal component in the data set affects the modeling mainly in two ways, first, you need to be very careful and avoid *leakage* of information in the data, and second, in the possible temporal drifting of the data. `Triage` solves the first splitting the data in temporal blocks to be used in the temporal crossvalidation and using those blocks for the feature generation.

`Triage` uses the concept of *experiment*. An *experiment* consists in a series of steps which aim to generate a good model for predicting the *label* of an new instance of the data set. The steps are *feature generation*, *label generation*, *model training* and *model scoring*. In each of all this steps, `triage` will take care of the temporal nuances of the data.

You need to specify (via a configuration file) how you want to time split your data, which combination of machine learning algorithms and their hyperparameters, which kind of features you want to generate and which subset of those features you want to try in each model. So, the experiment consists in try every combination of algorithm, hyperparameters and feature subset, and evaluate their performance using a set of metrics (also specified in the config file).

`Triage` will train one model for each block generated, so when the experiment finishes you will have several models for each algorithm and selection of hyperparameters. `Triage` calls this a `model_group`.


<a id="org75d5e95"></a>

## Triage interface

`Triage` is very simple to use, but it contains a lot of complex concepts that we will try to clarify in this section of the tutorial.

For running a `triage` experiment you need the following:

-   `triage` installed in your environment (this is already install in the docker container). You can verify that `triage` is installed (and its version) typying the following inside an `ipython` session inside `bastion`:

```ipython
import triage

triage.__version__
```

'2.2.0'

-   A database with (obviously) and two tables (at minimum): one that describes the *outcome* of each event on the database and a table that contains the state of each entity.

-   An *experiment config file*, this is where the magic happen. We will discuss this file at length in this section of the tutorial.

With this three components you can create your `experiment` object and `run` it. In this tutorial we are providing a `docker` container that executes `triage` experiments. You can run the container as follows:

```sh
./tutorial.sh triage --help
```

Usage: triage\_experiment [OPTIONS] COMMAND [ARGS]&#x2026;

Options: &#x2013;config\_file PATH Triage's experiment congiguration file name NOTE: It's assumed that the file is located inside triage/experiment\_config) [required] &#x2013;triage\_db TEXT DB URL, in the form of 'postgresql://user:password@host\_db:host\_port/db', by default it gets this from the environment (TRIAGE\_DB\_URL) [required] &#x2013;replace / &#x2013;no-replace Triage will (or won't) replace all the matrices and models &#x2013;help Show this message and exit.

Commands: run show\_feature\_generators show\_temporal\_blocks validate

You already had the database (you were working on it the last two sections of the tutorial) and the tutorial provide a recent container with `triage` installed. So, here, like in a real project you just need to worry about the *experiment's configuration file*. But before, we need to setup two more Tables.


<a id="org01e5396"></a>

### A tale of two Tables

The first thing that `triage` will do is split the time that the data covers in blocks considering the time horizon for the *label* (i.e. the thing that we want to predict: *Which facilities will fail an inspection in the following 3 months?* In the case of **inspection prioritization** or *Would be my restaurant inspected in the following month?* If you are working in a **early warning system** problem.) This time horizon is calculated from a set of specific dates (`as_of_date` in triage parlance) that divide the blocks in past (for training the model) and future (for testing the model).

`Triage` will create those *labels* using information about the *outcome* of the event, taking in account the temporal structure of the data. As an example of an *outcome* consider this if a inspection is realized (the event) and the facility fails the inspection (outcome *true*) or not (outcome *false*).

So, for a given *as of date*, in our data, for each entity, `triage` will ask: Are positive outcomes in the future time horizon? If so, `triage` will generate a positive *label* for that specific entity on that *as of date*. Henceforth, we need to create an outcomes Table.

The table that is needed describe the *states* of each entity. The table should have columns `entity_id`, `start__time, end_time` and `state`. The states table allows us to only include rows in your matrices in a specific state. The rationale of this comes from the need of only predict for entities in a particular state: Do the restaurant still open? Do the restaurant is new? etc.

In order of exemplify and explain the working of `triage`, we will create a subset of the `semantic.events` : one facility (`entity_id` `9581`), only two variables (`inspection_type, risk`), and spatial and temporal dimensions for aggregation (`location`, `zip_code` and `date`).

For this end, we will create a new `schema` called `triage`

```sql
create schema if not exists triage;
```

Almost all the components of `triage` works with `SQL` tables stored in `PostgreSQL` (this is very important to remember), so, let's create our test table with the `entity_id` `9581`:

```sql
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
```

```sql
select 
entity_id, 
inspection_type, risk, 
date, 
zip_code 
from triage.test 
order by date desc
limit 5
```

| entity\_id | inspection\_type | risk   | date       | zip\_code |
|---------- |---------------- |------ |---------- |--------- |
| 9581       | complaint        | medium | 2017-02-21 | 60621     |
| 9581       | complaint        | medium | 2017-02-10 | 60621     |
| 9581       | complaint        | medium | 2016-12-22 | 60621     |
| 9581       | complaint        | medium | 2016-08-26 | 60621     |
| 9581       | complaint        | medium | 2016-08-11 | 60621     |

`triage.test` contains two categorical variables (`inspection_type,risk`), two differnent groups for aggregation (`location, zip_code`), and the date when the inspection happened (`date`).

For this test, we will keep things simple and define the *outcome* as `TRUE` if the inspection got a result adverse and `FALSE` Otherwise.

```sql
drop table if exists triage.outcomes_9581;

create table triage.outcomes_9581 as (
select 
entity_id, 
date as outcome_date, 
(result = 'fail') as outcome
from semantic.events
where entity_id = 9581
);

```

```sql
select * from triage.outcomes_9581 limit 5;
```

| entity\_id | outcome\_date | outcome |
|---------- |------------- |------- |
| 9581       | 2011-04-22    | f       |
| 9581       | 2010-02-24    | f       |
| 9581       | 2016-06-15    | f       |
| 9581       | 2016-02-17    | f       |
| 9581       | 2016-02-25    | f       |

```sql
select 
outcome, count(*) 
from triage.outcomes_9581
group by 1;
```

| outcome | count |
|------- |----- |
| f       | 39    |
| t       | 6     |

For the time being, we will only consider one facility *state*: Is the facility "active" or not? This *state* represents if the facility is on business at the moment of the inspection (we don't want to predict a facility that is not active).

```sql
drop table if exists triage.active_facilities_9581 cascade;

create table triage.active_facilities_9581 as (
    select 
    entity_id, facility_type, location, 
    start_time, 
    case
    when end_time is NULL
    then '2020-01-01'
    else end_time
    end as end_time,
    'active' as state 
    from semantic.entities
);

```

`Triage` doesn't support open date intervals, so we had to impute `end_time` with the date '2020-01-01'

```sql
select * from triage.active_facilities_9581 limit 1;
```

| entity\_id | facility\_type | location                                           | start\_time | end\_time  | state  |
|---------- |-------------- |-------------------------------------------------- |----------- |---------- |------ |
| 1          | newsstand      | 0101000020E6100000B005FE6352EE55C09053AD5BF3ED4440 | 2013-06-06  | 2020-01-01 | active |


<a id="org2ff2505"></a>

### Experiment's configuration file

The *experiment configuration file* is used to create the `experiment` object. Here, you will specify the temporal configuration, the features to be generated, the labels to learn and the models that you want to train in your data.

The configuration file is a `yaml` file with the following main sections:

-   **[temporal\_config](#orga41f658):** Temporal specification of the data, used for creating the blocks for temporal crossvalidation.

-   **`events_table`:** Table that contains the information about the labels to be predicted. This is the `outcomes` table that we describe earlier.

-   **[feature\_generation](#org976a91a):** Which spatio-temporal aggregations of the columns in the data set do you want to generate as features for the models?

-   **`state_config` :** Specify which objects are in a given state in a particular interval of time, you can use this for filter which objects should be included in the training and prediction. This is the `states` table described above.

-   **`model_group_keys`:** How do you want to identify the `model_group` in the database (so you can run analysis on them)

-   **`grid_config`:** Which combination of hyperparameters and algorithms will be trained and evaluated in the data set?

-   **`scoring`:** Which metrics will be calculated?

Two of the more important sections (and the more confusing too) are `temporal_config` and `feature_generation`. We will explain them at detail in the next sections.

1.  Temporal crossvalidation

    The most acute problems are avoiding leakaging information and feature generation in a temporal setting.
    
    `Triage` uses the handy `timechop` library for this purpose. `Timechop` will build ("chop") the data set in several temporal blocks. These blocks will be used for creating the features and matrices for the training and evaluation of the machine learning models.
    
    Timechop has several parameters, first, you need to specify The limits of your data:
    
    -   **`feature_start_time`:** data aggregated into features begins at this point (earliest date included in features)
    -   **`feature_end_time`:** data aggregated into features is from before this point (latest date included in features)
    -   **`label_start_time`:** data aggregated into labels begins at this point (earliest event date included in any label (event date >= label\_start\_time)
    -   **`label_end_time`:** data aggregated is from before this point (event date < label\_end\_time to be included in any label)
    
    Other parameters controls the *labels*' time horizon, you have two 'knobs', one for training and one for testing.
    
    -   **`training_label_timespans`:** how much time is covered by training labels (e.g., outcomes in the next 1 year? 3 days? 2 months?) (training prediction span)
    
    -   **`test_label_timespans`:** how much time is covered by test prediction (e.g., outcomes in the next 1 year? 3 days? 2 months?) (test prediction span)
    
    These parameters will be used, together with the *outcomes* table to generate the *labels*. In an **EIS** setting regularly both will have the same value. For **inspections prioritization** this value is most of the time equal to `test_durations` and to `model_update_frequency`.
    
    -   **`model_update_frequency`:** amount of time between train/test splits (how frequently to retrain models)
    
    -   **`test_durations`:** how far into the future should a model be used to make predictions (test span) **NOTE**: in the typical case of wanting a single prediction set immediately after model training, this should be set to 0 days
    
    This last parameter is other that differes if the problem is an **EIS** or an **inspections prioritization**. In the former is recommended to be equal to `model_update_frequency`, in the latter is determined by the organizational process: *how far out are you scheduling for?*.
    
    The equivalent of `test_durations` for the training matrices is `max_training_histories`
    
    -   **`max_training_histories`:** the maximum amount of history for each entity to train on (early matrices may contain less than this time if it goes past label/feature start times)
    
    Finally, we should specify how many rows per `entity_id` in the train and test matrix
    
    -   **`training_as_of_date_frequencies`:** how much time between rows for a single entity in a training matrix (list time between rows for same entity in train matrix)
    
    -   **`test_as_of_date_frequencies`:** how much time between rows for a single entity in a test matrix (time between rows for same entity in test matrix)
    
    The following images (We will show you how to generate them later) shows the time blocks of several configurations. We will change one parameter at the time so you could see how that affects the blocks.
    
    1.  `{feature, label}_{end, start}_Time`
    
        The image below shows these `{feature, label}_start_time` equal, and the same for the `{feature, label}_end_time` ones. These parameters show in the image as dashed vertical black lines. This setup would be our **base** example.
        
        The plot is divided in two horizontal lines ("Block 0" and "Block 1"). Each line is divided by vertical dashed lines, the grey ones are the boundaries of the data for features and data for labels, and in this image they coincide. The black dash lines represents the beginning and the end of the test set. In the "Block 0" those lines are `2017` and `2018`, in "Block 1" they are `2016` and `2017`.
        
        The shaded areas (in this image there is just one per block, but you will see another examples below) represents the span of all the *as of dates* They start with the oldest *as of date* and end in the latest. Each line inside that area represents the span for the label calculation. Those lines begin at the *as of date*. In each *as of date* all the entities will get calculated their features (to the past) and the labels (to the future). So in the image, we will have two sets of train/test, in the "Block 0" our entity `9587` will have 13 rows of features, and 12 on "Block 1". The trainned models will predict the label using the features calculated in that *as of date* in the test data set, the solitary line represents the label's time horizon in testing.
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_1.svg "feature and label start, end time equal")
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month'
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '1y'  
        
        But they can be different (maybe you have more data for features that data for labels)
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_2.svg "feature\_start\_time different different that label\_start\_time.")
        
            temporal_config:
                feature_start_time: '2010-01-01'   # <------- The change happened here!
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month'
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '1y'  
    
    2.  `model_update_frequency`
    
        From our **base** `temporal_config` example ([228](#org0e17af3)), we will change how often we want a new model, so we need more train/test sets:
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '6month' # <------- The change happened here!
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month'
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '1y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_3.svg "A smaller model\_update\_frequency (from 1y to 6month) (The number of blocks grew)")
    
    3.  `max_training_histories`
    
        With this parameter you could get a *growing window* for training (depicted in [234](#orgfb555e1)) or as in all the other examples, *fixed training windows*.
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month'
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '10y'  # <------- The change happened here!
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_4.svg "The size of the block is bigger now")
    
    4.  `_as_of_date_frequencies` and `test_durations`
    
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '3month' # <------- The change happened here!
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_5.svg "More rows per entity in the training block")
        
        Now, change `test_as_of_date_frequencies`
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month' 
            
                test_durations: '0d'
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '3month'<------- The change happened here!
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_6.svg "We should get more rows per entity in the test matrix, but that didn't happen. Why?")
        
        Nothing change, that's because the test set doesn't have "space", that is controlled by `test_durations`, let's move that to to `6month`
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month' 
            
                test_durations: '6month' <------- The change happened here!
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_7.svg "The test duration is bigger now, so we got 6 rows (since the "base" frequency is 1 month)")
        
        So, now we will move both parameters: `test_durations`, `test_as_of_date_frequencies`
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month' 
            
                test_durations: '6month' <------- The change happened here!
                test_label_timespans: ['1y'] 
                test_as_of_date_frequencies: '3month' <------- and also here!
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_8.svg "With more room in testing, now test\_as\_of\_date\_frequencies has some effect.")
    
    5.  `-label_timespans`
    
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['1y']
                training_as_of_date_frequencies: '1month' 
            
                test_durations: '0d' 
                test_label_timespans: ['3month']  <------- The change happened here!
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_9.svg "The label time horizon in testing is smaller")
        
            temporal_config:
                feature_start_time: '2014-01-01'
                feature_end_time: '2018-01-01'
                label_start_time: '2014-01-02'
                label_end_time: '2018-01-01'
            
                model_update_frequency: '1y' 
                training_label_timespans: ['3month'] <------- The change happened here!
                training_as_of_date_frequencies: '1month' 
            
                test_durations: '0d' 
                test_label_timespans: ['1y']  
                test_as_of_date_frequencies: '1month'
            
                max_training_histories: '10y'  
        
        \#+ATTR\_ORG :width 100 :height 100 \#+ATTR\_HTML :width 600 :height 400 \#+ATTR\_LATEX :width 400 :height 300 ![img](./images/timechop_10.svg "The label time horizon is smaller in trainning, also, now we have more room for more rows per entity.")

2.  Feature engineering

    We will show how to create features using the *experiments config file*. `triage` for this end, uses `collate`. `Collate` is the python library that controls the generation of features (including the imputation rules for each feature generated). `Collate` helps the modeler to create features based on *spatio-temporal aggregations* (which is what we need in our modeling strategy based on **events**)
    
    As a first feature we want to know in a given interval of time, in a given specific date (remember *as of date*), *how many Inspections do each facility had?* and *how many flags resulted in "high risk" after the last inspection?* (the `risk` column), happened to that facility and the same questions but aggregated in the zip code in which the facility operates.
    
    Let's try to construct that in `SQL`:
    
    ```sql
    select entity_id, zip_code,
    count(*) as inspections,
    count(*) filter (where risk='high') as flagged_as_high_risk
    from triage.test
    group by grouping sets(entity_id, zip_code)
    ```
    
    | entity\_id | zip\_code | inspections | flagged\_as\_high\_risk |
    |---------- |--------- |----------- |----------------------- |
    | 9581       | [NULL]    | 45          | 0                       |
    | [NULL]     | 60621     | 45          | 0                       |
    
    This query is making an *aggregation*.Note that the previous `SQL` query is composed by four parts:
    
    -   The filter ((`risk = 'high')::int`)
    -   The aggregation function (`count()`)
    -   The name of the resulting transformation (`flagged_as_high_risk`)
    -   The context in which it is aggregated (by `entity_id` and `zip_code`).
    
    What about if we want to add the proportion of all the inspections that resulted in be flagged as "high risk"?
    
    ```sql
    select entity_id, zip_code,
    count(*) as inspections,
    count(*) filter (where risk='high') as flagged_as_high_risk,
    avg((risk='high')::int) as proportion_of_flags_as_high_risk
    from triage.test
    group by grouping sets(entity_id, zip_code)
    ```
    
    | entity\_id | zip\_code | inspections | flagged\_as\_high\_risk | proportion\_of\_flags\_as\_high\_risk |
    |---------- |--------- |----------- |----------------------- |------------------------------------- |
    | 9581       | [NULL]    | 45          | 0                       | 0.00000000000000000000                |
    | [NULL]     | 60621     | 45          | 0                       | 0.00000000000000000000                |
    
    But, what if we want to add also "medium" and "low" risk? And note that we didn't add the temporal interval neither. You can see that the event this simple set of features will require a very complex `SQL` to be constructed.


<a id="orgc78f810"></a>

## Machine learning governance: The `RESULTS` schema

While `triage` is executing the experiment, it will create a new schema, called `results`. This schema has the goal of storing the output of the models and describing the features, parameters and hyperparameters used in their training.

The tables contained in `results` are:

```sql
\dt results.*
```

| List of relations |                         |       |            |
|----------------- |----------------------- |----- |---------- |
| Schema            | Name                    | Type  | Owner      |
| results           | evaluations             | table | food\_user |
| results           | experiments             | table | food\_user |
| results           | feature\_importances    | table | food\_user |
| results           | individual\_importances | table | food\_user |
| results           | list\_predictions       | table | food\_user |
| results           | model\_groups           | table | food\_user |
| results           | models                  | table | food\_user |
| results           | predictions             | table | food\_user |


<a id="org81c7a35"></a>

### What are all the results tables about?

`model_groups` stores the algorithm (`model_type`), the hyperparameters (`model_parameters`) and the features shared by a particular set of models. `models` contains data specific to a model of the `model_group` (you can use `model_group_id` for linking the model to a model group) this table also includes temporal information (like `train_end_time`) and a reference to the train matrix (`train_matrix_uuid`). This **UUID** is important since that is the name of the file in which the matrix is stored.

Lastly, `results.predictions` contains all the *scores* generated by every model for every entity. `results.evaluation` stores the value of all the **metrics** for every model. These metrics were specified in the `scoring` section in the config file.

1.  `results.experiments`

    This table has the two columns: `experiment_hash` and `config`
    
    ```sql
    \d results.experiments
    ```
    
    | Table "results.experiments"                                                                                                                        |                   |           |
    |-------------------------------------------------------------------------------------------------------------------------------------------------- |----------------- |--------- |
    | Column                                                                                                                                             | Type              | Modifiers |
    | experiment\_hash                                                                                                                                   | character varying | not null  |
    | config                                                                                                                                             | jsonb             |           |
    | Indexes:                                                                                                                                           |                   |           |
    | "experiments\_pkey" PRIMARY KEY, btree (experiment\_hash)                                                                                          |                   |           |
    | Referenced by:                                                                                                                                     |                   |           |
    | TABLE "results.models" CONSTRAINT "models\_experiment\_hash\_fkey" FOREIGN KEY (experiment\_hash) REFERENCES results.experiments(experiment\_hash) |                   |           |
    
    `experiment_hash` contains the hash of the config that we used for our `triage` run. `config` that contains the configuration experiment file that we used for our Triage run, stored as `jsonb`
    
    We can note for our future selfs: If we are interested in all models that resulted from a certain config, we could lookup that config In `results.experiments` and then use its `experiment_hash` on other tables to find all the models that resulted from that configuration.

2.  `results.model_groups`

    Do you remember how we defined in `grid_config` the different classifiers that we want `triage` to train? For example, we said:
    
        'sklearn.tree.DecisionTreeClassifier':
            criterion: ['entropy']
            max_depth: [1, 2, 5, 10]
            random_state: [2193]
    
    By doing so, we are saying that we want to train 4 decision trees (`max_depth` is one of `1, 2, 5, 10`). However, remember that we are using temporal cross-validation to build our models. That means that we are going to have different slices of time that we are training our models on, e.g., 2010-2011, 2011-2012, etc.
    
    Therefore, we are going to train our four configurations of the decision trees on each time slice. Therefore, the trained model (or the instance of that model) will change across time splits, but the configuration will remain the same. This table lets us keep track of the different configurations (`model_groups`) and gives us an `id` for each configuration (`model_group_id`). We can leverage the `model_group_id` to find all the models that were trained by using the same config, but across different slices of time.
    
    ```sql
    select 
    model_group_id, model_type, model_parameters, model_config
    from 
    results.model_groups
    limit 1
    ```
    
    | model\_group\_id | model\_type                         | model\_parameters                     | model\_config                                               |
    |---------------- |----------------------------------- |------------------------------------- |----------------------------------------------------------- |
    | 1                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": 1} | {"experiment\_type": "test", "label\_definition": "failed"} |
    
    You can see that a model group is defined by the classifier (`model_type`), its parameters (`model_parameters`), the features (`feature_list`) (not shown), and the `model_config`. The `model_config` follows from the `model_group_keys` we had defined in the configuration file:
    
    -   'train\_duration'
    -   'label\_window'
    -   'example\_Frequency'
    
    *What can we learn from that?* For example, if we add a new feature and rerun `triage`, `triage` will create a new `model_group` even if the classifier and the `model_parameters` are the same as before.

3.  `results.models`

    This table stores the information about our actual *models*, i.e., instances of our classifiers trained on specific time Slices.
    
    ```sql
    \d results.models
    ```
    
    | Table "results.models"                                                                                                                                     |                             |                                                                      |
    |---------------------------------------------------------------------------------------------------------------------------------------------------------- |--------------------------- |-------------------------------------------------------------------- |
    | Column                                                                                                                                                     | Type                        | Modifiers                                                            |
    | model\_id                                                                                                                                                  | integer                     | not null default nextval('results.models\_model\_id\_seq'::regclass) |
    | model\_group\_id                                                                                                                                           | integer                     |                                                                      |
    | model\_hash                                                                                                                                                | character varying           |                                                                      |
    | run\_time                                                                                                                                                  | timestamp without time zone |                                                                      |
    | batch\_run\_time                                                                                                                                           | timestamp without time zone |                                                                      |
    | model\_type                                                                                                                                                | character varying           |                                                                      |
    | model\_parameters                                                                                                                                          | jsonb                       |                                                                      |
    | model\_comment                                                                                                                                             | text                        |                                                                      |
    | batch\_comment                                                                                                                                             | text                        |                                                                      |
    | config                                                                                                                                                     | json                        |                                                                      |
    | experiment\_hash                                                                                                                                           | character varying           |                                                                      |
    | train\_end\_time                                                                                                                                           | timestamp without time zone |                                                                      |
    | test                                                                                                                                                       | boolean                     |                                                                      |
    | train\_matrix\_uuid                                                                                                                                        | text                        |                                                                      |
    | training\_label\_timespan                                                                                                                                  | interval                    |                                                                      |
    | Indexes:                                                                                                                                                   |                             |                                                                      |
    | "models\_pkey" PRIMARY KEY, btree (model\_id)                                                                                                              |                             |                                                                      |
    | "ix\_results\_models\_model\_hash" UNIQUE, btree (model\_hash)                                                                                             |                             |                                                                      |
    | Foreign-key constraints:                                                                                                                                   |                             |                                                                      |
    | "models\_experiment\_hash\_fkey" FOREIGN KEY (experiment\_hash) REFERENCES results.experiments(experiment\_hash)                                           |                             |                                                                      |
    | "models\_model\_group\_id\_fkey" FOREIGN KEY (model\_group\_id) REFERENCES results.model\_groups(model\_group\_id)                                         |                             |                                                                      |
    | Referenced by:                                                                                                                                             |                             |                                                                      |
    | TABLE "results.evaluations" CONSTRAINT "evaluations\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id)                         |                             |                                                                      |
    | TABLE "results.feature\_importances" CONSTRAINT "feature\_importances\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id)       |                             |                                                                      |
    | TABLE "results.individual\_importances" CONSTRAINT "individual\_importances\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id) |                             |                                                                      |
    | TABLE "results.list\_predictions" CONSTRAINT "list\_predictions\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id)             |                             |                                                                      |
    | TABLE "results.predictions" CONSTRAINT "predictions\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id)                         |                             |                                                                      |
    
    Noteworthy columns are:
    
    -   **`model_id`:** The id of the model (i.e., instance&#x2026;). We will use this ID to trace back a model's performance evaluation to a `model_group` and vice versa.
    -   **`model_group_id`:** The id of the models model\_group we encountered above.
    -   **`model_hash`:** The *hash* of our model. We can use the hash to load the actual model. It gets stored under `TRIAGE_OUTPUT_PATH/trained_models/{model_hash}`. We are going to this later to look at a trained decision tree.
    -   **`run_time`:** Time when the model was trained.
    -   **`model_type`:** The algorithm used for trainning
    -   **`model_parameters`:** Hyperparameters used for the model configuration.
    -   **`experiment_hash`:** The hash of our experiment. We encountered this value in the `results.experiments` table before.
    -   **`train_end_time`:** When building the training matrix, we included training samples up until this date.
    -   **`train_matrix_uuid`:** The *hash* of the matrix that we used to train this model. The matrix gets stored as `csv` under `TRIAGE_OUTPUT_PATH/matrices/{train_matrix_uuid}.csv`. This is very helpful when trying to inspect the matrix and features that were used for training.
    -   **`train_label_window`:** How big was our window to get the labels for our training matrix? For example, a `train_label_window` of 1 year would mean that we look one year from a given date in the training matrix into the future to find the label for that training sample.

4.  `results.evaluations`

    This table lets us analyze how well our models are doing. Based on the config that we used for our `triage` run, `triage` is calculating metrics and storing them in this table, e.g., our model's precision at top 10%.
    
    ```sql
    \d results.evaluations
    ```
    
    | Table "results.evaluations"                                                                                                                    |                             |           |
    |---------------------------------------------------------------------------------------------------------------------------------------------- |--------------------------- |--------- |
    | Column                                                                                                                                         | Type                        | Modifiers |
    | model\_id                                                                                                                                      | integer                     | not null  |
    | evaluation\_start\_time                                                                                                                        | timestamp without time zone | not null  |
    | evaluation\_end\_time                                                                                                                          | timestamp without time zone | not null  |
    | as\_of\_date\_frequency                                                                                                                        | interval                    | not null  |
    | metric                                                                                                                                         | character varying           | not null  |
    | parameter                                                                                                                                      | character varying           | not null  |
    | value                                                                                                                                          | numeric                     |           |
    | num\_labeled\_examples                                                                                                                         | integer                     |           |
    | num\_labeled\_above\_threshold                                                                                                                 | integer                     |           |
    | num\_positive\_labels                                                                                                                          | integer                     |           |
    | sort\_seed                                                                                                                                     | integer                     |           |
    | Indexes:                                                                                                                                       |                             |           |
    | "evaluations\_pkey" PRIMARY KEY, btree (model\_id, evaluation\_start\_time, evaluation\_end\_time, as\_of\_date\_frequency, metric, parameter) |                             |           |
    | Foreign-key constraints:                                                                                                                       |                             |           |
    | "evaluations\_model\_id\_fkey" FOREIGN KEY (model\_id) REFERENCES results.models(model\_id)                                                    |                             |           |
    
    Its columns are:
    
    -   **`model_id`:** Our beloved `model_id` that we have encountered before.
    -   **`evaluation_start_time`:** After training the model, we evaluate it on a test matrix. This column tells us the earliest time that an example in our test matrix could have.
    -   **`evaluation_end_time`:** After training the model, we evaluate it on a test matrix. This column tells us the latest time that an example in our test matrix could have.
    -   **`metric`:** Indicates which metric we are evaluating, e.g., `precision@`.
    -   `parameter` ::Indicates at which parameter we are evaluating our metric, e.g., a metric of precision@ and a parameter of `100.0_pct` shows us the `precision@100pct`
    -   **`value`:** The value observed for our metric@parameter.
    -   **`num_labeled_examples`:** The number of labeled examples in our test matrix. Why does it matter? It could be the case that we have entities that we did not observe a label for during our test timeframe (for example in the [inspections prioritization](inspections.md) problem) . We still want to make predictions for these entities, but can't include them when calculating performance metrics.
    -   **`num_labeled_above_threshold`:** How many examples were labeled as above our treshold?
    -   **`num_positive_labels`:** The number of rows that had a true positive labels.
    
    A look at the table shows that we have multiple rows for each model to show the different performance metrics.
    
    ```sql
    select * from
    results.evaluations
    limit 5
    ```
    
    | model\_id | evaluation\_start\_time | evaluation\_end\_time | as\_of\_date\_frequency | metric     | parameter | value               | num\_labeled\_examples | num\_labeled\_above\_threshold | num\_positive\_labels | sort\_seed |
    |--------- |----------------------- |--------------------- |----------------------- |---------- |--------- |------------------- |---------------------- |------------------------------ |--------------------- |---------- |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | 1 mon                   | precision@ | 5.0\_pct  | 0.2653061224489796  | 1034                   | 49                             | 247                   | 5          |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | 1 mon                   | recall@    | 5.0\_pct  | 0.05263157894736842 | 1034                   | 49                             | 247                   | 5          |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | 1 mon                   | precision@ | 10.0\_pct | 0.2641509433962264  | 1034                   | 106                            | 247                   | 5          |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | 1 mon                   | recall@    | 10.0\_pct | 0.11336032388663968 | 1034                   | 106                            | 247                   | 5          |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | 1 mon                   | precision@ | 5\_abs    | 0.0                 | 1034                   | 0                              | 247                   | 5          |
    
    This table lets us answer: *how a model\_group is performing across the different time slices?*:
    
    ```sql
    select
    model_id, 
    evaluation_start_time, 
    evaluation_end_time,
    metric,
    parameter,
    value
    from results.evaluations
    where model_id in (
          select model_id from results.models where model_group_id=1
          )
    and metric='precision@' and parameter in ('100.0_pct', '5.0_pct')
    order by model_id, evaluation_start_time, parameter;
    ```
    
    | model\_id | evaluation\_start\_time | evaluation\_end\_time | metric     | parameter | value               |
    |--------- |----------------------- |--------------------- |---------- |--------- |------------------- |
    | 1         | 2016-01-01 00:00:00     | 2016-01-01 00:00:00   | precision@ | 5.0\_pct  | 0.2653061224489796  |
    | 7         | 2017-01-01 00:00:00     | 2017-01-01 00:00:00   | precision@ | 5.0\_pct  | 0.29333333333333333 |
    
    *What does this query tell us?*
    
    We can now see how the different instances (trained on different time slices, but with same model params) of one of our models perform over time. We are including the `precision@5.0_pct` to see what the **baseline** is. As you can see above, our model is beating the baseline in every year. Note how we only included the *models* that belong to Our *model group* `1`.

5.  `results.predictions`

    You can think of the previous table `results.evaluations` as a summary of individuals predictions that our model is making. But where can you find the individual predictions that our model is making? (So you can generate a list from here). And where can we find the test matrix that the predictions are based on? Let us introduce you to The `results.predictions` table.
    
    Here is what its first row looks Like:
    
    ```sql
    select *
    from results.predictions
    limit 1
    ```
    
    | model\_id | entity\_id | as\_of\_date        | score               | label\_value | rank\_abs | rank\_pct | matrix\_uuid                     | test\_label\_timespan |
    |--------- |---------- |------------------- |------------------- |------------ |--------- |--------- |-------------------------------- |--------------------- |
    | 1         | 1          | 2016-01-01 00:00:00 | 0.21631588415182587 | [NULL]       | [NULL]    | [NULL]    | f5ba9602cf9da2cc2fa74eede6ef6d17 | 1 mon                 |
    
    As you can see, the table contains our models' predictions for a given entity and date. In the case above, our *model* (`model_id 1`) predicted a score of `d` `0.21631588415182587` . The true label was `d` `[NULL]`.
    
    And do you notice the field `matrix_uuid`? Doesn't it look similar to the fields from above that gave us the names of our training matrices? In fact, it is the same. You can find the test matrix that was used to make this prediction under `TRIAGE_OUTPUT_PATH/matrices/{matrix_uuid}.csv`

6.  TODO : `results.feature_importances`

7.  TODO : `results.individual_importances`

8.  TODO : `results.list_predictions`

    | key | value |
    |--- |----- |
    | a   | 1     |
    | b   | 2     |
    
    Is there any way to refer to cell @2$2 within the text of an org-mode document, and have that reference converted to the value `d` `2` during export?


<a id="orgbc67b02"></a>

## Audition

**Audition** is a tool for helping you to select a subset of trained classifiers from a triage experiment. Often, production-scale experiments will come up with thousands of trained models, and sifting through all of those results can be time-consuming even after calculating the usual basic metrics like precision and recall.

You will be facing questions as:

-   Which metrics matter most?
-   Should you prioritize the best metric value over time or treat recent data as most important?
-   Is low metric variance important?

The answers to questions like these may not be obvious up front. **Audition** introduces a structured, semi-automated way of filtering models based on what you consider important


<a id="org3bb503d"></a>

## Post-modeling

As the name indicates, **postmodeling** occurs **after** you have modeled (potentially) thousands of models (different hyperparameters, different time windows, different algorithms, etc), and using `audition` you *pre* selected a small number of models.

Now, with the **postmodeling** tools you will be able to select your final model for using it in *production*.

Triage's postmodeling capabilities include:

-   Show the score distribution
-   Compare the list generated by a set of models
-   Compare the feature importance between a set of models
-   Diplay the probability calibration curves
-   Error analysis using a decision treee trained in the errors of the model.
-   Cross-tab analysis
-   Bias analysis

If you want to see **Audition** and **Postmodeling** in action please refer [Inspections modeling](inspections.md) or to [EIS modeling](eis.md) for practical examples.


<a id="orgccb7cc6"></a>

# What's next?

We will begin with [Inspections problem](inspections.md), let's go for It


<a id="orgbfd5b70"></a>

# Problem description

We will begin with the the **inspections prioritization** problem: we want to generate a list of facilities which are *likely* to have some **critical** o **serious** violation *given that* they are inspected.

The scenario, is the following: you work for the City of Chicago and you try to prioritize your resources (i.e. your inspection workforce), since they are limited. So, you will use the data for answering the next question:

> Which X facilities are likely to violate some code in the following Y period of time?

In this case maybe you are interested not in all the violations but in the more severe ones.


<a id="org4380b2e"></a>

# Creating the labels

We will define two different labels:

-   **Which facilities are likely to fail an inspection?**

Facilities who failed an inspection (i.e. `result` = `'fail'`)

-   **Which facilities are likely to fail an inspection with a major violation?**

Rremember that critical violations are coded between `1-14`, serious violations between `15-29`, everything above `30` is assumed to be a minor violation.

Facilities who failed an inspection (i.e. `result` = `'fail'`) and the `severity in ('critical', 'serious')`

We could extract the severity of the violation inspected using the following code:

```sql

select inspection, 
date,
result, 
array_agg(obj ->>'severity') as violations_severity,
(result = 'fail') as failed,
(result = 'fail' and
('serious' = ANY(array_agg(obj ->> 'severity')) or 'critical' = ANY(array_agg(obj ->> 'severity')))
) as failed_major_violation
from
(select inspection,date, result, jsonb_array_elements(violations::jsonb) as obj from semantic.events limit 20)
as t1
group by inspection, date, result
order by date desc

```

| inspection | date       | result | violations\_severity                                     | failed | failed\_major\_violation |
|---------- |---------- |------ |-------------------------------------------------------- |------ |------------------------ |
| 1770568    | 2016-05-11 | pass   | {critical,minor,minor,serious,serious}                   | f      | f                        |
| 1763967    | 2016-05-03 | fail   | {minor,critical,serious,serious,minor,minor,minor,minor} | t      | t                        |
| 1343315    | 2013-06-06 | fail   | {minor,serious,serious,serious,serious,minor}            | t      | t                        |
| 537439     | 2011-06-10 | fail   | {NULL}                                                   | t      | [NULL]                   |

Let's use the previous query to generate our outcomes in a new `inspections` Schema.

```sql
create schema if not exists inspections;
```

`Triage` has some restrictions (at the current version) about how to name (some) columns, in specific, our columns should include:

-   **`entity_id`    :** The entity affected / causing the event (In our case the facility)
-   **`outcome_date` :** The date in which the event happen / The date in which we discover the result (The inpection's date)
-   **`outcome`      :** The result (label) of the event (One of the labels speecified before)

`entity_id` an identifier for which the labels are applied to, `outcome_date` the date at which some outcome was known, `outcome` a boolean outcome.

Since we defined two labels, we will create two tables one per each outcome.

```sql

create temp table inspections_outcomes as (
select inspection, entity_id, date,
   (result = 'fail') as failed,
   (result = 'fail' and
       ('serious' = ANY(array_agg(obj ->> 'severity')) or 'critical' = ANY(array_agg(obj ->> 'severity')))
   ) as failed_major_violation
from
   (select inspection, entity_id, date, result, jsonb_array_elements(violations::jsonb) as obj from semantic.events)
as t1
group by inspection, entity_id, date, result
);


drop table if exists inspections.failed;

create table inspections.failed as (
select
entity_id,
date as outcome_date,
failed as outcome
from inspections_outcomes
);


drop table if exists inspections.failed_major_violation;

create table inspections.failed_major_violation as (
select
entity_id,
date as outcome_date,
failed_major_violation as outcome
from inspections_outcomes
);

```

Also, We need to create a new version of the `semantic.entities` table. `Triage` refers to this new table as the **states** table. It should have columns `entity_id`, `start__time, end_time` and `state`. The states table allows us to only include rows in your matrices in a specific state. In our case we only want to inspect **active** facilities. We will replace all the `NULL` values in the `end_time` column for a date in the future, in particular `2020-12-31`.

```sql

drop table if exists inspections.active_facilities;

create table inspections.active_facilities as (
select
distinct
entity_id, 'active'::VARCHAR  as state, start_time, coalesce(end_time, '2020-12-31'::date) as end_time
from semantic.entities
);
```


<a id="org7ecb94f"></a>

# Modeling using Machine Learning

It is time of getting all the previous steps and put them together. Don't worry, actually we are done with coding. `Triage` provides you with a configuration file for specifying the experiment that we want to run.


<a id="org7541dce"></a>

## Creating a simple experiment

For this first experiment we will try one of the simplest machine learning algorithms: a **Decision Tree Classifier**. We need to write the experiment config file for that, let's break it down and explain all the sections.

The config file for this first experiment is located in <triage/experiment_config/inspections_test.yaml>

The first lines of the experiment config file are related to the version config file (`v3` at the moment of writing this tutorial), a comment (`model_comment`), this will end up as a value in the `results.models` table, and a list of user defined metadata (`user_metadata`) that could be used for identifying the resulting model groups. In our test example, if you run experiments that share a temporal configuration but that use different label definitions (say, labeling building inspections with **any** violation as positive or labeling only building inspections with major violations as positive), you can use the user metadata keys to indicate that the matrices from these experiments have different labeling criteria. The matrices from the two experiments will have different filenames (and not be overwritten or inappropriately reused), and if you add the `label_definition` key to the `model_group_keys`, models made on different label definition will have different groups.

```yaml
config_version: 'v3'

model_comment: 'inspections_test'

user_metadata:
  label_definition: 'failed'
  experiment_type: 'inspections prioritization'
  purpose: 'test'
  org: 'DSaPP'
  team: 'Tutorial'
  author: 'Your name here'
```

Next, the **temporal configuration** section. The first four parameters are related to the availability of data: How much data you have for feature creation? How much data you have for label generation? For simplicity we will assume that we can use the full `semantic.events` time span for both.

```sql
select min(date), max(date) from semantic.events
```

| min        | max        |
|---------- |---------- |
| 2010-01-04 | 2018-02-13 |

The next parameters are related to the training intervals:

-   How frequently to retrain models? (`model_update_frequency`)
-   How many rows per entity in the train matrices? (`training_as_of_date_frequencies`)
-   How much time is covered by labels in the training matrices? (`training_label_timespans`)

The remaining elements are related to the **testing** matrices, in the particular case of **inspections**, you can choose them as follows:

-   `test_as_of_date_frequencies` is planning/scheduling frequency
-   `test_durations` is how far out are you scheduling for?
-   `test_label_timespan` is equal to `test_durations`

Let's assume that we need to do rounds of inspections every month (`test_as_of_date_frequencies = 1month`) and we need to complete that round in exactly one month (`test_durations = test_label_timespan = 1month`)

```yaml
temporal_config:
    feature_start_time: '2010-01-04'
    feature_end_time: '2017-02-13'
    label_start_time: '2015-02-01'
    label_end_time: '2017-02-13'

    model_update_frequency: '1y'
    training_label_timespans: ['1month']
    training_as_of_date_frequencies: '1month'

    test_durations: '1month'
    test_label_timespans: ['1month']
    test_as_of_date_frequencies: '1month'

    max_training_histories: '5y'
```

We can visualize the splitting using the function `show_timechop` introduced in [Introduction to triage](triage_intro.md).

```sh
./tutorial.sh triage --config_file inspections_test.yaml show_temporal_blocks
```

Using the config file /triage/experiment\_config/inspections\_test.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Generating temporal blocks image Image stored in: /triage/inspections\_test.svg

![img](./triage/inspections_test.svg)

We need to specify the table that keeps our labels, for this first experiment we will use the label `failed`, stored in `inspections.labels`.

```yaml
events_table: inspections.failed
```

`Triage` will generate the features for us, we need to tell which ones in the section `feature_aggregations`. Here, each entry describes a `collate.SpacetimeAggregation` object, and the arguments needed to create it. For this experiment we will try the following features:

-   Number of different types of inspections that happened in the facility in the last year from a particular day
-   

-   Number of different types of inspections that happened in the zip code in the last year from a particular day

If we observe the image generated from the `temporal_config` section, each particular date is the beginning of the rectangles that describes the rows in the matrix. In that date (`as_of_date` in `timechop` parlance) we will calculate both features, and we will repeat that for every other rectangle in that image.

```yaml
feature_aggregations:
    -
        prefix: 'inspections'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -
                column: 'type'
                choice_query: 'select distinct type from semantic.events where type is not null'
                metrics:
                    - 'sum'

        intervals:
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'
```

We just want to include **active** facilities in our matrices, so we tell `triage` to take that in account:

```yaml
state_config:
    table_name: 'inspections.active_facilities'
    state_filters:
       - 'active'
```

Now, lets discuss how we will define the different models to try in the data (Remember that the model is specified by the algorithm, the hyperparameters, and the subset of features to use). In `triage` you need to specify in the `grid_config` section, a list of machine learning algorithms that you want to train, and a set of list of hyperparameters. You can use any algorithm that you want, the only requirement is that respects the `sklearn` API.

```yaml
grid_config:
    'sklearn.tree.DecisionTreeClassifier':
        max_depth: [1,null]
        max_features: [1, sqrt, null]
```

Some of the parameters in `sklearn` are `None`, if you want to try those you need to indicate that with the `yaml` 's `null` keyword.

Besides the algorithm and the hyperparameters, you should specify which subset of features use. First, in the section `feature_group_definition` you specify how to group the features (you can use the `table name` or the `prefix` from the section `feature_aggregation`) and then choose one *strategy* for choosing the subsets: `all` (all the subsets at once), `leave-one-out` (try all the subsets except one, do that for all the combinations) or `leave-one-in` (just try subset at the time).

```yaml

feature_group_definition:
   prefix: ['inspections']

feature_group_strategies: ['all']
```

In this experiment we will end with **6** model groups (\(algorithms (1) \times hyperparameters combinations (2 \times 3) \times feature groups (1) \times temporal combinations (1)\)). Also, we will create **12** different models (2 per each model group) given that we have 2 temporal blocks (one model per temporal group).

`model_group_keys` defines a list of **additional** matrix metadata keys that should be considered when creating a model group. For example, if the models are built on matrices with different history lengths, different labeling windows (e.g., inspection violations in the next month, next year, or next two years), the frequency of rows for each entity, or the definition of a positive label (`label_definition`, from `user_metadata`).

The valid `model_group_keys` are

```yaml
model_group_keys:
    - 'label_definition'
    - 'experiment_type'
    - 'purpose'
```

Finally, we should define wich metrics we care for evaluating our model. Here we will concentrate only in `precision` and `recall`.

```yaml
scoring:
    sort_seed: 5
    metric_groups:
        -
            metrics: [precision@, recall@]
            thresholds:
                percentiles: [5.0, 10.0]
                top_n: [5, 10, 25]
```

You should be warned that precision and recall at \(k\) in this setting is kind of ill-defined (because you will end with a lot of `NULL` labels, remember, only a few of facilities are inspected in each period) &#x2026;

We will want as a result of our experiments, a **list** of facilities to be inspected. The length of our list is contrained by our inspection resources, i.e. the answer to the question How many facilities can I inpect in a month?. In this experiment we are assuming that the maximum capacity is **25** but we are testing also for a list of length **5**, and **10** (see `top_n` Above).

The execution of the experiments could take a long time, so, it is a good practice to *validate* the configuration file, *before* running the model. You don't want to wait for hours (or days) and then discover that there was something wrong

```sh
./tutorial.sh triage --config_file inspections_test.yaml validate
```

Using the config file /triage/experiment\_config/inspections\_test.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Validating experiment's configuration Experiment validation ran to completion with no errors

-&#x2014;TIME SPLIT SUMMARY-&#x2014;

Number of time splits: 2 Split index 0: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2015-11-13 00:00:00 (10 total) Testing as\_of\_time range: 2015-12-13 00:00:00 to 2015-12-13 00:00:00 (1 total)

Split index 1: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2016-11-13 00:00:00 (22 total) Testing as\_of\_time range: 2016-12-13 00:00:00 to 2016-12-13 00:00:00 (1 total)

For more detailed information on your time splits, inspect the experiment \`split\_definitions\` property

The experiment configuration doesn't contain any obvious errors. Any error that occurs from now on, possibly will be related to hit the maximum number of columns allowed or collision in the column names, both due to PostgreSQL limitations.

The experiment looks in good shape. May the force be with you

You can execute the experiment as

```sh
./tutorial.sh triage --config_file inspections_test.yaml run
```

Using the config file /triage/experiment\_config/inspections\_test.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Executing experiment Done Experiment completed in 0:01:41.427599 seconds

This will print a lot of output, and if everything is correct it will create 4 matrices (2 for training, 2 for testing) in `triage/matrices`, every matrix will be represented by two files, one with the metadata of the matrix (a `yaml` file) and the actual matrix (the `csv` file).

```sh
ls /triage/output/matrices | awk -F . '{print $NF}' | sort | uniq -c
```

4 csv 4 yaml

`Triage` also will store 12 trained models in `triage/trained_models`:

```sh
ls /triage/output/trained_models | wc -l
```

12

And it will populate the `results` schema in the database, as commented above, we will get `6` *model groups*:

```sql
select model_group_id, model_type, model_parameters from results.model_groups;
```

| model\_group\_id | model\_type                         | model\_parameters                             |
|---------------- |----------------------------------- |--------------------------------------------- |
| 1                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": 1}         |
| 2                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": "sqrt"}    |
| 3                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": null}      |
| 4                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": 1}      |
| 5                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": "sqrt"} |
| 6                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": null}   |

And `12` *Models*:

```sql
select
model_group_id, model_id, train_end_time
from results.models
order by model_group_id, train_end_time asc
```

| model\_group\_id | model\_id | train\_end\_time    |
|---------------- |--------- |------------------- |
| 1                | 1         | 2016-01-01 00:00:00 |
| 1                | 7         | 2017-01-01 00:00:00 |
| 2                | 2         | 2016-01-01 00:00:00 |
| 2                | 8         | 2017-01-01 00:00:00 |
| 3                | 3         | 2016-01-01 00:00:00 |
| 3                | 9         | 2017-01-01 00:00:00 |
| 4                | 4         | 2016-01-01 00:00:00 |
| 4                | 10        | 2017-01-01 00:00:00 |
| 5                | 5         | 2016-01-01 00:00:00 |
| 5                | 11        | 2017-01-01 00:00:00 |
| 6                | 6         | 2016-01-01 00:00:00 |
| 6                | 12        | 2017-01-01 00:00:00 |

From that last query, you should note that the order in which `triage` train the models is by block (`train_end_time`) from oldest to recent, and from `model_group`, also in ascending order. It will not go to the next block, until all the *models groups* were trained.

You can check with which matrix the models where trained

```sql
select
model_id, model_group_id, train_end_time, 
model_hash,train_matrix_uuid
from results.models
order by model_group_id, train_end_time asc
```

| model\_id | model\_group\_id | train\_end\_time    | model\_hash                      | train\_matrix\_uuid              |
|--------- |---------------- |------------------- |-------------------------------- |-------------------------------- |
| 1         | 1                | 2016-01-01 00:00:00 | 5062bb64aecdbf0f6875de579c4b4845 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 7         | 1                | 2017-01-01 00:00:00 | 6bb1c66e613fc9f19f3992ec36d743ab | 53ccca25d2096ad453831883e1e50e1d |
| 2         | 2                | 2016-01-01 00:00:00 | fd96142f002bdbdfe518dff477048bb9 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 8         | 2                | 2017-01-01 00:00:00 | 4473c1076e1479bb1aec875913b354c7 | 53ccca25d2096ad453831883e1e50e1d |
| 3         | 3                | 2016-01-01 00:00:00 | d140cd9a9de944ab8587efbba8692c99 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 9         | 3                | 2017-01-01 00:00:00 | 3f33a1dd1d1047fd4cc7a28695a83514 | 53ccca25d2096ad453831883e1e50e1d |
| 4         | 4                | 2016-01-01 00:00:00 | a1b6ea17f74ea1877212ea740d1d46d7 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 10        | 4                | 2017-01-01 00:00:00 | bbea50a714622b612e6da12722c34ec3 | 53ccca25d2096ad453831883e1e50e1d |
| 5         | 5                | 2016-01-01 00:00:00 | a85d9be461e9c41d21aee29cbcf421f3 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 11        | 5                | 2017-01-01 00:00:00 | 000a39b2678469280132e5b7b791ad42 | 53ccca25d2096ad453831883e1e50e1d |
| 6         | 6                | 2016-01-01 00:00:00 | 48204ce78ec79c479090c332fab73e26 | c834bd5ba5b9c3ebdf8d6e9ac37abee9 |
| 12        | 6                | 2017-01-01 00:00:00 | 8cc1037025ef7c97295381434b24977e | 53ccca25d2096ad453831883e1e50e1d |

As expected, we have two models per model group. Each model was trained with the matrix indicated in the column `train_matrix_uuid`. This `uuid` also is the file name of the stored matrix. The model itself was stored under the file named with the `model_hash`.

For example, the model `7` was stored as `/triage/trained_models/` `select train_matrix_uuid from results.models where model_id = 7` using the standard serialization of sklearn models. This model was trained with the matrix `select train_matrix_uuid from results.models where model_id = 7` stored in the directory `/triage/Matrices`.

The model `7` used the following hyperparameters:

```sql
select 
model_parameters 
from results.models 
where model_id = 7
```

| model\_parameters                     |
|------------------------------------- |
| {"max\_depth": 1, "max\_features": 1} |

We can visualize the model

```sh
./tutorial.sh triage --config_file inspections_baseline.yaml show_model_plot --model 7
```

Using the config file /triage/experiment\_config/inspections\_baseline.yaml The output (matrices and models) of this experiment will be stored in triage/output Using data stored in postgresql://food\_user:some\_password@food\_db/food The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Generating model image postgresql://food\_user:some\_password@food\_db/food Plotting tree number 0 Image stored in: ['/triage/output/images/model\_7\_tree\_0.svg']

![img](./triage/output/images/model_7_tree_0.svg)

This tree makes kind of sense, if the facility had more than 1.5 inspections related to food poisoning then it will fail the inspection.

The same model `7` is part of the model group `select model_group_id from results.models where model_id = 7`. That model group

```sql
select 
model_group_id, model_type, model_config 
from 
results.model_groups 
where model_group_id = 1
```

| model\_group\_id | model\_type                         | model\_config                                               |
|---------------- |----------------------------------- |----------------------------------------------------------- |
| 1                | sklearn.tree.DecisionTreeClassifier | {"experiment\_type": "test", "label\_definition": "failed"} |

The features used by that model are:

```sql
select 
unnest(feature_list) as features 
from 
results.model_groups 
where model_group_id = 1
```

| features                                                   |
|---------------------------------------------------------- |
| inspections\_entity\_id\_3month\_type\_canvass\_sum        |
| inspections\_entity\_id\_3month\_type\_complaint\_sum      |
| inspections\_entity\_id\_3month\_type\_consultation\_sum   |
| inspections\_entity\_id\_3month\_type\_food poisoning\_sum |
| inspections\_entity\_id\_3month\_type\_license\_sum        |
| inspections\_entity\_id\_3month\_type\_\_NULL\_sum         |
| inspections\_entity\_id\_3month\_type\_tag removal\_sum    |
| inspections\_entity\_id\_3month\_type\_task force\_sum     |
| inspections\_zip\_code\_3month\_type\_canvass\_sum         |
| inspections\_zip\_code\_3month\_type\_complaint\_sum       |
| inspections\_zip\_code\_3month\_type\_consultation\_sum    |
| inspections\_zip\_code\_3month\_type\_food poisoning\_sum  |
| inspections\_zip\_code\_3month\_type\_license\_sum         |
| inspections\_zip\_code\_3month\_type\_\_NULL\_sum          |
| inspections\_zip\_code\_3month\_type\_tag removal\_sum     |
| inspections\_zip\_code\_3month\_type\_task force\_sum      |

Finally, the performance of the model `7` are:

```sql
select
model_id,
metric || parameter as metric,
value,
num_labeled_examples, 
num_labeled_above_threshold,
num_positive_labels
from results.evaluations where model_id = 7
order by num_labeled_above_threshold asc,
metric || parameter
```

| model\_id | metric              | value                 | num\_labeled\_examples | num\_labeled\_above\_threshold | num\_positive\_labels |
|--------- |------------------- |--------------------- |---------------------- |------------------------------ |--------------------- |
| 7         | precision@5\_abs    | 0.0                   | 1173                   | 0                              | 269                   |
| 7         | recall@5\_abs       | 0.0                   | 1173                   | 0                              | 269                   |
| 7         | precision@10\_abs   | 1.0                   | 1173                   | 1                              | 269                   |
| 7         | recall@10\_abs      | 0.0037174721189591076 | 1173                   | 1                              | 269                   |
| 7         | precision@25\_abs   | 0.6                   | 1173                   | 5                              | 269                   |
| 7         | recall@25\_abs      | 0.011152416356877323  | 1173                   | 5                              | 269                   |
| 7         | precision@5.0\_pct  | 0.29333333333333333   | 1173                   | 75                             | 269                   |
| 7         | recall@5.0\_pct     | 0.08178438661710037   | 1173                   | 75                             | 269                   |
| 7         | precision@10.0\_pct | 0.25190839694656486   | 1173                   | 131                            | 269                   |
| 7         | recall@10.0\_pct    | 0.12267657992565056   | 1173                   | 131                            | 269                   |

The columns `num_labeled_examples, num_labeled_above_threshold, num_positive_labels` represents the number of selected entities in the prediction date which are labeled (there are `1173` entities in the test matrix with a label (`1` or `0`)), the number of entities with a positive label above the threshold (e.g. there are `1` entity with a positive label `1` in the first 10 entities ordered by score) and the number of entities with positive labels among all the labeled entities (`269` of `1173`) respectively. We can translate this to english: in our case *label* mean that between the *as of date* (`2017-01-01`) and one month later (until `2017-02-01`) there were `1173` facilities **inspected** and `269` **failed** the inspection.

We could check that the numbers make sense, the number of *active facilities* at `2017-01-01` (the prediction date) is

```sql
select count(*)
from inspections.active_facilities
where '2017-01-01'::date <@ daterange(start_time, end_time)
```

| count |
|----- |
| 19396 |

And this number matches with the predictions made by the model `7`, as expected.

```sql
select count(*) from results.predictions where model_id = 7 
```

| count |
|----- |
| 19396 |

The number of *labels* (`num_labeled_examples` = `1173`) is different, because only `1173` facilities were inspected in that time span. so, many of the facilities weren't inspected, then their label is `NULL`.

```sql
select count(distinct entity_id)
from inspections.failed
where outcome_date <@ '[2017-01-01, 2017-02-01)'::daterange
```

| count |
|----- |
| 1316  |

Still far from the `1173`. Do you remember the *states* table? Using it to filter we got the correct number:

```sql
select outcome,count(distinct entity_id)
from inspections.failed
inner join (
      select entity_id
      from inspections.active_facilities
      where '2017-01-01'::date <@ daterange(start_time, end_time)
) as t
using (entity_id)
where outcome_date <@ '[2017-01-01, 2017-02-01)'::daterange
group by rollup(outcome)
```

| outcome | count |
|------- |----- |
| f       | 1085  |
| t       | 269   |
| [NULL]  | 1173  |

Let's assume that this is our best model, Which is the list of 25 facilities to inspect?

```sql
select *
from results.predictions
where model_id = 7 
order by score desc
limit 25
```

| model\_id | entity\_id | as\_of\_date        | score               | label\_value | rank\_abs | rank\_pct | matrix\_uuid                     | test\_label\_timespan |
|--------- |---------- |------------------- |------------------- |------------ |--------- |--------- |-------------------------------- |--------------------- |
| 7         | 2          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 4          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 5          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 6          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 7          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 8          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 9          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 10         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 11         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 13         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 14         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 15         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 16         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 19         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 20         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 21         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 22         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 23         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 25         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 27         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 28         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 29         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 30         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 31         | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |
| 7         | 1          | 2017-01-01 00:00:00 | 0.22907692307692307 | [NULL]       | [NULL]    | [NULL]    | 86bad884c84b4c75ad2a127debc810b5 | 1 mon                 |


<a id="org5db3fbe"></a>

## Defining a baseline

As a second step, lets do a new experiment that defines our *baseline*. In order to achive this, we will use a similar experiment config file with the following changes:

    model_comment: 'inspections_baseline'
    
    user_metadata:
      label_definition: 'failed'
      experiment_type: 'inspections prioritization'
      purpose: 'baseline'
      org: 'DSaPP'
      team: 'Tutorial'
      author: 'Your name here'
    
    grid_config:
        'sklearn.dummy.DummyClassifier':
            strategy: [prior,uniform, most_frequent]
    
    model_group_keys:
        - 'label_definition'
        - 'experiment_type'
        - 'purpose'

The complete file is in [triage/experiment\_config/inspections\_baseline.yaml](./triage/experiment_config/inspections_baseline.yaml)

If we execute this experiment, we will get 3 more model groups (one for each strategy), and the corresponding 6 new models (2 per each model group).

```sh
./tutorial.sh triage --config_file inspections_baseline.yaml validate
```

Using the config file /triage/experiment\_config/inspections\_baseline.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Validating experiment's configuration Experiment validation ran to completion with no errors

-&#x2014;TIME SPLIT SUMMARY-&#x2014;

Number of time splits: 2 Split index 0: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2015-11-13 00:00:00 (10 total) Testing as\_of\_time range: 2015-12-13 00:00:00 to 2015-12-13 00:00:00 (1 total)

Split index 1: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2016-11-13 00:00:00 (22 total) Testing as\_of\_time range: 2016-12-13 00:00:00 to 2016-12-13 00:00:00 (1 total)

For more detailed information on your time splits, inspect the experiment \`split\_definitions\` property

The experiment configuration doesn't contain any obvious errors. Any error that occurs from now on, possibly will be related to hit the maximum number of columns allowed or collision in the column names, both due to PostgreSQL limitations.

The experiment looks in good shape. May the force be with you

You can execute the experiment as

```sh
./tutorial.sh triage --config_file inspections_baseline.yaml run
```

Using the config file /triage/experiment\_config/inspections\_baseline.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Executing experiment Done Experiment completed in 0:00:28.682451 seconds

```sql
select model_group_id, model_type, model_parameters from results.model_groups;
```

| model\_group\_id | model\_type                         | model\_parameters                             |
|---------------- |----------------------------------- |--------------------------------------------- |
| 1                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": 1}         |
| 2                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": "sqrt"}    |
| 3                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": 1, "max\_features": null}      |
| 4                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": 1}      |
| 5                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": "sqrt"} |
| 6                | sklearn.tree.DecisionTreeClassifier | {"max\_depth": null, "max\_features": null}   |
| 7                | sklearn.dummy.DummyClassifier       | {"strategy": "prior"}                         |
| 8                | sklearn.dummy.DummyClassifier       | {"strategy": "uniform"}                       |
| 9                | sklearn.dummy.DummyClassifier       | {"strategy": "most\_frequent"}                |

```sql

with baseline as (
select model_id, model_group_id
from results.models
where model_type ~ 'DummyClassifier'
)

select 
model_group_id, model_id, metric || parameter as metric, value
from results.evaluations
inner join baseline using(model_id)
where
metric || parameter = 'precision@25_abs'
order by metric || parameter, model_id
```

| model\_group\_id | model\_id | metric            | value |
|---------------- |--------- |----------------- |----- |
| 7                | 13        | precision@25\_abs | 0.0   |
| 8                | 14        | precision@25\_abs | 0.0   |
| 9                | 15        | precision@25\_abs | 0.0   |
| 7                | 16        | precision@25\_abs | 0.6   |
| 8                | 17        | precision@25\_abs | 0.6   |
| 9                | 18        | precision@25\_abs | 0.6   |


<a id="org0d2a8fb"></a>

## A more advanced experiment

Ok, let's add a more complete experiment. First the usual generalities. Note that we change `experiment_type`

```yaml
config_version: 'v3'

model_comment: 'inspections'

user_metadata:
  label_definition: 'failed'
  experiment_type: 'inspections prioritization'
  purpose: 'development'
  org: 'DSaPP'
  team: 'Tutorial'
  author: 'Your name here'
```

As before, we set the `triage` special tables that specifies *outcomes* (that is call `events_table`) and the one that specifies *states*. These are the same, we didn't change anything.

```yaml
events_table: inspections.failed

state_config:
    table_name: 'inspections.active_facilities'
    state_filters:
       - 'active'
```

Neither to the temporal configuration:

```yaml
temporal_config:
    feature_start_time: '2010-02-01'
    feature_end_time: '2018-02-01'
    label_start_time: '2015-02-01'
    label_end_time: '2018-02-01'

    model_update_frequency: '1y'
    training_label_timespans: ['1month']
    training_as_of_date_frequencies: '1month'

    test_durations: '1month'  
    test_label_timespans: ['1y'] #
    test_as_of_date_frequencies: '1month'

    max_training_histories: '10y'
```

```sh
./tutorial.sh triage --config_file inspections_label_failed_01.yaml show_temporal_blocks
```

Using the config file /triage/experiment\_config/inspections\_label\_failed\_01.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Generating temporal blocks image Image stored in: /triage/inspections.svg

![img](./triage/inspections.svg)

The first big change is that we are adding 3 more *features groups*: `inspections` (we already use this), `risks`, and `results`. Remember that all of this referes to events in the past, i.e. *How many times the facility was marked with high risk in the previous 3 Months?*, *Which is the average of failed inspections in the previous year?*

```yaml
feature_aggregations:
    -
        prefix: 'inspections'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -
                column: 'type'
                choice_query: 'select distinct type from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'

    -
        prefix: 'risks'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -
                column: 'risk'
                choice_query: 'select distinct risk from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'
            - 'facility_type'


    -
        prefix: 'results'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -
                column: 'result'
                choice_query: 'select distinct result from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'
            - 'facility_type'

```

We want to use all the features groups (`feature_group_definition`). The training will be made on matrices with `all` the feature groups, then letting one feature group out, `leave-one-out`, i.e. one model with `inspections` and `results`, another with `inspections` and `risks` and another one with `results` and `risks, and then just trying models with =inspections` or `results` or `risks` exclusively.

```yaml
feature_group_definition:
   prefix: ['inspections', 'results', 'risks']

feature_group_strategies: ['all', 'leave-one-in', 'leave-one-out']
```

Finally, we will try a `RandomForestClassifier`

```yaml
grid_config:
    'sklearn.ensemble.RandomForestClassifier':
        max_features: ['sqrt']
        criterion: ['gini']
        n_estimators: [1000]
        min_samples_leaf: [1]
        min_samples_split: [50]
        class_weight: ['balanced']


model_group_keys:
    - 'label_definition'
    - 'experiment_type'
    - 'purpose'

scoring:
    sort_seed: 1234
    metric_groups:
        -
            metrics: ['precision@', 'recall@']
            thresholds:
                percentiles: [1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 75.0, 95.0, 100.0]
                top_n: [5, 10, 25, 50, 75, 100, 150, 200, 300, 500, 1000, 2000]

```

```sh
./tutorial.sh triage --config_file inspections_label_failed_01.yaml validate
```

Using the config file /triage/experiment\_config/inspections\_label\_failed\_01.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Validating experiment's configuration Experiment validation ran to completion with no errors

-&#x2014;TIME SPLIT SUMMARY-&#x2014;

Number of time splits: 2 Split index 0: Training as\_of\_time\_range: 2015-02-01 00:00:00 to 2015-12-01 00:00:00 (11 total) Testing as\_of\_time range: 2016-01-01 00:00:00 to 2016-01-01 00:00:00 (1 total)

Split index 1: Training as\_of\_time\_range: 2015-02-01 00:00:00 to 2016-12-01 00:00:00 (23 total) Testing as\_of\_time range: 2017-01-01 00:00:00 to 2017-01-01 00:00:00 (1 total)

For more detailed information on your time splits, inspect the experiment \`split\_definitions\` property

The experiment configuration doesn't contain any obvious errors. Any error that occurs from now on, possibly will be related to hit the maximum number of columns allowed or collision in the column names, both due to PostgreSQL limitations.

The experiment looks in good shape. May the force be with you

You can execute the experiment with

```sh
./tutorial.sh triage --config_file inspections_label_failed_01.yaml run
```

Well, know we have a lot of models, How can you pick the best one for you? We will show you that when we model the *Early Intervention System*.


<a id="org8651d21"></a>

# What's next?

Do you want to know why the [Early Intervention System](eis.md) is different from the inspections problem? If so, continue reading.


<a id="org84553b0"></a>

# Problem description

Our final stop is using `triage` to build a *Early Intervention (or Warning) System*. There are several differences between the the **EIS** and the **inspection prioritization** problem. The difference that has more impact is that the *entity* in **EIS** is *active* i.e. it is doing stuff, and for that stuff the the entity is doing some outcome will happen. In the **inspection prioritization** the *entity* is acted on. This will change, from starters the way that the *outcome* is build.

The question that we want to resolve is the following:

> Will my restaurant be inspected in the *next X period of time?*

Where \(X\) could be 1 month, 1 week, 1 year, etc.

Knowing the answer to this question, allows you (as the restaurant's owner) to be prepared and take the pertinent actions.


<a id="orgd3ffda1"></a>

# Creating the labels

The trick to note is that every day there are two possible outcomes: *the facility was inspected* and *the facility wasn't inspected*. So, our *outcomes* table will be more larger, since we need for every date in our dataset for every *active* facility an *outcome*: Does the facility Inspected?

```sql
create schema if not exists eis;
```

For achiving that, we need to create a table (naïvely) of *number of days* &times; *number of entities*. Lets see how many rows do we generate.

```sql
select min(date), max(date) from semantic.events
```

| min        | max        |
|---------- |---------- |
| 2010-01-04 | 2018-02-13 |

```sql
select count(days) 
from generate_series((select min(date) from semantic.events), current_date, '1 day'::interval) days;
```

| count |
|----- |
| 2972  |

```sql
select count(*) from semantic.entities;
```

| count |
|----- |
| 34812 |

```ipython
34812*2968
```



103322016

The result is `print(int(entities[0])*int(days[0]))` `103322016` That's a lot of rows!

We could improve that taking only the *active* Entities

```sql
with dates as (
    select days::date
    from 
    generate_series(
       (select min(date) from semantic.events),
       current_date, '1 day'::interval) days
)

select count(*)
from semantic.entities
join dates d
on d.days <@ daterange(start_time, end_time)
```

| count    |
|-------- |
| 46772382 |

That's almost a reduction of `print(100*float(active_entities[0])/(int(entities[0])*int(days[0])))` =45.2685534126628=%, but still a huge number of rows given our infrastructure.

So we will cheat, and we will only consider *outcomes* from `2015`

```sql
with dates as (
    select days::date
    from 
    generate_series(
       '2015-01-01'::date,
       current_date, '1 day'::interval) days
)

select count(*)
from semantic.entities
join dates d
on d.days <@ daterange(start_time, end_time)
```

| count    |
|-------- |
| 21952711 |

```sql
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

```

The *states* table is the same that in the inspection's case.

```sql
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
```


<a id="org84b5cfc"></a>

# Modeling using Machine Learning


<a id="org5b55703"></a>

## Creating a simple Experiment

First the usual stuff. Note that we are changing `model_comment` and `label_definition` (remember that this is used for generating the *hash* that differentiates models and model groups)

```yaml
config_version: 'v3'

model_comment: 'eis'

user_metadata:
  label_definition: 'inspected'
  experiment_type: 'eis'
  purpose: 'exploring'
  org: 'DSaPP'
  team: 'Tutorial'
  author: 'Your name here'
```

We will use the `eis` tables for *outcomes* and *states* (obviously)

```yaml
events_table: eis.inspected
```

```yaml
state_config:
    table_name: 'eis.active_facilities'
    state_filters:
       - 'active'
```


<a id="org2e724de"></a>

### Temporal configuration

```yaml
temporal_config:
    feature_start_time: '2010-01-04'
    feature_end_time: '2017-02-13'
    label_start_time: '2015-02-01'
    label_end_time: '2017-02-13'

    model_update_frequency: '1y'
    training_label_timespans: ['1month']
    training_as_of_date_frequencies: '1month'

    test_durations: '1month'
    test_label_timespans: ['1month']
    test_as_of_date_frequencies: '1month'

    max_training_histories: '5y'
```

```sh
./tutorial.sh triage --config_file eis_01.yaml show_temporal_blocks
```

Using the config file /triage/experiment\_config/eis\_01.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Generating temporal blocks image Image stored in: /triage/eis.svg

![img](./triage/eis.svg)


<a id="org7ca350d"></a>

### Features

Regarding the features, we will use the same ones that were used in [inspections prioritization](inspections.md)

```yaml
feature_aggregations:
    -
        prefix: 'inspections'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -   # inspection type
                column: 'type'
                choice_query: 'select distinct type from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'

    -
        prefix: 'risks'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -   # Facility's Risk
                column: 'risk'
                choice_query: 'select distinct risk from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'
            - 'facility_type'


    -  
        prefix: 'results'
        from_obj: 'semantic.events'
        knowledge_date_column: 'date'

        categoricals_imputation:
            all:
                type: 'zero'

        categoricals:
            -   # Result of previous inspections
                column: 'result'
                choice_query: 'select distinct result from semantic.events'
                metrics:
                    - 'sum'
                    - 'avg'

        intervals:
            - '2y'
            - '1y'
            - '6month'
            - '3month'

        groups:
            - 'entity_id'
            - 'zip_code'
            - 'facility_type'

```

As before, we declare that we want to use all possible combinations for training:

```yaml
feature_group_definition:
   prefix: ['inspections', 'results', 'risks']

feature_group_strategies: ['all', 'leave-one-in', 'leave-one-out']
```


<a id="org5032498"></a>

### Algorithm and hyperparameters

We will collapse the baseline (`DummyClassifier`) and the exploratory configuration together:

```yaml
grid_config:
    'sklearn.tree.DecisionTreeClassifier':
        max_depth: [1,null]
    'sklearn.ensemble.RandomForestClassifier':
        max_features: ['sqrt']
        criterion: ['gini']
        n_estimators: [1000]
        min_samples_leaf: [1]
        min_samples_split: [50]
        class_weight: ['balanced']
    'sklearn.dummy.DummyClassifier':
        strategy: [prior,uniform, most_frequent]
```

The number of *model groups* to be generated are 6 algorithms and hyperparameters (2 `DecisionTreeClassifier`, 1 `RandomForestClassifier`, 3 `DummyClassifier`) &times; 7 features groups ( 1 `all`, 3 `leave-one-in`, 3 `leave-one-out`), which give a total of **42**.The total number of *models* is the double of that (we have 2 time blocks) i.e. **84**.

We don't want to mix different experiments together, it is very important that the `model_group_keys` distinguish between models, so use it wisely:

```yaml
model_group_keys:
    - 'label_definition'
    - 'experiment_type'
    - 'purpose'

scoring:
    sort_seed: 1234
    metric_groups:
        -
            metrics: ['precision@', 'recall@']
            thresholds:
                percentiles: [1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 75.0, 95.0, 100.0]
                top_n: [5, 10, 25, 50, 75, 100, 150, 200, 300, 500, 1000, 2000]
```

As a last step, we validate that the configuration file is correct:

```sh
./tutorial.sh triage --config_file eis_01.yaml validate
```

Using the config file /triage/experiment\_config/eis\_01.yaml The output (matrices and models) of this experiment will be stored in triage/output The experiment will utilize any preexisting matrix or model: False Creating experiment object Experiment loaded Validating experiment's configuration Experiment validation ran to completion with no errors

-&#x2014;TIME SPLIT SUMMARY-&#x2014;

Number of time splits: 2 Split index 0: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2015-11-13 00:00:00 (10 total) Testing as\_of\_time range: 2015-12-13 00:00:00 to 2015-12-13 00:00:00 (1 total)

Split index 1: Training as\_of\_time\_range: 2015-02-13 00:00:00 to 2016-11-13 00:00:00 (22 total) Testing as\_of\_time range: 2016-12-13 00:00:00 to 2016-12-13 00:00:00 (1 total)

For more detailed information on your time splits, inspect the experiment \`split\_definitions\` property

The experiment configuration doesn't contain any obvious errors. Any error that occurs from now on, possibly will be related to hit the maximum number of columns allowed or collision in the column names, both due to PostgreSQL limitations.

The experiment looks in good shape. May the force be with you

    ./tutorial.sh triage --config_file eis_01.yaml --no-replace --debug run

This will take a **lot** amount of time (on my computer took 3h 42m), so, grab your coffee, chat with your coworkers or check your email (or all the above). Is taking that amount of time for several reasons:

1.  There are a lot of models, parameters, etc
2.  We are running in serial mode (i.e. not in parallel)
3.  Our database, is running in your laptop

You can solve 2 and 3. For the second point you could use the `docker` container that has the multicore option enabled. For 3, I recommed you to use a PostgreSQL database in the cloud, for example in **AWS** the service is call **PostgreSQL RDS**.

After the experiment had finished we could create the following table

```sql
with features_groups as (
select model_group_id, split_part(unnest(feature_list), '_', 1) as feature_groups
from results.model_groups
), 

features_arrays as (
select model_group_id, array_agg(distinct feature_groups) as feature_groups
from features_groups
group by model_group_id
)

select
model_group_id,
model_type,
model_parameters,
feature_groups,
array_agg(model_id) as models
from results.models
join features_arrays using(model_group_id)
where model_comment = 'eis'
group by model_group_id, model_type, model_parameters, feature_groups order by model_group_id 
```

| model\_group\_id | model\_type                             | model\_parameters                                                                                                                                      | feature\_groups             | models   |
|---------------- |--------------------------------------- |------------------------------------------------------------------------------------------------------------------------------------------------------ |--------------------------- |-------- |
| 10               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {inspections,results,risks} | {61,19}  |
| 11               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {inspections,results,risks} | {62,20}  |
| 12               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {inspections,results,risks} | {63,21}  |
| 13               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {inspections,results,risks} | {64,22}  |
| 14               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {inspections,results,risks} | {65,23}  |
| 15               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {inspections,results,risks} | {66,24}  |
| 16               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {inspections}               | {67,25}  |
| 17               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {inspections}               | {68,26}  |
| 18               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {inspections}               | {69,27}  |
| 19               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {inspections}               | {70,28}  |
| 20               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {inspections}               | {71,29}  |
| 21               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {inspections}               | {72,30}  |
| 22               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {results}                   | {73,31}  |
| 23               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {results}                   | {74,32}  |
| 24               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {results}                   | {75,33}  |
| 25               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {results}                   | {76,34}  |
| 26               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {results}                   | {77,35}  |
| 27               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {results}                   | {78,36}  |
| 28               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {risks}                     | {79,37}  |
| 29               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {risks}                     | {80,38}  |
| 30               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {risks}                     | {81,39}  |
| 31               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {risks}                     | {82,40}  |
| 32               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {risks}                     | {83,41}  |
| 33               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {risks}                     | {84,42}  |
| 34               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {results,risks}             | {85,43}  |
| 35               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {results,risks}             | {86,44}  |
| 36               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {results,risks}             | {87,45}  |
| 37               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {results,risks}             | {88,46}  |
| 38               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {results,risks}             | {89,47}  |
| 39               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {results,risks}             | {90,48}  |
| 40               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {inspections,risks}         | {91,49}  |
| 41               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {inspections,risks}         | {92,50}  |
| 42               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {inspections,risks}         | {93,51}  |
| 43               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {inspections,risks}         | {94,52}  |
| 44               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {inspections,risks}         | {95,53}  |
| 45               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {inspections,risks}         | {96,54}  |
| 46               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": 1}                                                                                                                                      | {inspections,results}       | {97,55}  |
| 47               | sklearn.tree.DecisionTreeClassifier     | {"max\_depth": null}                                                                                                                                   | {inspections,results}       | {98,56}  |
| 48               | sklearn.ensemble.RandomForestClassifier | {"criterion": "gini", "class\_weight": "balanced", "max\_features": "sqrt", "n\_estimators": 1000, "min\_samples\_leaf": 1, "min\_samples\_split": 50} | {inspections,results}       | {99,57}  |
| 49               | sklearn.dummy.DummyClassifier           | {"strategy": "prior"}                                                                                                                                  | {inspections,results}       | {100,58} |
| 50               | sklearn.dummy.DummyClassifier           | {"strategy": "uniform"}                                                                                                                                | {inspections,results}       | {101,59} |
| 51               | sklearn.dummy.DummyClassifier           | {"strategy": "most\_frequent"}                                                                                                                         | {inspections,results}       | {102,60} |

Let's check the performance of the *model group* 12 (a Random Forest with all the features)

```sql
select
model_id, evaluation_start_time,
metric || parameter as metric,
value,
num_labeled_examples, 
num_labeled_above_threshold,
num_positive_labels
from results.evaluations 
where model_id in (21, 63)
and metric || parameter = 'precision@25_abs'
order by num_labeled_above_threshold asc,
metric || parameter
```

| model\_id | evaluation\_start\_time | metric            | value | num\_labeled\_examples | num\_labeled\_above\_threshold | num\_positive\_labels |
|--------- |----------------------- |----------------- |----- |---------------------- |------------------------------ |--------------------- |
| 21        | 2015-12-13 00:00:00     | precision@25\_abs | 0.84  | 18668                  | 25                             | 790                   |
| 63        | 2016-12-13 00:00:00     | precision@25\_abs | 0.88  | 19358                  | 25                             | 958                   |

```sql
select *
from results.predictions
where model_id = 21
order by score desc
limit 25
```

| model\_id | entity\_id | as\_of\_date        | score              | label\_value | rank\_abs | rank\_pct | matrix\_uuid                     | test\_label\_timespan |
|--------- |---------- |------------------- |------------------ |------------ |--------- |--------- |-------------------------------- |--------------------- |
| 21        | 25854      | 2015-12-13 00:00:00 | 0.9484136677797923 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 3019       | 2015-12-13 00:00:00 | 0.9436469079812785 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 13792      | 2015-12-13 00:00:00 | 0.9419947954600382 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 17502      | 2015-12-13 00:00:00 | 0.9312907285784298 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 2466       | 2015-12-13 00:00:00 | 0.9243102785460537 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 10382      | 2015-12-13 00:00:00 | 0.9206737935216891 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 24297      | 2015-12-13 00:00:00 | 0.9200144700893553 | 0            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 143        | 2015-12-13 00:00:00 | 0.9199824040634403 | 0            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 29174      | 2015-12-13 00:00:00 | 0.9141830973245461 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 1816       | 2015-12-13 00:00:00 | 0.9116947701339125 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 15936      | 2015-12-13 00:00:00 | 0.910420304141231  | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 4019       | 2015-12-13 00:00:00 | 0.9101049552562018 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 8835       | 2015-12-13 00:00:00 | 0.909611746159294  | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 30294      | 2015-12-13 00:00:00 | 0.9053675764327609 | 0            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 27955      | 2015-12-13 00:00:00 | 0.9046749372346382 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 27956      | 2015-12-13 00:00:00 | 0.9046749372346382 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 13783      | 2015-12-13 00:00:00 | 0.9015988243973061 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 8760       | 2015-12-13 00:00:00 | 0.8936300434147297 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 27071      | 2015-12-13 00:00:00 | 0.8889020831400419 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 27073      | 2015-12-13 00:00:00 | 0.8889020831400419 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 1381       | 2015-12-13 00:00:00 | 0.8856752816172949 | 0            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 23063      | 2015-12-13 00:00:00 | 0.8838436286127278 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 1355       | 2015-12-13 00:00:00 | 0.8828514873911587 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 19735      | 2015-12-13 00:00:00 | 0.8806239565602527 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |
| 21        | 6959       | 2015-12-13 00:00:00 | 0.8736905232325605 | 1            | [NULL]    | [NULL]    | 2e85917732c60eb208f2d052a9e4fe60 | 1 mon                 |

1.  Feature Importances

    ```sql
    select * from results.feature_importances 
    where model_id = 21 
    order by feature_importance desc
    limit 25
    ```
    
    | model\_id | feature                                                 | feature\_importance | rank\_abs | rank\_pct |
    |--------- |------------------------------------------------------- |------------------- |--------- |--------- |
    | 21        | risks\_facility\_type\_2y\_risk\_high\_avg              | 0.0174800538        | 1         | 0.003125  |
    | 21        | results\_entity\_id\_3month\_result\_fail\_avg          | 0.0133257966        | 2         | 0.00625   |
    | 21        | risks\_facility\_type\_1y\_risk\_high\_avg              | 0.0131853305        | 3         | 0.009375  |
    | 21        | risks\_facility\_type\_2y\_risk\_high\_sum              | 0.0131239412        | 4         | 0.0125    |
    | 21        | results\_entity\_id\_6month\_result\_pass\_avg          | 0.0129326733        | 5         | 0.015625  |
    | 21        | risks\_facility\_type\_6month\_risk\_high\_avg          | 0.0124089975        | 6         | 0.01875   |
    | 21        | results\_facility\_type\_2y\_result\_pass\_avg          | 0.0119138182        | 7         | 0.021875  |
    | 21        | risks\_entity\_id\_2y\_risk\_high\_sum                  | 0.011606308         | 8         | 0.025     |
    | 21        | results\_entity\_id\_6month\_result\_pass\_sum          | 0.0115504677        | 9         | 0.028125  |
    | 21        | risks\_facility\_type\_1y\_risk\_high\_sum              | 0.0106386415        | 10        | 0.03125   |
    | 21        | results\_zip\_code\_1y\_result\_pass w/ conditions\_avg | 0.009624423         | 11        | 0.034375  |
    | 21        | risks\_zip\_code\_1y\_risk\_medium\_sum                 | 0.0094457436        | 12        | 0.0375    |
    | 21        | results\_entity\_id\_3month\_result\_pass\_sum          | 0.009225408         | 13        | 0.040625  |
    | 21        | results\_entity\_id\_6month\_result\_fail\_avg          | 0.0091078199        | 14        | 0.04375   |
    | 21        | results\_entity\_id\_3month\_result\_pass\_avg          | 0.0088542878        | 15        | 0.046875  |
    | 21        | inspections\_zip\_code\_3month\_type\_canvass\_avg      | 0.0087851068        | 16        | 0.05      |
    | 21        | risks\_entity\_id\_2y\_risk\_low\_sum                   | 0.0085351           | 17        | 0.053125  |
    | 21        | risks\_entity\_id\_2y\_risk\_low\_avg                   | 0.0080073084        | 18        | 0.05625   |
    | 21        | results\_zip\_code\_1y\_result\_fail\_sum               | 0.0079038494        | 19        | 0.059375  |
    | 21        | results\_zip\_code\_2y\_result\_fail\_avg               | 0.0078180121        | 20        | 0.0625    |
    | 21        | results\_zip\_code\_2y\_result\_pass\_sum               | 0.0077150654        | 21        | 0.065625  |
    | 21        | inspections\_zip\_code\_2y\_type\_license\_sum          | 0.0076692378        | 22        | 0.06875   |
    | 21        | risks\_facility\_type\_3month\_risk\_high\_avg          | 0.0076609972        | 23        | 0.071875  |
    | 21        | risks\_zip\_code\_1y\_risk\_medium\_avg                 | 0.0075045563        | 24        | 0.075     |
    | 21        | results\_zip\_code\_2y\_result\_pass w/ conditions\_sum | 0.0074907219        | 25        | 0.078125  |
    
    This set of features identifies as important looks reasonable, so the results seem solid.


<a id="org22db263"></a>

## How can I pick the best one?

Well now you have **42** *model groups* Which one must you select to use? Which one is the best one? This is not as easy as it sounds, due several Factors:

-   You could try to pick the best one using just one of the metrics that we establish in the config file (`precision@` and `recall@`) but at what point of time? Maybe different model groups are the best at different prediction times.
-   You could just use the one that perfom better in the last temporal point
-   Or you could value that the model is stable across time? Maybe is not the best but is consistent.
-   Also, even if there are several model groups that perform similar, the lists generated are more or less similar, so, it doesn't really matter which one do you Pick.

`Triage` provides that functionality in `audition` and in `postmodel`. At the moment of this writing this two modules require more interaction (they aren't integrated to the *configuration file*).

So, one more time, you need to and open `bastion`


<a id="orgd6b042f"></a>

# Postmodeling

-   Postmodeling?
-   Bias analysis?


<a id="orgb72701c"></a>

# What's next?

-   Add the shape file <https://data.cityofchicago.org/api/geospatial/gdcf-axmw?method=export&format=Shapefile> and generate geospatial variables using `location`
-   Text analysis on the *violations*' `comments` column and generate new *outcomes* or *features*?
-   Run `pgdedup` and had a better `semantic.entities`?
-   Routing based on the inspection list?
-   Add more data sources (Census, Schools, bus stops, ACS data, Yelp!)?


<a id="org52bf477"></a>

# Notes

<span class="timestamp-wrapper"><span class="timestamp">[2018-01-01 Mon 00:50]</span></span>

*What are you inspecting?* (people, places, other) *How far do you want to predict?* (e.g. 1 mo, 6mo, 12 mo, etc) *How often do you want to update the list?* (e.g. 1 mo, 6mo, 12 mo, etc) *What do you want to optimize for?* (e.g. efficiency, long term compliance, novelty)

Inspection the join starts from outcomes (outcome centric) (if you haven't been inspected, we can not said anything about you)


<a id="orgd2fb903"></a>

## A neat trick

Add small, medium, full grid (Rayid magic
