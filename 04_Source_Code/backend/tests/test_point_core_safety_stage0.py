import unittest
import os
import sys
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from datetime import datetime, timedelta

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, get_db
from app import models
from app.auth import create_access_token
from app.database import Base, engine as db_engine
from app.services.point_service import PointService


class TestPointCoreSafetyStage0(unittest.TestCase):
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
        # Seed user with 500P balance
        self.user = models.User(
            id="usr_stage0_test",
            email="tester@nampogogo.com",
            nickname="테스터",
            current_points=500,
            lifetime_earned_points=200,
            role="member",
            status="active"
        )
        self.store = models.Store(
            id="store_s0_001",
            name="남포베이커리",
            category="카페",
            address="부산 중구 남포동",
            description="남포동 디저트 전문 베이커리",
            latitude=35.098,
            longitude=129.030,
            review_location_radius_m=50,
            review_verification_type="ATTRACTION_LOCATION"
        )
        self.coupon = models.Coupon(
            id="cpn_s0_001",
            title="아메리카노 1잔 무료",
            description="500P 교환 쿠폰",
            cost_points=500,
            expiry_days=30,
            status="active"
        )
        db.add_all([self.user, self.store, self.coupon])
        db.commit()
        db.close()

        self.token = create_access_token(data={"sub": "usr_stage0_test"})

    def test_T01_normal_earn_updates_balance_and_ledger_together(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(
            "/users/points/earn",
            json={"points": 200, "activity": "테스트 보너스 적립"},
            headers=headers
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["current_points"], 700)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 700)
        
        ph = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test").order_by(models.PointHistory.created_at.desc()).first()
        self.assertIsNotNone(ph)
        self.assertEqual(ph.points, 200)
        self.assertEqual(ph.activity, "테스트 보너스 적립")
        db.close()

    def test_T02_normal_spend_updates_balance_and_ledger_together(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(
            "/users/points/spend",
            json={"points": 300, "activity": "테스트 포인트 사용"},
            headers=headers
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["current_points"], 200)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 200)

        ph = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test").order_by(models.PointHistory.created_at.desc()).first()
        self.assertIsNotNone(ph)
        self.assertEqual(ph.points, -300)
        self.assertEqual(ph.activity, "테스트 포인트 사용")
        db.close()

    def test_T03_insufficient_balance_no_mutation(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(
            "/users/points/spend",
            json={"points": 9999, "activity": "초과 사용 시도"},
            headers=headers
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("보유 포인트가 부족합니다", res.json()["detail"])

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 500)

        histories = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test").all()
        self.assertEqual(len(histories), 0)
        db.close()

    def test_T05_sequential_conflicting_spends_cannot_overdraw(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        # First spend 400P (balance 500 -> 100)
        res1 = self.client.post("/users/points/spend", json={"points": 400, "activity": "1차 사용"}, headers=headers)
        self.assertEqual(res1.status_code, 200)
        self.assertEqual(res1.json()["current_points"], 100)

        # Second spend 200P (requires 200, but balance is 100 -> rejected)
        res2 = self.client.post("/users/points/spend", json={"points": 200, "activity": "2차 초과 사용"}, headers=headers)
        self.assertEqual(res2.status_code, 400)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 100)
        db.close()

    def test_T06_coupon_exchange_insufficient_balance_rejected(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        # Drain points first to 100P
        self.client.post("/users/points/spend", json={"points": 400, "activity": "사전 차감"}, headers=headers)

        # Try to exchange 500P coupon with 100P balance
        res = self.client.post(f"/coupons/{self.coupon.id}/exchange", json={}, headers=headers)
        self.assertEqual(res.status_code, 400)
        self.assertIn("보유 포인트가 부족합니다", res.json()["detail"])

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 100)
        coupons = db.query(models.UserCoupon).filter_by(user_id="usr_stage0_test").all()
        self.assertEqual(len(coupons), 0)
        db.close()

    def test_T07_coupon_exchange_balance_and_coupon_state_atomic(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(f"/coupons/{self.coupon.id}/exchange", json={}, headers=headers)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["current_points"], 0)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        self.assertEqual(u.current_points, 0)

        user_coupons = db.query(models.UserCoupon).filter_by(user_id="usr_stage0_test").all()
        self.assertEqual(len(user_coupons), 1)
        self.assertEqual(user_coupons[0].status, "unused")

        ph = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test", transaction_type="SPEND_COUPON").first()
        self.assertIsNotNone(ph)
        self.assertEqual(ph.points, -500)
        db.close()

    def test_T08_point_charge_atomic_success(self):
        db = self.SessionLocal()
        payment = models.Payment(
            id="pay_point_charge_001",
            user_id="usr_stage0_test",
            target_type="POINT_CHARGE",
            target_id="usr_stage0_test",
            amount=10000,
            payment_method="CARD",
            status="pending"
        )
        db.add(payment)
        db.commit()
        db.close()

        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(
            "/payments/complete",
            json={"payment_id": "pay_point_charge_001", "provider_tx_id": "mock_tx_10000"},
            headers=headers
        )
        self.assertEqual(res.status_code, 200)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        # Initial 500 + 10% of 10000 (1000P) = 1500P
        self.assertEqual(u.current_points, 1500)
        self.assertEqual(u.lifetime_earned_points, 1200)

        ph = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test", transaction_type="POINT_CHARGE_BONUS").first()
        self.assertIsNotNone(ph)
        self.assertEqual(ph.points, 1000)
        db.close()

    def test_T09_refund_rolls_back_points(self):
        db = self.SessionLocal()
        payment = models.Payment(
            id="pay_to_refund_001",
            user_id="usr_stage0_test",
            target_type="POINT_CHARGE",
            target_id="usr_stage0_test",
            amount=10000,
            payment_method="CARD",
            status="paid"
        )
        # Give initial points
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        u.current_points = 1500
        db.add(payment)
        db.commit()
        db.close()

        headers = {"Authorization": f"Bearer {self.token}"}
        res = self.client.post(
            "/payments/refund",
            json={"payment_id": "pay_to_refund_001", "refund_amount": 10000, "reason": "고객 요청"},
            headers=headers
        )
        self.assertEqual(res.status_code, 201)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        # 1500 - 1000 = 500
        self.assertEqual(u.current_points, 500)

        ph = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test", transaction_type="POINT_CHARGE_REFUND").first()
        self.assertIsNotNone(ph)
        self.assertEqual(ph.points, -1000)
        db.close()

    def test_T10_ledger_balance_delta_matches_successful_mutation(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        # Multiple mutations
        self.client.post("/users/points/earn", json={"points": 150, "activity": "적립 1"}, headers=headers)
        self.client.post("/users/points/spend", json={"points": 50, "activity": "사용 1"}, headers=headers)
        self.client.post("/users/points/earn", json={"points": 300, "activity": "적립 2"}, headers=headers)

        db = self.SessionLocal()
        u = db.query(models.User).filter_by(id="usr_stage0_test").first()
        # 500 + 150 - 50 + 300 = 900
        self.assertEqual(u.current_points, 900)

        histories = db.query(models.PointHistory).filter_by(user_id="usr_stage0_test").all()
        net_history = sum(h.points for h in histories)
        self.assertEqual(net_history, 400) # 150 - 50 + 300
        self.assertEqual(500 + net_history, u.current_points)
        db.close()


if __name__ == "__main__":
    unittest.main()
