import unittest
import uuid
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app import models, auth

class TestHomeSearchAndOwnerControlsHotfix(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def setUp(self):
        self.db = SessionLocal()
        self.client = TestClient(app)

        # Clean tables for test isolation
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.BusinessMembership).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create test store
        self.store = models.Store(
            id=str(uuid.uuid4()),
            name="K-Lounge",
            category="체험",
            address="부산 중구 남포길 50-1 2층",
            description="K-Lounge 매장 설명입니다.",
            status="영업중",
            rating=5.0
        )
        self.db.add(self.store)

        # Create user 1 (Owner)
        self.user1 = models.User(
            id=str(uuid.uuid4()),
            email="owner_test@example.com",
            nickname="리뷰주인",
            role="member",
            status="active"
        )
        self.token1 = auth.create_access_token({"sub": self.user1.id, "role": "member"})

        # Create user 2 (Non-owner)
        self.user2 = models.User(
            id=str(uuid.uuid4()),
            email="other_user@example.com",
            nickname="타인유저",
            role="member",
            status="active"
        )
        self.token2 = auth.create_access_token({"sub": self.user2.id, "role": "member"})

        self.db.add(self.user1)
        self.db.add(self.user2)
        self.db.commit()

        # User 1 active review
        self.rev1 = models.Review(
            id=str(uuid.uuid4()),
            store_id=self.store.id,
            user_id=self.user1.id,
            guest_id="guest_u1_initial",
            rating=5,
            content="유저1의 K-Lounge 방문 후기입니다. 10자 이상 작성.",
            is_deleted=False
        )
        self.db.add(self.rev1)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_1_logged_in_owner_returns_active_my_review(self):
        res = self.client.get(
            f"/stores/{self.store.id}/my-review",
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "ACTIVE")
        self.assertTrue(data["can_edit"])
        self.assertTrue(data["can_delete"])

    def test_2_non_owner_returns_none_my_review(self):
        res = self.client.get(
            f"/stores/{self.store.id}/my-review",
            headers={"Authorization": f"Bearer {self.token2}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "NONE")
        self.assertFalse(data["can_edit"])

    def test_3_missing_auth_header_denies_ownership(self):
        res = self.client.get(f"/stores/{self.store.id}/my-review")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "NONE")

    def test_4_guest_id_mismatch_denies_guest_ownership(self):
        res = self.client.get(
            f"/stores/{self.store.id}/my-review",
            headers={"x-guest-id": "guest_different_9999"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "NONE")

    def test_5_repeated_edits_maintain_owner_permission(self):
        # First edit
        res_e1 = self.client.patch(
            f"/reviews/{self.rev1.id}",
            json={"rating": 5, "content": "첫 번째 수정된 리뷰 내용입니다. 10자 이상."},
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        self.assertEqual(res_e1.status_code, 200)
        self.assertTrue(res_e1.json()["is_owner"])

        # Second edit
        res_e2 = self.client.patch(
            f"/reviews/{self.rev1.id}",
            json={"rating": 5, "content": "두 번째 연속 수정된 리뷰 내용입니다. 10자 이상."},
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        self.assertEqual(res_e2.status_code, 200)
        self.assertTrue(res_e2.json()["is_owner"])
        self.assertTrue(res_e2.json()["can_edit"])

if __name__ == "__main__":
    unittest.main()
