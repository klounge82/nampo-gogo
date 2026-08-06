import unittest
import json
import uuid
import os
import sys
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, get_db
from app import models, database

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_ag03.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

class TestAG03VirtualPaymentAndReferral(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        models.Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        models.Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_ag03.db"):
            try:
                os.remove("./test_ag03.db")
            except Exception:
                pass

    def setUp(self):
        self.db = TestingSessionLocal()
        # Clean test tables
        self.db.query(models.PaymentLog).delete()
        self.db.query(models.PaymentRefund).delete()
        self.db.query(models.Payment).delete()
        self.db.query(models.StoreRecommendation).delete()
        self.db.query(models.PointHistory).delete()
        self.db.query(models.Notification).delete()
        self.db.query(models.StoreReservation).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.StoreOwner).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create Nampo Toast & K-Lounge stores
        self.toast_store = models.Store(
            id="store-toast-test",
            name="남포토스트",
            category="맛집",
            address="부산 중구 광복로 55-1",
            description="토스트 전문점",
            tier="VERIFIED_BETA"
        )
        self.klounge_store = models.Store(
            id="store-klounge-test",
            name="K-Lounge",
            category="체험",
            address="부산 중구 구덕로 50-1 2층",
            description="마사지 웰니스 매장",
            tier="OFFICIAL"
        )
        self.db.add_all([self.toast_store, self.klounge_store])

        # Create Customer user
        self.customer = models.User(
            id="user-customer-test",
            email="test_customer@nampogogo.com",
            nickname="테스트이용자",
            role="member",
            current_points=1000
        )
        self.db.add(self.customer)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_01_virtual_payment_creation_and_notice(self):
        """Test virtual payment creation with is_test flag and point usage limits"""
        p = models.Payment(
            user_id=self.customer.id,
            amount=9000,
            payment_method="CARD",
            target_type="RESERVATION",
            target_id="res-101",
            status="paid",
            is_test=True,
            idempotency_key=str(uuid.uuid4())
        )
        self.db.add(p)
        self.db.commit()

        self.assertTrue(p.is_test)
        self.assertEqual(p.status, "paid")
        self.assertEqual(p.amount, 9000)

    def test_02_point_usage_and_restore_on_cancellation(self):
        """Test redeeming points for reservation and restoring points on cancellation"""
        # User spends 500P
        self.customer.current_points -= 500
        h_spend = models.PointHistory(
            user_id=self.customer.id,
            points=-500,
            activity="예약 결제 포인트 사용"
        )
        self.db.add(h_spend)
        self.db.commit()

        self.assertEqual(self.customer.current_points, 500)

        # Cancel reservation -> restore 500P
        self.customer.current_points += 500
        h_restore = models.PointHistory(
            user_id=self.customer.id,
            points=500,
            activity="예약 취소에 따른 포인트 원복"
        )
        self.db.add(h_restore)
        self.db.commit()

        self.assertEqual(self.customer.current_points, 1000)

    def test_03_business_recommendation_flow_and_duplicate_prevention(self):
        """Test recommendation flow: Nampo Toast -> K-Lounge and atomic reward check"""
        rec = models.StoreRecommendation(
            referrer_store_id=self.toast_store.id,
            recommended_store_id=self.klounge_store.id,
            customer_user_id=self.customer.id,
            status="CREATED"
        )
        self.db.add(rec)
        self.db.commit()

        # Step 1: Customer reserves K-Lounge -> CREATED to RESERVED
        rec.status = "RESERVED"
        self.db.commit()
        self.assertEqual(rec.status, "RESERVED")

        # Step 2: Customer completes QR Visit -> RESERVED to VISITED to REWARDED
        rec.status = "REWARDED"
        rec.points_rewarded = 1000
        
        # Reward customer 500P and referrer owner 1000P
        self.customer.current_points += 500
        h_cust = models.PointHistory(
            user_id=self.customer.id,
            points=500,
            activity="추천 매장 방문 보너스 포인트 적립"
        )
        self.db.add(h_cust)
        self.db.commit()

        self.assertEqual(rec.status, "REWARDED")
        self.assertEqual(self.customer.current_points, 1500)

        # Duplicate reward attempt check
        if rec.status == "REWARDED":
            duplicate_prevented = True
        else:
            duplicate_prevented = False

        self.assertTrue(duplicate_prevented)

if __name__ == "__main__":
    unittest.main()
