import os
import sys
import logging
import hashlib
from datetime import datetime, timedelta
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import text

# Ensure app module can be imported
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import models, database

logger = logging.getLogger("seed_beta_places")
logging.basicConfig(level=logging.INFO)

# 5 Attractions + 4 Stores Definition
BETA_PLACES_SEED: List[Dict[str, Any]] = [
    # --- 5 관광지 (Attractions) ---
    {
        "id": "attraction-yongdusan-01",
        "name": "용두산공원",
        "category": "관광지",
        "address": "부산 중구 용두산길 37-55",
        "description": "부산의 역사와 탁 트인 조망을 자랑하는 대표 도심 공원 및 부산타워가 위치한 명소입니다.",
        "latitude": 35.1008,
        "longitude": 129.0326,
        "is_attraction": True,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 300,
        "manual_visit_allowed": True,
        "qr_token": "QR_ATTRACTION_YONGDUSAN_01",
        "products": []
    },
    {
        "id": "attraction-jagalchi-01",
        "name": "자갈치시장",
        "category": "관광지",
        "address": "부산 중구 자갈치해안로 52",
        "description": "한국을 대표하는 수산물 시장으로 신선한 회와 수산물 체험이 가능한 남포동 대표 관광지입니다.",
        "latitude": 35.0967,
        "longitude": 129.0305,
        "is_attraction": True,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 300,
        "manual_visit_allowed": True,
        "qr_token": "QR_ATTRACTION_JAGALCHI_01",
        "products": []
    },
    {
        "id": "attraction-gukje-01",
        "name": "국제시장",
        "category": "관광지",
        "address": "부산 중구 신창동4가 국제시장",
        "description": "영화 국제시장의 배경이자 부산의 역사와 전통 시장 문화가 살아 숨 쉬는 쇼핑 명소입니다.",
        "latitude": 35.1012,
        "longitude": 129.0279,
        "is_attraction": True,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 300,
        "manual_visit_allowed": True,
        "qr_token": "QR_ATTRACTION_GUKJE_01",
        "products": []
    },
    {
        "id": "attraction-biff-01",
        "name": "BIFF광장",
        "category": "관광지",
        "address": "부산 중구 구덕로 58-1",
        "description": "부산국제영화제의 역사가 담긴 명예의 거리와 씨앗호떡 등 대표 먹거리가 가득한 문화 광장입니다.",
        "latitude": 35.0987,
        "longitude": 129.0289,
        "is_attraction": True,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 300,
        "manual_visit_allowed": True,
        "qr_token": "QR_ATTRACTION_BIFF_01",
        "products": []
    },
    {
        "id": "attraction-gwangbok-01",
        "name": "광복로",
        "category": "관광지",
        "address": "부산 중구 광복로 74",
        "description": "패션, 쇼핑, 문화 이벤트가 연중 펼쳐지는 남포동 중심 가로변 쇼핑 문화 거리입니다.",
        "latitude": 35.0995,
        "longitude": 129.0310,
        "is_attraction": True,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 300,
        "manual_visit_allowed": True,
        "qr_token": "QR_ATTRACTION_GWANGBOK_01",
        "products": []
    },

    # --- 4 사업장 (Stores) ---
    {
        "id": "store-nampo-toast-01",
        "name": "남포토스트",
        "category": "맛집/카페",
        "address": "부산 중구 광복로 55-1",
        "description": "바삭하고 고소한 수제 토스트와 시원한 갓 짠 과일 음료를 즐길 수 있는 남포동 시그니처 토스트 전문점.",
        "latitude": 35.0991,
        "longitude": 129.0302,
        "is_attraction": False,
        "tier": "VERIFIED_BETA",
        "is_test_data": False,
        "review_verification_type": "BUSINESS_QR",
        "qr_token": "QR_STORE_NAMPO_TOAST_01",
        "products": [
            {"name": "스페셜 씨앗 토스트", "price": 4500, "description": "각종 견과류와 특제 소스로 맛을 낸 인기 토스트"},
            {"name": "치즈 베이컨 토스트", "price": 5000, "description": "체다 치즈와 듬뿍 넣은 훈제 베이컨 토스트"},
            {"name": "생과일 에이드", "price": 4000, "description": "생과일을 직접 짠 시원한 계절 에이드"}
        ]
    },
    {
        "id": "store-nampo-gukbap-01",
        "name": "남포돼지국밥",
        "category": "맛집",
        "address": "부산 중구 자갈치로 30",
        "description": "30년 전통의 진한 사골 육수와 부드러운 수육이 듬뿍 들어간 남포동 대표 돼지국밥 전문점.",
        "latitude": 35.0975,
        "longitude": 129.0298,
        "is_attraction": False,
        "tier": "VERIFIED_BETA",
        "is_test_data": False,
        "review_verification_type": "BUSINESS_QR",
        "qr_token": "QR_STORE_NAMPO_GUKBAP_01",
        "products": [
            {"name": "진국 돼지국밥", "price": 9500, "description": "깊고 진한 사골 육수에 수육을 더한 대표 국밥"},
            {"name": "얼큰 순대국밥", "price": 10000, "description": "수제 순대와 얼큰한 다대기가 어우러진 국밥"},
            {"name": "모둠 수육 (소)", "price": 25000, "description": "국내산 항정살과 항정 수육 한 접시"}
        ]
    },
    {
        "id": "store-nampo-bokguk-01",
        "name": "남포복국",
        "category": "맛집",
        "address": "부산 중구 구덕로 34",
        "description": "시원하고 아삭한 콩나물과 담백한 참복이 어우러져 숙취 해소와 보양에 으뜸인 남포동 복국 전문점.",
        "latitude": 35.0980,
        "longitude": 129.0282,
        "is_attraction": False,
        "tier": "TEST",
        "is_test_data": True,
        "review_verification_type": "BUSINESS_QR",
        "qr_token": "QR_STORE_NAMPO_BOKGUK_01",
        "products": [
            {"name": "은복지리", "price": 13000, "description": "담백하고 개운한 맑은 복국 지리탕"},
            {"name": "밀복지리", "price": 18000, "description": "쫄깃한 식감의 고급 밀복 지리탕"},
            {"name": "복튀김", "price": 20000, "description": "바삭하게 튀겨낸 고소한 복어 튀김"}
        ]
    },
    {
        "id": "store-k-lounge-01",
        "name": "K-Lounge",
        "category": "체험",
        "address": "부산광역시 중구 구덕로 50-1 2층",
        "description": "부산 남포동 BIFF광장, 자갈치시장, 국제시장 인근에 위치한 마사지·웰니스 매장입니다.",
        "latitude": 35.0992,
        "longitude": 129.0295,
        "is_attraction": False,
        "tier": "OFFICIAL",
        "is_test_data": False,
        "review_verification_type": "BUSINESS_QR",
        "qr_token": "QR_STORE_KLOUNGE_01",
        "products": [
            {"name": "아로마 발 케어 (45분)", "price": 45000, "description": "여행의 피로를 풀어주는 하반신 릴렉싱 발 케어"},
            {"name": "전신 릴렉싱 마사지 (60분)", "price": 65000, "description": "뭉친 근육을 부드럽게 풀어주는 건식 전신 관리"},
            {"name": "프리미엄 웰니스 스파 (90분)", "price": 95000, "description": "아로마 오일 테라피와 프리미엄 스파 케어"}
        ]
    }
]

