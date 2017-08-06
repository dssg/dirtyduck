FROM python:3.6

## Installing clients
RUN  sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > /etc/apt/sources.list.d/pgdg.list" && \
     wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && \
     apt-get -y update && \
     apt-get -y install redis-tools postgresql-9.6-postgis-2.2 \
     postgresql-contrib-9.6 \
     libpq-dev postgresql-9.6-pgrouting


COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
