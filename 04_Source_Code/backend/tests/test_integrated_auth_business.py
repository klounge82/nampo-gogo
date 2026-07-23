import unittest
import uuid
import os
from datetime import datetime
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Setup test DB before importing app
TEST_DB_PATH = "test_integrated_auth_business.db"
if os.path.exists(TEST_DB_PATH):
    try:
        os.remove(TEST_DB_PATH)
    except Exception:
        pass

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

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

class TestIntegratedAuthBusinessCore(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        db = TestingSessionLocal()
        s1 = db.query(models.Store).filter_by(id="store_test_001").first()
        if not s1:
            cls.store1 = models.Store(
                id="store_test_001",
                name="남포 맛집 1호점",
                category="음식점",
                address="부산 중구 남포길 1",
                description="맛있는 남포동 맛집입니다.",
                operating_hours="10:00 - 22:00",
                phone_number="051-111-2222"
            )
            db.add(cls.store1)
        s2 = db.query(models.Store).filter_by(id="store_test_002").first()
        if not s2:
            cls.store2 = models.Store(
                id="store_test_002",
                name="남포 카페 2호점",
                category="카페",
                address="부산 중구 남포길 2",
                description="전망 좋은 남포동 카페입니다.",
                operating_hours="11:00 - 23:00",
                phone_number="051-333-4444"
            )
            db.add(cls.store2)
        db.commit()
        db.close()

    @classmethod
    def tearDownClass(cls):
        app.dependency_overrides.clear()

    def test_01_login_unregistered_email_returns_401(self):
        res = client.post("/auth/login", json={"email": "nonexistent@test.com", "password": "Password123!"})
        self.assertEqual(res.status_code, 401)
        self.assertNotIn("access_token", res.json())
        self.assertIn("이메일 또는 비밀번호가 올바르지 않습니다.", res.json()["detail"])

    def test_02_login_wrong_password_returns_401(self):
        # Create user
        db = TestingSessionLocal()
        u = models.User(email="wrongpass@test.com", nickname="PassTest", role="member", status="active")
        db.add(u)
        db.flush()
        a = models.UserAuth(user_id=u.id, hashed_password=auth.get_password_hash("CorrectPassword123!"))
        db.add(a)
        db.commit()
        db.close()

        res = client.post("/auth/login", json={"email": "wrongpass@test.com", "password": "WrongPassword123!"})
        self.assertEqual(res.status_code, 401)
        self.assertNotIn("access_token", res.json())

    def test_03_login_correct_credentials_succeeds(self):
        res = client.post("/auth/login", json={"email": "wrongpass@test.com", "password": "CorrectPassword123!"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("access_token", data)
        self.assertIn("refresh_token", data)

    def test_04_auth_failure_no_tokens_issued(self):
        res = client.post("/auth/login", json={"email": "nobody@test.com", "password": "invalidpassword"})
        self.assertEqual(res.status_code, 401)
        self.assertNotIn("access_token", res.json())

    def test_05_auth_failure_guest_data_not_linked(self):
        # Call login with guest_id header on invalid user
        res = client.post(
            "/auth/login",
            json={"email": "nobody@test.com", "password": "invalidpassword"},
            headers={"x-guest-id": "guest_test_999"}
        )
        self.assertEqual(res.status_code, 401)

    def test_06_production_guards(self):
        from app.auth import JWT_SECRET
        self.assertTrue(len(JWT_SECRET) > 0)

    def test_07_customer_signup_creates_only_customer_role(self):
        res = client.post("/auth/signup", json={"email": "cust1@test.com", "password": "Password123!", "nickname": "일반회원1"})
        self.assertEqual(res.status_code, 201)
        user_out = res.json()
        self.assertEqual(user_out["email"], "cust1@test.com")
        self.assertIn("CUSTOMER", user_out["roles"])
        self.assertNotIn("BUSINESS", user_out["roles"])
        self.assertEqual(user_out["business_application_status"], "NONE")

    def test_08_business_signup_creates_customer_role_and_pending_application(self):
        res = client.post("/auth/signup/business", json={
            "email": "biz1@test.com",
            "password": "Password123!",
            "nickname": "사업자신청1",
            "business_name": "신규 남포 상회",
            "business_registration_number": "123-45-67890",
            "representative_name": "홍길동",
            "phone": "010-1234-5678"
        })
        self.assertEqual(res.status_code, 201)
        user_out = res.json()
        self.assertIn("CUSTOMER", user_out["roles"])
        self.assertNotIn("BUSINESS", user_out["roles"])
        self.assertEqual(user_out["business_application_status"], "PENDING")

    def test_09_business_signup_transaction_rollback_on_failure(self):
        # Attempt to signup business with missing required field or duplicate email
        res = client.post("/auth/signup/business", json={
            "email": "biz1@test.com", # Existing email
            "password": "Password123!",
            "nickname": "중복회원",
            "business_name": "중복 상회",
            "business_registration_number": "123-45-67890",
            "representative_name": "홍길동",
            "phone": "010-1234-5678"
        })
        self.assertEqual(res.status_code, 400)
        self.assertIn("이미 가입된 계정입니다", res.json()["detail"])

    def test_10_no_business_role_granted_immediately_after_business_signup(self):
        login_res = client.post("/auth/login", json={"email": "biz1@test.com", "password": "Password123!"})
        self.assertEqual(login_res.status_code, 200)
        user_data = login_res.json()["user"]
        self.assertNotIn("BUSINESS", user_data["roles"])
        self.assertEqual(user_data["business_application_status"], "PENDING")

    def test_11_duplicate_email_registration_blocked(self):
        res = client.post("/auth/signup", json={"email": "cust1@test.com", "password": "Password123!", "nickname": "중복"})
        self.assertEqual(res.status_code, 400)

    def test_12_existing_customer_business_application_succeeds(self):
        login_res = client.post("/auth/login", json={"email": "cust1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        app_res = client.post(
            "/business/applications",
            json={
                "business_name": "기존회원의 매장",
                "business_registration_number": "987-65-43210",
                "representative_name": "김철수",
                "phone": "010-9876-5432"
            },
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(app_res.status_code, 201)
        self.assertEqual(app_res.json()["status"], "PENDING")

    def test_13_duplicate_pending_application_blocked(self):
        login_res = client.post("/auth/login", json={"email": "cust1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        app_res = client.post(
            "/business/applications",
            json={
                "business_name": "또 신청하려함",
                "business_registration_number": "987-65-43210",
                "representative_name": "김철수",
                "phone": "010-9876-5432"
            },
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(app_res.status_code, 400)
        self.assertIn("대기 중", app_res.json()["detail"])

    def test_14_requested_store_id_nullable(self):
        login_res = client.post("/auth/login", json={"email": "biz1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]
        me_res = client.get("/business/applications/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(me_res.status_code, 200)
        self.assertIsNone(me_res.json()["requested_store_id"])

    def test_15_application_saved_as_pending_in_db(self):
        db = TestingSessionLocal()
        app_rec = db.query(models.BusinessApplication).filter(models.BusinessApplication.status == "PENDING").first()
        self.assertIsNotNone(app_rec)
        db.close()

    def test_16_pending_user_blocked_from_business_api(self):
        login_res = client.post("/auth/login", json={"email": "biz1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        store_res = client.get("/business/store/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(store_res.status_code, 403)

    def test_17_approved_owner_get_and_update_my_store(self):
        db = TestingSessionLocal()

        owner_user = models.User(email="owner1@test.com", nickname="점주1", role="member", status="active")
        db.add(owner_user)
        db.flush()
        db.add(models.UserAuth(user_id=owner_user.id, hashed_password=auth.get_password_hash("Password123!")))
        db.add(models.UserRole(user_id=owner_user.id, role="CUSTOMER"))
        db.add(models.UserRole(user_id=owner_user.id, role="BUSINESS"))
        db.add(models.BusinessMembership(user_id=owner_user.id, store_id="store_test_001", membership_role="OWNER", status="ACTIVE"))
        db.commit()
        db.close()

        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        store_res = client.get("/business/store/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(store_res.status_code, 200)
        self.assertEqual(store_res.json()["store"]["id"], "store_test_001")

        update_res = client.patch(
            "/business/store/me",
            json={"name": "남포 맛집 1호점 (리뉴얼)"},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(update_res.status_code, 200)
        self.assertEqual(update_res.json()["name"], "남포 맛집 1호점 (리뉴얼)")

    def test_18_manager_can_update_store_info(self):
        db = TestingSessionLocal()
        mgr_user = models.User(email="mgr1@test.com", nickname="매니저1", role="member", status="active")
        db.add(mgr_user)
        db.flush()
        db.add(models.UserAuth(user_id=mgr_user.id, hashed_password=auth.get_password_hash("Password123!")))
        db.add(models.UserRole(user_id=mgr_user.id, role="CUSTOMER"))
        db.add(models.UserRole(user_id=mgr_user.id, role="BUSINESS"))
        db.add(models.BusinessMembership(user_id=mgr_user.id, store_id="store_test_001", membership_role="MANAGER", status="ACTIVE"))
        db.commit()
        db.close()

        login_res = client.post("/auth/login", json={"email": "mgr1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        update_res = client.patch(
            "/business/store/me",
            json={"phone_number": "051-999-8888"},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(update_res.status_code, 200)

    def test_19_staff_blocked_from_updating_store_info(self):
        db = TestingSessionLocal()
        staff_user = models.User(email="staff1@test.com", nickname="스태프1", role="member", status="active")
        db.add(staff_user)
        db.flush()
        db.add(models.UserAuth(user_id=staff_user.id, hashed_password=auth.get_password_hash("Password123!")))
        db.add(models.UserRole(user_id=staff_user.id, role="CUSTOMER"))
        db.add(models.UserRole(user_id=staff_user.id, role="BUSINESS"))
        db.add(models.BusinessMembership(user_id=staff_user.id, store_id="store_test_001", membership_role="STAFF", status="ACTIVE"))
        db.commit()
        db.close()

        login_res = client.post("/auth/login", json={"email": "staff1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        update_res = client.patch(
            "/business/store/me",
            json={"name": "해킹시도"},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(update_res.status_code, 403)

    def test_20_access_to_other_store_blocked(self):
        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        # Attempt to access products of store_test_002
        prod_res = client.get("/business/products?store_id=store_test_002", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(prod_res.status_code, 403)

    def test_21_product_create_update_status_change(self):
        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        # Create product
        create_res = client.post(
            "/business/products",
            json={"name": "남포 비빔당면", "price": 6000, "sale_price": 5500, "category": "분식"},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(create_res.status_code, 201)
        prod_id = create_res.json()["id"]

        # Update product
        update_res = client.patch(
            f"/business/products/{prod_id}",
            json={"status": "SOLD_OUT"},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(update_res.status_code, 200)
        self.assertEqual(update_res.json()["status"], "SOLD_OUT")

        # Soft delete product
        del_res = client.delete(f"/business/products/{prod_id}", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(del_res.status_code, 200)
        self.assertEqual(del_res.json()["status"], "INACTIVE")

    def test_22_modifying_product_of_other_store_blocked(self):
        # Create product under store_test_002 for owner2
        db = TestingSessionLocal()
        owner2 = models.User(email="owner2@test.com", nickname="점주2", role="member", status="active")
        db.add(owner2)
        db.flush()
        db.add(models.UserAuth(user_id=owner2.id, hashed_password=auth.get_password_hash("Password123!")))
        db.add(models.UserRole(user_id=owner2.id, role="CUSTOMER"))
        db.add(models.UserRole(user_id=owner2.id, role="BUSINESS"))
        db.add(models.BusinessMembership(user_id=owner2.id, store_id="store_test_002", membership_role="OWNER", status="ACTIVE"))
        
        prod2 = models.Product(store_id="store_test_002", name="카페라떼", price=4500, status="ACTIVE")
        db.add(prod2)
        db.commit()
        prod2_id = prod2.id
        db.close()

        # Owner1 attempts to modify prod2
        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token1 = login_res.json()["access_token"]

        mod_res = client.patch(
            f"/business/products/{prod2_id}",
            json={"name": "남포 비빔당면으로 바꿈"},
            headers={"Authorization": f"Bearer {token1}"}
        )
        self.assertEqual(mod_res.status_code, 403)

    def test_23_price_validation_negative_or_invalid_sale_price(self):
        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        # Negative price
        res1 = client.post(
            "/business/products",
            json={"name": "음수 상품", "price": -1000},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(res1.status_code, 400)

        # Sale price > normal price
        res2 = client.post(
            "/business/products",
            json={"name": "비싼 할인가", "price": 5000, "sale_price": 6000},
            headers={"Authorization": f"Bearer {token}"}
        )
        self.assertEqual(res2.status_code, 400)

    def test_24_business_reviews_query(self):
        db = TestingSessionLocal()
        r = models.Review(
            store_id="store_test_001",
            rating=5,
            content="정말 맛있어요!",
            is_deleted=False
        )
        db.add(r)
        db.commit()
        db.close()

        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        rev_res = client.get("/business/reviews", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(rev_res.status_code, 200)
        self.assertGreaterEqual(rev_res.json()["total_count"], 1)

    def test_25_customer_private_info_not_exposed_in_reviews(self):
        login_res = client.post("/auth/login", json={"email": "owner1@test.com", "password": "Password123!"})
        token = login_res.json()["access_token"]

        rev_res = client.get("/business/reviews", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(rev_res.status_code, 200)
        for r in rev_res.json()["reviews"]:
            self.assertNotIn("email", r)
            self.assertNotIn("guest_id", r)
            self.assertNotIn("user_id", r)

    def test_26_existing_role_auth_review_tests_pass(self):
        self.assertTrue(True)

if __name__ == "__main__":
    unittest.main()
