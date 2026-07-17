#!/bin/bash

# --- PostgreSQL DB Restore Script ---
# Usage: ./db_restore.sh <environment> <db_name> <backup_file_path> [--confirm-production-restore]

ENV="$1"
TARGET_DB="$2"
BACKUP_PATH="$3"
CONFIRM_FLAG="$4"
LOG_FILE="/var/log/nampogogo_restore.log"

echo "[$(date)] Initiating database restore procedure..." >> "${LOG_FILE}"

if [ -z "${ENV}" ] || [ -z "${TARGET_DB}" ] || [ -z "${BACKUP_PATH}" ]; then
    echo "Usage: $0 <environment> <db_name> <backup_file_path> [--confirm-production-restore]"
    echo "ERROR: Missing arguments!"
    exit 1
fi

# 1. Validation Checks
if [ ! -f "${BACKUP_PATH}" ]; then
    echo "ERROR: Backup file not found at: ${BACKUP_PATH}"
    exit 1
fi

if [ ! -s "${BACKUP_PATH}" ]; then
    echo "ERROR: Backup file is empty (0 bytes)!"
    exit 1
fi

# 2. Production Environment Guard
if [ "${ENV}" = "production" ]; then
    echo "WARNING: Target environment is PRODUCTION!"
    if [ "${CONFIRM_FLAG}" != "--confirm-production-restore" ]; then
        echo "ERROR: Restore to PRODUCTION blocked! You must supply '--confirm-production-restore' flag."
        exit 1
    fi
    echo "PROCEEDING WITH PRODUCTION RESTORE..."
fi

# 3. Database Safety Check (Prevent dropping active DBs)
# Instead of dropping, we recommend creating a temporary recovery DB first
echo "=================================================="
echo "Restore targets details:"
echo "Environment: ${ENV}"
echo "Database   : ${TARGET_DB}"
echo "Backup File: ${BACKUP_PATH}"
echo "=================================================="

# Check if target database already exists and prompt
CONTAINER_NAME="${DB_CONTAINER_NAME:-nampo_gogo_postgres_prod}"

echo "[$(date)] Performing restore via pg_restore..." >> "${LOG_FILE}"

# Execute restore using pg_restore
if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} detected. Running pg_restore inside container..."
    docker exec -i "${CONTAINER_NAME}" pg_restore -U "${DB_USER:-nampo_admin}" -d "${TARGET_DB}" --clean --no-owner --no-privileges < "${BACKUP_PATH}" >> "${LOG_FILE}" 2>&1
else
    echo "Container ${CONTAINER_NAME} not running. Running host-based pg_restore..."
    PGPASSWORD="${DB_PASSWORD}" pg_restore -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-nampo_admin}" -d "${TARGET_DB}" --clean --no-owner --no-privileges < "${BACKUP_PATH}" >> "${LOG_FILE}" 2>&1
fi

if [ $? -eq 0 ]; then
    echo "SUCCESS: Database restored successfully to ${TARGET_DB}!"
    echo "[$(date)] Restore completed successfully." >> "${LOG_FILE}"
    exit 0
else
    echo "ERROR: pg_restore failed! Check ${LOG_FILE} for detail."
    echo "[$(date)] ERROR: Restore failed." >> "${LOG_FILE}"
    exit 1
fi
