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

class TestVC50ProductionTruth(unittest.TestCase):
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
        # Seed test user matching exact Live Production Railway truth after 300P policy reconciliation
        self.user = models.User(
            id="2abb6e52-d447-4338-8beb-e638890a5ecc",
            email="jazzbj@naver.com",
            nickname="jazzbj",
            current_points=300,
            lifetime_earned_points=0,
            role="member",
            status="active"
        )
        history_signup = models.PointHistory(
            id="ph_signup_001",
            user_id="2abb6e52-d447-4338-8beb-e638890a5ecc",
            points=1000,
            activity="신규 가입 웰컴 축하 포인트"
        )
        history_corr = models.PointHistory(
            id="ph_corr_001",
            user_id="2abb6e52-d447-4338-8beb-e638890a5ecc",
            points=-700,
            activity="공식 가입 보너스 정책 보정 (-700P)",
            transaction_type="CORRECTION"
        )
        db.add_all([self.user, history_signup, history_corr])
        db.commit()
        db.close()

        self.token = create_access_token(data={"sub": "2abb6e52-d447-4338-8beb-e638890a5ecc"})

    def test_01_auth_me_returns_exact_production_truth(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        resp = self.client.get("/auth/me", headers=headers)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["current_points"], 300)
        self.assertEqual(data["lifetime_earned_points"], 0)

    def test_02_point_history_returns_exact_signup_bonus_record(self):
        resp = self.client.get("/users/points/history?user_id=2abb6e52-d447-4338-8beb-e638890a5ecc")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(len(data), 2)
        net_pts = sum(row["points"] for row in data)
        self.assertEqual(net_pts, 300)

if __name__ == "__main__":
    unittest.main()
