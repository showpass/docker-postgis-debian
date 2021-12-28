FROM postgres:9.6-stretch

LABEL maintainer="milan@showpass.com"


# Common settings
# Fixes error "max_wal_senders must be less than max_connections"
ENV PG_MAX_CONNECTIONS 500
ENV PG_WAL_KEEP_SEGMENTS 256
ENV PG_MAX_WAL_SENDERS 100

# Master/slave settings
ENV REPLICATION_ROLE master
ENV REPLICATION_USER replication
ENV REPLICATION_PASSWORD ""

# Slave settings
ENV POSTGRES_MASTER_SERVICE_HOST localhost
ENV POSTGRES_MASTER_SERVICE_DB postgres
ENV POSTGRES_MASTER_SERVICE_USER postgres
ENV POSTGRES_MASTER_SERVICE_PASSWORD ""
ENV POSTGRES_MASTER_SERVICE_PORT 5432


ENV POSTGIS_MAJOR 2.4
ENV POSTGIS_VERSION=2.4.4+dfsg-4.pgdg90+1

RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
      && apt-get install postgresql-$PG_MAJOR-pglogical \
      && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin