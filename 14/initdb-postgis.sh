#!/bin/sh

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_postgis' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis "$POSTGRES_DB"; do
	echo "Loading PostGIS extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
EOSQL
done

# Load PG_TRGM into both template1 and $POSTGRES_DB
for DB in template1 "$POSTGRES_DB"; do
	echo "Loading PG_TRGM extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL
done

# Load PG_LOGICAL into both template1 and $POSTGRES_DB
for DB in template1 "$POSTGRES_DB"; do
	echo "Loading PG_LOGICAL extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
	  ALTER SYSTEM SET shared_preload_libraries = 'pglogical';
		CREATE EXTENSION IF NOT EXISTS pglogical;
EOSQL
done

pg_ctl restart

# Configure Replication Role
echo [*] configuring $REPLICATION_ROLE instance

echo "max_connections = $PG_MAX_CONNECTIONS" >> "$PGDATA/postgresql.conf"

# Slave and master settings
echo "wal_level = hot_standby" >> "$PGDATA/postgresql.conf"
echo "wal_keep_segments = $PG_WAL_KEEP_SEGMENTS" >> "$PGDATA/postgresql.conf"

# Slave settings
if [ $REPLICATION_ROLE = "slave" ]; then
    echo "hot_standby = on" >> "$PGDATA/postgresql.conf"
fi

echo "host replication $REPLICATION_USER 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"


# Replication Setup
if [ $REPLICATION_ROLE = "master" ]; then
    psql -U postgres -c "CREATE ROLE $REPLICATION_USER WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' LOGIN"

elif [ $REPLICATION_ROLE = "slave" ]; then
    # stop postgres instance and reset PGDATA,
    # confs will be copied by pg_basebackup
    pg_ctl -D "$PGDATA" -m fast -w stop
    # make sure standby's data directory is empty
    rm -r "$PGDATA"/*

    until pg_basebackup \
         --write-recovery-conf \
         --pgdata="$PGDATA" \
         --xlog-method=fetch \
         --username=$REPLICATION_USER \
         --host=$POSTGRES_MASTER_SERVICE_HOST \
         --port=$POSTGRES_MASTER_SERVICE_PORT \
         --progress \
         --verbose
    do
        echo "Waiting for master to connect..."
        sleep 2s
    done


    # useless postgres start to fullfil docker-entrypoint.sh stop
    pg_ctl -D "$PGDATA" \
         -o "-c listen_addresses=''" \
         -w start
fi

echo [*] $REPLICATION_ROLE instance configured!