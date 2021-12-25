#!/bin/bash
set -e

echo [*] configuring $REPLICATION_ROLE instance

echo "max_connections = $PG_MAX_CONNECTIONS" >> "$PGDATA/postgresql.conf"

# Slave and master settings
echo "wal_level = hot_standby" >> "$PGDATA/postgresql.conf"
echo "wal_keep_segments = $PG_WAL_KEEP_SEGMENTS" >> "$PGDATA/postgresql.conf"
echo "max_wal_senders = $PG_MAX_WAL_SENDERS" >> "$PGDATA/postgresql.conf"

# Slave settings
if [ $REPLICATION_ROLE = "slave" ]; then
    echo "hot_standby = on" >> "$PGDATA/postgresql.conf"
fi

echo "host replication $REPLICATION_USER 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"
