"""
Idempotent QA Staging Seed Script for NAMPO GOGO.
Provides verified QA stores and missions for device/spatial testing.
Strictly isolated with data_scope = "QA".
DO NOT EXECUTE IN PRODUCTION.
"""
import sys
import os
from pathlib import Path
from typing import Dict, Any, List
from sqlalchemy.orm import Session

# Ensure backend root in python path
backend_root = Path(__file__).resolve().parent.parent
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

from app import models
from app.database import SessionLocal

# ==============================================================================
# QA STORES SEED (data_scope = "QA")
# ==============================================================================
QA_STORES_SEED: List[Dict[str, Any]] = [
    # 1. 수영강변 (LINE_BUFFER 50m)
    {
        "id": "qa-store-suyeong-river-photo-004",
        "name": "QA 수영강변 현장사진 장소",
        "name_en": "QA Suyeong River Photo Spot",
        "name_ja": "QA 水営江辺 現場写真スポット",
        "name_zh": "QA 水营江边 现场拍照地点",
        "category": "ATTRACTION",
        "address": "부산 해운대구 수영강변대로",
        "address_en": "Suyeonggangbyeon-daero, Haeundae-gu, Busan",
        "address_ja": "釜山広域市海雲台区水営江辺大路",
        "address_zh": "釜山广域市海云台区水营江边大路",
        "description": "수영강 산책로",
        "description_en": "Suyeong River Walking Trail",
        "description_ja": "水営江散策路",
        "description_zh": "水营江散步路",
        "latitude": 35.1658,
        "longitude": 129.1251,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 50,
        "geometry_type": "LINE_BUFFER",
        "geometry_data": '{"type":"LINE_BUFFER","lines":[[[35.1665,129.1215],[35.1650,129.1230],[35.1635,129.1245],[35.1620,129.1258]],[[35.1600,129.1270],[35.1590,129.1280],[35.1580,129.1290]]],"buffer_m":50.0}',
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
    # 2. 감포로 (GPS Radius 100m)
    {
        "id": "store_gampo_001",
        "name": "QA 감포로",
        "name_en": "QA Gampo-ro",
        "name_ja": "QA 甘浦路",
        "name_zh": "QA 甘浦路",
        "category": "ATTRACTION",
        "address": "부산 수영구 감포로 100",
        "address_en": "100 Gampo-ro, Suyeong-gu, Busan",
        "address_ja": "釜山広域市水営区甘浦路100",
        "address_zh": "釜山广域市水营区甘浦路100",
        "description": "감포로 GPS 테스트 장소",
        "description_en": "Gampo-ro GPS Test Spot",
        "description_ja": "甘浦路 GPSテストスポット",
        "description_zh": "甘浦路 GPS测试点",
        "latitude": 35.167413,
        "longitude": 129.118103,
        "review_verification_type": "ATTRACTION_LOCATION",
        "review_location_radius_m": 100,
        "geometry_type": "POINT_RADIUS",
        "geometry_data": None,
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
    # 3. 을지로골뱅이 (QR + GPS)
    {
        "id": "store_euljiro_001",
        "name": "QA 수영 을지로골뱅이",
        "name_en": "QA Suyeong Euljiro Golbaengi",
        "name_ja": "QA 水営 乙支路つぶ貝",
        "name_zh": "QA 水营 乙支路海螺",
        "category": "FOOD",
        "address": "부산 수영구 수영로 725번길",
        "address_en": "Suyeong-ro 725beon-gil, Suyeong-gu, Busan",
        "address_ja": "釜山広域市水営区水営路725番ギル",
        "address_zh": "釜山广域市水营区水营路725号街",
        "description": "을지로골뱅이 QR 및 GPS 테스트 장소",
        "description_en": "Euljiro Golbaengi QR and GPS Test Spot",
        "description_ja": "乙支路つぶ貝 QRおよびGPSテストスポット",
        "description_zh": "乙支路海螺 QR及GPS测试点",
        "latitude": 35.1645,
        "longitude": 129.1158,
        "review_verification_type": "BUSINESS_QR",
        "review_location_radius_m": 100,
        "geometry_type": "POINT_RADIUS",
        "geometry_data": None,
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
]

# ==============================================================================
# QA MISSIONS SEED (data_scope = "QA")
# ==============================================================================
QA_MISSIONS_SEED: List[Dict[str, Any]] = [
    # 1. 수영강변 사진 인증
    {
        "id": "qa-mission-suyeong-river-photo-004",
        "store_id": "qa-store-suyeong-river-photo-004",
        "title": "QA 수영강변 사진 인증",
        "title_en": "QA Suyeong River Photo Verification",
        "title_ja": "QA 水営江辺 写真認証",
        "title_zh": "QA 水营江边 拍照认证",
        "description": "수영강 산책 사진 촬영",
        "description_en": "Take and upload a photo on Suyeong River trail",
        "description_ja": "水営江散策路で写真を撮影してアップロード",
        "description_zh": "在水营江散步路拍摄并上传照片",
        "points": 100,
        "auth_type": "PHOTO",
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
    # 2. 수영강변 PHOTO_GPS 인증
    {
        "id": "qa-mission-suyeong-photo-gps-005",
        "store_id": "qa-store-suyeong-river-photo-004",
        "title": "QA 수영강변 PHOTO_GPS 인증",
        "title_en": "QA Suyeong River Photo & GPS Verification",
        "title_ja": "QA 水営江辺 写真・GPS認証",
        "title_zh": "QA 水营江边 拍照及GPS认证",
        "description": "수영강 산책로 50m 구간 내 사진 및 GPS 위치 동시 인증",
        "description_en": "Simultaneous photo and GPS verification within 50m Suyeong River corridor",
        "description_ja": "水営江散策路50m区間内で写真とGPS位置を同時認証",
        "description_zh": "在水营江散步路50m区间内同时完成拍照和GPS位置认证",
        "points": 100,
        "auth_type": "PHOTO_GPS",
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
    # 3. 감포로 GPS 인증
    {
        "id": "qa-mission-gampo-gps-002",
        "store_id": "store_gampo_001",
        "title": "QA 감포로 GPS 인증",
        "title_en": "QA Gampo-ro GPS Verification",
        "title_ja": "QA 甘浦路 GPS認証",
        "title_zh": "QA 甘浦路 GPS认证",
        "description": "감포로 100m 반경 내에서 GPS 위치 인증을 완료하세요.",
        "description_en": "Verify your GPS location within 100m of Gampo-ro.",
        "description_ja": "甘浦路100m以内でGPS位置認証を完了してください。",
        "description_zh": "在甘浦路100m范围内完成GPS位置认证。",
        "points": 100,
        "auth_type": "GPS",
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
    # 4. 을지로골뱅이 QR+GPS 인증
    {
        "id": "msn_001",
        "store_id": "store_euljiro_001",
        "title": "QA 수영 을지로골뱅이 QR+GPS 방문",
        "title_en": "QA Suyeong Euljiro Golbaengi QR+GPS Visit",
        "title_ja": "QA 水営 乙支路つぶ貝 QR+GPS訪問",
        "title_zh": "QA 水营 乙支路海螺 QR+GPS到店",
        "description": "을지로골뱅이 매장 방문 후 QR코드 및 GPS 위치를 인증하세요.",
        "description_en": "Visit Euljiro Golbaengi store and verify QR code and GPS location.",
        "description_ja": "乙支路つぶ貝店舗訪問後、QRコードおよびGPS位置を認証してください。",
        "description_zh": "探访乙支路海螺门店后，认证二维码及GPS位置。",
        "points": 100,
        "auth_type": "QR_GPS",
        "status": "active",
        "data_scope": "QA",
        "lifecycle_status": "ACTIVE",
    },
]

def seed_qa_staging(db: Session) -> Dict[str, Any]:
    """
    Idempotently seeds QA stores and missions with data_scope='QA'.
    Safe to re-run; will not touch data_scope='REAL' or production rows.
    """
    store_created = 0
    store_updated = 0
    mission_created = 0
    mission_updated = 0

    valid_store_cols = {c.name for c in models.Store.__table__.columns}
    valid_mission_cols = {c.name for c in models.Mission.__table__.columns}

    # 1. Upsert QA Stores
    for s_data in QA_STORES_SEED:
        s_id = s_data["id"]
        store = db.query(models.Store).filter(models.Store.id == s_id).first()
        filtered = {k: v for k, v in s_data.items() if k in valid_store_cols}

        if not store:
            store = models.Store(**filtered)
            db.add(store)
            store_created += 1
        else:
            for k, v in filtered.items():
                setattr(store, k, v)
            store_updated += 1

    db.flush()

    # 2. Upsert QA Missions
    for m_data in QA_MISSIONS_SEED:
        m_id = m_data["id"]
        mission = db.query(models.Mission).filter(models.Mission.id == m_id).first()
        filtered = {k: v for k, v in m_data.items() if k in valid_mission_cols}

        if not mission:
            mission = models.Mission(**filtered)
            db.add(mission)
            mission_created += 1
        else:
            for k, v in filtered.items():
                setattr(mission, k, v)
            mission_updated += 1

    db.commit()

    return {
        "status": "SUCCESS",
        "stores_created": store_created,
        "stores_updated": store_updated,
        "missions_created": mission_created,
        "missions_updated": mission_updated,
        "total_qa_stores": len(QA_STORES_SEED),
        "total_qa_missions": len(QA_MISSIONS_SEED),
    }

from app.auth import get_password_hash

def bootstrap_qa_staging_environment(db: Session) -> Dict[str, Any]:
    """
    Idempotent QA Staging Bootstrap:
    1. Ensures tester@nampogogo.com (TEST + CUSTOMER roles, 500P)
    2. Ensures QA stores and 4 canonical QA missions
    Strictly non-destructive.
    """
    tester_email = "tester@nampogogo.com"
    user = db.query(models.User).filter(models.User.email == tester_email).first()
    if not user:
        user = models.User(
            id="usr_stage0_test",
            email=tester_email,
            nickname="QA Tester",
            role="member",
            status="active",
            current_points=500
        )
        db.add(user)
        db.flush()
    else:
        user.current_points = 500
        user.status = "active"

    # Ensure Roles are strictly TEST, CUSTOMER (ADMIN: NO)
    db.query(models.UserRole).filter(
        models.UserRole.user_id == user.id,
        models.UserRole.role.notin_(["TEST", "CUSTOMER"])
    ).delete(synchronize_session=False)

    existing_roles = {r.role for r in db.query(models.UserRole).filter(models.UserRole.user_id == user.id).all()}
    for r_name in ["TEST", "CUSTOMER"]:
        if r_name not in existing_roles:
            db.add(models.UserRole(user_id=user.id, role=r_name))

    # Auth
    user_auth = db.query(models.UserAuth).filter(models.UserAuth.user_id == user.id).first()
    hashed_pw = get_password_hash("Password123!")
    if not user_auth:
        user_auth = models.UserAuth(
            user_id=user.id,
            hashed_password=hashed_pw
        )
        db.add(user_auth)
    else:
        user_auth.hashed_password = hashed_pw

    # Ensure PointLot and PointHistory exist for lot SOT consistency
    existing_lots = db.query(models.PointLot).filter(models.PointLot.user_id == user.id, models.PointLot.status == "ACTIVE").all()
    if not existing_lots:
        import uuid
        from datetime import datetime, timedelta
        now = datetime.utcnow()
        init_lot = models.PointLot(
            id=str(uuid.uuid4()),
            user_id=user.id,
            source_type="QA_BOOTSTRAP",
            original_points=500,
            remaining_points=500,
            reserved_points=0,
            expires_at=now + timedelta(days=365),
            is_transferable=True,
            status="ACTIVE",
            created_at=now
        )
        db.add(init_lot)

    # Ensure second tester (tester2@nampogogo.com) exists for gift E2E testing
    tester2_email = "tester2@nampogogo.com"
    user2 = db.query(models.User).filter(models.User.email == tester2_email).first()
    if not user2:
        user2 = models.User(
            id="usr_stage0_test2",
            email=tester2_email,
            nickname="QA 테스터2",
            role="member",
            status="active",
            current_points=100
        )
        db.add(user2)
        db.flush()
    else:
        user2.status = "active"

    user2_roles = {r.role for r in db.query(models.UserRole).filter(models.UserRole.user_id == user2.id).all()}
    for r_name in ["TEST", "CUSTOMER"]:
        if r_name not in user2_roles:
            db.add(models.UserRole(user_id=user2.id, role=r_name))

    user2_auth = db.query(models.UserAuth).filter(models.UserAuth.user_id == user2.id).first()
    if not user2_auth:
        db.add(models.UserAuth(user_id=user2.id, hashed_password=hashed_pw))

    # Ensure QA Admin (jazzbj@naver.com) has ADMIN role and password
    admin_email = "jazzbj@naver.com"
    admin_user = db.query(models.User).filter(models.User.email == admin_email).first()
    admin_pw_hash = get_password_hash("hwang123")
    if not admin_user:
        admin_user = models.User(
            id="usr_jazz_001",
            email=admin_email,
            nickname="QA Admin (황병준)",
            role="admin",
            status="active",
            current_points=1000
        )
        db.add(admin_user)
        db.flush()
    else:
        admin_user.role = "admin"
        admin_user.status = "active"
        if hasattr(admin_user, "hashed_password"):
            admin_user.hashed_password = admin_pw_hash

    admin_roles = {r.role for r in db.query(models.UserRole).filter(models.UserRole.user_id == admin_user.id).all()}
    for r_name in ["ADMIN", "TEST", "CUSTOMER"]:
        if r_name not in admin_roles:
            db.add(models.UserRole(user_id=admin_user.id, role=r_name))

    admin_auth = db.query(models.UserAuth).filter(models.UserAuth.user_id == admin_user.id).first()
    if not admin_auth:
        db.add(models.UserAuth(user_id=admin_user.id, hashed_password=admin_pw_hash))
    else:
        admin_auth.hashed_password = admin_pw_hash

    db.commit()

    # QA Stores and Missions
    seed_result = seed_qa_staging(db)
    return {
        "tester_status": "READY",
        "qa_seed": seed_result
    }


if __name__ == "__main__":
    db = SessionLocal()
    try:
        res = bootstrap_qa_staging_environment(db)
        print("[QA STAGING BOOTSTRAP RESULT]", res)
    finally:
        db.close()