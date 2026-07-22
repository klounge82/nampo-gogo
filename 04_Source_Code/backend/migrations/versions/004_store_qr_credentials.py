"""add store_qr_credentials table for expiring pre-issued QR verification

Revision ID: 004_store_qr_credentials
Revises: 003_review_verification_gate
Create Date: 2026-07-23 08:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '004_store_qr_credentials'
down_revision: Union[str, None] = '003_review_verification_gate'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.create_table(
        'store_qr_credentials',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('store_id', sa.String(length=36), nullable=False),
        sa.Column('token_hash', sa.String(length=255), nullable=False),
        sa.Column('issued_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='ACTIVE'),
        sa.Column('purpose', sa.String(length=50), nullable=False, server_default='REVIEW_VISIT'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('revoked_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_store_qr_credentials_store_id', 'store_qr_credentials', ['store_id'], unique=False)
    op.create_index('ix_store_qr_credentials_token_hash', 'store_qr_credentials', ['token_hash'], unique=False)

def downgrade() -> None:
    op.drop_index('ix_store_qr_credentials_token_hash', table_name='store_qr_credentials')
    op.drop_index('ix_store_qr_credentials_store_id', table_name='store_qr_credentials')
    op.drop_table('store_qr_credentials')
