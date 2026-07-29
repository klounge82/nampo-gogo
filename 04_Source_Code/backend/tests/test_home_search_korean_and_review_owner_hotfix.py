import unittest
import uuid
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app import models, auth

class TestHomeSearchKoreanAndReviewOwnerHotfix(unittest.TestCase):
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

        # Create public test store with name_ko
        self.store = models.Store(
            id=str(uuid.uuid4()),
            name="K-Lounge",
            category="체험",
            address="부산 중구 남포길 50-1 2층",
            description="K-Lounge 매장 설명입니다.",
            status="영업중",
            rating=5.0
        )
        self.store.name_ko = "케이라운지"
        self.db.add(self.store)

        # Create user (Owner of review)
        self.user = models.User(
            id=str(uuid.uuid4()),
            email="jazzbj_test@example.com",
            nickname="jazzbj",
            role="member",
            status="active"
        )
        self.token = auth.create_access_token({"sub": self.user.id, "role": "member"})
        self.db.add(self.user)
        self.db.commit()

        # Create review linked to user
        self.rev = models.Review(
            id=str(uuid.uuid4()),
            store_id=self.store.id,
            user_id=self.user.id,
            guest_id="guest_1784760839308_2729",
            rating=5,
            content="안녕하세요 후기샘플 1회작성완료 10자 이상 작성.",
            is_deleted=False
        )
        self.db.add(self.rev)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_1_search_korean_full_name_returns_klounge(self):
        res = self.client.get("/search?q=케이라운지")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(len(data["items"]), 1)
        self.assertEqual(data["items"][0]["id"], self.store.id)

    def test_2_search_korean_prefix_returns_klounge(self):
        res = self.client.get("/search?q=케이")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(len(data["items"]), 1)
        self.assertEqual(data["items"][0]["id"], self.store.id)

    def test_3_search_korean_suffix_returns_klounge(self):
        res = self.client.get("/search?q=라운지")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(len(data["items"]), 1)
        self.assertEqual(data["items"][0]["id"], self.store.id)

    def test_4_logged_in_user_returns_is_owner_true_for_review(self):
        res = self.client.get(
            f"/stores/{self.store.id}/reviews",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        self.assertEqual(res.status_code, 200)
        reviews = res.json()
        self.assertEqual(len(reviews), 1)
        self.assertTrue(reviews[0]["is_owner"])
        self.assertTrue(reviews[0]["can_edit"])
        self.assertTrue(reviews[0]["can_delete"])

if __name__ == "__main__":
    unittest.main()
