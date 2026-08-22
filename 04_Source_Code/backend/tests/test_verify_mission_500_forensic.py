import unittest
import base64
from fastapi.testclient import TestClient
from app.main import app, get_db
from app import models, auth
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base

from sqlalchemy.pool import StaticPool

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

class TestVerifyMission500Forensic(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.db = TestingSessionLocal()
        # Create test user
        self.user = models.User(
            id="test_user_forensic_001",
            email="testuser@nampogogo.com",
            nickname="TestUser",
            role="USER",
            current_points=0,
            lifetime_earned_points=0,
        )
        self.db.add(self.user)
        
        # Create test store
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

        # Create test mission
        self.mission = models.Mission(
            id="qa-mission-suyeong-river-photo-004",
            store_id=self.store.id,
            title="QA 수영강변 사진 인증",
            description="수영강 산책 사진 촬영",
            auth_type="PHOTO_VERIFICATION",
            points=100,
        )
        self.db.add(self.mission)

        # Create test mission 2
        self.mission_gps = models.Mission(
            id="qa-mission-suyeong-photo-gps-005",
            store_id=self.store.id,
            title="QA 수영강변 PHOTO_GPS 인증",
            description="수영강 산책 사진 촬영",
            auth_type="PHOTO_GPS",
            points=100,
        )
        self.db.add(self.mission_gps)
        self.db.commit()

        # Token
        self.token = auth.create_access_token(data={"sub": self.user.id})
        self.headers = {"Authorization": f"Bearer {self.token}"}

    def tearDown(self):
        self.db.close()

    def test_photo_verification_submission(self):
        # 1x1 24-bit JPEG image
        dummy_jpeg_b64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
        
        payload = {
            "qr_code": "qa-mission-suyeong-river-photo-004",
            "user_id": self.user.id,
            "latitude": 35.1658,
            "longitude": 129.1251,
            "image_base64": dummy_jpeg_b64
        }

        resp = self.client.post(
            f"/missions/{self.mission.id}/verify",
            json=payload,
            headers=self.headers
        )

        print("TEST RESPONSE STATUS:", resp.status_code)
        print("TEST RESPONSE JSON:", resp.json())

        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json().get("success"))
        self.assertEqual(resp.json().get("points_awarded"), 100)

        # Check DB state via fresh query
        fresh_db = TestingSessionLocal()
        fresh_user = fresh_db.query(models.User).filter_by(id=self.user.id).first()
        self.assertEqual(fresh_user.current_points, 100)
        self.assertEqual(fresh_user.lifetime_earned_points, 100)
        fresh_db.close()

if __name__ == "__main__":
    unittest.main()
