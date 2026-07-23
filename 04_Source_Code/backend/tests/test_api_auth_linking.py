import os
import unittest
import uuid

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_auth_linking.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app

class TestAuthGuestLinking(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.client = TestClient(app)
        self.db = SessionLocal()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.UserRecommendation).delete()
        self.db.query(models.Favorite).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.query(models.Store).delete()
        self.db.commit()

        # Seed sample store
        self.store = models.Store(
            id="store_test_auth_01",
            name="남포 포장마차",
            category="음식점",
            address="부산 중구 남포동",
            description="테스트 매장"
        )
        self.db.add(self.store)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_signup_and_duplicate_rejection(self):
        # 1. Signup Success
        res = self.client.post(
            "/auth/signup",
            json={
                "email": "newuser@example.com",
                "password": "password123",
                "nickname": "신규유저"
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["email"], "newuser@example.com")
        self.assertEqual(data["nickname"], "신규유저")

        # 2. Duplicate Signup Rejection
        res_dup = self.client.post(
            "/auth/signup",
            json={
                "email": "newuser@example.com",
                "password": "password123",
                "nickname": "중복유저"
            }
        )
        self.assertEqual(res_dup.status_code, 400)
        self.assertIn("이미 가입된 이메일", res_dup.json()["detail"])

    def test_login_success_and_wrong_password_rejection(self):
        # 1. Signup
        self.client.post(
            "/auth/signup",
            json={
                "email": "loginuser@example.com",
                "password": "correct_password_123",
                "nickname": "로그인유저"
            }
        )

        # 2. Wrong Password
        res_wrong = self.client.post(
            "/auth/login",
            json={
                "email": "loginuser@example.com",
                "password": "wrong_password_999"
            }
        )
        self.assertEqual(res_wrong.status_code, 400)

        # 3. Correct Password
        res_ok = self.client.post(
            "/auth/login",
            json={
                "email": "loginuser@example.com",
                "password": "correct_password_123"
            }
        )
        self.assertEqual(res_ok.status_code, 200)
        token_res = res_ok.json()
        self.assertIn("access_token", token_res)
        self.assertIn("refresh_token", token_res)
        self.assertEqual(token_res["user"]["email"], "loginuser@example.com")

    def test_guest_data_atomic_linking_on_signup(self):
        guest_id = "guest_temp_999"

        # 1. Create Guest Verification and Review
        ver = models.VisitVerification(
            id="v_guest_111",
            store_id=self.store.id,
            guest_id=guest_id,
            verification_method="BUSINESS_QR",
            expires_at=models.func.now(),
            status="USED"
        )
        self.db.add(ver)

        rev = models.Review(
            id="r_guest_111",
            store_id=self.store.id,
            guest_id=guest_id,
            rating=5,
            content="게스트로 작성한 남포동 맛집 후기 10자 이상입니다.",
            verification_id="v_guest_111",
            verification_method="BUSINESS_QR",
            verification_badge="QR 방문 인증"
        )
        self.db.add(rev)

        rec = models.UserRecommendation(
            id="rec_guest_111",
            guest_id=guest_id,
            travel_type="SOLO",
            travel_duration="TWO_HOURS",
            transport_mode="WALK",
            start_latitude=35.1,
            start_longitude=129.0
        )
        self.db.add(rec)
        self.db.commit()

        # 2. Signup with guest_id
        res_signup = self.client.post(
            "/auth/signup",
            json={
                "email": "guest_convert@example.com",
                "password": "password123",
                "nickname": "게스트전환회원",
                "guest_id": guest_id
            }
        )
        self.assertEqual(res_signup.status_code, 201)
        user_id = res_signup.json()["id"]

        # 3. Verify that Review, VisitVerification, UserRecommendation now have user_id set!
        linked_rev = self.db.query(models.Review).filter(models.Review.id == "r_guest_111").first()
        self.assertEqual(linked_rev.user_id, user_id)
        self.assertEqual(linked_rev.verification_id, "v_guest_111")
        self.assertEqual(linked_rev.verification_badge, "QR 방문 인증")

        linked_ver = self.db.query(models.VisitVerification).filter(models.VisitVerification.id == "v_guest_111").first()
        self.assertEqual(linked_ver.user_id, user_id)

        linked_rec = self.db.query(models.UserRecommendation).filter(models.UserRecommendation.id == "rec_guest_111").first()
        self.assertEqual(linked_rec.user_id, user_id)

    def test_relinking_guard_against_other_user_claim(self):
        guest_id = "guest_shared_777"

        # User A signs up and claims guest_id
        res_a = self.client.post(
            "/auth/signup",
            json={
                "email": "user_a@example.com",
                "password": "password123",
                "nickname": "유저A",
                "guest_id": guest_id
            }
        )
        user_a_id = res_a.json()["id"]

        # Create review claimed by User A
        rev = models.Review(
            id="r_claimed_777",
            store_id=self.store.id,
            user_id=user_a_id,
            guest_id=guest_id,
            rating=5,
            content="유저 A가 소유한 리뷰 내용 10자 이상."
        )
        self.db.add(rev)
        self.db.commit()

        # User B attempts to claim the same guest_id -> Guard prevents re-linking!
        res_b = self.client.post(
            "/auth/signup",
            json={
                "email": "user_b@example.com",
                "password": "password123",
                "nickname": "유저B",
                "guest_id": guest_id
            }
        )
        self.assertEqual(res_b.status_code, 201)
        user_b_id = res_b.json()["id"]

        # Verify review is STILL owned by User A, NOT User B
        rev_check = self.db.query(models.Review).filter(models.Review.id == "r_claimed_777").first()
        self.assertEqual(rev_check.user_id, user_a_id)

if __name__ == "__main__":
    unittest.main()
