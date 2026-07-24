import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Handle dynamic password substitution for DATABASE_URL
_db_url_env = os.getenv("DATABASE_URL")
_test_mode = os.getenv("TEST_MODE", "false").lower() == "true"

if _db_url_env:
    db_url = _db_url_env
else:
    db_url = "sqlite:///./nampo_gogo_test.db"

if "CHANGE_ME" in db_url:
    password = os.getenv("POSTGRES_PASSWORD", "Hwang123!!")
    db_url = db_url.replace("CHANGE_ME", password)

connect_args = {"check_same_thread": False} if "sqlite" in db_url else {}

engine = create_engine(
    db_url,
    pool_pre_ping=True,
    connect_args=connect_args,
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
