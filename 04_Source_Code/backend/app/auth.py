import os
import bcrypt
from datetime import datetime, timedelta
from jose import jwt, JWTError

# Secret & Algorithm configs
_raw_secret = os.getenv("JWT_SECRET")
_app_env = os.getenv("APP_ENV", "development")

if _app_env == "production":
    if not _raw_secret or _raw_secret in ["CHANGE_ME_TO_A_LONG_RANDOM_VALUE", "nampo_gogo_default_secret_key_2026_07_14"]:
        raise RuntimeError("JWT_SECRET_MISSING: Secure JWT_SECRET must be configured in Production environment variable!")
    JWT_SECRET = _raw_secret
else:
    JWT_SECRET = _raw_secret if _raw_secret else "nampo_gogo_development_fallback_secret_key"


ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain_password.encode('utf-8'), 
            hashed_password.encode('utf-8')
        )
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)

def create_refresh_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return {}

ROLE_CAPABILITIES = {
    "CUSTOMER": {
        "place.read",
        "favorite.manage",
        "course.manage",
        "review.manage",
        "reservation.create",
    },
    "BUSINESS": {
        "business.dashboard.read",
        "store.own.read",
        "store.own.update",
        "product.own.manage",
        "review.own.read",
        "reservation.own.manage",
        "recommendation.own.read",
    },
    "ADMIN": {
        "business.approve",
        "user.manage",
        "store.manage_all",
        "review.moderate",
        "system.audit",
    }
}
