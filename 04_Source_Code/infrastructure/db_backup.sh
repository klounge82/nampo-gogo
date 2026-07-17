#!/bin/bash

# --- PostgreSQL Production Daily Backup Script ---
# Run via crontab: 0 3 * * * /app/infrastructure/db_backup.sh

# Environment overrides or defaults
ENV="${APP_ENV:-production}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-nampo_admin}"
DB_NAME="${DB_NAME:-nampo_gogo}"
CONTAINER_NAME="${DB_CONTAINER_NAME:-nampo_gogo_postgres_prod}"

BACKUP_DIR="/var/backups/nampogogo"
RETENTION_DAYS=7
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/nampo_gogo_${ENV}_${TIMESTAMP}.dump"
LOG_FILE="/var/log/nampogogo_backup.log"

echo "[$(date)] Starting Nampo GoGo ${ENV} DB Backup..." >> "${LOG_FILE}"

# Create backup directory if not exists
mkdir -p "${BACKUP_DIR}"

# Execute pg_dump. Try docker exec first, fallback to local pg_dump
if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo "[$(date)] Container ${CONTAINER_NAME} found. Executing pg_dump inside container..." >> "${LOG_FILE}"
    docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -F c > "${BACKUP_FILE}" 2>> "${LOG_FILE}"
else
    echo "[$(date)] Container ${CONTAINER_NAME} not running. Trying host pg_dump..." >> "${LOG_FILE}"
    PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F c > "${BACKUP_FILE}" 2>> "${LOG_FILE}"
fi

# Validation Checks
if [ $? -eq 0 ] && [ -f "${BACKUP_FILE}" ] && [ -s "${BACKUP_FILE}" ]; then
    FILE_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
    echo "[$(date)] Backup completed successfully. File: ${BACKUP_FILE} (Size: ${FILE_SIZE})" >> "${LOG_FILE}"
else
    echo "[$(date)] ERROR: Backup failed or output file is empty!" >> "${LOG_FILE}"
    # Keep the failed backup file if it exists but is zero-sized for diagnostic investigation, do not delete success ones
    exit 1
fi

# Retention policy: remove backups older than 7 days
echo "[$(date)] Cleaning up backups older than ${RETENTION_DAYS} days..." >> "${LOG_FILE}"
find "${BACKUP_DIR}" -name "nampo_gogo_${ENV}_*.dump" -type f -mtime +${RETENTION_DAYS} -delete >> "${LOG_FILE}" 2>&1

echo "[$(date)] Backup rotation completed." >> "${LOG_FILE}"
