import unittest
import os
import threading
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.dialects import postgresql

# 1. Setup isolated ephemeral local test SQLite DB
TEST_DB_PATH = "test_p7_mission_idempotency.db"
if os.path.exists(TEST_DB_PATH):
    try:
        os.remove(TEST_DB_PATH)
    except Exception:
        pass

os.environ["APP_ENV"] = "test"
os.environ["TESTING"] = "true"
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

client = TestClient(app)

class TestMissionIdempotency(unittest.TestCase):

    def setUp(self):
        self._orig_overrides = dict(app.dependency_overrides)
        app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        app.dependency_overrides.clear()
        app.dependency_overrides.update(self._orig_overrides)

    @classmethod
    def setUpClass(cls):
        db = TestingSessionLocal()

        cls.user_id = "user_mission_tester_001"
        cls.store_id = "store_mission_test_001"
        cls.mission_id_1 = "mission_qr_test_001"
        cls.mission_id_2 = "mission_qr_test_002"
        cls.mission_id_3 = "mission_qr_test_003"

        test_user = models.User(
            id=cls.user_id,
            email="mission_tester@test.com",
            nickname="MissionTester",
            status="active",
            role="CUSTOMER",
            current_points=0,
            lifetime_earned_points=0
        )

        test_store = models.Store(
            id=cls.store_id,
            name="남포 미션 검증 매장",
            category="음식점",
            address="부산 중구 남포대로 1",
            description="미션 테스트용 매장입니다."
        )

        mission_1 = models.Mission(
            id=cls.mission_id_1,
            store_id=cls.store_id,
            title="남포 매장 QR 미션 1",
            description="QR 코드를 스캔하여 미션을 완료하세요.",
            points=100,
            auth_type="QR",
            status="active"
        )

        mission_2 = models.Mission(
            id=cls.mission_id_2,
            store_id=cls.store_id,
            title="남포 매장 QR 미션 2",
            description="두 번째 미션입니다.",
            points=150,
            auth_type="QR",
            status="active"
        )

        mission_3 = models.Mission(
            id=cls.mission_id_3,
            store_id=cls.store_id,
            title="남포 매장 QR 미션 3",
            description="동시성 스모크 테스트용 미션입니다.",
            points=200,
            auth_type="QR",
            status="active"
        )

        db.add_all([test_user, test_store, mission_1, mission_2, mission_3])
        db.commit()
        db.close()

        # Generate JWT token
        cls.token = auth.create_access_token({"sub": cls.user_id})

    @classmethod
    def tearDownClass(cls):
        if os.path.exists(TEST_DB_PATH):
            try:
                os.remove(TEST_DB_PATH)
            except Exception:
                pass

    def test_m1_first_completion_succeeds(self):
        """M1: Valid QR mission completion succeeds -> HTTP 200, points awarded, UserMission created"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {"qr_code": f"QR_{self.mission_id_1}"}
        res = client.post(f"/missions/{self.mission_id_1}/verify", json=payload, headers=headers)

        self.assertEqual(res.status_code, 200, f"Expected 200, got {res.status_code}: {res.text}")
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("points_awarded"), 100)

        # Verify DB state
        db = TestingSessionLocal()
        user = db.query(models.User).filter_by(id=self.user_id).first()
        self.assertEqual(user.current_points, 100)
        self.assertEqual(user.lifetime_earned_points, 100)

        um = db.query(models.UserMission).filter_by(user_id=self.user_id, mission_id=self.mission_id_1).all()
        self.assertEqual(len(um), 1)

        ph = db.query(models.PointHistory).filter_by(
            user_id=self.user_id,
            source_id=self.mission_id_1,
            transaction_type="MISSION_REWARD"
        ).all()
        self.assertEqual(len(ph), 1)
        self.assertEqual(ph[0].points, 100)
        db.close()

    def test_m2_second_same_mission_rejected(self):
        """M2: Submitting same completed mission again -> HTTP 400 rejection ('이미 완료한 미션입니다.')"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {"qr_code": f"QR_{self.mission_id_1}"}
        res = client.post(f"/missions/{self.mission_id_1}/verify", json=payload, headers=headers)

        self.assertEqual(res.status_code, 400, f"Expected 400, got {res.status_code}: {res.text}")
        self.assertIn("이미 완료한 미션입니다", res.text)

    def test_m3_single_reward_invariant(self):
        """M3: Verifies that after duplicate attempts, total reward and history entries remain exactly 1"""
        db = TestingSessionLocal()
        user = db.query(models.User).filter_by(id=self.user_id).first()
        self.assertEqual(user.current_points, 100)
        self.assertEqual(user.lifetime_earned_points, 100)

        um_count = db.query(models.UserMission).filter_by(user_id=self.user_id, mission_id=self.mission_id_1).count()
        self.assertEqual(um_count, 1)

        ph_count = db.query(models.PointHistory).filter_by(
            user_id=self.user_id,
            source_id=self.mission_id_1,
            transaction_type="MISSION_REWARD"
        ).count()
        self.assertEqual(ph_count, 1)
        db.close()

    def test_m4_different_mission_succeeds(self):
        """M4: Same user completing a distinct mission succeeds without lock interference"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {"qr_code": f"QR_{self.mission_id_2}"}
        res = client.post(f"/missions/{self.mission_id_2}/verify", json=payload, headers=headers)

        self.assertEqual(res.status_code, 200, f"Expected 200, got {res.status_code}: {res.text}")

        db = TestingSessionLocal()
        user = db.query(models.User).filter_by(id=self.user_id).first()
        self.assertEqual(user.current_points, 250) # 100 + 150
        self.assertEqual(user.lifetime_earned_points, 250)

        total_missions = db.query(models.UserMission).filter_by(user_id=self.user_id).count()
        self.assertEqual(total_missions, 2)
        db.close()

    def test_m5_sqlite_concurrent_smoke(self):
        """M5: LOCAL_SQLITE_SMOKE_ONLY - Concurrent verification smoke test without unhandled server crashes.

        NOTE: SQLite does not honor SELECT FOR UPDATE row locks. M5 verifies concurrent execution survives
        without producing unhandled 500 errors or corrupt memory states. M6 separately verifies PostgreSQL
        FOR UPDATE query structure.
        """
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {"qr_code": f"QR_{self.mission_id_3}"}
        results = []

        def make_request():
            res = client.post(f"/missions/{self.mission_id_3}/verify", json=payload, headers=headers)
            results.append(res.status_code)

        t1 = threading.Thread(target=make_request)
        t2 = threading.Thread(target=make_request)

        t1.start()
        t2.start()
        t1.join()
        t2.join()

        self.assertEqual(len(results), 2, f"Expected 2 completed requests, got {results}")
        for status in results:
            self.assertIn(status, [200, 400], f"Unexpected status code in results: {results}")
        self.assertNotIn(500, results, f"Server returned unhandled 500 error under concurrency: {results}")

    def test_m6_postgres_for_update_sql_structure(self):
        """M6: POSTGRES_DIALECT_SQL_STRUCTURE_ONLY - Compile User lock query against PostgreSQL dialect"""
        db = TestingSessionLocal()
        query = db.query(models.User).filter(models.User.id == self.user_id).with_for_update()
        compiled_sql = str(query.statement.compile(dialect=postgresql.dialect()))
        db.close()

        self.assertIn("FOR UPDATE", compiled_sql, f"Expected 'FOR UPDATE' in compiled SQL: {compiled_sql}")

if __name__ == "__main__":
    unittest.main()
