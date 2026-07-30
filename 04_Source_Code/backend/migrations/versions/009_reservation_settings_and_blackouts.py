"""create reservation settings and blackouts tables and extend store_reservations

Revision ID: 009_reservation_settings
Revises: 008_create_products_table
Create Date: 2026-07-30 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '009_reservation_settings'
down_revision: Union[str, None] = '008_create_products_table'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    if 'reservation_settings' not in tables:
        op.create_table(
            'reservation_settings',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('store_id', sa.String(length=36), nullable=False),
            sa.Column('reservations_enabled', sa.Boolean(), nullable=False, server_default='0'),
            sa.Column('approval_mode', sa.String(length=50), nullable=False, server_default='MANUAL'),
            sa.Column('available_weekdays', sa.String(length=100), nullable=False, server_default='1,2,3,4,5,6,7'),
            sa.Column('operating_start_time', sa.String(length=10), nullable=False, server_default='09:00'),
            sa.Column('operating_end_time', sa.String(length=10), nullable=False, server_default='22:00'),
            sa.Column('slot_interval_minutes', sa.Integer(), nullable=False, server_default='30'),
            sa.Column('minimum_advance_minutes', sa.Integer(), nullable=False, server_default='120'),
            sa.Column('maximum_advance_days', sa.Integer(), nullable=False, server_default='30'),
            sa.Column('same_day_booking_allowed', sa.Boolean(), nullable=False, server_default='1'),
            sa.Column('same_day_cutoff_time', sa.String(length=10), nullable=True),
            sa.Column('minimum_party_size', sa.Integer(), nullable=False, server_default='1'),
            sa.Column('maximum_party_size', sa.Integer(), nullable=False, server_default='6'),
            sa.Column('max_reservations_per_slot', sa.Integer(), nullable=False, server_default='1'),
            sa.Column('temporary_pause_enabled', sa.Boolean(), nullable=False, server_default='0'),
            sa.Column('temporary_pause_until', sa.DateTime(), nullable=True),
            sa.Column('temporary_pause_reason', sa.Text(), nullable=True),
            sa.Column('timezone', sa.String(length=50), nullable=False, server_default='Asia/Seoul'),
            sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_reservation_settings_store_id'), 'reservation_settings', ['store_id'], unique=True)

    if 'reservation_blackouts' not in tables:
        op.create_table(
            'reservation_blackouts',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('store_id', sa.String(length=36), nullable=False),
            sa.Column('weekday', sa.Integer(), nullable=True),
            sa.Column('start_time', sa.String(length=10), nullable=False),
            sa.Column('end_time', sa.String(length=10), nullable=False),
            sa.Column('reason', sa.String(length=255), nullable=True),
            sa.Column('is_active', sa.Boolean(), nullable=False, server_default='1'),
            sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_reservation_blackouts_store_id'), 'reservation_blackouts', ['store_id'], unique=False)

    if 'store_reservations' in tables:
        columns = [c['name'] for c in inspector.get_columns('store_reservations')]
        if 'product_id' not in columns:
            op.add_column('store_reservations', sa.Column('product_id', sa.String(length=36), nullable=True))
        if 'customer_note' not in columns:
            op.add_column('store_reservations', sa.Column('customer_note', sa.Text(), nullable=True))
        if 'reservation_date' not in columns:
            op.add_column('store_reservations', sa.Column('reservation_date', sa.String(length=10), nullable=True))
        if 'start_time' not in columns:
            op.add_column('store_reservations', sa.Column('start_time', sa.String(length=10), nullable=True))
        if 'rejection_reason' not in columns:
            op.add_column('store_reservations', sa.Column('rejection_reason', sa.Text(), nullable=True))
        if 'cancellation_reason' not in columns:
            op.add_column('store_reservations', sa.Column('cancellation_reason', sa.Text(), nullable=True))

def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()
    if 'reservation_blackouts' in tables:
        op.drop_index(op.f('ix_reservation_blackouts_store_id'), table_name='reservation_blackouts')
        op.drop_table('reservation_blackouts')
    if 'reservation_settings' in tables:
        op.drop_index(op.f('ix_reservation_settings_store_id'), table_name='reservation_settings')
        op.drop_table('reservation_settings')