def ensure_columns_exist(db: Session):
    """Dynamically add missing columns to stores table if not present"""
    columns_to_add = [
        ("is_attraction", "BOOLEAN DEFAULT FALSE"),
        ("tier", "VARCHAR(50) DEFAULT 'OFFICIAL'"),
        ("is_test_data", "BOOLEAN DEFAULT FALSE"),
        ("entrance_image_url", "VARCHAR(500)"),
        ("interior_images_json", "TEXT"),
        ("product_images_json", "TEXT")
    ]
    for col_name, col_type in columns_to_add:
        try:
            db.execute(text(f"ALTER TABLE stores ADD COLUMN {col_name} {col_type};"))
            db.commit()
            logger.info(f"Added column {col_name} to stores table.")
        except Exception:
            db.rollback()

def seed_beta_places(db: Session) -> Dict[str, Any]:
    """
    Idempotent seed function for 5 attractions + 4 stores.
    Creates or updates stores, products, and QR credentials.
    """
    ensure_columns_exist(db)

    created_count = 0
    updated_count = 0
    qr_credentials_count = 0
    products_count = 0

    for item in BETA_PLACES_SEED:
        name = item["name"]
        store = db.query(models.Store).filter(
            (models.Store.name == name) | (models.Store.id == item["id"])
        ).first()

        if not store:
            store = models.Store(
                id=item["id"],
                name=item["name"],
                category=item["category"],
                rating=4.8 if item["tier"] == "OFFICIAL" else 4.5,
                address=item["address"],
                description=item["description"],
                latitude=item["latitude"],
                longitude=item["longitude"],
                is_attraction=item["is_attraction"],
                tier=item["tier"],
                is_test_data=item["is_test_data"],
                review_verification_type=item["review_verification_type"],
                review_location_radius_m=item.get("review_location_radius_m", 300),
                manual_visit_allowed=item.get("manual_visit_allowed", True),
                status="영업중"
            )
            db.add(store)
            db.flush()
            created_count += 1
        else:
            store.is_attraction = item["is_attraction"]
            store.tier = item["tier"]
            store.is_test_data = item["is_test_data"]
            store.review_verification_type = item["review_verification_type"]
            store.latitude = item["latitude"]
            store.longitude = item["longitude"]
            updated_count += 1

        # Seed QR Credential
        token_str = item["qr_token"]
        token_hash = hashlib.sha256(token_str.encode('utf-8')).hexdigest()

        existing_qr = db.query(models.StoreQrCredential).filter(
            models.StoreQrCredential.store_id == store.id,
            models.StoreQrCredential.status == "ACTIVE"
        ).first()

        if not existing_qr:
            qr_cred = models.StoreQrCredential(
                store_id=store.id,
                token_hash=token_hash,
                expires_at=datetime.utcnow() + timedelta(days=3650),
                status="ACTIVE",
                purpose="REVIEW_VISIT"
            )
            db.add(qr_cred)
            qr_credentials_count += 1

        # Seed Products for stores
        for p in item.get("products", []):
            existing_prod = db.query(models.Product).filter(
                models.Product.store_id == store.id,
                models.Product.name == p["name"]
            ).first()

            if not existing_prod:
                prod = models.Product(
                    store_id=store.id,
                    name=p["name"],
                    price=p["price"],
                    description=p["description"],
                    status="ACTIVE"
                )
                db.add(prod)
                products_count += 1

    db.commit()

    logger.info(
        f"[BETA SEED COMPLETE] Created: {created_count}, Updated: {updated_count}, "
        f"QR Creds: {qr_credentials_count}, Products: {products_count}"
    )

    return {
        "created_count": created_count,
        "updated_count": updated_count,
        "qr_credentials_count": qr_credentials_count,
        "products_count": products_count,
        "total_places": len(BETA_PLACES_SEED)
    }

if __name__ == "__main__":
    db = database.SessionLocal()
    try:
        res = seed_beta_places(db)
        print("SEED SUCCESS:", res)
    finally:
        db.close()
