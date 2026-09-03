"""add point_operations, point_lots, point_allocations, point_gifts, and users non-negative point check constraint

Revision ID: 012_point_economy_stage1_lots_and_gifts
Revises: 011_canonical_data_scope
Create Date: 2026-09-03 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision: str = '012_point_economy_stage1'
down_revision: Union[str, None] = '011_canonical_data_scope'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # 0. Safety Precheck on existing users (Halt if any negative point balances exist)
    negative_users_count = conn.execute(text("SELECT count(*) FROM users WHERE current_points < 0")).scalar()
    if negative_users_count > 0:
        raise ValueError(f"MIGRATION_HALT: Found {negative_users_count} users with negative current_points. Manual reconciliation required.")

    # 1. Create point_operations table
    op.create_table(
        'point_operations',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('actor_user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('operation_type', sa.String(length=50), nullable=False),
        sa.Column('idempotency_key', sa.String(length=128), nullable=True),
        sa.Column('request_fingerprint', sa.String(length=64), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='STARTED'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
    )
    # Partial unique indexes for idempotency
    op.create_index(
        'uq_point_ops_user_idempotency',
        'point_operations',
        ['actor_user_id', 'operation_type', 'idempotency_key'],
        unique=True,
        postgresql_where=text("actor_user_id IS NOT NULL AND idempotency_key IS NOT NULL")
    )
    op.create_index(
        'uq_point_ops_system_idempotency',
        'point_operations',
        ['operation_type', 'idempotency_key'],
        unique=True,
        postgresql_where=text("actor_user_id IS NULL AND idempotency_key IS NOT NULL")
    )

    # 2. Create point_lots table
    op.create_table(
        'point_lots',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('source_history_id', sa.String(length=36), sa.ForeignKey('point_histories.id', ondelete='SET NULL'), nullable=True),
        sa.Column('operation_id', sa.String(length=36), sa.ForeignKey('point_operations.id', ondelete='SET NULL'), nullable=True),
        sa.Column('source_type', sa.String(length=50), nullable=False),
        sa.Column('original_points', sa.Integer(), nullable=False),
        sa.Column('remaining_points', sa.Integer(), nullable=False),
        sa.Column('reserved_points', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('expires_at', sa.DateTime(), nullable=True),
        sa.Column('is_transferable', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='ACTIVE'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint('original_points > 0', name='chk_point_lots_orig_positive'),
        sa.CheckConstraint('remaining_points >= 0', name='chk_point_lots_rem_nonnegative'),
        sa.CheckConstraint('reserved_points >= 0', name='chk_point_lots_res_nonnegative'),
        sa.CheckConstraint('reserved_points <= remaining_points', name='chk_point_lots_res_le_rem'),
    )
    op.create_index(
        'idx_point_lots_user_active_fefo',
        'point_lots',
        ['user_id', 'status', 'is_transferable', 'expires_at', 'created_at', 'id']
    )
    # Partial unique index to guarantee at most one LEGACY_MIGRATION lot per user
    op.create_index(
        'uq_point_lots_user_legacy_migration',
        'point_lots',
        ['user_id'],
        unique=True,
        postgresql_where=text("source_type = 'LEGACY_MIGRATION'")
    )

    # 3. Create point_allocations table
    op.create_table(
        'point_allocations',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('lot_id', sa.String(length=36), sa.ForeignKey('point_lots.id', ondelete='CASCADE'), nullable=False),
        sa.Column('operation_id', sa.String(length=36), sa.ForeignKey('point_operations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('points', sa.Integer(), nullable=False),
        sa.Column('allocation_type', sa.String(length=30), nullable=False), # 'CONSUMPTION', 'RESERVATION', 'RESERVATION_RELEASE'
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint('points > 0', name='chk_point_alloc_points_positive'),
    )
    op.create_index(
        'idx_point_alloc_lot_op',
        'point_allocations',
        ['lot_id', 'operation_id']
    )

    # 4. Create point_gifts table
    op.create_table(
        'point_gifts',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('sender_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('recipient_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('create_operation_id', sa.String(length=36), sa.ForeignKey('point_operations.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('accept_operation_id', sa.String(length=36), sa.ForeignKey('point_operations.id', ondelete='RESTRICT'), nullable=True),
        sa.Column('gift_token_hash', sa.String(length=64), nullable=False),
        sa.Column('gross_points', sa.Integer(), nullable=False),
        sa.Column('fee_points', sa.Integer(), nullable=False),
        sa.Column('net_points', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='PENDING'), # 'PENDING', 'ACCEPTED', 'CANCELLED', 'EXPIRED'
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('accepted_at', sa.DateTime(), nullable=True),
        sa.Column('cancelled_at', sa.DateTime(), nullable=True),
        sa.CheckConstraint('gross_points > 0', name='chk_gift_gross_positive'),
        sa.CheckConstraint('fee_points >= 0', name='chk_gift_fee_nonnegative'),
        sa.CheckConstraint('net_points > 0', name='chk_gift_net_positive'),
        sa.CheckConstraint('gross_points = fee_points + net_points', name='chk_gift_total_balance'),
        sa.CheckConstraint('recipient_id IS NULL OR recipient_id != sender_id', name='chk_gift_no_self_claim'),
    )
    op.create_index('uq_point_gifts_token_hash', 'point_gifts', ['gift_token_hash'], unique=True)
    op.create_index('idx_point_gifts_sender_status', 'point_gifts', ['sender_id', 'status'])
    op.create_index('idx_point_gifts_recipient_status', 'point_gifts', ['recipient_id', 'status'])
    op.create_index('idx_point_gifts_expires_status', 'point_gifts', ['expires_at', 'status'])

    # 5. Add users non-negative check constraint
    with op.batch_alter_table('users') as batch_op:
        batch_op.create_check_constraint('chk_users_current_points_nonnegative', 'current_points >= 0')


def downgrade() -> None:
    with op.batch_alter_table('users') as batch_op:
        batch_op.drop_constraint('chk_users_current_points_nonnegative', type_='check')

    op.drop_table('point_gifts')
    op.drop_table('point_allocations')
    op.drop_table('point_lots')
    op.drop_table('point_operations')
