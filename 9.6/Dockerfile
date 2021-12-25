FROM postgres:9.6-stretch

LABEL maintainer="milan@showpass.com"

ENV POSTGIS_MAJOR 2.4
ENV POSTGIS_VERSION=2.4.4+dfsg-4.pgdg90+1

RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
      && rm -rf /var/lib/apt/lists/*

COPY ./10-replication-config.sh /docker-entrypoint-initdb.d/
COPY ./20-replication-setup.sh /docker-entrypoint-initdb.d/
COPY ./30-initdb-postgis.sh /docker-entrypoint-initdb.d/
COPY ./40-install-trgm.sh /docker-entrypoint-initdb.d/
COPY ./update-postgis.sh /usr/local/bin

RUN chmod +x /docker-entrypoint-initdb.d/10-replication-config.sh \
    /docker-entrypoint-initdb.d/20-replication-setup.sh \
    /docker-entrypoint-initdb.d/30-initdb-postgis.sh \
    /docker-entrypoint-initdb.d/40-install-trgm.sh \
    /usr/local/bin/update-postgis.sh