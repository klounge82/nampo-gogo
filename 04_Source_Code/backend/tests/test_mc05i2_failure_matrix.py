import unittest
import base64
from fastapi.testclient import TestClient
from app.main import app, get_db
from app import models, auth
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine
from tests.test_db_session import TestingSessionLocal, init_test_db

class TestMC05I2FailureMatrix(unittest.TestCase):
    def setUp(self):
        init_test_db()
        self.client = TestClient(app)
        self.db = TestingSessionLocal()
        # Clean existing test objects
        self.db.query(models.UserMission).delete()
        self.db.query(models.PointHistory).delete()
        self.db.query(models.Mission).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create test user representing PM (jazzbj)
        self.user = models.User(
            id="usr_jazzbj_test_001",
            email="jazzbj@naver.com",
            nickname="jazzbj",
            role="USER",
            current_points=300,
            lifetime_earned_points=0,
        )
        self.db.add(self.user)
        
        # Create test store (Suyeong River LINE_BUFFER 50m)
        self.store = models.Store(
            id="qa-store-suyeong-river-photo-004",
            name="QA 수영강변 현장사진 장소",
            category="ATTRACTION",
            address="부산 해운대구 수영강변대로",
            description="수영강 산책로",
            latitude=35.1658,
            longitude=129.1251,
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=50,
            geometry_type="LINE_BUFFER",
            geometry_data='{"type":"LINE_BUFFER","lines":[[[35.1658,129.1251],[35.1693,129.1230]]],"buffer_m":50.0}'
        )
        self.db.add(self.store)

        # Create test photo mission
        self.mission = models.Mission(
            id="qa-mission-suyeong-river-photo-004",
            store_id=self.store.id,
            title="QA 수영강변 사진 인증",
            description="수영강 산책 사진 촬영",
            auth_type="PHOTO_VERIFICATION",
            points=100,
        )
        self.db.add(self.mission)
        self.db.commit()

        # Token for jazzbj
        self.token = auth.create_access_token(data={"sub": self.user.id, "email": self.user.email})
        self.headers = {"Authorization": f"Bearer {self.token}"}

        # 1x1 valid JPEG image b64
        self.valid_jpeg_b64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="

    def tearDown(self):
        self.db.close()

    def test_a_valid_photo_and_inside_location(self):
        """Test A: Valid photo inside geometry -> Success 200, points +100"""
        payload = {
            "qr_code": self.mission.id,
            "user_id": self.user.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": self.valid_jpeg_b64
        }
        resp = self.client.post(f"/missions/{self.mission.id}/verify", json=payload, headers=self.headers)
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json().get("success"))

        fresh_db = TestingSessionLocal()
        fu = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fu.current_points, 400) # 300 + 100
        self.assertEqual(fu.lifetime_earned_points, 100) # 0 + 100
        ph = fresh_db.query(models.PointHistory).filter_by(user_id=self.user.id).all()
        self.assertEqual(len(ph), 1)
        self.assertEqual(ph[0].points, 100)
        fresh_db.close()

    def test_b_empty_image_base64(self):
        """Test B: Empty image_base64 -> 400 Bad Request, 0 mutation"""
        payload = {
            "qr_code": self.mission.id,
            "user_id": self.user.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": ""
        }
        resp = self.client.post(f"/missions/{self.mission.id}/verify", json=payload, headers=self.headers)
        self.assertEqual(resp.status_code, 400)

        fresh_db = TestingSessionLocal()
        fu = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fu.current_points, 300)
        self.assertEqual(fu.lifetime_earned_points, 0)
        fresh_db.close()

    def test_c_malformed_base64(self):
        """Test C: Malformed base64 -> 400 Bad Request, 0 mutation"""
        payload = {
            "qr_code": self.mission.id,
            "user_id": self.user.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": "invalid_b64_str_!!!"
        }
        resp = self.client.post(f"/missions/{self.mission.id}/verify", json=payload, headers=self.headers)
        self.assertEqual(resp.status_code, 400)

        fresh_db = TestingSessionLocal()
        fu = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fu.current_points, 300)
        self.assertEqual(fu.lifetime_earned_points, 0)
        fresh_db.close()

    def test_d_missing_auth(self):
        """Test D: Missing auth header -> 401 Unauthorized, 0 mutation"""
        payload = {
            "qr_code": self.mission.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": self.valid_jpeg_b64
        }
        resp = self.client.post(f"/missions/{self.mission.id}/verify", json=payload)
        self.assertEqual(resp.status_code, 401)

        fresh_db = TestingSessionLocal()
        fu = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fu.current_points, 300)
        fresh_db.close()

    def test_e_duplicate_request_block(self):
        """Test I: Duplicate request -> 400 Bad Request on second attempt, no duplicate +100"""
        payload = {
            "qr_code": self.mission.id,
            "user_id": self.user.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": self.valid_jpeg_b64
        }
        # First attempt -> 200
        resp1 = self.client.post(f"/missions/{self.mission.id}/verify", json=payload, headers=self.headers)
        self.assertEqual(resp1.status_code, 200)

        # Second attempt -> 400 Bad Request
        resp2 = self.client.post(f"/missions/{self.mission.id}/verify", json=payload, headers=self.headers)
        self.assertEqual(resp2.status_code, 400)

        fresh_db = TestingSessionLocal()
        fu = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fu.current_points, 400) # Exactly 300 + 100 (NOT 500)
        self.assertEqual(fu.lifetime_earned_points, 100) # Exactly 0 + 100 (NOT 200)
        fresh_db.close()

if __name__ == "__main__":
    unittest.main()
