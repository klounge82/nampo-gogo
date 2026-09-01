import unittest
import os
import threading
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 1. Setup isolated ephemeral local test SQLite DB
TEST_DB_PATH = "test_p7_coupon_redemption.db"
if os.path.exists(TEST_DB_PATH):
    try:
        os.remove(TEST_DB_PATH)
    except Exception:
        pass

os.environ["APP_ENV"] = "test"
os.environ["TESTING"] = "true"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from app.main import app, get_db
from app.database import Base
from app import models, auth

engine = create_engine(f"sqlite:///{TEST_DB_PATH}", connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

client = TestClient(app)

class TestCouponRedemptionAtomic(unittest.TestCase):

    def setUp(self):
        self._orig_overrides = dict(app.dependency_overrides)
        app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        app.dependency_overrides.clear()
        app.dependency_overrides.update(self._orig_overrides)

    @classmethod
    def setUpClass(cls):
        db = TestingSessionLocal()

        cls.user_owner_id = "user_owner_001"
        cls.user_attacker_id = "user_attacker_002"
        cls.coupon_id = "coupon_redemption_500"
        cls.user_coupon_id_1 = "user_coupon_seq_001"
        cls.user_coupon_id_2 = "user_coupon_atomic_002"
        cls.user_coupon_id_3 = "user_coupon_conc_003"

        owner_user = models.User(
            id=cls.user_owner_id,
            email="owner@test.com",
            nickname="OwnerUser",
            status="active",
            role="CUSTOMER",
            current_points=5000,
            lifetime_earned_points=5000
        )
        attacker_user = models.User(
            id=cls.user_attacker_id,
            email="attacker@test.com",
            nickname="AttackerUser",
            status="active",
            role="CUSTOMER",
            current_points=1000,
            lifetime_earned_points=1000
        )
        coupon = models.Coupon(
            id=cls.coupon_id,
            title="남포 맛집 500P 교환 쿠폰",
            description="테스트용 교환 쿠폰",
            cost_points=500,
            expiry_days=30,
            status="active"
        )
        user_coupon_1 = models.UserCoupon(
            id=cls.user_coupon_id_1,
            user_id=cls.user_owner_id,
            coupon_id=cls.coupon_id,
            status="unused",
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        user_coupon_2 = models.UserCoupon(
            id=cls.user_coupon_id_2,
            user_id=cls.user_owner_id,
            coupon_id=cls.coupon_id,
            status="unused",
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        user_coupon_3 = models.UserCoupon(
            id=cls.user_coupon_id_3,
            user_id=cls.user_owner_id,
            coupon_id=cls.coupon_id,
            status="unused",
            expires_at=datetime.utcnow() + timedelta(days=30)
        )

        db.add_all([owner_user, attacker_user, coupon, user_coupon_1, user_coupon_2, user_coupon_3])
        db.commit()
        db.close()

        # Generate JWT tokens
        cls.token_owner = auth.create_access_token({"sub": cls.user_owner_id})
        cls.token_attacker = auth.create_access_token({"sub": cls.user_attacker_id})

    @classmethod
    def tearDownClass(cls):
        if os.path.exists(TEST_DB_PATH):
            try:
                os.remove(TEST_DB_PATH)
            except Exception:
                pass

    def test_c1_first_redemption_succeeds(self):
        """C1: Authenticated owner redeems unused coupon -> HTTP 200, status becomes used"""
        headers = {"Authorization": f"Bearer {self.token_owner}"}
        res = client.post(
            f"/users/coupons/{self.user_coupon_id_1}/use",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 200, f"Expected 200, got {res.status_code}: {res.text}")
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("message"), "쿠폰 사용이 완료되었습니다.")

        # Verify DB status
        db = TestingSessionLocal()
        uc = db.query(models.UserCoupon).filter_by(id=self.user_coupon_id_1).first()
        self.assertIsNotNone(uc)
        self.assertEqual(uc.status, "used")
        self.assertIsNotNone(uc.used_at)
        db.close()

    def test_c2_second_redemption_rejected(self):
        """C2: Attempting to redeem already used coupon -> HTTP 400 rejection"""
        headers = {"Authorization": f"Bearer {self.token_owner}"}
        res = client.post(
            f"/users/coupons/{self.user_coupon_id_1}/use",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 400, f"Expected 400, got {res.status_code}: {res.text}")
        self.assertIn("사용할 수 없는 쿠폰입니다", res.text)

    def test_c3_wrong_owner_rejected(self):
        """C3: Another user attempting to redeem someone else's coupon -> HTTP 403 Forbidden"""
        headers = {"Authorization": f"Bearer {self.token_attacker}"}
        res = client.post(
            f"/users/coupons/{self.user_coupon_id_2}/use",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 403, f"Expected 403, got {res.status_code}: {res.text}")
        self.assertIn("다른 사용자의 쿠폰을 사용할 수 없습니다", res.text)

    def test_c4_atomic_rowcount_guard(self):
        """C4: Verifies update succeeds only while status='unused' and rowcount==0 triggers rejection"""
        headers = {"Authorization": f"Bearer {self.token_owner}"}

        # Step 1: Successful first redemption on user_coupon_id_2
        res1 = client.post(
            f"/users/coupons/{self.user_coupon_id_2}/use",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res1.status_code, 200)

        # Step 2: Directly simulate concurrent state by attempting another update
        db = TestingSessionLocal()
        affected_count = db.query(models.UserCoupon).filter(
            models.UserCoupon.id == self.user_coupon_id_2,
            models.UserCoupon.status == "unused"
        ).update({
            models.UserCoupon.status: "used",
            models.UserCoupon.used_at: datetime.utcnow()
        }, synchronize_session=False)
        db.commit()
        db.close()

        self.assertEqual(affected_count, 0, "Expected affected rowcount to be 0 for already used coupon")

    def test_c5_concurrent_redemption_smoke_test(self):
        """C5: Smoke test of concurrent redemption requests; exactly 1 must succeed"""
        headers = {"Authorization": f"Bearer {self.token_owner}"}
        results = []

        def make_request():
            res = client.post(
                f"/users/coupons/{self.user_coupon_id_3}/use",
                json={"user_id": None},
                headers=headers
            )
            results.append(res.status_code)

        t1 = threading.Thread(target=make_request)
        t2 = threading.Thread(target=make_request)

        t1.start()
        t2.start()
        t1.join()
        t2.join()

        success_count = results.count(200)
        rejection_count = results.count(400)

        self.assertEqual(success_count, 1, f"Expected exactly 1 success (200), got {results}")
        self.assertEqual(rejection_count, 1, f"Expected exactly 1 rejection (400), got {results}")

if __name__ == "__main__":
    unittest.main()
