import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

sys.path.append(os.path.abspath('.'))
from scripts.migrate_canonical_data_scope import run_migration

db_path = 'test_disposable_migration.db'
if os.path.exists(db_path):
    os.remove(db_path)

engine = create_engine(f'sqlite:///{db_path}')
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    db.execute(text('''
        CREATE TABLE stores (
            id VARCHAR(36) PRIMARY KEY,
            name VARCHAR(100),
            is_test_data BOOLEAN,
            tier VARCHAR(50)
        );
    '''))
    db.execute(text('''
        CREATE TABLE missions (
            id VARCHAR(36) PRIMARY KEY,
            store_id VARCHAR(36),
            title VARCHAR(100)
        );
    '''))
    db.commit()

    db.execute(text("INSERT INTO stores (id, name, is_test_data, tier) VALUES ('store_a', 'Store Alpha', 0, 'OFFICIAL');"))
    db.execute(text("INSERT INTO stores (id, name, is_test_data, tier) VALUES ('store_b', 'Store Beta', 1, 'TEST');"))
    db.execute(text("INSERT INTO missions (id, store_id, title) VALUES ('mission_a', 'store_a', 'Mission Alpha');"))
    db.execute(text("INSERT INTO missions (id, store_id, title) VALUES ('mission_b', 'store_b', 'Mission Beta');"))
    db.commit()

    run_migration(db, dry_run=False)

    res_stores = db.execute(text("SELECT id, data_scope, lifecycle_status FROM stores ORDER BY id")).fetchall()
    res_missions = db.execute(text("SELECT id, data_scope, lifecycle_status FROM missions ORDER BY id")).fetchall()
    print("STORES_AFTER_MIGRATION=", res_stores)
    print("MISSIONS_AFTER_MIGRATION=", res_missions)

    run_migration(db, dry_run=False)
    print("IDEMPOTENCY_TEST=PASS")

    db.execute(text("INSERT INTO missions (id, store_id, title, data_scope, lifecycle_status) VALUES ('mission_orphan', 'non_existent_store', 'Orphan Mission', NULL, NULL);"))
    db.commit()

    try:
        run_migration(db, dry_run=False)
        print("FAILURE_TEST=FAIL_SHOULD_HAVE_RAISED")
    except ValueError as ve:
        print("FAILURE_TEST_RAISED_EXPECTED=", str(ve))

finally:
    db.close()
    engine.dispose()
    if os.path.exists(db_path):
        try:
            os.remove(db_path)
        except Exception as e:
            print(f"CLEANUP_WARNING: {e}")
    print("DISPOSABLE_DB_CLEANED_UP=YES")
