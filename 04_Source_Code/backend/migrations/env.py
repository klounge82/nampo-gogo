import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
# from myapp import mymodel
# target_metadata = mymodel.Base.metadata
from app.database import Base
# Import models to ensure they are registered on the Base.metadata
from app import models

target_metadata = Base.metadata

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.

def get_url():
    app_env = os.getenv("APP_ENV", "development")
    url = os.getenv("DATABASE_URL")
    
    if app_env == "production":
        if not url or "placeholder" in url or "localhost" in url or "127.0.0.1" in url:
            raise RuntimeError("PRODUCTION_MIGRATION_BLOCKED: A valid DATABASE_URL must be provided via env for Production Migration!")
        return url
    
    return url if url else config.get_main_option("sqlalchemy.url")

def print_target_environment(url: str):
    app_env = os.getenv("APP_ENV", "development")
    import re
    masked_url = re.sub(r":([^/@:]+)@", r":****@", url)
    print(f"\n==================================================")
    print(f"[{app_env.upper()} MIGRATION] Alembic Target: {masked_url}")
    print(f"==================================================\n")


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here will emit the relation
    string to the script output.

    """
    url = get_url()
    print_target_environment(url)
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    url = get_url()
    print_target_environment(url)
    configuration = config.get_section(config.config_ini_section) or {}
    configuration["sqlalchemy.url"] = url
    
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
