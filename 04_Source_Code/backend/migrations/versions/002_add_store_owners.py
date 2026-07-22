"""add store owners table

Revision ID: 002_add_store_owners
Revises: 001_initial_schema
Create Date: 2026-07-22 13:40:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '002_add_store_owners'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.create_table(
        'store_owners',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('store_id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='active'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('store_id', 'user_id', name='uq_store_owner')
    )
    op.create_index('ix_store_owners_store_id', 'store_owners', ['store_id'], unique=False)
    op.create_index('ix_store_owners_user_id', 'store_owners', ['user_id'], unique=False)

def downgrade() -> None:
    op.drop_index('ix_store_owners_user_id', table_name='store_owners')
    op.drop_index('ix_store_owners_store_id', table_name='store_owners')
    op.drop_table('store_owners')
