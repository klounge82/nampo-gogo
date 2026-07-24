"""create user_roles, business_applications, business_memberships tables and backfill CUSTOMER role

Revision ID: 007_role_shell_module_foundation
Revises: 006_user_recommendations_guest_id
Create Date: 2026-07-23 18:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '007_role_shell_module_base'
down_revision: Union[str, None] = '006_user_recommendations_guest'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. Create user_roles table
    op.create_table(
        'user_roles',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('role', sa.String(length=50), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'role', name='uq_user_role')
    )
    op.create_index(op.f('ix_user_roles_user_id'), 'user_roles', ['user_id'], unique=False)

    # 2. Create business_applications table
    op.create_table(
        'business_applications',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('business_name', sa.String(length=255), nullable=False),
        sa.Column('business_registration_number', sa.String(length=100), nullable=False),
        sa.Column('representative_name', sa.String(length=100), nullable=False),
        sa.Column('phone', sa.String(length=50), nullable=False),
        sa.Column('requested_store_id', sa.String(length=36), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='PENDING'),
        sa.Column('rejection_reason', sa.Text(), nullable=True),
        sa.Column('reviewed_by', sa.String(length=36), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['requested_store_id'], ['stores.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['reviewed_by'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_business_applications_user_id'), 'business_applications', ['user_id'], unique=False)

    # 3. Create business_memberships table
    op.create_table(
        'business_memberships',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('store_id', sa.String(length=36), nullable=False),
        sa.Column('membership_role', sa.String(length=50), nullable=False, server_default='OWNER'),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='ACTIVE'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['store_id'], ['stores.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'store_id', name='uq_user_store_membership')
    )
    op.create_index(op.f('ix_business_memberships_store_id'), 'business_memberships', ['store_id'], unique=False)
    op.create_index(op.f('ix_business_memberships_user_id'), 'business_memberships', ['user_id'], unique=False)

    # 4. Data Backfill: Ensure all existing users get CUSTOMER role, and existing admins/owners get corresponding roles
    bind = op.get_bind()
    users = bind.execute(sa.text("SELECT id, role FROM users")).fetchall()
    
    import uuid
    for u in users:
        u_id = u[0]
        u_role = u[1] if u[1] else 'member'
        
        # Add CUSTOMER role
        bind.execute(
            sa.text("INSERT INTO user_roles (id, user_id, role, created_at) VALUES (:id, :user_id, 'CUSTOMER', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING"),
            {"id": str(uuid.uuid4()), "user_id": u_id}
        )
        
        # If legacy role was admin
        if u_role == 'admin':
            bind.execute(
                sa.text("INSERT INTO user_roles (id, user_id, role, created_at) VALUES (:id, :user_id, 'ADMIN', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING"),
                {"id": str(uuid.uuid4()), "user_id": u_id}
            )

        # If legacy role was owner
        if u_role == 'owner':
            bind.execute(
                sa.text("INSERT INTO user_roles (id, user_id, role, created_at) VALUES (:id, :user_id, 'BUSINESS', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING"),
                {"id": str(uuid.uuid4()), "user_id": u_id}
            )

    # Backfill business_memberships from store_owners table if exists
    try:
        owners = bind.execute(sa.text("SELECT user_id, store_id FROM store_owners")).fetchall()
        for o in owners:
            bind.execute(
                sa.text("INSERT INTO user_roles (id, user_id, role, created_at) VALUES (:id, :user_id, 'BUSINESS', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING"),
                {"id": str(uuid.uuid4()), "user_id": o[0]}
            )
            bind.execute(
                sa.text("INSERT INTO business_memberships (id, user_id, store_id, membership_role, status, created_at, updated_at) VALUES (:id, :user_id, :store_id, 'OWNER', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING"),
                {"id": str(uuid.uuid4()), "user_id": o[0], "store_id": o[1]}
            )
    except Exception:
        pass

def downgrade() -> None:
    op.drop_table('business_memberships')
    op.drop_table('business_applications')
    op.drop_table('user_roles')
