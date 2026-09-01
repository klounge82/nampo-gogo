import unittest
import os
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 1. Setup isolated ephemeral local test SQLite DB
TEST_DB_PATH = "test_p7_coupon_exchange.db"
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

class TestCouponExchangeAuthAndIntegrity(unittest.TestCase):

    def setUp(self):
        self._orig_overrides = dict(app.dependency_overrides)
        app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        app.dependency_overrides.clear()
        app.dependency_overrides.update(self._orig_overrides)

    @classmethod
    def setUpClass(cls):
        db = TestingSessionLocal()

        # Create test users
        cls.user_rich = models.User(
            id="user_rich_001",
            email="rich@test.com",
            nickname="RichUser",
            status="active",
            role="CUSTOMER",
            current_points=10000,
            lifetime_earned_points=10000
        )
        cls.user_poor = models.User(
            id="user_poor_002",
            email="poor@test.com",
            nickname="PoorUser",
            status="active",
            role="CUSTOMER",
            current_points=100,
            lifetime_earned_points=100
        )
        cls.user_victim = models.User(
            id="user_victim_003",
            email="victim@test.com",
            nickname="VictimUser",
            status="active",
            role="CUSTOMER",
            current_points=5000,
            lifetime_earned_points=5000
        )

        # Create test coupon
        cls.coupon_id = "coupon_test_500"
        cls.coupon = models.Coupon(
            id=cls.coupon_id,
            title="남포동 500P 할인 쿠폰",
            description="500 포인트 차감 교환 쿠폰",
            cost_points=500,
            expiry_days=30,
            status="active"
        )

        db.add_all([cls.user_rich, cls.user_poor, cls.user_victim, cls.coupon])
        db.commit()
        db.close()

        # Create JWT access tokens
        cls.token_rich = auth.create_access_token({"sub": "user_rich_001"})
        cls.token_poor = auth.create_access_token({"sub": "user_poor_002"})
        cls.token_victim = auth.create_access_token({"sub": "user_victim_003"})

    @classmethod
    def tearDownClass(cls):
        if os.path.exists(TEST_DB_PATH):
            try:
                os.remove(TEST_DB_PATH)
            except Exception:
                pass

    def test_t1_unauthenticated_request_rejected(self):
        """T1: Unauthenticated request without Authorization header returns HTTP 401"""
        res = client.post(
            f"/coupons/{self.coupon_id}/exchange",
            json={"user_id": None}
        )
        self.assertEqual(res.status_code, 401, f"Expected 401, got {res.status_code}: {res.text}")

    def test_t2_authenticated_valid_user_succeeds(self):
        """T2: Authenticated user with sufficient points succeeds with HTTP 200"""
        headers = {"Authorization": f"Bearer {self.token_rich}"}
        res = client.post(
            f"/coupons/{self.coupon_id}/exchange",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 200, f"Expected 200, got {res.status_code}: {res.text}")
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("user_coupon_id", data)
        self.assertEqual(data.get("current_points"), 9500)

    def test_t3_user_identity_binding_rejects_spoofed_user_id(self):
        """T3: Non-admin user attempting to exchange on behalf of victim user_id returns HTTP 403"""
        headers = {"Authorization": f"Bearer {self.token_poor}"}
        res = client.post(
            f"/coupons/{self.coupon_id}/exchange",
            json={"user_id": "user_victim_003"},
            headers=headers
        )
        self.assertEqual(res.status_code, 403, f"Expected 403, got {res.status_code}: {res.text}")

    def test_t4_insufficient_points_rejected(self):
        """T4: Authenticated user with insufficient points returns HTTP 400"""
        headers = {"Authorization": f"Bearer {self.token_poor}"}
        res = client.post(
            f"/coupons/{self.coupon_id}/exchange",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 400, f"Expected 400, got {res.status_code}: {res.text}")
        self.assertIn("보유 포인트가 부족합니다", res.text)

    def test_t5_nonexistent_coupon_returns_404(self):
        """T5: Nonexistent coupon_id returns HTTP 404"""
        headers = {"Authorization": f"Bearer {self.token_rich}"}
        res = client.post(
            "/coupons/nonexistent_coupon_id_9999/exchange",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 404, f"Expected 404, got {res.status_code}: {res.text}")

    def test_t6_successful_mutation_integrity_in_test_db(self):
        """T6: Verifies UserCoupon creation, status='unused', PointHistory 'SPEND_COUPON', and point deduction"""
        db = TestingSessionLocal()
        user = db.query(models.User).filter_by(id="user_rich_001").first()
        initial_points = user.current_points

        headers = {"Authorization": f"Bearer {self.token_rich}"}
        res = client.post(
            f"/coupons/{self.coupon_id}/exchange",
            json={"user_id": None},
            headers=headers
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        user_coupon_id = data["user_coupon_id"]

        # Verify DB rows
        db.expire_all()
        user_after = db.query(models.User).filter_by(id="user_rich_001").first()
        self.assertEqual(user_after.current_points, initial_points - 500)

        user_coupon = db.query(models.UserCoupon).filter_by(id=user_coupon_id).first()
        self.assertIsNotNone(user_coupon)
        self.assertEqual(user_coupon.status, "unused")
        self.assertEqual(user_coupon.user_id, "user_rich_001")
        self.assertEqual(user_coupon.coupon_id, self.coupon_id)

        point_history = db.query(models.PointHistory).filter_by(
            user_id="user_rich_001",
            source_id=self.coupon_id,
            transaction_type="SPEND_COUPON"
        ).first()
        self.assertIsNotNone(point_history)
        self.assertEqual(point_history.points, -500)
        db.close()

if __name__ == "__main__":
    unittest.main()
