import os
import unittest
import uuid

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_role_shell.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app

class TestRoleShellModuleFoundation(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.client = TestClient(app)
        self.db = SessionLocal()
        self.db.query(models.BusinessMembership).delete()
        self.db.query(models.BusinessApplication).delete()
        self.db.query(models.UserRole).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.query(models.Store).delete()
        self.db.commit()

        # Create sample stores
        self.store1 = models.Store(
            id="store_role_01",
            name="남포 포차 1호점",
            category="음식점",
            address="부산 중구 남포동",
            description="테스트 매장 1"
        )
        self.store2 = models.Store(
            id="store_role_02",
            name="남포 카페 2호점",
            category="카페",
            address="부산 중구 광복동",
            description="테스트 매장 2"
        )
        self.db.add(self.store1)
        self.db.add(self.store2)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_signup_grants_customer_role_only(self):
        res = self.client.post(
            "/auth/signup",
            json={
                "email": "cust@example.com",
                "password": "password123",
                "nickname": "일반회원"
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["roles"], ["CUSTOMER"])
        self.assertEqual(data["available_app_modes"], ["CUSTOMER"])
        self.assertIn("place.read", data["capabilities"])
        self.assertNotIn("business.dashboard.read", data["capabilities"])

    def test_business_application_lifecycle_and_approval(self):
        # 1. Signup Customer User
        res_signup = self.client.post(
            "/auth/signup",
            json={
                "email": "owner_applicant@example.com",
                "password": "password123",
                "nickname": "사업자신청자"
            }
        )
        cust_id = res_signup.json()["id"]

        # Login to get token
        login_res = self.client.post(
            "/auth/login",
            json={"email": "owner_applicant@example.com", "password": "password123"}
        )
        cust_token = login_res.json()["access_token"]
        cust_headers = {"Authorization": f"Bearer {cust_token}"}

        # 2. Apply for business
        app_res = self.client.post(
            "/business/applications",
            json={
                "business_name": "남포 포차 유한회사",
                "business_registration_number": "123-45-67890",
                "representative_name": "홍길동",
                "phone": "010-1234-5678",
                "requested_store_id": self.store1.id
            },
            headers=cust_headers
        )
        self.assertEqual(app_res.status_code, 201)
        app_data = app_res.json()
        self.assertEqual(app_data["status"], "PENDING")

        # 3. Duplicate application fails (400)
        dup_res = self.client.post(
            "/business/applications",
            json={
                "business_name": "중복 신청",
                "business_registration_number": "000-00-00000",
                "representative_name": "홍길동",
                "phone": "010-0000-0000"
            },
            headers=cust_headers
        )
        self.assertEqual(dup_res.status_code, 400)

        # 4. Create Admin User
        admin_user = models.User(
            email="admin@example.com",
            nickname="총관리자",
            role="admin"
        )
        self.db.add(admin_user)
        self.db.flush()
        self.db.add(models.UserRole(user_id=admin_user.id, role="ADMIN"))
        self.db.commit()

        admin_token = auth.create_access_token({"sub": admin_user.id, "email": admin_user.email})
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # Non-admin approve fails (403)
        no_admin_approve = self.client.post(
            f"/admin/business/applications/{app_data['id']}/approve",
            headers=cust_headers
        )
        self.assertEqual(no_admin_approve.status_code, 403)

        # 5. Admin approves application
        approve_res = self.client.post(
            f"/admin/business/applications/{app_data['id']}/approve",
            json={"store_id": self.store1.id},
            headers=admin_headers
        )
        self.assertEqual(approve_res.status_code, 200)
        self.assertEqual(approve_res.json()["status"], "APPROVED")

        # 6. Verify user now has BUSINESS role and available_app_modes includes BUSINESS
        me_res = self.client.get("/auth/me", headers=cust_headers)
        me_data = me_res.json()
        self.assertIn("BUSINESS", me_data["roles"])
        self.assertIn("BUSINESS", me_data["available_app_modes"])
        self.assertEqual(len(me_data["business_memberships"]), 1)
        self.assertEqual(me_data["business_memberships"][0]["store_id"], self.store1.id)

    def test_unauthorized_store_access_blocked(self):
        # Create business user for store1 only
        biz_user = models.User(
            email="biz_user@example.com",
            nickname="매장1주인"
        )
        self.db.add(biz_user)
        self.db.flush()
        self.db.add(models.UserRole(user_id=biz_user.id, role="CUSTOMER"))
        self.db.add(models.UserRole(user_id=biz_user.id, role="BUSINESS"))
        self.db.add(models.BusinessMembership(user_id=biz_user.id, store_id=self.store1.id, membership_role="OWNER", status="ACTIVE"))
        self.db.commit()

        token = auth.create_access_token({"sub": biz_user.id, "email": biz_user.email})
        headers = {"Authorization": f"Bearer {token}"}

        # Check me
        me_res = self.client.get("/auth/me", headers=headers)
        self.assertEqual(me_res.status_code, 200)

if __name__ == "__main__":
    unittest.main()
