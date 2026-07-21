import os
import sys
import logging
from typing import Dict, Any, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure app module can be imported
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import models

logger = logging.getLogger("store_seed")

REQUIRED_FIELDS = ["name", "category", "address", "description"]

# Confirmed K-Lounge Initial Seed Data
K_LOUNGE_SEED_DATA: Dict[str, Any] = {
    "name": "K-Lounge",
    "category": "체험",
    "rating": 0.0,
    "address": "부산광역시 중구 구덕로 50-1 2층",
    "description": "부산 남포동 BIFF광장, 자갈치시장, 국제시장 인근에 위치한 마사지·웰니스 매장입니다. 발 마사지, 건식 전신 마사지, 아로마 마사지와 뷰티 테라피를 제공하며 외국인 관광객을 위한 영어·중국어·일본어 안내가 가능합니다. 매일 11:00~23:00 예약제로 운영합니다.",
    "phone_number": "051-243-8880",
    "operating_hours": "11:00 - 23:00 (매일, 예약제)",
    "status": "영업중",
    "name_en": "K-Lounge",
    "image_url": None,
    "latitude": None,
    "longitude": None,
    "homepage_url": None,
    "name_ja": None,
    "name_zh": None,
    "description_en": None,
    "description_ja": None,
    "description_zh": None,
}

def seed_initial_store(db: Session, store_data: Optional[Dict[str, Any]] = None) -> Tuple[str, Optional[models.Store], str]:
    """
    Idempotent initial store seed helper function.
    Defaults to K_LOUNGE_SEED_DATA if store_data is not passed.
    
    Returns:
        Tuple[status, store_instance, message]
        status can be: "CREATED", "ALREADY_EXISTS", "INPUT_REQUIRED", "FAILED"
    """
    target_data = store_data if store_data is not None else K_LOUNGE_SEED_DATA

    if not target_data:
        return "INPUT_REQUIRED", None, "매장 데이터가 제공되지 않았습니다."

    missing = [field for field in REQUIRED_FIELDS if not target_data.get(field)]
    if missing:
        msg = f"필수 필드가 누락되었습니다: {', '.join(missing)}"
        logger.warning(msg)
        return "INPUT_REQUIRED", None, msg

    try:
        # Check idempotency by matching exact name and address
        name = target_data.get("name")
        address = target_data.get("address")
        phone_number = target_data.get("phone_number")

        query = db.query(models.Store).filter(models.Store.name == name)
        if address:
            query = query.filter(models.Store.address == address)
            
        existing_store = query.first()

        if not existing_store and phone_number:
            existing_store = db.query(models.Store).filter(models.Store.phone_number == phone_number).first()

        if existing_store:
            msg = f"매장 '{name}'이(가) 이미 존재합니다 (ID: {existing_store.id}). 중복 생성을 방지하고 기존 매장을 유지합니다."
            logger.info(msg)
            return "ALREADY_EXISTS", existing_store, msg

        # Construct Store instance safely using valid attributes (No fallback mock defaults)
        store_kwargs = {
            "name": target_data.get("name"),
            "category": target_data.get("category"),
            "rating": target_data.get("rating", 0.0),
            "address": target_data.get("address"),
            "description": target_data.get("description"),
            "image_url": target_data.get("image_url"),
            "latitude": target_data.get("latitude"),
            "longitude": target_data.get("longitude"),
            "name_en": target_data.get("name_en"),
            "name_ja": target_data.get("name_ja"),
            "name_zh": target_data.get("name_zh"),
            "description_en": target_data.get("description_en"),
            "description_ja": target_data.get("description_ja"),
            "description_zh": target_data.get("description_zh"),
            "status": target_data.get("status", "영업중"),
            "operating_hours": target_data.get("operating_hours"),
            "phone_number": target_data.get("phone_number"),
            "homepage_url": target_data.get("homepage_url")
        }

        new_store = models.Store(**store_kwargs)
        db.add(new_store)
        db.commit()
        db.refresh(new_store)

        msg = f"매장 '{new_store.name}'이(가) 성공적으로 생성되었습니다 (ID: {new_store.id})."
        logger.info(msg)
        return "CREATED", new_store, msg

    except Exception as e:
        db.rollback()
        msg = f"Seed 실행 중 오류 발생: {str(e)}"
        logger.error(msg)
        return "FAILED", None, msg

def main():
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("RESULT: INPUT_REQUIRED - DATABASE_URL 환경변수가 설정되지 않았습니다.")
        sys.exit(1)

    # Use environment variables if explicitly provided, otherwise default to confirmed K_LOUNGE_SEED_DATA
    store_name = os.environ.get("STORE_SEED_NAME")
    if store_name:
        k_lounge_data = {
            "name": store_name,
            "category": os.environ.get("STORE_SEED_CATEGORY", K_LOUNGE_SEED_DATA["category"]),
            "address": os.environ.get("STORE_SEED_ADDRESS", K_LOUNGE_SEED_DATA["address"]),
            "description": os.environ.get("STORE_SEED_DESCRIPTION", K_LOUNGE_SEED_DATA["description"]),
            "rating": float(os.environ.get("STORE_SEED_RATING", "0.0")),
            "image_url": os.environ.get("STORE_SEED_IMAGE_URL"),
            "latitude": float(os.environ.get("STORE_SEED_LATITUDE")) if os.environ.get("STORE_SEED_LATITUDE") else None,
            "longitude": float(os.environ.get("STORE_SEED_LONGITUDE")) if os.environ.get("STORE_SEED_LONGITUDE") else None,
            "phone_number": os.environ.get("STORE_SEED_PHONE", K_LOUNGE_SEED_DATA["phone_number"]),
            "operating_hours": os.environ.get("STORE_SEED_OPERATING_HOURS", K_LOUNGE_SEED_DATA["operating_hours"]),
            "homepage_url": os.environ.get("STORE_SEED_HOMEPAGE"),
            "name_en": os.environ.get("STORE_SEED_NAME_EN", K_LOUNGE_SEED_DATA["name_en"]),
            "status": os.environ.get("STORE_SEED_STATUS", K_LOUNGE_SEED_DATA["status"])
        }
    else:
        k_lounge_data = K_LOUNGE_SEED_DATA

    engine = create_engine(database_url)
    SessionMaker = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionMaker()

    try:
        status, store, message = seed_initial_store(db, k_lounge_data)
        print(f"RESULT: {status} - {message}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
