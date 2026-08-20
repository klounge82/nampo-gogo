import unittest
import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, get_db
from app import models
from app.auth import create_access_token
from app.database import Base, engine as db_engine

class TestVC46BRework(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        models.Base.metadata.create_all(bind=db_engine)
        cls.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=db_engine)

        def override_get_db():
            db = cls.SessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        cls.client = TestClient(app)

    def setUp(self):
        models.Base.metadata.drop_all(bind=db_engine)
        models.Base.metadata.create_all(bind=db_engine)

        db = self.SessionLocal()
        # Seed test user jazzbj with 300 current_points, 700 lifetime_earned_points
        self.user_jazz = models.User(
            id="usr_jazz_002",
            email="jazzbj@naver.com",
            nickname="jazzbj",
            current_points=300,
            lifetime_earned_points=700,
            role="member",
            status="active"
        )
        db.add(self.user_jazz)
        db.commit()
        db.close()

        self.jazz_token = create_access_token(data={"sub": "usr_jazz_002"})

    def test_01_auth_me_returns_both_current_and_lifetime_points(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.get("/auth/me", headers=headers)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["current_points"], 300)
        self.assertEqual(data["lifetime_earned_points"], 700)

    def test_02_users_points_returns_both_fields(self):
        resp = self.client.get("/users/points?user_id=usr_jazz_002")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["current_points"], 300)
        self.assertEqual(data["lifetime_earned_points"], 700)

    def test_03_get_missions_returns_is_completed_for_user(self):
        db = self.SessionLocal()
        store = models.Store(id="store_gampo_001", name="QA 감포로", category="볼거리", address="부산 수영구", description="테스트", latitude=35.167, longitude=129.118)
        mission1 = models.Mission(id="mis_01", store_id="store_gampo_001", title="BIFF 광장 호떡 인증!", description="테스트", points=500, auth_type="PHOTO", status="active")
        mission2 = models.Mission(id="mis_02", store_id="store_gampo_001", title="용두산 타워 정복", description="테스트", points=500, auth_type="GPS", status="active")
        um = models.UserMission(id="um_01", user_id="usr_jazz_002", mission_id="mis_01")
        db.add_all([store, mission1, mission2, um])
        db.commit()
        db.close()

        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.get("/missions", headers=headers)
        self.assertEqual(resp.status_code, 200)
        missions = resp.json()
        m1 = next(m for m in missions if m["id"] == "mis_01")
        m2 = next(m for m in missions if m["id"] == "mis_02")
        self.assertTrue(m1["is_completed"])
        self.assertFalse(m2["is_completed"])

if __name__ == "__main__":
    unittest.main()
