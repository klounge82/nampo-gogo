"""deterministic legacy balance backfill into point_lots

Revision ID: 013_point_legacy_backfill
Revises: 012_point_economy_stage1
Create Date: 2026-09-03 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision: str = '013_point_legacy_backfill'
down_revision: Union[str, None] = '012_point_economy_stage1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # 1. Negative Balance Precheck - Halt if any negative current_points found
    negative_count = conn.execute(text("SELECT count(*) FROM users WHERE current_points < 0")).scalar()
    if negative_count > 0:
        raise ValueError(f"BACKFILL_HALT: Found {negative_count} users with negative current_points. Manual reconciliation required.")

    # 2. Deterministic, Idempotent Legacy Lot Creation for all users with current_points > 0
    # Uses gen_random_uuid() (or uuid_generate_v4() in PostgreSQL) to generate lot ID.
    # Expiration: NULL (Policy locked: NO_EXPIRY for pre-existing legacy balances).
    # Transferable: False (Policy locked: Non-transferable).
    # Idempotency Guard: WHERE NOT EXISTS (SELECT 1 FROM point_lots pl WHERE pl.user_id = u.id AND pl.source_type = 'LEGACY_MIGRATION')
    backfill_sql = text("""
        INSERT INTO point_lots (
            id,
            user_id,
            source_history_id,
            operation_id,
            source_type,
            original_points,
            remaining_points,
            reserved_points,
            expires_at,
            is_transferable,
            status,
            created_at
        )
        SELECT
            gen_random_uuid()::text,
            u.id,
            NULL,
            NULL,
            'LEGACY_MIGRATION',
            u.current_points,
            u.current_points,
            0,
            NULL,
            FALSE,
            'ACTIVE',
            NOW()
        FROM users u
        WHERE u.current_points > 0
          AND NOT EXISTS (
              SELECT 1
              FROM point_lots pl
              WHERE pl.user_id = u.id
                AND pl.source_type = 'LEGACY_MIGRATION'
          );
    """)
    conn.execute(backfill_sql)


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(text("DELETE FROM point_lots WHERE source_type = 'LEGACY_MIGRATION';"))
