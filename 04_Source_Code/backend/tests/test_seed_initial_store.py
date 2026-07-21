import os
import sys
import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend root is in sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import Base
from app import models
from scripts.seed_initial_store import seed_initial_store, K_LOUNGE_SEED_DATA

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

class TestSeedInitialStore(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_seed_initial_store_first_creation_with_confirmed_k_lounge_data(self):
        status, store, message = seed_initial_store(self.db)

        self.assertEqual(status, "CREATED")
        self.assertIsNotNone(store)
        self.assertEqual(store.name, "K-Lounge")
        self.assertEqual(store.category, "체험")
        self.assertEqual(store.address, "부산광역시 중구 구덕로 50-1 2층")
        self.assertEqual(store.phone_number, "051-243-8880")
        self.assertEqual(store.operating_hours, "11:00 - 23:00 (매일, 예약제)")
        self.assertIsNone(store.latitude)
        self.assertIsNone(store.longitude)
        self.assertIsNone(store.image_url)
        self.assertIsNone(store.homepage_url)
        self.assertEqual(store.name_en, "K-Lounge")
        self.assertEqual(self.db.query(models.Store).count(), 1)

    def test_seed_initial_store_idempotent_duplicate(self):
        # 1st execution
        status1, store1, _ = seed_initial_store(self.db)
        self.assertEqual(status1, "CREATED")

        # 2nd execution with default K-Lounge data
        status2, store2, message2 = seed_initial_store(self.db)
        self.assertEqual(status2, "ALREADY_EXISTS")
        self.assertEqual(store2.id, store1.id)
        self.assertEqual(self.db.query(models.Store).count(), 1)
        self.assertIn("이미 존재합니다", message2)

    def test_seed_initial_store_missing_fields(self):
        incomplete_data = {
            "name": "K-Lounge",
            "category": "체험"
            # address and description missing
        }

        status, store, message = seed_initial_store(self.db, incomplete_data)

        self.assertEqual(status, "INPUT_REQUIRED")
        self.assertIsNone(store)
        self.assertIn("필수 필드가 누락되었습니다", message)
        self.assertEqual(self.db.query(models.Store).count(), 0)

    def test_seed_initial_store_no_overwriting_or_other_store_impact(self):
        # Create existing store A
        existing_store = models.Store(
            name="기존 매장 A",
            category="맛집",
            address="부산 중구 구덕로 10",
            description="기존에 존재하는 맛집"
        )
        self.db.add(existing_store)
        self.db.commit()

        # Seed new store
        status, store, _ = seed_initial_store(self.db)

        self.assertEqual(status, "CREATED")
        self.assertEqual(self.db.query(models.Store).count(), 2)

        # Check original store unchanged
        original = self.db.query(models.Store).filter(models.Store.name == "기존 매장 A").first()
        self.assertIsNotNone(original)
        self.assertEqual(original.category, "맛집")

    def test_seed_script_no_mock_fallbacks_or_destructive_sql(self):
        script_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scripts", "seed_initial_store.py")
        with open(script_path, "r", encoding="utf-8") as f:
            content = f.read().upper()

        self.assertNotIn("DROP TABLE", content)
        self.assertNotIn("TRUNCATE", content)
        self.assertNotIn("DELETE FROM", content)
        self.assertNotIn("BASE.METADATA.CREATE_ALL", content)
        self.assertNotIn("051-123-4567", content)
        self.assertNotIn("09:00 - 22:00", content)

if __name__ == "__main__":
    unittest.main()
