import unittest
from datetime import datetime, timedelta
import uuid
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app, get_db
from app.database import Base
from app import models, auth

# Isolated in-memory SQLite database for Yongdusan Park tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_yongdusan_attraction.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


class TestYongdusanAttractionVerification(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        app.dependency_overrides[get_db] = override_get_db

    @classmethod
    def tearDownClass(cls):
        app.dependency_overrides.clear()
        Base.metadata.drop_all(bind=engine)

    def setUp(self):
        self.db = TestingSessionLocal()
        self.client = TestClient(app)

        # Clear tables
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.StoreQrCredential).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create Test Users
        self.user1 = models.User(
            id="usr_yd_001",
            email="yongdusan1@test.com",
            nickname="부산여행자1",
            role="CUSTOMER",
            status="active"
        )
        self.user2 = models.User(
            id="usr_yd_002",
            email="yongdusan2@test.com",
            nickname="부산여행자2",
            role="CUSTOMER",
            status="active"
        )
        self.db.add_all([self.user1, self.user2])
        self.db.commit()

        # 1. Yongdusan Park Attraction Store
        self.yongdusan_store = models.Store(
            id="yongdusan-park-busan-tower-001",
            name="용두산공원 부산타워",
            name_en="Yongdusan Park Busan Tower",
            category="볼거리",
            rating=4.6,
            address="부산 중구 용두산길 37-55",
            description="남포동 한가운데 우뚝 솟은 부산의 상징입니다.",
            latitude=35.1008,
            longitude=129.0326,
            status="영업중",
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )

        # 2. K-Lounge Business Store (BUSINESS_QR)
        self.klounge_store = models.Store(
            id="31b96920-2eb3-4f93-ab51-546fd8d933d1",
            name="K-Lounge",
            category="체험",
            rating=4.8,
            address="부산 중구 광복로 1",
            description="공개 K-Lounge 사업장 매장입니다.",
            latitude=None,
            longitude=None,
            status="영업중",
            review_verification_type="BUSINESS_QR"
        )

        self.db.add_all([self.yongdusan_store, self.klounge_store])
        self.db.commit()

        self.token1 = auth.create_access_token({"sub": self.user1.id, "role": "CUSTOMER"})
        self.token2 = auth.create_access_token({"sub": self.user2.id, "role": "CUSTOMER"})

    def tearDown(self):
        self.db.close()

    # 1. Yongdusan Park Searchable
    def test_01_yongdusan_searchable(self):
        res = self.client.get("/search", params={"q": "용두산"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        items = data.get("items", [])
        ids = [i["id"] for i in items]
        self.assertIn(self.yongdusan_store.id, ids)








    # 2. ATTRACTION_LOCATION Verification Options
    def test_02_verification_options(self):
        res = self.client.get(f"/stores/{self.yongdusan_store.id}/verification-options")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertFalse(data["can_use_qr"])
        self.assertTrue(data["can_use_gps"])
        self.assertTrue(data["can_use_visit_date"])
        self.assertEqual(data["review_verification_type"], "ATTRACTION_LOCATION")

    # 3. QR Verification Blocked
    def test_03_qr_verification_blocked(self):
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-qr",
            json={"qr_token": "ANY_QR_TOKEN", "user_id": self.user1.id}
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("관광지", res.json()["detail"])

    # 4. GPS Verification Within Radius Succeeds
    def test_04_gps_verification_inside_radius_success(self):
        # 50m away from center (35.1008, 129.0326)
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-location",
            json={
                "latitude": 35.1009,
                "longitude": 129.0327,
                "accuracy": 20.0,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["verification_method"], "ATTRACTION_GPS")
        self.assertEqual(data["user_id"], self.user1.id)

    # 5. GPS Verification Outside Radius Blocked
    def test_05_gps_verification_outside_radius_blocked(self):
        # 2km away from Yongdusan Park
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-location",
            json={
                "latitude": 35.1200,
                "longitude": 129.0500,
                "accuracy": 15.0,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.json()["detail"], "현재 위치에서는 이 관광지 방문을 확인할 수 없습니다.")

    # 6. Low Location Accuracy (>500m) Blocked
    def test_06_low_accuracy_blocked(self):
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-location",
            json={
                "latitude": 35.1008,
                "longitude": 129.0326,
                "accuracy": 600.0,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("정확도", res.json()["detail"])

    # 7. Visit Date Verification Success
    def test_07_visit_date_verification_success(self):
        recent_date = datetime.utcnow() - timedelta(days=5)
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-manual-visit",
            json={
                "visit_date": recent_date.isoformat(),
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["verification_method"], "ATTRACTION_DATE")
        self.assertEqual(data["user_id"], self.user1.id)

    # 8. Future Visit Date Blocked
    def test_08_future_visit_date_blocked(self):
        future_date = datetime.utcnow() + timedelta(days=2)
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-manual-visit",
            json={
                "visit_date": future_date.isoformat(),
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("미래", res.json()["detail"])

    # 9. Visit Date > 90 Days Ago Blocked
    def test_09_visit_date_older_than_90_days_blocked(self):
        old_date = datetime.utcnow() - timedelta(days=95)
        res = self.client.post(
            f"/stores/{self.yongdusan_store.id}/verify-manual-visit",
            json={
                "visit_date": old_date.isoformat(),
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("90일", res.json()["detail"])

    # 10. Existing BUSINESS_QR Workflow Preserved
    def test_10_business_qr_preserved(self):
        v_res = self.client.post(
            f"/stores/{self.klounge_store.id}/verify-qr",
            json={"qr_token": f"QR_SECRET_{self.klounge_store.id}", "user_id": self.user1.id}
        )
        self.assertEqual(v_res.status_code, 201)
        self.assertEqual(v_res.json()["verification_method"], "BUSINESS_QR")

        r_res = self.client.post(
            f"/stores/{self.klounge_store.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={
                "rating": 5,
                "content": "K-Lounge 사업장 QR 방문 인증 후기입니다.",
                "verification_id": v_res.json()["id"],
                "user_id": self.user1.id
            }
        )
        self.assertEqual(r_res.status_code, 201)
        self.assertEqual(r_res.json()["verification_badge"], "QR 방문 인증")


if __name__ == "__main__":
    unittest.main()
