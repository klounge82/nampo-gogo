import sys, os, base64, unittest, tempfile, shutil
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app, get_db
from app.auth import create_access_token
from app.database import Base
from app import models

class TestJwtMissionUserBinding(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # 1. Photo Test File Isolation — Create temporary test directory
        cls.temp_dir = tempfile.mkdtemp(prefix="nampo_test_photo_evidence_")
        
        # Override backend EVIDENCE_DIR if configurable or monkeypatch photo evidence path during test
        cls.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        cls.TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=cls.engine)

        def override_get_db():
            db = cls.TestingSessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        # Clean up temporary test evidence directory
        if os.path.exists(cls.temp_dir):
            shutil.rmtree(cls.temp_dir, ignore_errors=True)

    def setUp(self):
        # 4. Test Independence — Fresh schema & re-seeded fixtures per test
        Base.metadata.drop_all(bind=self.engine)
        Base.metadata.create_all(bind=self.engine)

        db = self.TestingSessionLocal()
        self.user1 = models.User(id="usr_sun_001", email="sun@kakao.com", nickname="황선아", current_points=0, role="member", status="active")
        self.user2 = models.User(id="usr_jazz_002", email="jazzbj@naver.com", nickname="jazzbj", current_points=0, role="member", status="active")

        self.store_gps = models.Store(id="store_gampo_001", name="QA 감포로", category="볼거리", address="부산 수영구 감포로 100", description="테스트", latitude=35.167413, longitude=129.118103, review_location_radius_m=100, review_verification_type="ATTRACTION_LOCATION", is_test_data=True, tier="TEST")
        self.mission_gps = models.Mission(id="mission_gampo_001", store_id="store_gampo_001", title="QA 감포로 GPS", description="QA 테스트", points=100, auth_type="GPS_VERIFICATION", status="active")

        self.store_qr = models.Store(id="store_qr_001", name="QA QR 매장", category="맛집", address="부산 수영구 감포로 100", description="QR 테스트", latitude=35.167413, longitude=129.118103, review_location_radius_m=50, review_verification_type="BUSINESS_QR", is_test_data=True, tier="TEST")
        self.mission_qr = models.Mission(id="mission_qr_001", store_id="store_qr_001", title="QA QR+GPS", description="QR 테스트", points=100, auth_type="QR_GPS", status="active")

        self.store_photo = models.Store(id="store_photo_001", name="QA 수영강변 Photo", category="볼거리", address="부산 수영구 수영강변", description="사진 테스트", latitude=35.1635, longitude=129.1245, review_location_radius_m=100, review_verification_type="ATTRACTION_LOCATION", is_test_data=True, tier="TEST")
        self.mission_photo = models.Mission(id="mission_photo_001", store_id="store_photo_001", title="QA Photo", description="사진 테스트", points=100, auth_type="PHOTO_VERIFICATION", status="active")
        self.mission_photo_gps = models.Mission(id="mission_photo_gps_001", store_id="store_photo_001", title="QA Photo GPS", description="사진 GPS 테스트", points=100, auth_type="PHOTO_GPS", status="active")

        db.add_all([self.user1, self.user2, self.store_gps, self.mission_gps, self.store_qr, self.mission_qr, self.store_photo, self.mission_photo, self.mission_photo_gps])
        db.commit()
        db.close()

        self.jazz_token = create_access_token(data={"sub": "usr_jazz_002"})
        self.invalid_token = "invalid.jwt.signature"

    def test_01_unauthenticated_reject_with_zero_mutation(self):
        resp = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 35.167413, "longitude": 129.118103})
        self.assertEqual(resp.status_code, 401)

        # 2. Zero-Mutation Assertion
        db = self.TestingSessionLocal()
        self.assertEqual(db.query(models.UserMission).count(), 0)
        self.assertEqual(db.query(models.PointHistory).count(), 0)
        u1 = db.query(models.User).filter(models.User.id == "usr_sun_001").first()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u1.current_points, 0)
        self.assertEqual(u2.current_points, 0)
        db.close()

    def test_02_authenticated_jazzbj_success_and_db_attribution(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 35.167413, "longitude": 129.118103}, headers=headers)
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["success"])

        db = self.TestingSessionLocal()
        u1 = db.query(models.User).filter(models.User.id == "usr_sun_001").first()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u1.current_points, 0)
        self.assertEqual(u2.current_points, 100)
        self.assertEqual(db.query(models.UserMission).count(), 1)
        self.assertEqual(db.query(models.PointHistory).count(), 1)
        db.close()

    def test_04_invalid_jwt_reject_with_zero_mutation(self):
        headers = {"Authorization": f"Bearer {self.invalid_token}"}
        resp = self.client.post("/missions/mission_qr_001/verify", json={"qr_code": "mission_qr_001", "latitude": 35.167413, "longitude": 129.118103}, headers=headers)
        self.assertEqual(resp.status_code, 401)

        # 2. Zero-Mutation Assertion
        db = self.TestingSessionLocal()
        self.assertEqual(db.query(models.UserMission).count(), 0)
        self.assertEqual(db.query(models.PointHistory).count(), 0)
        u1 = db.query(models.User).filter(models.User.id == "usr_sun_001").first()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u1.current_points, 0)
        self.assertEqual(u2.current_points, 0)
        db.close()

    def test_05_identity_mismatch_immunity(self):
        # Option A: Schema accepts optional user_id, but backend uses JWT current_user exclusively
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.post(
            "/missions/mission_qr_001/verify",
            json={"qr_code": "mission_qr_001", "user_id": "usr_sun_001", "latitude": 35.167413, "longitude": 129.118103},
            headers=headers
        )
        self.assertEqual(resp.status_code, 200)

        db = self.TestingSessionLocal()
        u1 = db.query(models.User).filter(models.User.id == "usr_sun_001").first()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u1.current_points, 0)
        self.assertEqual(u2.current_points, 100)
        db.close()

    def test_06_duplicate_reward_prevention_with_zero_additional_mutation(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        # First completion
        resp1 = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 35.167413, "longitude": 129.118103}, headers=headers)
        self.assertEqual(resp1.status_code, 200)

        # Duplicate attempt
        resp2 = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 35.167413, "longitude": 129.118103}, headers=headers)
        self.assertEqual(resp2.status_code, 400)
        self.assertIn("이미 완료한 미션", resp2.json()["detail"])

        # 2. Zero Additional Mutation Assertion
        db = self.TestingSessionLocal()
        self.assertEqual(db.query(models.UserMission).count(), 1)
        self.assertEqual(db.query(models.PointHistory).count(), 1)
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u2.current_points, 100)
        db.close()

    def test_08_photo_verification_identity_regression(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")

        resp_unauth = self.client.post("/missions/mission_photo_001/verify", json={"qr_code": "mission_photo_001", "image_base64": base64_photo, "latitude": 35.1635, "longitude": 129.1245})
        self.assertEqual(resp_unauth.status_code, 401)

        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp_auth = self.client.post("/missions/mission_photo_001/verify", json={"qr_code": "mission_photo_001", "image_base64": base64_photo, "latitude": 35.1635, "longitude": 129.1245}, headers=headers)
        self.assertEqual(resp_auth.status_code, 200)

        db = self.TestingSessionLocal()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u2.current_points, 100)
        db.close()

    def test_09_photo_verification_without_gps_coordinates_success(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")

        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        # PHOTO verification with valid JWT + image, NO latitude or longitude
        resp = self.client.post("/missions/mission_photo_001/verify", json={"qr_code": "mission_photo_001", "image_base64": base64_photo}, headers=headers)
        self.assertEqual(resp.status_code, 200)

        db = self.TestingSessionLocal()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u2.current_points, 100)
        db.close()

    def test_10_gps_outside_radius_returns_structured_error(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        # Coordinates far from store (store_gampo_001 is at 35.167413, 129.118103)
        resp = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 37.5665, "longitude": 126.9780}, headers=headers)
        self.assertEqual(resp.status_code, 400)
        detail = resp.json()["detail"]
        self.assertEqual(detail["code"], "GPS_OUTSIDE_RADIUS")
        self.assertGreater(detail["distance_m"], detail["allowed_radius_m"])
        self.assertEqual(detail["outside_by_m"], detail["distance_m"] - detail["allowed_radius_m"])

    def test_11_photo_gps_inside_radius_success(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")
        headers = {"Authorization": f"Bearer {self.jazz_token}"}

        # Inside store_photo_001 geofence (35.1635, 129.1245)
        resp = self.client.post(
            "/missions/mission_photo_gps_001/verify",
            json={"qr_code": "mission_photo_gps_001", "image_base64": base64_photo, "latitude": 35.1635, "longitude": 129.1245},
            headers=headers
        )
        self.assertEqual(resp.status_code, 200)

        db = self.TestingSessionLocal()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u2.current_points, 100)
        db.close()

    def test_12_photo_gps_outside_radius_returns_photo_gps_outside_code(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")
        headers = {"Authorization": f"Bearer {self.jazz_token}"}

        # Far away coordinates (37.5665, 126.9780)
        resp = self.client.post(
            "/missions/mission_photo_gps_001/verify",
            json={"qr_code": "mission_photo_gps_001", "image_base64": base64_photo, "latitude": 37.5665, "longitude": 126.9780},
            headers=headers
        )
        self.assertEqual(resp.status_code, 400)
        detail = resp.json()["detail"]
        self.assertEqual(detail["code"], "PHOTO_GPS_OUTSIDE_RADIUS")

        db = self.TestingSessionLocal()
        u2 = db.query(models.User).filter(models.User.id == "usr_jazz_002").first()
        self.assertEqual(u2.current_points, 0)
        db.close()

    def test_13_photo_gps_no_coordinates_reject(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")
        headers = {"Authorization": f"Bearer {self.jazz_token}"}

        resp = self.client.post(
            "/missions/mission_photo_gps_001/verify",
            json={"qr_code": "mission_photo_gps_001", "image_base64": base64_photo},
            headers=headers
        )
        self.assertEqual(resp.status_code, 400)

    def test_14_photo_gps_no_image_reject(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.post(
            "/missions/mission_photo_gps_001/verify",
            json={"qr_code": "mission_photo_gps_001", "latitude": 35.1635, "longitude": 129.1245},
            headers=headers
        )
        self.assertEqual(resp.status_code, 400)

    def test_15_photo_gps_unauthenticated_reject(self):
        raw_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00" + b"\x00" * 100
        base64_photo = base64.b64encode(raw_jpeg).decode("utf-8")

        resp = self.client.post(
            "/missions/mission_photo_gps_001/verify",
            json={"qr_code": "mission_photo_gps_001", "image_base64": base64_photo, "latitude": 35.1635, "longitude": 129.1245}
        )
        self.assertEqual(resp.status_code, 401)

if __name__ == "__main__":
    unittest.main()
