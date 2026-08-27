import os
import unittest
import uuid
import datetime

os.environ["DATABASE_URL"] = "sqlite:///./test_admin_users_role_contract.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app, user_to_user_out

class TestAdminUsersRoleContract(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.UserRole).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create Admin User with multiple roles (CUSTOMER, ADMIN)
        self.admin_user = models.User(
            id="usr_test_admin_001",
            email="test_admin@nampogogo.com",
            nickname="Test Admin",
            role="admin",
            status="active",
            current_points=300,
            lifetime_earned_points=300,
            language_code="ko"
        )
        self.db.add(self.admin_user)
        self.db.flush()

        role1 = models.UserRole(user_id=self.admin_user.id, role="CUSTOMER")
        role2 = models.UserRole(user_id=self.admin_user.id, role="ADMIN")
        self.db.add_all([role1, role2])
        self.db.commit()

        # Create auth token for admin
        self.token = auth.create_access_token(data={"sub": self.admin_user.id})

    def tearDown(self):
        self.db.close()

    def test_user_to_user_out_mapper_converts_user_role_orm_to_list_of_strings(self):
        # Refresh user from DB with relationship
        user = self.db.query(models.User).filter(models.User.id == self.admin_user.id).first()
        user_out = user_to_user_out(user)

        self.assertIsNotNone(user_out)
        self.assertIsInstance(user_out, schemas.UserOut)
        self.assertIsInstance(user_out.roles, list)
        self.assertEqual(len(user_out.roles), 2)
        self.assertEqual(user_out.roles, ["CUSTOMER", "ADMIN"])
        self.assertIsInstance(user_out.roles[0], str)
        self.assertEqual(user_out.current_points, 300)
        self.assertEqual(user_out.lifetime_earned_points, 300)

    def test_get_admin_users_api_returns_http_200_and_serialized_roles_list(self):
        headers = {"Authorization": f"Bearer {self.token}"}
        response = self.client.get("/admin/users", headers=headers)

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIsInstance(data, list)
        self.assertGreaterEqual(len(data), 1)

        admin_item = [u for u in data if u["id"] == self.admin_user.id][0]
        self.assertEqual(admin_item["email"], "test_admin@nampogogo.com")
        self.assertIsInstance(admin_item["roles"], list)
        self.assertIn("CUSTOMER", admin_item["roles"])
        self.assertIn("ADMIN", admin_item["roles"])

    def test_non_admin_access_rejected_with_403(self):
        member_user = models.User(
            id="usr_test_member_002",
            email="test_member@nampogogo.com",
            nickname="Test Member",
            role="member",
            status="active"
        )
        self.db.add(member_user)
        self.db.commit()

        member_token = auth.create_access_token(data={"sub": member_user.id})
        headers = {"Authorization": f"Bearer {member_token}"}
        response = self.client.get("/admin/users", headers=headers)

        self.assertEqual(response.status_code, 403)

if __name__ == "__main__":
    unittest.main()
