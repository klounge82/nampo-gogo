import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Handle dynamic password substitution for DATABASE_URL
db_url = os.getenv("DATABASE_URL", "postgresql+psycopg://nampo_admin:Hwang123!!@db:5432/nampo_gogo")
if "CHANGE_ME" in db_url:
    password = os.getenv("POSTGRES_PASSWORD", "Hwang123!!")
    db_url = db_url.replace("CHANGE_ME", password)

# For local host development if needed (fallback if not in container)
# db_url = db_url.replace("@db:5432", "@localhost:15432") # Not applied by default since we run in docker

engine = create_engine(
    db_url,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
