#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# This gawk operation adds pg_hint_plan to shared_preload_libraries if it isn't added.
gawk '/^#shared_preload_libraries/ { sub(/^#/, "") }
     /^shared_preload_libraries/ {
         if ($3 == "\047\047") {
             sub(/\047\047/, "\047pg_hint_plan\047");
         } else if ($0 !~ /pg_hint_plan/) {
             match($0, /\047([^\047]*)/, arr);
             sub(/\047([^\047]*)/, "\047" arr[1] ", pg_hint_plan");
         }
     }
     {print}' $PGDATA/postgresql.conf > ~/tmp.conf && mv ~/tmp.conf $PGDATA/postgresql.conf

# Create the 'template_postgis' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis "$POSTGRES_DB"; do
	echo "Loading PostGIS, fuzzystrmatch, vector, unaccent and pg_hint_plan extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		-- Reconnect to update pg_setting.resetval
		-- See https://github.com/postgis/docker-postgis/issues/288
		\c
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
        CREATE EXTENSION IF NOT EXISTS vector;
        CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS pg_hint_plan;
EOSQL
done

# Load PG_TRGM into both template1 and $POSTGRES_DB
for DB in template1 "$POSTGRES_DB"; do
	echo "Loading PG_TRGM, vector, unaccent and pg_hint_plan extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE EXTENSION IF NOT EXISTS vector;
        CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS pg_hint_plan;
EOSQL
done
