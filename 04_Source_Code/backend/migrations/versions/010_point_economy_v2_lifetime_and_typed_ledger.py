"""add lifetime_earned_points and typed_ledger fields for Point Economy V2

Revision ID: 010_point_economy_v2
Revises: 009_reservation_settings
Create Date: 2026-08-20 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '010_point_economy_v2'
down_revision: Union[str, None] = '009_reservation_settings'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    # 1. Add lifetime_earned_points to users if not present
    users_cols = [c['name'] for c in inspector.get_columns('users')]
    if 'lifetime_earned_points' not in users_cols:
        op.add_column('users', sa.Column('lifetime_earned_points', sa.Integer(), nullable=False, server_default='0'))

    # 2. Add typed ledger columns to point_histories if not present
    ph_cols = [c['name'] for c in inspector.get_columns('point_histories')]
    if 'transaction_type' not in ph_cols:
        op.add_column('point_histories', sa.Column('transaction_type', sa.String(length=50), nullable=True))
    if 'source_type' not in ph_cols:
        op.add_column('point_histories', sa.Column('source_type', sa.String(length=50), nullable=True))
    if 'source_id' not in ph_cols:
        op.add_column('point_histories', sa.Column('source_id', sa.String(length=36), nullable=True))
    if 'correction_of_history_id' not in ph_cols:
        op.add_column('point_histories', sa.Column('correction_of_history_id', sa.String(length=36), nullable=True))

    # 3. Deterministic Backfill for users.lifetime_earned_points
    # Includes ONLY positive credit records for MISSION, REVIEW, VISIT rewards
    # Excludes EXACT incident ph_sun_incident_001 and SIGNUP_BONUS / ADMIN_CREDIT / CORRECTION / QA_TEST
    backfill_sql = """
    UPDATE users u
    SET lifetime_earned_points = COALESCE((
        SELECT SUM(ph.points)
        FROM point_histories ph
        WHERE ph.user_id = u.id
          AND ph.points > 0
          AND ph.id != 'ph_sun_incident_001'
          AND (ph.activity LIKE '미션 완료:%' OR ph.activity = '방문 리뷰 작성 보상' OR ph.activity LIKE '방문 인증 완료:%')
          AND ph.activity NOT LIKE '%회원가입%'
          AND ph.activity NOT LIKE '%웰컴%'
          AND ph.activity NOT LIKE '%관리자%'
          AND ph.activity NOT LIKE '%복원%'
          AND ph.activity NOT LIKE '%보정%'
    ), 0);
    """
    conn.execute(sa.text(backfill_sql))

def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)

    users_cols = [c['name'] for c in inspector.get_columns('users')]
    if 'lifetime_earned_points' in users_cols:
        op.drop_column('users', 'lifetime_earned_points')

    ph_cols = [c['name'] for c in inspector.get_columns('point_histories')]
    if 'correction_of_history_id' in ph_cols:
        op.drop_column('point_histories', 'correction_of_history_id')
    if 'source_id' in ph_cols:
        op.drop_column('point_histories', 'source_id')
    if 'source_type' in ph_cols:
        op.drop_column('point_histories', 'source_type')
    if 'transaction_type' in ph_cols:
        op.drop_column('point_histories', 'transaction_type')
