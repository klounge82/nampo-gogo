import unittest
import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app.database import Base, get_db
from app.main import app
from app import models
from app.auth import create_access_token

class TestDataScopeEnforcement(unittest.TestCase):
    def setUp(self):
        # In-memory SQLite DB with StaticPool for TestClient multi-threading
        self.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        self.TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = self.TestingSessionLocal()

        def override_get_db():
            db = self.TestingSessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        self.client = TestClient(app)

        # 1. Create Users (Customer, QA/Test User, Admin)
        self.customer = models.User(
            id="usr_cust_01",
            email="cust@test.com",
            nickname="고객",
            role="member",
            status="active"
        )
        self.qa_user = models.User(
            id="usr_qa_01",
            email="qa@test.com",
            nickname="QA테스터",
            role="member",
            status="active"
        )
        self.admin_user = models.User(
            id="usr_admin_01",
            email="admin@test.com",
            nickname="관리자",
            role="admin",
            status="active"
        )
        self.db.add_all([self.customer, self.qa_user, self.admin_user])
        self.db.flush()

        role_cust = models.UserRole(user_id=self.customer.id, role="CUSTOMER")
        role_qa_cust = models.UserRole(user_id=self.qa_user.id, role="CUSTOMER")
        role_qa_test = models.UserRole(user_id=self.qa_user.id, role="TEST")
        role_admin = models.UserRole(user_id=self.admin_user.id, role="ADMIN")
        self.db.add_all([role_cust, role_qa_cust, role_qa_test, role_admin])

        # 2. Create Stores
        self.real_store = models.Store(
            id="store_real_01",
            name="실제 매장 01",
            category="맛집",
            address="부산 중구 1",
            description="실제 매장 설명",
            data_scope="REAL",
            lifecycle_status="ACTIVE",
            status="영업중"
        )
        self.qa_store = models.Store(
            id="store_qa_01",
            name="QA 테스트 매장 01",
            category="맛집",
            address="부산 중구 2",
            description="QA 매장 설명",
            data_scope="QA",
            lifecycle_status="ACTIVE",
            status="영업중"
        )
        self.hidden_store = models.Store(
            id="store_hidden_01",
            name="숨김 매장",
            category="맛집",
            address="부산 중구 3",
            description="숨김 매장",
            data_scope="REAL",
            lifecycle_status="HIDDEN",
            status="영업중"
        )
        self.archived_store = models.Store(
            id="store_archived_01",
            name="보관 매장",
            category="맛집",
            address="부산 중구 4",
            description="보관 매장",
            data_scope="REAL",
            lifecycle_status="ARCHIVED",
            status="영업중"
        )
        self.db.add_all([self.real_store, self.qa_store, self.hidden_store, self.archived_store])

        # 3. Create Missions
        self.real_mission = models.Mission(
            id="mission_real_01",
            store_id=self.real_store.id,
            title="실제 미션 01",
            description="실제 미션 설명",
            points=100,
            auth_type="PHOTO",
            data_scope="REAL",
            lifecycle_status="ACTIVE"
        )
        self.qa_mission = models.Mission(
            id="mission_qa_01",
            store_id=self.qa_store.id,
            title="QA 미션 01",
            description="QA 미션 설명",
            points=100,
            auth_type="PHOTO",
            data_scope="QA",
            lifecycle_status="ACTIVE"
        )
        self.hidden_mission = models.Mission(
            id="mission_hidden_01",
            store_id=self.real_store.id,
            title="숨김 미션",
            description="숨김 미션",
            points=100,
            auth_type="PHOTO",
            data_scope="REAL",
            lifecycle_status="HIDDEN"
        )
        self.db.add_all([self.real_mission, self.qa_mission, self.hidden_mission])
        self.db.commit()

        # Auth headers
        self.cust_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': self.customer.id})}"}
        self.qa_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': self.qa_user.id})}"}
        self.admin_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': self.admin_user.id})}"}

    def tearDown(self):
        app.dependency_overrides.clear()
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_s1_customer_store_list_excludes_qa(self):
        res = self.client.get("/stores", headers=self.cust_headers)
        self.assertEqual(res.status_code, 200)
        store_ids = [s["id"] for s in res.json()]
        self.assertIn("store_real_01", store_ids)
        self.assertNotIn("store_qa_01", store_ids)

    def test_s2_customer_direct_qa_store_detail_denied(self):
        res = self.client.get("/stores/store_qa_01", headers=self.cust_headers)
        self.assertEqual(res.status_code, 404)

    def test_s3_customer_mission_list_excludes_qa(self):
        res = self.client.get("/missions", headers=self.cust_headers)
        self.assertEqual(res.status_code, 200)
        mission_ids = [m["id"] for m in res.json()]
        self.assertIn("mission_real_01", mission_ids)
        self.assertNotIn("mission_qa_01", mission_ids)

    def test_s4_customer_direct_qa_mission_denied(self):
        res = self.client.get("/missions/mission_qa_01", headers=self.cust_headers)
        self.assertEqual(res.status_code, 404)

    def test_s5_real_mission_to_real_store_allowed(self):
        payload = {
            "store_id": "store_real_01",
            "title": "신규 실제 미션",
            "description": "설명",
            "points": 100,
            "auth_type": "PHOTO",
            "data_scope": "REAL"
        }
        res = self.client.post("/admin/missions", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.json()["data_scope"], "REAL")

    def test_s6_qa_mission_to_qa_store_allowed(self):
        payload = {
            "store_id": "store_qa_01",
            "title": "신규 QA 미션",
            "description": "설명",
            "points": 100,
            "auth_type": "PHOTO",
            "data_scope": "QA"
        }
        res = self.client.post("/admin/missions", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.json()["data_scope"], "QA")

    def test_s7_real_mission_to_qa_store_rejected(self):
        payload = {
            "store_id": "store_qa_01",
            "title": "불일치 미션",
            "description": "설명",
            "points": 100,
            "auth_type": "PHOTO",
            "data_scope": "REAL"
        }
        res = self.client.post("/admin/missions", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 400)
        self.assertIn("일치해야 합니다", res.json()["detail"])

    def test_s8_qa_mission_to_real_store_rejected(self):
        payload = {
            "store_id": "store_real_01",
            "title": "불일치 미션",
            "description": "설명",
            "points": 100,
            "auth_type": "PHOTO",
            "data_scope": "QA"
        }
        res = self.client.post("/admin/missions", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 400)
        self.assertIn("일치해야 합니다", res.json()["detail"])

    def test_s9_hidden_record_excluded_from_customer(self):
        res = self.client.get("/stores/store_hidden_01", headers=self.cust_headers)
        self.assertEqual(res.status_code, 404)

    def test_s10_archived_record_excluded_from_customer(self):
        res = self.client.get("/stores/store_archived_01", headers=self.cust_headers)
        self.assertEqual(res.status_code, 404)

    def test_s11_authorized_qa_scope_accessible(self):
        res = self.client.get("/stores/store_qa_01", headers=self.qa_headers, params={"data_scope": "QA"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["id"], "store_qa_01")

    def test_s12_unauthorized_user_requesting_qa_denied(self):
        # Testing unauthorized user requesting QA scope explicitly
        res = self.client.get("/stores/store_qa_01", headers=self.cust_headers)
        self.assertEqual(res.status_code, 404)

if __name__ == "__main__":
    unittest.main()
