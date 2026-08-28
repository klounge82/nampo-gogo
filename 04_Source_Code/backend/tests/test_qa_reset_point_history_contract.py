import os
import unittest
import uuid

os.environ["DATABASE_URL"] = "sqlite:///./test_qa_reset_point_history.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app

class TestQaResetPointHistoryContract(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.UserMission).delete()
        self.db.query(models.PointHistory).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Target QA Admin User (jazzbj@naver.com)
        self.qa_user = models.User(
            id="2abb6e52-d447-4338-8beb-e638890a5ecc",
            email="jazzbj@naver.com",
            nickname="총관리자",
            role="admin",
            status="active",
            current_points=600,
            lifetime_earned_points=600
        )
        self.db.add(self.qa_user)

        # Other Customer User
        self.other_user = models.User(
            id="usr_other_999",
            email="other@nampogogo.com",
            nickname="다른사용자",
            role="member",
            status="active",
            current_points=500,
            lifetime_earned_points=500
        )
        self.db.add(self.other_user)
        self.db.commit()

        # Seed PointHistory for Target QA User:
        # Case 1: SIGNUP_BONUS (should be PRESERVED)
        ph1 = models.PointHistory(
            id="ph_signup_001",
            user_id=self.qa_user.id,
            points=300,
            activity="가입 축하 포인트 (300P)",
            transaction_type="SIGNUP_BONUS"
        )
        # Case 2: NULL transaction_type (legacy reward - should be DELETED)
        ph2 = models.PointHistory(
            id="ph_legacy_null_002",
            user_id=self.qa_user.id,
            points=100,
            activity="QA 수영강변 사진 인증",
            transaction_type=None
        )
        # Case 3: EARN transaction_type (legacy reward - should be DELETED)
        ph3 = models.PointHistory(
            id="ph_legacy_earn_003",
            user_id=self.qa_user.id,
            points=100,
            activity="QA 수영 을지로골뱅이 QR+GPS 방문",
            transaction_type="EARN"
        )
        # Case 4: MISSION transaction_type (legacy reward - should be DELETED)
        ph4 = models.PointHistory(
            id="ph_legacy_mission_004",
            user_id=self.qa_user.id,
            points=100,
            activity="QA 감포로 GPS 방문 인증",
            transaction_type="MISSION"
        )
        # Case 5: MISSION_REWARD transaction_type (should be DELETED)
        ph5 = models.PointHistory(
            id="ph_reward_005",
            user_id=self.qa_user.id,
            points=100,
            activity="QA 추가 미션 보상",
            transaction_type="MISSION_REWARD"
        )

        # Seed PointHistory for Other User (should be UNTOUCHED)
        ph_other = models.PointHistory(
            id="ph_other_101",
            user_id=self.other_user.id,
            points=200,
            activity="다른 사용자 적립",
            transaction_type="EARN"
        )

        self.db.add_all([ph1, ph2, ph3, ph4, ph5, ph_other])

        # Seed UserMission for Target QA User (should be DELETED)
        um1 = models.UserMission(
            id="um_qa_001",
            user_id=self.qa_user.id,
            mission_id="msn_001",
            status="COMPLETED"
        )
        self.db.add(um1)
        self.db.commit()

        self.qa_token = auth.create_access_token(data={"sub": self.qa_user.id})

    def tearDown(self):
        self.db.close()

    def test_qa_baseline_reset_deletes_all_non_signup_histories_null_safe(self):
        headers = {"Authorization": f"Bearer {self.qa_token}"}
        res = self.client.post(f"/admin/users/{self.qa_user.id}/reset-qa-baseline", headers=headers)

        self.assertEqual(res.status_code, 200)

        # 1. Verify User summary points
        user = self.db.query(models.User).filter(models.User.id == self.qa_user.id).first()
        self.assertEqual(user.current_points, 300)
        self.assertEqual(user.lifetime_earned_points, 300)

        # 2. Verify PointHistory for target QA user: ONLY 1 row (SIGNUP_BONUS, sum 300P)
        qa_histories = self.db.query(models.PointHistory).filter(models.PointHistory.user_id == self.qa_user.id).all()
        self.assertEqual(len(qa_histories), 1)
        self.assertEqual(qa_histories[0].transaction_type, "SIGNUP_BONUS")
        self.assertEqual(qa_histories[0].points, 300)

        # 3. Verify UserMission for target QA user is cleared
        qa_missions = self.db.query(models.UserMission).filter(models.UserMission.user_id == self.qa_user.id).all()
        self.assertEqual(len(qa_missions), 0)

        # 4. Verify Other User's PointHistory is COMPLETELY UNTOUCHED
        other_histories = self.db.query(models.PointHistory).filter(models.PointHistory.user_id == self.other_user.id).all()
        self.assertEqual(len(other_histories), 1)
        self.assertEqual(other_histories[0].points, 200)

    def test_qa_baseline_reset_idempotent_repeat_run(self):
        headers = {"Authorization": f"Bearer {self.qa_token}"}

        # Run 1
        res1 = self.client.post(f"/admin/users/{self.qa_user.id}/reset-qa-baseline", headers=headers)
        self.assertEqual(res1.status_code, 200)

        # Run 2 (Repeat reset on already-clean baseline)
        res2 = self.client.post(f"/admin/users/{self.qa_user.id}/reset-qa-baseline", headers=headers)
        self.assertEqual(res2.status_code, 200)

        qa_histories = self.db.query(models.PointHistory).filter(models.PointHistory.user_id == self.qa_user.id).all()
        self.assertEqual(len(qa_histories), 1)
        self.assertEqual(qa_histories[0].transaction_type, "SIGNUP_BONUS")
        self.assertEqual(qa_histories[0].points, 300)

    def test_qa_baseline_reset_denied_for_arbitrary_non_qa_user(self):
        # Non-QA customer account
        headers = {"Authorization": f"Bearer {self.qa_token}"}
        res = self.client.post(f"/admin/users/{self.other_user.id}/reset-qa-baseline", headers=headers)
        self.assertEqual(res.status_code, 400)

if __name__ == "__main__":
    unittest.main()
