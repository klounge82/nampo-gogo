"""add deleted_at column to reviews table for review soft delete

Revision ID: 005_review_deleted_at
Revises: 004_store_qr_credentials
Create Date: 2026-07-23 13:40:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '005_review_deleted_at'
down_revision: Union[str, None] = '004_store_qr_credentials'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.add_column('reviews', sa.Column('deleted_at', sa.DateTime(), nullable=True))

def downgrade() -> None:
    op.drop_column('reviews', 'deleted_at')
