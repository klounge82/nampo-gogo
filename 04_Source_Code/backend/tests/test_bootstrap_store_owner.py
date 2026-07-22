import os
import unittest
from datetime import datetime, timedelta
from fastapi import HTTPException

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_bootstrap.db"

from app.database import SessionLocal, engine, Base
from app import models, schemas, auth
from app.main import validate_and_update_reservation_status, require_store_owner_or_admin
from scripts.bootstrap_store_owner import bootstrap_store_owner

class TestBootstrapStoreOwner(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.Review).delete()
        self.db.query(models.StoreReservation).delete()
        self.db.query(models.StoreOwner).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.query(models.Store).delete()
        self.db.commit()

        # Create test store 1 (K-Lounge)
        self.store = models.Store(
            id="31b96920-2eb3-4f93-ab51-546fd8d933d1",
            name="K-Lounge",
            category="체험",
            rating=0.0,
            address="부산광역시 중구 구덕로 50-1 2층",
            description="K-Lounge 매장"
        )
        self.db.add(self.store)

        # Create test store 2 (Other Store)
        self.other_store = models.Store(
            id="other-store-id-8888",
            name="Other Store",
            category="음식점",
            rating=0.0,
            address="부산광역시 중구 남포길 99",
            description="다른 매장"
        )
        self.db.add(self.other_store)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_bootstrap.db"):
            try:
                os.remove("./test_bootstrap.db")
            except Exception:
                pass

    def test_missing_credentials_returns_input_required(self):
        status, user, msg = bootstrap_store_owner(self.db, "", "")
        self.assertEqual(status, "INPUT_REQUIRED")
        self.assertIsNone(user)

    def test_first_time_owner_creation_with_store_owner_link(self):
        email = "klounge_owner_test@example.com"
        pwd = "SecureOwnerPwd123!"

        status, user, msg = bootstrap_store_owner(
            self.db,
            email=email,
            password=pwd,
            nickname="K-Lounge 운영자",
            store_id=self.store.id,
            role="owner"
        )

        self.assertEqual(status, "CREATED")
        self.assertIsNotNone(user)
        self.assertEqual(user.email, email)
        self.assertEqual(user.role, "owner")

        # Verify StoreOwner record created
        so_record = self.db.query(models.StoreOwner).filter(
            models.StoreOwner.user_id == user.id,
            models.StoreOwner.store_id == self.store.id
        ).first()
        self.assertIsNotNone(so_record)
        self.assertEqual(so_record.status, "active")

    def test_idempotent_duplicate_creation_preserves_single_store_owner_link(self):
        email = "klounge_owner_dup@example.com"
        pwd = "SecureOwnerPwd123!"

        status1, user1, msg1 = bootstrap_store_owner(self.db, email, pwd, store_id=self.store.id)
        self.assertEqual(status1, "CREATED")

        status2, user2, msg2 = bootstrap_store_owner(self.db, email, "DifferentPwd456!", store_id=self.store.id)
        self.assertEqual(status2, "ALREADY_CONFIGURED")

        # Verify StoreOwner count is exactly 1
        so_count = self.db.query(models.StoreOwner).filter(
            models.StoreOwner.user_id == user1.id,
            models.StoreOwner.store_id == self.store.id
        ).count()
        self.assertEqual(so_count, 1)

    def test_existing_member_prevents_auto_promotion(self):
        email = "existing_member@example.com"

        member = models.User(email=email, nickname="일반회원", role="member", status="active")
        self.db.add(member)
        self.db.commit()

        status, user, msg = bootstrap_store_owner(self.db, email, "NewPwd123!", store_id=self.store.id)
        self.assertEqual(status, "EXISTING_MEMBER_REQUIRES_APPROVAL")

        db_user = self.db.query(models.User).filter(models.User.email == email).first()
        self.assertEqual(db_user.role, "member")

    def test_store_scoped_owner_permission_guard(self):
        # 1. Create K-Lounge Owner
        _, owner_k, _ = bootstrap_store_owner(self.db, "owner_k@example.com", "Pwd12345!", store_id=self.store.id)

        # 2. Create Other Store Owner
        _, owner_other, _ = bootstrap_store_owner(self.db, "owner_other@example.com", "Pwd12345!", store_id=self.other_store.id)

        # 3. Create Admin User
        admin = models.User(email="admin_scope@example.com", nickname="총괄관리자", role="admin", status="active")
        self.db.add(admin)

        # 4. Create Member User
        member = models.User(email="member_scope@example.com", nickname="일반고객", role="member", status="active")
        self.db.add(member)
        self.db.commit()

        # Test require_store_owner_or_admin helper
        # Admin -> Allowed for both stores
        self.assertIsNotNone(require_store_owner_or_admin(admin, self.store.id, self.db))
        self.assertIsNotNone(require_store_owner_or_admin(admin, self.other_store.id, self.db))

        # K-Lounge Owner -> Allowed for K-Lounge, Blocked (403) for Other Store
        self.assertIsNotNone(require_store_owner_or_admin(owner_k, self.store.id, self.db))
        with self.assertRaises(HTTPException) as cm:
            require_store_owner_or_admin(owner_k, self.other_store.id, self.db)
        self.assertEqual(cm.exception.status_code, 403)

        # Other Store Owner -> Allowed for Other Store, Blocked (403) for K-Lounge
        self.assertIsNotNone(require_store_owner_or_admin(owner_other, self.other_store.id, self.db))
        with self.assertRaises(HTTPException) as cm:
            require_store_owner_or_admin(owner_other, self.store.id, self.db)
        self.assertEqual(cm.exception.status_code, 403)

        # Regular Member -> Blocked (403) for any store
        with self.assertRaises(HTTPException) as cm:
            require_store_owner_or_admin(member, self.store.id, self.db)
        self.assertEqual(cm.exception.status_code, 403)

if __name__ == "__main__":
    unittest.main()
