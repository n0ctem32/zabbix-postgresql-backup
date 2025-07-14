#!/bin/bash

ACTION=$1  # "dump" or "restore"
LOGDIR="/var/log/pg_backup_monitor"
BACKUPDIR="/var/backups"

mkdir -p "$LOGDIR"
mkdir -p "$BACKUPDIR"

DATABASES=$(psql -U postgres -tAc "SELECT datname FROM pg_database WHERE datistemplate = false;")

for DB in $DATABASES; do
    BACKUPFILE="$BACKUPDIR/${DB}_backup.dump"
    START_TIME=$(date +%s)
    START_DATE=$START_TIME

    LOGFILE="$LOGDIR/${DB}_${ACTION}.log"

    if [[ "$ACTION" == "dump" ]]; then
        pg_dump -Fc -f "$BACKUPFILE" "$DB" 2> "$LOGFILE"
        EXIT_CODE=$?
    elif [[ "$ACTION" == "restore" ]]; then
        pg_restore -d "$DB" "$BACKUPFILE" 2> "$LOGFILE"
        EXIT_CODE=$?
    else
        echo "Invalid action: $ACTION"
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
        echo "$ACTION operation for database '$DB' was successful." >> "$LOGFILE"
    else
        echo "FAILED" > "$LOGDIR/${DB}_${ACTION}_status"
        echo "$ACTION operation for database '$DB' failed." >> "$LOGFILE"
    fi
done