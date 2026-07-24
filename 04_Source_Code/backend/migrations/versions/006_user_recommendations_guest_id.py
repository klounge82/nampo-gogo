"""add guest_id column to user_recommendations table for guest course account linking

Revision ID: 006_user_recommendations_guest_id
Revises: 005_review_deleted_at
Create Date: 2026-07-23 17:10:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '006_user_recommendations_guest'
down_revision: Union[str, None] = '005_review_deleted_at'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.add_column('user_recommendations', sa.Column('guest_id', sa.String(length=255), nullable=True))

def downgrade() -> None:
    op.drop_column('user_recommendations', 'guest_id')
