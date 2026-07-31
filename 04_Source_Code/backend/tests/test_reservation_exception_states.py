import unittest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app, get_db
from app import models, auth, schemas

class TestReservationExceptionStates(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        models.Base.metadata.create_all(bind=self.engine)
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = TestingSessionLocal()

        def override_get_db():
            try:
                yield self.db
            finally:
                pass

        app.dependency_overrides[get_db] = override_get_db
        self.client = TestClient(app)

        # 1. Create Business Owner
        self.owner = models.User(
            id="owner_i3_001",
            email="owner_i3@nampogogo.kr",
            nickname="사업자I3",
            role="BUSINESS",
        )
        self.db.add(self.owner)
        self.owner_token = auth.create_access_token(data={"sub": self.owner.id, "role": "BUSINESS"})

        # 2. Create Store for Owner
        self.store = models.Store(
            id="store_i3_klounge",
            name="K-Lounge I3",
            category="휴게공간",
            address="부산 중구 광복로 1",
            description="K-Lounge I3 테스트 매장",
            status="APPROVED",
        )
        self.db.add(self.store)
        self.db.commit()

        # Add BusinessMembership for Owner
        self.membership = models.BusinessMembership(
            id="mem_i3_owner",
            user_id=self.owner.id,
            store_id=self.store.id,
            membership_role="OWNER",
            status="ACTIVE",
        )
        self.db.add(self.membership)

        # 3. Create Other Store & Owner
        self.other_store = models.Store(
            id="store_other_i3",
            name="Other Store I3",
            category="식당",
            address="부산 중구 남포동 1",
            description="다른 테스트 매장",
            status="APPROVED",
        )
        self.db.add(self.other_store)


        self.other_owner = models.User(
            id="owner_other_i3",
            email="other_i3@nampogogo.kr",
            nickname="타사업자I3",
            role="BUSINESS",
        )
        self.db.add(self.other_owner)
        self.db.commit()

        self.other_membership = models.BusinessMembership(
            id="mem_i3_other_owner",
            user_id=self.other_owner.id,
            store_id=self.other_store.id,
            membership_role="OWNER",
            status="ACTIVE",
        )
        self.db.add(self.other_membership)
        self.other_owner_token = auth.create_access_token(data={"sub": self.other_owner.id, "role": "BUSINESS"})

        # 4. Create Customer User
        self.customer = models.User(
            id="customer_i3_001",
            email="customer_i3@nampogogo.kr",
            nickname="이용자I3",
            role="CUSTOMER",
        )
        self.db.add(self.customer)
        self.customer_token = auth.create_access_token(data={"sub": self.customer.id, "role": "CUSTOMER"})

        # 5. Create Other Customer User
        self.other_customer = models.User(
            id="customer_other_i3",
            email="other_cust_i3@nampogogo.kr",
            nickname="타이용자I3",
            role="CUSTOMER",
        )
        self.db.add(self.other_customer)
        self.other_customer_token = auth.create_access_token(data={"sub": self.other_customer.id, "role": "CUSTOMER"})



        self.db.commit()

    def tearDown(self):
        self.db.close()
        models.Base.metadata.drop_all(bind=self.engine)

    def _create_reservation(self, status="PENDING", user_id=None):
        uid = user_id or self.customer.id
        res = models.StoreReservation(
            id=f"res_test_{datetime.utcnow().timestamp()}",
            user_id=uid,
            store_id=self.store.id,
            reservation_date="2026-08-01",
            start_time="14:00",
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status=status,
            customer_note="테스트 예약",
        )
        self.db.add(res)
        self.db.commit()
        self.db.refresh(res)
        return res

    def test_01_pending_to_rejected_with_reason(self):
        res = self._create_reservation("PENDING")
        response = self.client.post(
            f"/business/reservations/{res.id}/reject",
            json={"reason": "재료 소진으로 인한 거절"},
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "REJECTED")
        self.assertEqual(data["rejection_reason"], "재료 소진으로 인한 거절")

    def test_02_pending_to_cancelled_by_customer(self):
        res = self._create_reservation("PENDING")
        response = self.client.post(
            f"/reservations/{res.id}/cancel",
            json={"reason": "일정이 변경되었습니다"},
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 200)
        
        # Verify status in DB
        db_res = self.db.query(models.StoreReservation).filter_by(id=res.id).first()
        self.assertEqual(db_res.status, "CANCELLED_BY_CUSTOMER")
        self.assertEqual(db_res.cancellation_reason, "일정이 변경되었습니다")

    def test_03_approved_to_cancelled_by_customer(self):
        res = self._create_reservation("APPROVED")
        response = self.client.post(
            f"/reservations/{res.id}/cancel",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 200)
        db_res = self.db.query(models.StoreReservation).filter_by(id=res.id).first()
        self.assertEqual(db_res.status, "CANCELLED_BY_CUSTOMER")

    def test_04_approved_to_cancelled_by_business(self):
        res = self._create_reservation("APPROVED")
        response = self.client.post(
            f"/business/reservations/{res.id}/cancel",
            json={"reason": "매장 사정으로 취소"},
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "CANCELLED_BY_BUSINESS")
        self.assertEqual(data["cancellation_reason"], "매장 사정으로 취소")

    def test_05_approved_to_no_show(self):
        res = self._create_reservation("APPROVED")
        response = self.client.post(
            f"/business/reservations/{res.id}/no-show",
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "NO_SHOW")

    def test_06_completed_cancellation_blocked(self):
        res = self._create_reservation("COMPLETED")
        response = self.client.post(
            f"/reservations/{res.id}/cancel",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("이미 취소 또는 완료", response.json()["detail"])

    def test_07_no_show_cancellation_blocked(self):
        res = self._create_reservation("NO_SHOW")
        response = self.client.post(
            f"/reservations/{res.id}/cancel",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 400)

    def test_08_rejected_approval_blocked(self):
        res = self._create_reservation("REJECTED")
        response = self.client.post(
            f"/business/reservations/{res.id}/approve",
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 400)

    def test_09_cancelled_completion_blocked(self):
        res = self._create_reservation("CANCELLED_BY_CUSTOMER")
        response = self.client.post(
            f"/business/reservations/{res.id}/complete",
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 400)

    def test_10_other_business_access_blocked(self):
        res = self._create_reservation("PENDING")
        response = self.client.post(
            f"/business/reservations/{res.id}/approve",
            headers={"Authorization": f"Bearer {self.other_owner_token}"},
        )
        self.assertEqual(response.status_code, 403)

    def test_11_other_user_cancel_blocked(self):
        res = self._create_reservation("PENDING")
        response = self.client.post(
            f"/reservations/{res.id}/cancel",
            headers={"Authorization": f"Bearer {self.other_customer_token}"},
        )
        self.assertEqual(response.status_code, 404)

    def test_12_pending_business_cancel_blocked(self):
        res = self._create_reservation("PENDING")
        response = self.client.post(
            f"/business/reservations/{res.id}/cancel",
            json={"reason": "승인 전 매장 취소 시도"},
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("승인된 예약만 매장 취소", response.json()["detail"])

    def test_13_get_reservation_detail_success(self):
        res = self._create_reservation("APPROVED")
        response = self.client.get(
            f"/reservations/{res.id}",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["id"], res.id)
        self.assertEqual(data["status"], "APPROVED")
        self.assertIn("K-Lounge", data["store_name"])


    def test_14_get_reservation_detail_rejection_reason(self):
        res = self._create_reservation("PENDING")
        self.client.post(
            f"/business/reservations/{res.id}/reject",
            json={"reason": "재고 부족으로 거절"},
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        response = self.client.get(
            f"/reservations/{res.id}",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "REJECTED")
        self.assertEqual(data["rejection_reason"], "재고 부족으로 거절")

    def test_15_get_reservation_detail_cancellation_reasons(self):
        res = self._create_reservation("APPROVED")
        self.client.post(
            f"/business/reservations/{res.id}/cancel",
            json={"reason": "매장 임시휴업으로 취소"},
            headers={"Authorization": f"Bearer {self.owner_token}"},
        )
        response = self.client.get(
            f"/reservations/{res.id}",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "CANCELLED_BY_BUSINESS")
        self.assertEqual(data["cancellation_reason"], "매장 임시휴업으로 취소")

    def test_16_get_reservation_detail_other_user_forbidden(self):
        res = self._create_reservation("PENDING")
        response = self.client.get(
            f"/reservations/{res.id}",
            headers={"Authorization": f"Bearer {self.other_customer_token}"},
        )
        self.assertEqual(response.status_code, 403)
        self.assertIn("권한이 없습니다", response.json()["detail"])

    def test_17_get_reservation_detail_not_found(self):
        response = self.client.get(
            "/reservations/non_existent_res_99999",
            headers={"Authorization": f"Bearer {self.customer_token}"},
        )
        self.assertEqual(response.status_code, 404)

if __name__ == '__main__':
    unittest.main()


