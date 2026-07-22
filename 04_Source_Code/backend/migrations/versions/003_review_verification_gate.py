"""add review verification gate tables and columns

Revision ID: 003_review_verification_gate
Revises: 002_add_store_owners
Create Date: 2026-07-23 07:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '003_review_verification_gate'
down_revision: Union[str, None] = '002_add_store_owners'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. Add review policy columns to stores table
    op.add_column('stores', sa.Column('review_verification_type', sa.String(length=50), nullable=True, server_default='BUSINESS_QR'))
    op.add_column('stores', sa.Column('review_location_radius_m', sa.Integer(), nullable=True, server_default='300'))
    op.add_column('stores', sa.Column('manual_visit_allowed', sa.Boolean(), nullable=True, server_default='1'))

    # 2. Create visit_verifications table
    op.create_table(
        'visit_verifications',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('store_id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=True),
        sa.Column('guest_id', sa.String(length=255), nullable=True),
        sa.Column('verification_method', sa.String(length=50), nullable=False),
        sa.Column('qr_code_id', sa.String(length=36), nullable=True),
        sa.Column('qr_token_hash', sa.String(length=255), nullable=True),
        sa.Column('verified_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('review_used_at', sa.DateTime(), nullable=True),
        sa.Column('visit_date', sa.DateTime(), nullable=True),
        sa.Column('measured_distance_m', sa.Float(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='ACTIVE'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_visit_verifications_store_id', 'visit_verifications', ['store_id'], unique=False)
    op.create_index('ix_visit_verifications_user_id', 'visit_verifications', ['user_id'], unique=False)
    op.create_index('ix_visit_verifications_guest_id', 'visit_verifications', ['guest_id'], unique=False)

    # 3. Add verification & guest columns to reviews table
    op.add_column('reviews', sa.Column('guest_id', sa.String(length=255), nullable=True))
    op.add_column('reviews', sa.Column('verification_id', sa.String(length=36), nullable=True))
    op.add_column('reviews', sa.Column('verification_method', sa.String(length=50), nullable=True))
    op.add_column('reviews', sa.Column('verification_badge', sa.String(length=100), nullable=True))
    op.alter_column('reviews', 'user_id', existing_type=sa.String(length=36), nullable=True)
    op.create_foreign_key('fk_reviews_verification_id', 'reviews', 'visit_verifications', ['verification_id'], ['id'], ondelete='SET NULL')

def downgrade() -> None:
    op.drop_constraint('fk_reviews_verification_id', 'reviews', type_='foreignkey')
    op.alter_column('reviews', 'user_id', existing_type=sa.String(length=36), nullable=False)
    op.drop_column('reviews', 'verification_badge')
    op.drop_column('reviews', 'verification_method')
    op.drop_column('reviews', 'verification_id')
    op.drop_column('reviews', 'guest_id')

    op.drop_index('ix_visit_verifications_guest_id', table_name='visit_verifications')
    op.drop_index('ix_visit_verifications_user_id', table_name='visit_verifications')
    op.drop_index('ix_visit_verifications_store_id', table_name='visit_verifications')
    op.drop_table('visit_verifications')

    op.drop_column('stores', 'manual_visit_allowed')
    op.drop_column('stores', 'review_location_radius_m')
    op.drop_column('stores', 'review_verification_type')
