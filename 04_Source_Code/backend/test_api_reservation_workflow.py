import os
import unittest

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_workflow.db"

from datetime import datetime, timedelta
from fastapi import HTTPException
from app.database import SessionLocal, engine, Base
from app import models, schemas
from app.main import validate_and_update_reservation_status, create_review

class TestReservationWorkflow(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        # Clean up existing test data
        self.db.query(models.Review).delete()
        self.db.query(models.StoreReservation).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.query(models.Store).delete()
        self.db.commit()

        # Create test store
        self.store = models.Store(
            id="31b96920-2eb3-4f93-ab51-546fd8d933d1",
            name="K-Lounge",
            category="카페",
            rating=0.0,
            address="부산 중구 남포길 12",
            description="K-Lounge 매장"
        )
        self.db.add(self.store)

        # Create second store
        self.other_store = models.Store(
            id="other-store-id-9999",
            name="Other Store",
            category="음식점",
            rating=0.0,
            address="부산 중구 남포길 34",
            description="다른 매장"
        )
        self.db.add(self.other_store)

        # Create Admin User
        self.admin_user = models.User(
            email="admin_workflow@gogo.com",
            nickname="관리자",
            role="admin",
            status="active"
        )
        self.db.add(self.admin_user)

        # Create Owner User
        self.owner_user = models.User(
            email="owner_workflow@gogo.com",
            nickname="운영자",
            role="owner",
            status="active"
        )
        self.db.add(self.owner_user)

        # Create Member User A
        self.member_user = models.User(
            email="member_workflow@gogo.com",
            nickname="일반회원A",
            role="member",
            status="active"
        )
        self.db.add(self.member_user)

        # Create Member User B
        self.member_user_b = models.User(
            email="member_b_workflow@gogo.com",
            nickname="일반회원B",
            role="member",
            status="active"
        )
        self.db.add(self.member_user_b)

        self.db.commit()

    def tearDown(self):
        self.db.close()

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_workflow.db"):
            try:
                os.remove("./test_workflow.db")
            except Exception:
                pass

    def test_reservation_status_transitions_and_guards(self):
        # 1. Create Pending Reservation
        res = models.StoreReservation(
            user_id=self.member_user.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res)
        self.db.commit()
        self.db.refresh(res)

        # 2. Transition pending -> confirmed (by Admin)
        updated = validate_and_update_reservation_status(res, "confirmed", self.admin_user, self.db)
        self.assertEqual(updated.status, "confirmed")

        # 3. Transition confirmed -> completed (by Owner)
        updated = validate_and_update_reservation_status(updated, "completed", self.owner_user, self.db)
        self.assertEqual(updated.status, "completed")

        # 4. Attempt invalid transition completed -> pending (Must fail with 400)
        with self.assertRaises(HTTPException) as cm:
            validate_and_update_reservation_status(updated, "pending", self.admin_user, self.db)
        self.assertEqual(cm.exception.status_code, 400)

        # 5. Idempotent check (same status completed -> completed)
        same_res = validate_and_update_reservation_status(updated, "completed", self.admin_user, self.db)
        self.assertEqual(same_res.status, "completed")

    def test_cancelled_reservation_cannot_be_completed(self):
        res = models.StoreReservation(
            user_id=self.member_user.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res)
        self.db.commit()

        # pending -> cancelled
        res_cancelled = validate_and_update_reservation_status(res, "cancelled", self.admin_user, self.db)
        self.assertEqual(res_cancelled.status, "cancelled")

        # cancelled -> completed (Must fail with 400)
        with self.assertRaises(HTTPException) as cm:
            validate_and_update_reservation_status(res_cancelled, "completed", self.admin_user, self.db)
        self.assertEqual(cm.exception.status_code, 400)

    def test_direct_pending_to_completed_allowed(self):
        res = models.StoreReservation(
            user_id=self.member_user.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res)
        self.db.commit()

        res_completed = validate_and_update_reservation_status(res, "completed", self.admin_user, self.db)
        self.assertEqual(res_completed.status, "completed")

    def test_invalid_status_value_rejected(self):
        res = models.StoreReservation(
            user_id=self.member_user.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res)
        self.db.commit()

        with self.assertRaises(HTTPException) as cm:
            validate_and_update_reservation_status(res, "unknown_status", self.admin_user, self.db)
        self.assertEqual(cm.exception.status_code, 400)

    def test_review_authorization_linkage(self):
        # Create pending reservation for Member A
        res_a = models.StoreReservation(
            user_id=self.member_user.id,
            store_id=self.store.id,
            reservation_time=datetime.utcnow() + timedelta(days=1),
            party_size=2,
            status="pending"
        )
        self.db.add(res_a)
        self.db.commit()

        req = schemas.ReviewCreate(
            rating=5,
            content="정말 훌륭하고 만족스러운 매장입니다. 꼭 다시 오겠습니다!",
            user_id=self.member_user.id
        )

        # 1. Review creation while status is pending MUST FAIL with 403
        with self.assertRaises(HTTPException) as cm:
            create_review(self.store.id, req, self.db)
        self.assertEqual(cm.exception.status_code, 403)

        # 2. Change status to completed
        validate_and_update_reservation_status(res_a, "completed", self.admin_user, self.db)

        # 3. Review creation after completion MUST SUCCEED (201)
        review_out = create_review(self.store.id, req, self.db)
        self.assertIsNotNone(review_out.id)
        self.assertEqual(review_out.rating, 5)

        # 4. Member B trying to post review for Member A's reservation MUST FAIL with 403
        req_b = schemas.ReviewCreate(
            rating=4,
            content="타인의 예약으로 작성하려는 리뷰 테스트 내용입니다.",
            user_id=self.member_user_b.id
        )
        with self.assertRaises(HTTPException) as cm:
            create_review(self.store.id, req_b, self.db)
        self.assertEqual(cm.exception.status_code, 403)

        # 5. Member A trying to post review for another store (where they have no completed res) MUST FAIL with 403
        req_other = schemas.ReviewCreate(
            rating=5,
            content="예약 없는 다른 매장에 대한 리뷰 작성 시도입니다.",
            user_id=self.member_user.id
        )
        with self.assertRaises(HTTPException) as cm:
            create_review(self.other_store.id, req_other, self.db)
        self.assertEqual(cm.exception.status_code, 403)

if __name__ == "__main__":
    unittest.main()
