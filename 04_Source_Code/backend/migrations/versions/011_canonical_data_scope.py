"""add canonical data_scope and lifecycle_status to stores and missions

Revision ID: 011_canonical_data_scope
Revises: 010_point_economy_v2
Create Date: 2026-09-03 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision: str = '011_canonical_data_scope'
down_revision: Union[str, None] = '010_point_economy_v2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)

    # 1. Add columns to stores if not present
    stores_cols = [c['name'] for c in inspector.get_columns('stores')]
    if 'data_scope' not in stores_cols:
        op.add_column('stores', sa.Column('data_scope', sa.String(length=10), nullable=True))
    if 'lifecycle_status' not in stores_cols:
        op.add_column('stores', sa.Column('lifecycle_status', sa.String(length=20), nullable=True))

    # 2. Add columns to missions if not present
    missions_cols = [c['name'] for c in inspector.get_columns('missions')]
    if 'data_scope' not in missions_cols:
        op.add_column('missions', sa.Column('data_scope', sa.String(length=10), nullable=True))
    if 'lifecycle_status' not in missions_cols:
        op.add_column('missions', sa.Column('lifecycle_status', sa.String(length=20), nullable=True))

    # 3. Backfill stores data_scope & lifecycle_status from explicit legacy flags only if present
    has_is_test_data = 'is_test_data' in stores_cols
    has_tier = 'tier' in stores_cols

    if has_is_test_data and has_tier:
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'QA'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND (is_test_data = TRUE OR tier = 'TEST');
        """))
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'REAL'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND (is_test_data IS NULL OR is_test_data = FALSE)
              AND (tier IS NULL OR tier != 'TEST');
        """))
    elif has_is_test_data:
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'QA'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND is_test_data = TRUE;
        """))
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'REAL'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND (is_test_data IS NULL OR is_test_data = FALSE);
        """))
    elif has_tier:
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'QA'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND tier = 'TEST';
        """))
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'REAL'
            WHERE (data_scope IS NULL OR data_scope = '')
              AND (tier IS NULL OR tier != 'TEST');
        """))
    else:
        # In a clean base-to-head chain without legacy test flags, default unassigned stores to REAL
        conn.execute(text("""
            UPDATE stores
            SET data_scope = 'REAL'
            WHERE data_scope IS NULL OR data_scope = '';
        """))

    conn.execute(text("""
        UPDATE stores
        SET lifecycle_status = 'ACTIVE'
        WHERE lifecycle_status IS NULL OR lifecycle_status = '';
    """))

    # 4. Backfill missions from parent linked store
    conn.execute(text("""
        UPDATE missions
        SET data_scope = (
            SELECT s.data_scope FROM stores s WHERE s.id = missions.store_id
        ),
        lifecycle_status = 'ACTIVE'
        WHERE missions.data_scope IS NULL OR missions.data_scope = '';
    """))

    # 5. Strict Validation Checks (Halt if any anomaly found)
    unresolved_missions = conn.execute(text("SELECT count(*) FROM missions WHERE data_scope IS NULL OR data_scope = ''")).scalar()
    if unresolved_missions > 0:
        raise ValueError(f"MIGRATION_HALT: Found {unresolved_missions} missions with unresolved parent stores.")

    null_stores = conn.execute(text("SELECT count(*) FROM stores WHERE data_scope IS NULL OR data_scope = ''")).scalar()
    if null_stores > 0:
        raise ValueError(f"MIGRATION_HALT: Found {null_stores} stores with NULL data_scope.")

    cross_scope_anomalies = conn.execute(text("""
        SELECT count(*) FROM missions m
        JOIN stores s ON m.store_id = s.id
        WHERE m.data_scope != s.data_scope
    """)).scalar()
    if cross_scope_anomalies > 0:
        raise ValueError(f"MIGRATION_HALT: Found {cross_scope_anomalies} cross-scope mission-store links.")

    # 6. Alter columns to NOT NULL with server defaults where supported
    with op.batch_alter_table('stores') as batch_op:
        batch_op.alter_column('data_scope', nullable=False, server_default='REAL')
        batch_op.alter_column('lifecycle_status', nullable=False, server_default='ACTIVE')
        batch_op.create_index('idx_stores_scope_lifecycle', ['data_scope', 'lifecycle_status'])

    with op.batch_alter_table('missions') as batch_op:
        batch_op.alter_column('data_scope', nullable=False, server_default='REAL')
        batch_op.alter_column('lifecycle_status', nullable=False, server_default='ACTIVE')
        batch_op.create_index('idx_missions_scope_lifecycle', ['data_scope', 'lifecycle_status'])


def downgrade() -> None:
    with op.batch_alter_table('missions') as batch_op:
        batch_op.drop_index('idx_missions_scope_lifecycle')
        batch_op.drop_column('lifecycle_status')
        batch_op.drop_column('data_scope')

    with op.batch_alter_table('stores') as batch_op:
        batch_op.drop_index('idx_stores_scope_lifecycle')
        batch_op.drop_column('lifecycle_status')
        batch_op.drop_column('data_scope')
