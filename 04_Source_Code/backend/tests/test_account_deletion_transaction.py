import unittest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid

from app.main import app, get_db
from app.database import Base
from app import models
from app.auth import create_access_token, get_password_hash

from sqlalchemy.pool import StaticPool

# Use isolated in-memory SQLite database for test suite
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


class TestAccountDeletionTransaction(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.db = TestingSessionLocal()
        # Clean users and related tables before each test
        self.db.query(models.NotificationToken).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.BusinessMembership).delete()
        self.db.query(models.StoreOwner).delete()
        self.db.query(models.User).delete()
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def _create_test_user(self, email, nickname="일반회원", role="CUSTOMER", status="active"):
        user_id = str(uuid.uuid4())
        user = models.User(
            id=user_id,
            email=email,
            nickname=nickname,
            role=role,
            status=status,
        )
        self.db.add(user)
        self.db.commit()

        user_auth = models.UserAuth(
            user_id=user_id,
            hashed_password=get_password_hash("password123"),
        )
        token = models.NotificationToken(
            user_id=user_id,
            device_id="device_123",
            device_type="android",
            fcm_token="fcm_token_123",
            is_active=True,
        )
        self.db.add(user_auth)
        self.db.add(token)
        self.db.commit()
        self.db.refresh(user)
        return user

    def test_01_unauthenticated_deletion_returns_401(self):
        res = self.client.delete("/users/me")
        self.assertEqual(res.status_code, 401)

    def test_02_normal_user_account_deletion_transaction_success(self):
        user = self._create_test_user("delete_test_1@example.com", nickname="탈퇴전닉네임")
        token = create_access_token(data={"sub": user.id, "email": user.email, "role": user.role})

        res = self.client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["success"])

        # Check DB State directly (expire cached instances in test session)
        self.db.expire_all()
        db_user = self.db.query(models.User).filter(models.User.id == user.id).first()
        self.assertEqual(db_user.status, "withdrawn")
        self.assertEqual(db_user.nickname, "탈퇴한 사용자")
        self.assertEqual(db_user.email, f"withdrawn_{user.id}@deleted.local")
        self.assertIsNone(db_user.profile_image_url)

        # Check UserAuth deleted
        user_auth = self.db.query(models.UserAuth).filter(models.UserAuth.user_id == user.id).first()
        self.assertIsNone(user_auth)

        # Check NotificationToken deactivated
        notif_token = self.db.query(models.NotificationToken).filter(models.NotificationToken.user_id == user.id).first()
        self.assertFalse(notif_token.is_active)

    def test_03_owner_account_deletion_blocked_with_409(self):
        user = self._create_test_user("owner_test_1@example.com", role="BUSINESS")
        store_id = str(uuid.uuid4())
        owner_entry = models.StoreOwner(
            user_id=user.id,
            store_id=store_id,
            status="active",
        )
        self.db.add(owner_entry)
        self.db.commit()

        token = create_access_token(data={"sub": user.id, "email": user.email, "role": user.role})
        res = self.client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})

        self.assertEqual(res.status_code, 409)
        self.assertIn("소유 중인 사업장", res.json()["detail"])

        # Ensure user status was NOT changed
        db_user = self.db.query(models.User).filter(models.User.id == user.id).first()
        self.assertEqual(db_user.status, "active")

    def test_04_withdrawn_user_token_reuse_returns_403(self):
        user = self._create_test_user("delete_test_2@example.com")
        token = create_access_token(data={"sub": user.id, "email": user.email, "role": user.role})

        # Withdraw
        res_del = self.client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(res_del.status_code, 200)

        # Reuse same token to access protected API
        res_me = self.client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(res_me.status_code, 403)
        self.assertIn("탈퇴 처리된 사용자", res_me.json()["detail"])

    def test_05_login_with_original_email_fails_after_withdrawal(self):
        email = "delete_test_3@example.com"
        user = self._create_test_user(email)
        token = create_access_token(data={"sub": user.id, "email": user.email, "role": user.role})

        # Withdraw
        self.client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})

        # Attempt Login with original email & password
        res_login = self.client.post("/auth/login", json={"email": email, "password": "password123"})
        self.assertEqual(res_login.status_code, 401)

    def test_06_already_withdrawn_re_request_handled_safely(self):
        user = self._create_test_user("delete_test_4@example.com", status="withdrawn")
        token = create_access_token(data={"sub": user.id, "email": user.email, "role": user.role})

        # Re-request withdrawal on already withdrawn account token
        # get_current_user blocks status=='withdrawn' with 403
        res = self.client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(res.status_code, 403)


if __name__ == "__main__":
    unittest.main()
