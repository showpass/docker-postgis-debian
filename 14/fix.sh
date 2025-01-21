#!/bin/bash
set -Eeo pipefail

docker_process_sql() {
	local query_runner=( psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --no-password --no-psqlrc )
	if [ -n "$POSTGRES_DB" ]; then
		query_runner+=( --dbname "$POSTGRES_DB" )
	fi

	PGHOST= PGHOSTADDR= "${query_runner[@]}" "$@"
}

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		printf >&2 'error: both %s and %s are set (but are exclusive)\n' "$var" "$fileVar"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

docker_setup_env() {
	file_env 'POSTGRES_PASSWORD'

	file_env 'POSTGRES_USER' 'postgres'
	file_env 'POSTGRES_DB' "$POSTGRES_USER"
	file_env 'POSTGRES_INITDB_ARGS'
	: "${POSTGRES_HOST_AUTH_METHOD:=}"

	declare -g DATABASE_ALREADY_EXISTS
	: "${DATABASE_ALREADY_EXISTS:=}"
	# look specifically for PG_VERSION, as it is expected in the DB dir
	if [ -s "$PGDATA/PG_VERSION" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi
}

docker_setup_env

psql=( docker_process_sql )


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

for DB in template_postgis "$POSTGRES_DB"; do
	echo "Enabling pg_hint_plan and updating PostGIS extensions on $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
    CREATE EXTENSION IF NOT EXISTS pg_hint_plan;
    ALTER EXTENSION postgis UPDATE;
    ALTER EXTENSION postgis_topology UPDATE;
    ALTER EXTENSION postgis_tiger_geocoder UPDATE;
EOSQL
done

for DB in template1; do
	echo "Enabling pg_hint_plan on $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
    CREATE EXTENSION IF NOT EXISTS pg_hint_plan;
EOSQL
done