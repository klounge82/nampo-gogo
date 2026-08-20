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

class TestVC49RuntimeTruth(unittest.TestCase):
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
        # Seed test user matching Production DB truth: current_points=300, lifetime_earned_points=0 (signup bonus only)
        self.user = models.User(
            id="2abb6e52-d447-4338-8beb-e638890a5ecc",
            email="jazzbj@naver.com",
            nickname="jazzbj",
            current_points=300,
            lifetime_earned_points=0,
            role="member",
            status="active"
        )
        db.add(self.user)
        db.commit()
        db.close()

        self.token = create_access_token(data={"sub": "2abb6e52-d447-4338-8beb-e638890a5ecc"})

    def test_01_auth_me_returns_actual_lifetime_0(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        resp = self.client.get("/auth/me", headers=headers)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["current_points"], 300)
        self.assertEqual(data["lifetime_earned_points"], 0)

    def test_02_auth_me_returns_lifetime_700_when_mission_completed(self):
        db = self.SessionLocal()
        u = db.query(models.User).filter(models.User.id == "2abb6e52-d447-4338-8beb-e638890a5ecc").first()
        u.lifetime_earned_points = 700
        db.commit()
        db.close()

        headers = {"Authorization": f"Bearer {self.token}"}
        resp = self.client.get("/auth/me", headers=headers)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["current_points"], 300)
        self.assertEqual(data["lifetime_earned_points"], 700)

if __name__ == "__main__":
    unittest.main()
