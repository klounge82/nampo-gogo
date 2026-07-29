import unittest
import uuid
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app import models

class TestKLoungeStoreMismatchHotfix(unittest.TestCase):
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

        # 1. Public K-Lounge fixture
        self.public_klounge = models.Store(
            id=str(uuid.uuid4()),
            name="K-Lounge",
            category="체험",
            address="부산 중구 남포길 50-1 2층",
            description="공개 K-Lounge 매장입니다.",
            status="영업중",
            rating=5.0
        )
        self.db.add(self.public_klounge)

        # 2. Draft 케이라운지 fixture
        self.draft_klounge = models.Store(
            id=str(uuid.uuid4()),
            name="케이라운지",
            category="일반",
            address="부산 중구",
            description="DRAFT 사업자 등록 매장입니다.",
            status="DRAFT",
            rating=0.0
        )
        self.db.add(self.draft_klounge)
        self.db.commit()

        # 3. Add 2 ACTIVE reviews to Public K-Lounge
        self.rev1 = models.Review(
            id=str(uuid.uuid4()),
            store_id=self.public_klounge.id,
            rating=5,
            content="첫 번째 활성 후기 내용입니다. 10자 이상 작성.",
            is_deleted=False
        )
        self.rev2 = models.Review(
            id=str(uuid.uuid4()),
            store_id=self.public_klounge.id,
            rating=5,
            content="두 번째 활성 후기 내용입니다. 10자 이상 작성.",
            is_deleted=False
        )
        self.db.add(self.rev1)
        self.db.add(self.rev2)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_1_public_klounge_returns_2_active_reviews(self):
        res = self.client.get(f"/stores/{self.public_klounge.id}/reviews")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(len(data), 2)
        ids = [r["id"] for r in data]
        self.assertIn(self.rev1.id, ids)
        self.assertIn(self.rev2.id, ids)

    def test_2_draft_klounge_excluded_from_public_search_and_stores(self):
        # GET /stores
        res_stores = self.client.get("/stores")
        self.assertEqual(res_stores.status_code, 200)
        store_ids = [s["id"] for s in res_stores.json()]
        self.assertIn(self.public_klounge.id, store_ids)
        self.assertNotIn(self.draft_klounge.id, store_ids)

        # GET /search?q=케이라운지
        res_search = self.client.get("/search?q=케이라운지")
        self.assertEqual(res_search.status_code, 200)
        search_items = res_search.json().get("items", [])
        search_ids = [item["id"] for item in search_items]
        self.assertNotIn(self.draft_klounge.id, search_ids)

    def test_3_store_reviews_isolation(self):
        # Public store has 2 reviews, Draft store has 0 reviews
        res_pub = self.client.get(f"/stores/{self.public_klounge.id}/reviews")
        res_draft = self.client.get(f"/stores/{self.draft_klounge.id}/reviews")
        self.assertEqual(len(res_pub.json()), 2)
        self.assertEqual(len(res_draft.json()), 0)

    def test_4_no_store_review_deletion_or_modification(self):
        pub_store_in_db = self.db.query(models.Store).filter_by(id=self.public_klounge.id).first()
        draft_store_in_db = self.db.query(models.Store).filter_by(id=self.draft_klounge.id).first()
        self.assertIsNotNone(pub_store_in_db)
        self.assertIsNotNone(draft_store_in_db)
        self.assertEqual(pub_store_in_db.status, "영업중")
        self.assertEqual(draft_store_in_db.status, "DRAFT")

if __name__ == "__main__":
    unittest.main()
