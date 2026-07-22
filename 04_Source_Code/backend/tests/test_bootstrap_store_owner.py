import os
import unittest
from datetime import datetime, timedelta
from fastapi import HTTPException

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_bootstrap.db"

from app.database import SessionLocal, engine, Base
from app import models, schemas, auth
from app.main import validate_and_update_reservation_status
from scripts.bootstrap_store_owner import bootstrap_store_owner

class TestBootstrapStoreOwner(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.Review).delete()
        self.db.query(models.StoreReservation).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.query(models.Store).delete()
        self.db.commit()

        # Create test store K-Lounge
        self.store = models.Store(
            id="31b96920-2eb3-4f93-ab51-546fd8d933d1",
            name="K-Lounge",
            category="체험",
            rating=0.0,
            address="부산광역시 중구 구덕로 50-1 2층",
            description="K-Lounge 매장"
        )
        self.db.add(self.store)
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

    def test_first_time_owner_creation(self):
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
        self.assertEqual(user.nickname, "K-Lounge 운영자")

        # Verify password is saved as hashed and not plaintext
        auth_record = self.db.query(models.UserAuth).filter(models.UserAuth.user_id == user.id).first()
        self.assertIsNotNone(auth_record)
        self.assertNotEqual(auth_record.hashed_password, pwd)
        self.assertTrue(auth.verify_password(pwd, auth_record.hashed_password))

    def test_idempotent_duplicate_creation(self):
        email = "klounge_owner_dup@example.com"
        pwd = "SecureOwnerPwd123!"

        # First run
        status1, user1, msg1 = bootstrap_store_owner(self.db, email, pwd, store_id=self.store.id)
        self.assertEqual(status1, "CREATED")

        # Second run with same email
        status2, user2, msg2 = bootstrap_store_owner(self.db, email, "DifferentPwd456!", store_id=self.store.id)
        self.assertEqual(status2, "ALREADY_CONFIGURED")
        self.assertEqual(user2.id, user1.id)

        # Verify password was NOT overwritten by second run
        auth_record = self.db.query(models.UserAuth).filter(models.UserAuth.user_id == user1.id).first()
        self.assertTrue(auth.verify_password(pwd, auth_record.hashed_password))

        # Verify total user count remains 1 for this email
        count = self.db.query(models.User).filter(models.User.email == email).count()
        self.assertEqual(count, 1)

    def test_existing_member_prevents_auto_promotion(self):
        email = "existing_member@example.com"

        # Pre-create member user
        member = models.User(email=email, nickname="일반회원", role="member", status="active")
        self.db.add(member)
        self.db.commit()

        # Attempt to run bootstrap on existing member email
        status, user, msg = bootstrap_store_owner(self.db, email, "NewPwd123!", store_id=self.store.id)
        self.assertEqual(status, "EXISTING_MEMBER_REQUIRES_APPROVAL")

        # Verify role was NOT altered
        db_user = self.db.query(models.User).filter(models.User.email == email).first()
        self.assertEqual(db_user.role, "member")

    def test_owner_reservation_status_update_permission(self):
        # 1. Create Owner via Bootstrap
        owner_email = "klounge_owner_perm@example.com"
        _, owner, _ = bootstrap_store_owner(self.db, owner_email, "Pwd12345!", store_id=self.store.id)

        # 2. Create Member & Reservation
        member = models.User(email="member_perm@example.com", nickname="예약고객", role="member", status="active")
        self.db.add(member)
        self.db.commit()

        res = models.StoreReservation(
            user_id=member.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res)
        self.db.commit()

        # 3. Owner updates reservation status pending -> confirmed -> completed (Allowed)
        updated = validate_and_update_reservation_status(res, "confirmed", owner, self.db)
        self.assertEqual(updated.status, "confirmed")

        updated = validate_and_update_reservation_status(updated, "completed", owner, self.db)
        self.assertEqual(updated.status, "completed")

if __name__ == "__main__":
    unittest.main()
