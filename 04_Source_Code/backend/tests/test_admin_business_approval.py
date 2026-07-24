import unittest
from fastapi.testclient import TestClient
import uuid

from app.main import app, get_db
from app.database import Base, engine, SessionLocal
from app import models, auth

class TestAdminBusinessApproval(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        self.client = TestClient(app)

        # Clear test data
        self.db.query(models.AdminAuditLog).delete()
        self.db.query(models.BusinessMembership).delete()
        self.db.query(models.BusinessApplication).delete()
        self.db.query(models.UserRole).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create Admin User fixture
        self.admin_user = models.User(
            id=str(uuid.uuid4()),
            email="admin_test@nampo.com",
            nickname="총관리자",
            role="admin"
        )
        self.db.add(self.admin_user)
        self.db.commit()
        self.db.add(models.UserRole(user_id=self.admin_user.id, role="ADMIN"))
        self.db.commit()

        # Create Customer User fixture
        self.customer_user = models.User(
            id=str(uuid.uuid4()),
            email="customer_test@nampo.com",
            nickname="일반고객",
            role="member"
        )
        self.db.add(self.customer_user)
        self.db.commit()
        self.db.add(models.UserRole(user_id=self.customer_user.id, role="CUSTOMER"))
        self.db.commit()

        # Generate tokens
        self.admin_token = auth.create_access_token(data={"sub": self.admin_user.id, "email": self.admin_user.email})
        self.customer_token = auth.create_access_token(data={"sub": self.customer_user.id, "email": self.customer_user.email})

        # Existing store fixture
        self.existing_store = models.Store(
            id=str(uuid.uuid4()),
            name="기존 광복동 카페",
            category="카페",
            address="부산 중구 광복로 1",
            description="기존 카페",
            status="영업중"
        )
        self.db.add(self.existing_store)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_admin_access_control_customer_forbidden(self):
        res = self.client.get(
            "/admin/business/applications",
            headers={"Authorization": f"Bearer {self.customer_token}"}
        )
        self.assertEqual(res.status_code, 403)

    def test_admin_get_applications_list_and_summary(self):
        app_obj = models.BusinessApplication(
            id=str(uuid.uuid4()),
            user_id=self.customer_user.id,
            business_name="신규 남포 상점",
            business_registration_number="123-45-67890",
            representative_name="홍길동",
            phone="010-1234-5678",
            status="PENDING"
        )
        self.db.add(app_obj)
        self.db.commit()

        res_sum = self.client.get(
            "/admin/business/application-summary",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res_sum.status_code, 200)
        data_sum = res_sum.json()
        self.assertEqual(data_sum["pending_count"], 1)

        res_list = self.client.get(
            "/admin/business/applications",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res_list.status_code, 200)
        items = res_list.json()
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["business_name"], "신규 남포 상점")
        self.assertIn("*", items[0]["phone_masked"])
        self.assertEqual(items[0]["application_type"], "NEW_STORE")

    def test_approve_existing_store_application(self):
        app_obj = models.BusinessApplication(
            id=str(uuid.uuid4()),
            user_id=self.customer_user.id,
            business_name="광복동 카페 사업자",
            business_registration_number="987-65-43210",
            representative_name="김대표",
            phone="010-9876-5432",
            requested_store_id=self.existing_store.id,
            status="PENDING"
        )
        self.db.add(app_obj)
        self.db.commit()

        res = self.client.post(
            f"/admin/business/applications/{app_obj.id}/approve",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "APPROVED")

        # Expire local session cache to read latest committed DB status
        self.db.expire_all()

        # Verify DB states
        updated_app = self.db.query(models.BusinessApplication).filter_by(id=app_obj.id).first()
        self.assertEqual(updated_app.status, "APPROVED")

        # Check BUSINESS role added
        user_roles = [r.role for r in self.db.query(models.UserRole).filter_by(user_id=self.customer_user.id).all()]
        self.assertIn("BUSINESS", user_roles)

        # Check membership
        mem = self.db.query(models.BusinessMembership).filter_by(user_id=self.customer_user.id, store_id=self.existing_store.id).first()
        self.assertIsNotNone(mem)
        self.assertEqual(mem.membership_role, "OWNER")

    def test_approve_new_store_application_creates_draft_store(self):
        app_obj = models.BusinessApplication(
            id=str(uuid.uuid4()),
            user_id=self.customer_user.id,
            business_name="새로 여는 빵집",
            business_registration_number="111-22-33333",
            representative_name="이대표",
            phone="010-1111-2222",
            requested_store_id=None,
            status="PENDING"
        )
        self.db.add(app_obj)
        self.db.commit()

        res = self.client.post(
            f"/admin/business/applications/{app_obj.id}/approve",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "APPROVED")

        self.db.expire_all()

        # Check that draft store was created with status DRAFT
        draft_store = self.db.query(models.Store).filter_by(name="새로 여는 빵집").first()
        self.assertIsNotNone(draft_store)
        self.assertEqual(draft_store.status, "DRAFT")

        # Verify draft store is NOT returned in public /stores query
        public_stores = self.client.get("/stores").json()
        store_ids = [s["id"] for s in public_stores]
        self.assertNotIn(draft_store.id, store_ids)

    def test_duplicate_approval_rejected(self):
        app_obj = models.BusinessApplication(
            id=str(uuid.uuid4()),
            user_id=self.customer_user.id,
            business_name="이미 승인된 가게",
            business_registration_number="555-44-33333",
            representative_name="박대표",
            phone="010-5555-4444",
            status="APPROVED"
        )
        self.db.add(app_obj)
        self.db.commit()

        res = self.client.post(
            f"/admin/business/applications/{app_obj.id}/approve",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res.status_code, 400)

    def test_reject_application_requires_reason(self):
        app_obj = models.BusinessApplication(
            id=str(uuid.uuid4()),
            user_id=self.customer_user.id,
            business_name="거절 대상 가게",
            business_registration_number="999-88-77777",
            representative_name="최대표",
            phone="010-9999-8888",
            status="PENDING"
        )
        self.db.add(app_obj)
        self.db.commit()

        # Reject without reason -> 400
        res = self.client.post(
            f"/admin/business/applications/{app_obj.id}/reject",
            json={"rejection_reason": ""},
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res.status_code, 400)

        # Reject with reason -> 200
        res_ok = self.client.post(
            f"/admin/business/applications/{app_obj.id}/reject",
            json={"rejection_reason": "사업자등록번호 불일치"},
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(res_ok.status_code, 200)
        self.assertEqual(res_ok.json()["status"], "REJECTED")

        self.db.expire_all()

        # Verify no BUSINESS role or membership was created
        roles = [r.role for r in self.db.query(models.UserRole).filter_by(user_id=self.customer_user.id).all()]
        self.assertNotIn("BUSINESS", roles)

if __name__ == "__main__":
    unittest.main()
