import unittest
import os
import sys
from datetime import datetime
from sqlalchemy import text
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, get_db
from app import models
from app.auth import create_access_token
from app.database import Base, engine as db_engine

class TestPointEconomyV2(unittest.TestCase):
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
        # Seed test users
        self.user_sun = models.User(id="usr_sun_001", email="sun@kakao.com", nickname="황선아", current_points=300, lifetime_earned_points=0, role="member", status="active")
        self.user_jazz = models.User(id="usr_jazz_002", email="jazzbj@naver.com", nickname="jazzbj", current_points=300, lifetime_earned_points=0, role="member", status="active")
        
        # Seed store and mission
        self.store = models.Store(id="store_gampo_001", name="QA 감포로", category="볼거리", address="부산 수영구", description="테스트", latitude=35.167, longitude=129.118, review_location_radius_m=100, review_verification_type="ATTRACTION_LOCATION")
        self.mission = models.Mission(id="mission_gampo_001", store_id="store_gampo_001", title="QA 감포로 GPS", description="테스트", points=100, auth_type="GPS", status="active")

        # Seed historical incident for sun@kakao.com
        self.ph_sun = models.PointHistory(id="ph_sun_incident_001", user_id="usr_sun_001", points=100, activity="미션 완료: QA 감포로 GPS", transaction_type="MISSION_REWARD")
        self.um_sun = models.UserMission(id="um_sun_incident_001", user_id="usr_sun_001", mission_id="mission_gampo_001")

        # Seed signup bonus history (300P each)
        self.ph_sun_signup = models.PointHistory(id="ph_signup_001", user_id="usr_sun_001", points=300, activity="신규 회원가입 축하 포인트", transaction_type="SIGNUP_BONUS")
        self.ph_jazz_signup = models.PointHistory(id="ph_signup_002", user_id="usr_jazz_002", points=300, activity="신규 회원가입 축하 포인트", transaction_type="SIGNUP_BONUS")

        db.add_all([self.user_sun, self.user_jazz, self.store, self.mission, self.ph_sun, self.um_sun, self.ph_sun_signup, self.ph_jazz_signup])
        db.commit()
        db.close()

        self.jazz_token = create_access_token(data={"sub": "usr_jazz_002"})

    def test_01_deterministic_backfill_excludes_exact_incident_and_signup_bonus(self):
        db = self.SessionLocal()
        # Seed qualifying rewards for jazzbj
        ph_m = models.PointHistory(id="ph_jazz_001", user_id="usr_jazz_002", points=500, activity="미션 완료: BIFF 광장 호떡 인증!", transaction_type="MISSION_REWARD")
        ph_r = models.PointHistory(id="ph_jazz_002", user_id="usr_jazz_002", points=100, activity="방문 리뷰 작성 보상", transaction_type="REVIEW_REWARD")
        ph_v = models.PointHistory(id="ph_jazz_003", user_id="usr_jazz_002", points=100, activity="방문 인증 완료: K-Lounge", transaction_type="VISIT_REWARD")
        db.add_all([ph_m, ph_r, ph_v])
        db.commit()

        # Run Backfill SQL
        backfill_sql = """
        UPDATE users
        SET lifetime_earned_points = COALESCE((
            SELECT SUM(ph.points)
            FROM point_histories ph
            WHERE ph.user_id = users.id
              AND ph.points > 0
              AND ph.id != 'ph_sun_incident_001'
              AND (ph.activity LIKE '미션 완료:%' OR ph.activity = '방문 리뷰 작성 보상' OR ph.activity LIKE '방문 인증 완료:%')
              AND ph.activity NOT LIKE '%회원가입%'
              AND ph.activity NOT LIKE '%웰컴%'
              AND ph.activity NOT LIKE '%관리자%'
              AND ph.activity NOT LIKE '%복원%'
              AND ph.activity NOT LIKE '%보정%'
        ), 0);
        """
        db.execute(text(backfill_sql))
        db.commit()

        jazz = db.query(models.User).filter_by(id="usr_jazz_002").first()
        sun = db.query(models.User).filter_by(id="usr_sun_001").first()

        # Assert jazzbj lifetime_earned_points == 700 (500 + 100 + 100)
        self.assertEqual(jazz.lifetime_earned_points, 700)
        self.assertEqual(jazz.current_points, 300)

        # Assert sun lifetime_earned_points == 0 (Incident ph_sun_incident_001 and Signup 300 bonus excluded!)
        self.assertEqual(sun.lifetime_earned_points, 0)
        db.close()

    def test_02_mission_reward_atomic_increment(self):
        headers = {"Authorization": f"Bearer {self.jazz_token}"}
        resp = self.client.post("/missions/mission_gampo_001/verify", json={"qr_code": "mission_gampo_001", "latitude": 35.167, "longitude": 129.118}, headers=headers)
        self.assertEqual(resp.status_code, 200)

        db = self.SessionLocal()
        jazz = db.query(models.User).filter_by(id="usr_jazz_002").first()
        # current_points 300 -> 400, lifetime_earned_points 0 -> 100
        self.assertEqual(jazz.current_points, 400)
        self.assertEqual(jazz.lifetime_earned_points, 100)
        db.close()

    def test_03_get_user_points_returns_both_fields(self):
        resp = self.client.get("/users/points?user_id=usr_jazz_002")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertIn("current_points", data)
        self.assertIn("lifetime_earned_points", data)

if __name__ == "__main__":
    unittest.main()
