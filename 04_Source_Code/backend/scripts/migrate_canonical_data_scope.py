"""
Canonical Data Scope and Lifecycle Migration Script
DO NOT RUN AGAINST PRODUCTION WITHOUT EXPLICIT PM APPROVAL.

Sequence:
1. Adds data_scope and lifecycle_status columns to `stores` and `missions` if not present.
2. Backfills Store data_scope exclusively from explicit legacy flags:
   - if is_test_data == TRUE or tier == 'TEST' -> 'QA'
   - else -> 'REAL'
3. Backfills Mission data_scope exclusively from parent Store.data_scope.
4. Backfills lifecycle_status to 'ACTIVE'.
5. Validates zero NULLs and zero cross-scope anomalies.
6. Creates composite indexes:
   - stores(data_scope, lifecycle_status)
   - missions(data_scope, lifecycle_status)
"""

import sys
import os
import logging
from sqlalchemy.orm import Session
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import database, models

logger = logging.getLogger("migrate_canonical_data_scope")
logging.basicConfig(level=logging.INFO)

def run_migration(db: Session, dry_run: bool = False):
    logger.info(f"Starting Canonical Data Scope Migration (dry_run={dry_run})...")

    # M1. Add columns as NULLABLE without initial defaults
    columns = [
        ("stores", "data_scope", "VARCHAR(10)"),
        ("stores", "lifecycle_status", "VARCHAR(20)"),
        ("missions", "data_scope", "VARCHAR(10)"),
        ("missions", "lifecycle_status", "VARCHAR(20)"),
    ]

    for table, col_name, col_type in columns:
        try:
            db.execute(text(f"ALTER TABLE {table} ADD COLUMN {col_name} {col_type};"))
            db.commit()
            logger.info(f"Added column {col_name} to {table}.")
        except Exception as e:
            db.rollback()
            logger.debug(f"Column {col_name} on {table} already exists or error: {e}")

    # M2. Backfill Stores only if data_scope is unset/NULL (Idempotent safe)
    logger.info("Backfilling stores data_scope from explicit legacy flags...")
    update_stores_qa = text("""
        UPDATE stores
        SET data_scope = 'QA'
        WHERE (data_scope IS NULL OR data_scope = '')
          AND (is_test_data = TRUE OR tier = 'TEST');
    """)
    update_stores_real = text("""
        UPDATE stores
        SET data_scope = 'REAL'
        WHERE (data_scope IS NULL OR data_scope = '')
          AND (is_test_data IS NULL OR is_test_data = FALSE)
          AND (tier IS NULL OR tier != 'TEST');
    """)
    update_stores_lifecycle = text("""
        UPDATE stores
        SET lifecycle_status = 'ACTIVE'
        WHERE lifecycle_status IS NULL OR lifecycle_status = '';
    """)

    db.execute(update_stores_qa)
    db.execute(update_stores_real)
    db.execute(update_stores_lifecycle)

    # M3. Backfill Missions from linked Store for unset/NULL rows
    logger.info("Backfilling missions data_scope from linked stores...")
    update_missions = text("""
        UPDATE missions
        SET data_scope = (
            SELECT s.data_scope FROM stores s WHERE s.id = missions.store_id
        ),
        lifecycle_status = 'ACTIVE'
        WHERE missions.data_scope IS NULL OR missions.data_scope = '';
    """)
    db.execute(update_missions)

    # M4. Validation Checks
    unresolved_missions = db.execute(text("SELECT count(*) FROM missions WHERE data_scope IS NULL OR data_scope = ''")).scalar()
    if unresolved_missions > 0:
        db.rollback()
        raise ValueError(f"MIGRATION_HALT: Found {unresolved_missions} missions with unresolved parent stores.")

    null_stores = db.execute(text("SELECT count(*) FROM stores WHERE data_scope IS NULL OR data_scope = ''")).scalar()
    if null_stores > 0:
        db.rollback()
        raise ValueError(f"MIGRATION_HALT: Found {null_stores} stores with NULL data_scope.")

    cross_scope_anomalies = db.execute(text("""
        SELECT count(*) FROM missions m
        JOIN stores s ON m.store_id = s.id
        WHERE m.data_scope != s.data_scope
    """)).scalar()
    if cross_scope_anomalies > 0:
        db.rollback()
        raise ValueError(f"MIGRATION_HALT: Found {cross_scope_anomalies} cross-scope mission-store links.")

    # M5. Create Indexes
    try:
        db.execute(text("CREATE INDEX IF NOT EXISTS idx_stores_scope_lifecycle ON stores(data_scope, lifecycle_status);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS idx_missions_scope_lifecycle ON missions(data_scope, lifecycle_status);"))
    except Exception as e:
        logger.debug(f"Index creation notice: {e}")

    if dry_run:
        db.rollback()
        logger.info("[DRY RUN COMPLETE] Validation succeeded. Transaction rolled back.")
    else:
        db.commit()
        logger.info("[MIGRATION COMPLETE] All records successfully migrated and verified.")

if __name__ == "__main__":
    db = database.SessionLocal()
    try:
        dry_run = "--dry-run" in sys.argv
        run_migration(db, dry_run=dry_run)
    finally:
        db.close()
