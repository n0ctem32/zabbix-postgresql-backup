#!/bin/bash

ACTION=$1  # "dump" or "restore"
LOGDIR="/var/log/pg_backup_monitor" #Directory for where the logs are stored.
BACKUPDIR="/var/backups" #Directory where the backup is stored.

mkdir -p "$LOGDIR"
mkdir -p "$BACKUPDIR"

# Auto-discover all DBs (excluding templates)
DATABASES=$(psql -U postgres -tAc "SELECT datname FROM pg_database WHERE datistemplate = false;")

for DB in $DATABASES; do
    BACKUPFILE="$BACKUPDIR/${DB}_backup.dump"
    START_TIME=$(date +%s)
    START_DATE=$START_TIME

    if [[ "$ACTION" == "dump" ]]; then
        pg_dump -Fc -f "$BACKUPFILE" "$DB" 2> "$LOGDIR/${DB}_dump.log"
        EXIT_CODE=$?
    elif [[ "$ACTION" == "restore" ]]; then
        pg_restore -d "$DB" "$BACKUPFILE" 2> "$LOGDIR/${DB}_restore.log"
        EXIT_CODE=$?
    else
        echo "Invalid action"
        exit 1
    fi

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    END_DATE=$END_TIME
    echo "$EXIT_CODE" > "$LOGDIR/${DB}_${ACTION}_exit_code"
    echo "$DURATION" > "$LOGDIR/${DB}_${ACTION}_duration"
    echo "$START_DATE" > "$LOGDIR/${DB}_${ACTION}_start"
    echo "$END_DATE" > "$LOGDIR/${DB}_${ACTION}_end"
    touch "$LOGDIR/${DB}_${ACTION}_last_update"

    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "OK" > "$LOGDIR/${DB}_${ACTION}_status"
    else
        echo "FAILED" > "$LOGDIR/${DB}_${ACTION}_status"
    fi
done

