"""create products table

Revision ID: 008_create_products_table
Revises: 007_role_shell_module_foundation
Create Date: 2026-07-24 06:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '008_create_products_table'
down_revision: Union[str, None] = '007_role_shell_module_base'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()
    
    if 'products' not in tables:
        op.create_table(
            'products',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('store_id', sa.String(length=36), nullable=False),
            sa.Column('name', sa.String(length=100), nullable=False),
            sa.Column('description', sa.Text(), nullable=True),
            sa.Column('price', sa.Integer(), nullable=False),
            sa.Column('sale_price', sa.Integer(), nullable=True),
            sa.Column('duration_minutes', sa.Integer(), nullable=True),
            sa.Column('category', sa.String(length=50), nullable=True),
            sa.Column('image_url', sa.String(length=500), nullable=True),
            sa.Column('display_order', sa.Integer(), nullable=False, server_default='0'),
            sa.Column('status', sa.String(length=50), nullable=False, server_default='ACTIVE'),
            sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_products_store_id'), 'products', ['store_id'], unique=False)

def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()
    if 'products' in tables:
        op.drop_index(op.f('ix_products_store_id'), table_name='products')
        op.drop_table('products')
