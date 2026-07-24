import unittest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid

from app.main import app
from app.database import Base, engine, SessionLocal
from app import models, auth

class TestReviewIdentityState(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        self.client = TestClient(app)

        # Clear test data
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.UserRole).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create store fixture
        self.store = models.Store(
            id=str(uuid.uuid4()),
            name="남포동 커피스토어",
            category="카페",
            address="부산 중구 남포길 10",
            description="테스트 카페",
            review_verification_type="OPEN_REVIEW",
            status="영업중"
        )
        self.db.add(self.store)
        self.db.commit()

        # Create User A fixture
        self.user_a = models.User(
            id=str(uuid.uuid4()),
            email="usera_test@nampo.com",
            nickname="유저A",
            role="member"
        )
        self.db.add(self.user_a)
        self.db.commit()
        self.db.add(models.UserRole(user_id=self.user_a.id, role="CUSTOMER"))
        self.db.commit()

        # Create User B fixture
        self.user_b = models.User(
            id=str(uuid.uuid4()),
            email="userb_test@nampo.com",
            nickname="유저B",
            role="member"
        )
        self.db.add(self.user_b)
        self.db.commit()
        self.db.add(models.UserRole(user_id=self.user_b.id, role="CUSTOMER"))
        self.db.commit()

        self.token_a = auth.create_access_token(data={"sub": self.user_a.id, "email": self.user_a.email})
        self.token_b = auth.create_access_token(data={"sub": self.user_b.id, "email": self.user_b.email})

    def tearDown(self):
        self.db.close()

    def test_1_active_review_returns_my_review_active(self):
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=5,
            content="정말 좋은 맛집입니다. 강력 추천합니다!",
            is_deleted=False,
            deleted_at=None
        )
        self.db.add(rev)
        self.db.commit()

        res = self.client.get(f"/stores/{self.store.id}/my-review?user_id={self.user_a.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "ACTIVE")
        self.assertTrue(data["can_edit"])
        self.assertTrue(data["can_delete"])
        self.assertFalse(data["can_restore"])
        self.assertNotNull = self.assertIsNotNone(data["review"])

    def test_2_deleted_review_returns_my_review_deleted(self):
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=4,
            content="삭제된 후기 테스트 내용입니다. 최소 10자 이상 작성.",
            is_deleted=True,
            deleted_at=datetime.utcnow()
        )
        self.db.add(rev)
        self.db.commit()

        res = self.client.get(f"/stores/{self.store.id}/my-review?user_id={self.user_a.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "DELETED")
        self.assertFalse(data["can_edit"])
        self.assertFalse(data["can_delete"])
        self.assertTrue(data["can_restore"])
        self.assertTrue(data["can_rewrite"])

    def test_3_other_user_review_does_not_block_current_user(self):
        # User A has a review
        rev_a = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=5,
            content="유저A가 작성한 훌륭한 리뷰입니다.",
            is_deleted=False
        )
        self.db.add(rev_a)
        self.db.commit()

        # User B creates review -> Should succeed with 201 Created!
        res_b = self.client.post(
            f"/stores/{self.store.id}/reviews",
            json={
                "rating": 5,
                "content": "유저B가 작성한 신규 리뷰입니다. 최소 10자 이상.",
                "user_id": self.user_b.id
            }
        )
        self.assertEqual(res_b.status_code, 201)

    def test_4_orphan_used_verification_allows_new_review(self):
        # Orphan USED verification with no review linked
        v_orphan = models.VisitVerification(
            id=str(uuid.uuid4()),
            store_id=self.store.id,
            user_id=self.user_a.id,
            verification_method="OPEN",
            status="USED",
            expires_at=datetime.utcnow() + timedelta(hours=24),
            review_used_at=datetime.utcnow()
        )
        self.db.add(v_orphan)
        self.db.commit()

        # Creating review for User A should succeed!
        res = self.client.post(
            f"/stores/{self.store.id}/reviews",
            json={
                "rating": 5,
                "content": "고아 USED 방문 인증이 있어도 리뷰 작성이 정상 허용됩니다.",
                "user_id": self.user_a.id
            }
        )
        self.assertEqual(res.status_code, 201)

    def test_5_guest_review_linked_to_user_maintains_same_review_id(self):
        guest_id = "test_guest_uuid_12345"
        rev_guest = models.Review(
            id=str(uuid.uuid4()),
            user_id=None,
            guest_id=guest_id,
            store_id=self.store.id,
            rating=5,
            content="게스트 상태에서 작성한 리뷰입니다.",
            is_deleted=False
        )
        self.db.add(rev_guest)
        self.db.commit()
        original_review_id = rev_guest.id

        # User signs up with guest_id header
        res_signup = self.client.post(
            "/auth/signup",
            json={
                "email": "new_signup_user@nampo.com",
                "password": "Password123!",
                "nickname": "신규회원"
            },
            headers={"x-guest-id": guest_id}
        )
        self.assertEqual(res_signup.status_code, 201)

        self.db.expire_all()
        linked_rev = self.db.query(models.Review).filter_by(id=original_review_id).first()
        self.assertEqual(linked_rev.id, original_review_id)
        self.assertIsNotNone(linked_rev.user_id)

    def test_6_logged_out_guest_cannot_claim_linked_user_review(self):
        guest_id = "test_guest_uuid_67890"
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            guest_id=guest_id, # Previously linked to User A
            store_id=self.store.id,
            rating=5,
            content="회원에 연결된 후기입니다.",
            is_deleted=False
        )
        self.db.add(rev)
        self.db.commit()

        # Logged-out guest queries my-review with guest_id
        res_guest = self.client.get(
            f"/stores/{self.store.id}/my-review",
            headers={"x-guest-id": guest_id}
        )
        self.assertEqual(res_guest.status_code, 200)
        self.assertEqual(res_guest.json()["status"], "NONE")

    def test_7_multiple_edits_maintain_owner_permission(self):
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=4,
            content="첫 번째 수정 전 원본 내용입니다.",
            is_deleted=False
        )
        self.db.add(rev)
        self.db.commit()

        # Edit 1
        res1 = self.client.patch(
            f"/reviews/{rev.id}",
            json={"rating": 5, "content": "첫 번째 수정 완료된 리뷰 내용입니다.", "user_id": self.user_a.id}
        )
        self.assertEqual(res1.status_code, 200)
        self.assertTrue(res1.json()["can_edit"])

        # Edit 2
        res2 = self.client.patch(
            f"/reviews/{rev.id}",
            json={"rating": 5, "content": "두 번째 연속 수정 완료된 리뷰 내용입니다.", "user_id": self.user_a.id}
        )
        self.assertEqual(res2.status_code, 200)
        self.assertTrue(res2.json()["can_edit"])

    def test_8_delete_restore_rewrite_do_not_require_qr(self):
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=5,
            content="삭제 및 복구 테스트 리뷰 내용입니다.",
            is_deleted=False
        )
        self.db.add(rev)
        self.db.commit()

        # Delete -> 200
        res_del = self.client.delete(f"/reviews/{rev.id}?user_id={self.user_a.id}")
        self.assertEqual(res_del.status_code, 200)

        # Restore -> 200 (No QR required)
        res_restore = self.client.post(f"/reviews/{rev.id}/restore?user_id={self.user_a.id}")
        self.assertEqual(res_restore.status_code, 200)

    def test_9_72h_duplicate_review_policy_enforced(self):
        rev = models.Review(
            id=str(uuid.uuid4()),
            user_id=self.user_a.id,
            store_id=self.store.id,
            rating=5,
            content="최근 72시간 이내 작성된 리뷰입니다.",
            is_deleted=False,
            created_at=datetime.utcnow() - timedelta(hours=2)
        )
        self.db.add(rev)
        self.db.commit()

        # Creating another review within 72h -> 409 Conflict
        res = self.client.post(
            f"/stores/{self.store.id}/reviews",
            json={
                "rating": 5,
                "content": "72시간 이내 중복 리뷰 작성 시도입니다.",
                "user_id": self.user_a.id
            }
        )
        self.assertEqual(res.status_code, 409)

if __name__ == "__main__":
    unittest.main()
