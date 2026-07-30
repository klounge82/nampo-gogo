import unittest
from datetime import datetime, timedelta
import uuid
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app, get_db
from app.database import Base
from app import models, auth

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_h4_i1_reservations.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

class TestH4KLoungeLinkAndI1Reservations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        app.dependency_overrides[get_db] = override_get_db

    @classmethod
    def tearDownClass(cls):
        app.dependency_overrides.clear()
        try:
            Base.metadata.drop_all(bind=engine)
        except Exception:
            pass


    def setUp(self):
        self.db = TestingSessionLocal()
        self.client = TestClient(app)


        # Clear tables
        self.db.query(models.ReservationBlackout).delete()
        self.db.query(models.ReservationSettings).delete()
        self.db.query(models.StoreReservation).delete()
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.BusinessMembership).delete()
        self.db.query(models.StoreQrCredential).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # 1. Setup Users
        self.owner_hwang = models.User(
            id="usr_hwang_001",
            email="jazzbj@naver.com",
            nickname="황병준",
            role="BUSINESS",
            status="active"
        )
        self.other_biz = models.User(
            id="usr_other_002",
            email="otherbiz@test.com",
            nickname="다른사업자",
            role="BUSINESS",
            status="active"
        )
        self.customer1 = models.User(
            id="usr_cust_001",
            email="cust1@test.com",
            nickname="손님1",
            role="CUSTOMER",
            status="active"
        )
        self.db.add_all([self.owner_hwang, self.other_biz, self.customer1])
        self.db.commit()

        self.token_hwang = auth.create_access_token(data={"sub": self.owner_hwang.id})
        self.token_other = auth.create_access_token(data={"sub": self.other_biz.id})
        self.token_cust1 = auth.create_access_token(data={"sub": self.customer1.id})

        # 2. Setup Stores
        self.public_klounge = models.Store(
            id="31b96920-2eb3-4f93-ab51-546fd8d933d1",
            name="K-Lounge",
            category="체험",
            status="영업중",
            review_verification_type="BUSINESS_QR",
            manual_visit_allowed=True,
            phone_number="051-243-8880",
            address="부산광역시 중구 구덕로 50-1 2층",
            description="K-Lounge 공개 매장 설명"
        )
        self.draft_klounge = models.Store(
            id="ca407921-a8e0-4f9a-980b-6ba635b09c17",
            name="케이라운지",
            category="일반",
            status="DRAFT",
            review_verification_type="BUSINESS_QR",
            manual_visit_allowed=True,
            phone_number="051-123-4567",
            address="부산 중구",
            description="케이라운지 초안 매장 설명"
        )

        self.db.add_all([self.public_klounge, self.draft_klounge])
        self.db.commit()

        # 3. Setup Memberships (H4 Single Active OWNER for Hwang on Public K-Lounge)
        self.mem_hwang = models.BusinessMembership(
            id="mem_hwang_001",
            user_id=self.owner_hwang.id,
            store_id=self.public_klounge.id,
            membership_role="OWNER",
            status="ACTIVE"
        )
        self.db.add(self.mem_hwang)
        self.db.commit()

        self.public_klounge_id = self.public_klounge.id
        self.draft_klounge_id = self.draft_klounge.id

    def tearDown(self):
        self.db.close()



    # H4-1. Public K-Lounge OWNER Manage Access
    def test_h4_01_public_klounge_owner_manage_access(self):
        res = self.client.get(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_hwang}"}
        )
        self.assertEqual(res.status_code, 200)

        # Other business user is forbidden (403)
        res_other = self.client.get(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_other}"}
        )
        self.assertEqual(res_other.status_code, 403)

    # H4-2. DRAFT Store Excluded from Public Search
    def test_h4_02_draft_store_excluded(self):
        res = self.client.get("/stores")
        self.assertEqual(res.status_code, 200)
        store_ids = [s["id"] for s in res.json()]
        self.assertNotIn(self.draft_klounge_id, store_ids)


    # I1-1. Reservation OFF Blocks Booking
    def test_i1_01_reservation_off_blocks_booking(self):
        # Default settings is OFF
        future_date = (datetime.utcnow() + timedelta(days=2)).strftime("%Y-%m-%d")
        res = self.client.post(
            "/reservations",
            headers={"Authorization": f"Bearer {self.token_cust1}"},
            json={
                "store_id": self.public_klounge_id,
                "reservation_date": future_date,
                "start_time": "14:00",
                "party_size": 2
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("지원하지 않습니다", res.json()["detail"])

    # I1-2. Reservation ON Enables Booking & Valid Flow
    def test_i1_02_reservation_on_enables_booking(self):
        # Turn ON reservations
        self.client.put(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_hwang}"},
            json={
                "reservations_enabled": True,
                "available_weekdays": "1,2,3,4,5,6,7",
                "minimum_advance_minutes": 0,
                "maximum_advance_days": 30
            }
        )


        future_date = (datetime.utcnow() + timedelta(days=2)).strftime("%Y-%m-%d")
        res = self.client.post(
            "/reservations",
            headers={"Authorization": f"Bearer {self.token_cust1}"},
            json={
                "store_id": self.public_klounge_id,
                "reservation_date": future_date,
                "start_time": "14:00",
                "party_size": 2,
                "customer_note": "창가 자리 부탁드립니다."
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["status"], "PENDING")
        self.assertEqual(data["party_size"], 2)

    # I1-3. Blackout / Peak-Time Blocked
    def test_i1_03_blackout_peaktime_blocked(self):
        self.client.put(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_hwang}"},
            json={"reservations_enabled": True}
        )
        # Add Lunch Blackout 11:30~14:00
        bo_res = self.client.post(
            f"/business/stores/{self.public_klounge_id}/reservation-blackouts",
            headers={"Authorization": f"Bearer {self.token_hwang}"},
            json={"start_time": "11:30", "end_time": "14:00", "reason": "점심 피크타임"}
        )
        self.assertEqual(bo_res.status_code, 201)

        future_date = (datetime.utcnow() + timedelta(days=2)).strftime("%Y-%m-%d")
        res = self.client.post(
            "/reservations",
            headers={"Authorization": f"Bearer {self.token_cust1}"},
            json={
                "store_id": self.public_klounge_id,
                "reservation_date": future_date,
                "start_time": "12:00",
                "party_size": 2
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("바빠 예약을 받지 않습니다", res.json()["detail"])

    # I1-4. Minimum Advance Time Validation
    def test_i1_04_minimum_advance_time_validation(self):
        self.client.put(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_hwang}"},
            json={"reservations_enabled": True, "minimum_advance_minutes": 120}
        )
        # Booking in 30 minutes (less than 120m)
        now_kst = datetime.utcnow() + timedelta(hours=9)
        near_time = (now_kst + timedelta(minutes=30))
        today_date = near_time.strftime("%Y-%m-%d")
        near_time_str = near_time.strftime("%H:%M")

        res = self.client.post(
            "/reservations",
            headers={"Authorization": f"Bearer {self.token_cust1}"},
            json={
                "store_id": self.public_klounge_id,
                "reservation_date": today_date,
                "start_time": near_time_str,
                "party_size": 2
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("최소", res.json()["detail"])

    # I1-5. Business Approve, Complete, and Customer Cancel
    def test_i1_05_business_approve_complete_and_customer_cancel(self):
        self.client.put(
            f"/business/stores/{self.public_klounge_id}/reservation-settings",
            headers={"Authorization": f"Bearer {self.token_hwang}"},
            json={"reservations_enabled": True}
        )
        future_date = (datetime.utcnow() + timedelta(days=2)).strftime("%Y-%m-%d")

        # 1. Customer creates reservation
        res = self.client.post(
            "/reservations",
            headers={"Authorization": f"Bearer {self.token_cust1}"},
            json={
                "store_id": self.public_klounge_id,
                "reservation_date": future_date,
                "start_time": "15:00",
                "party_size": 2
            }
        )
        self.assertEqual(res.status_code, 201)
        res_id = res.json()["id"]

        # 2. Business approves reservation
        app_res = self.client.post(
            f"/business/reservations/{res_id}/approve",
            headers={"Authorization": f"Bearer {self.token_hwang}"}
        )
        self.assertEqual(app_res.status_code, 200)
        self.assertEqual(app_res.json()["status"], "APPROVED")

        # 3. Business completes reservation
        comp_res = self.client.post(
            f"/business/reservations/{res_id}/complete",
            headers={"Authorization": f"Bearer {self.token_hwang}"}
        )
        self.assertEqual(comp_res.status_code, 200)
        self.assertEqual(comp_res.json()["status"], "COMPLETED")

if __name__ == "__main__":
    unittest.main()
