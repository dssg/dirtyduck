FROM postgres:9.6

## PostGIS activation
RUN apt-get -y update \
    && apt-get -y  install wget less \
    && wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - \
    && apt-get -y update \
    && apt-get -y install postgresql-9.6-postgis-2.3 postgis postgresql-9.6-pgrouting


## DB setup
ADD activate_postgis.sql /docker-entrypoint-initdb.d/
ADD create_inspections_table.sql /docker-entrypoint-initdb.d/
ADD create_extensions.sql /docker-entrypoint-initdb.d/

RUN chown postgres:postgres /docker-entrypoint-initdb.d/*.sql
