"""
Permanent idempotent seed script for NAMPO GOGO Staging Missions with full i18n support.
Target: mis_staging_001, mis_staging_002
"""
import sys
import os
from pathlib import Path
from sqlalchemy.orm import Session

# Ensure backend root in python path
backend_root = Path(__file__).resolve().parent.parent
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

from app import models
from app.database import SessionLocal

STAGING_MISSIONS_SEED = [
    {
        "id": "mis_staging_001",
        "title": "남포동 맛집 탐방 QR 인증",
        "title_en": "Nampo Gourmet Tour QR Verification",
        "title_ja": "南浦洞 グルメ探訪 QR認証",
        "title_zh": "南浦洞 美食探访 QR认证",
        "description": "남포동 대표 맛집을 방문하고 매장 내 비치된 QR 코드를 스캔하여 500P를 적립하세요!",
        "description_en": "Visit a featured Nampo-dong restaurant and scan the QR code to earn 500P!",
        "description_ja": "南浦洞の代表的なグルメ店を訪問し、店内のQRコードをスキャンして500Pを獲得しましょう！",
        "description_zh": "探访南浦洞特色美食店铺，扫描店内二维码即可获取500积分！",
        "points": 500,
        "auth_type": "qr",
        "status": "active",
        "data_scope": "REAL",
        "lifecycle_status": "ACTIVE",
        "store_id": "attraction-yongdusan-01",
        "image_url": "https://images.unsplash.com/photo-1541167760496-1628856ab772"
    },
    {
        "id": "mis_staging_002",
        "title": "용두산공원 부산타워 사진 인증",
        "title_en": "Yongdusan Park Busan Tower Photo Verification",
        "title_ja": "龍頭山公園 釜山タワー 写真認証",
        "title_zh": "龙头山公园 釜山塔 拍照认证",
        "description": "부산타워 앞에서 멋진 풍경 사진을 찍어 업로드하면 300P가 즉시 지급됩니다.",
        "description_en": "Take and upload a scenic photo in front of Busan Tower to receive 300P instantly.",
        "description_ja": "釜山タワー前で素敵な風景写真を撮影・アップロードすると、300P가 즉시 지급됩니다.",
        "description_zh": "在釜山塔前拍摄并上传精彩风景照片，即可立享300积分。",
        "points": 300,
        "auth_type": "photo",
        "status": "active",
        "data_scope": "REAL",
        "lifecycle_status": "ACTIVE",
        "store_id": "attraction-yongdusan-01",
        "image_url": "https://raw.githubusercontent.com/klounge82/nampo-gogo/main/assets/images/yongdusan_park.jpg"
    }
]

def seed_staging_missions(db: Session):
    """
    Upserts staging missions to ensure multilingual fields are preserved.
    """
    created_count = 0
    updated_count = 0

    for m_data in STAGING_MISSIONS_SEED:
        mission_id = m_data["id"]
        mission = db.query(models.Mission).filter(models.Mission.id == mission_id).first()

        if not mission:
            mission = models.Mission(**m_data)
            db.add(mission)
            created_count += 1
        else:
            for k, v in m_data.items():
                setattr(mission, k, v)
            updated_count += 1

    db.commit()
    print(f"[STAGING SEED] Missions synced. Created: {created_count}, Updated: {updated_count}")
    return {"created": created_count, "updated": updated_count}

if __name__ == "__main__":
    db = SessionLocal()
    try:
        res = seed_staging_missions(db)
        print("Result:", res)
    finally:
        db.close()
