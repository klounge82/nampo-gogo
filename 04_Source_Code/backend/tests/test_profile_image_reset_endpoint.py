import os
import unittest
import uuid
import datetime

os.environ["DATABASE_URL"] = "sqlite:///./test_profile_image_reset.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app

class TestProfileImageResetEndpoint(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_profile_image_reset.db"):
            try:
                os.remove("./test_profile_image_reset.db")
            except OSError:
                pass

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.UserRole).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create test customer user with existing non-null profile image
        self.user = models.User(
            id="usr_profile_img_001",
            email="profile_tester@nampogogo.com",
            nickname="이미지테스터",
            role="member",
            status="active",
            current_points=500,
            lifetime_earned_points=1000,
            language_code="ko",
            profile_image_url="http://10.0.2.2:18080/static/profile_images/sample_avatar.png"
        )
        self.db.add(self.user)
        self.db.flush()

        role = models.UserRole(user_id=self.user.id, role="CUSTOMER")
        self.db.add(role)

        hashed_pwd = auth.get_password_hash("TestPassword123!")
        user_auth = models.UserAuth(user_id=self.user.id, hashed_password=hashed_pwd)
        self.db.add(user_auth)
        self.db.commit()

        self.token = auth.create_access_token(data={"sub": self.user.id})
        self.headers = {"Authorization": f"Bearer {self.token}"}

    def tearDown(self):
        self.db.close()

    def test_delete_profile_image_resets_url_and_returns_valid_user_out(self):
        # 1. Verify precondition: DB has non-null profile image
        user_before = self.db.query(models.User).filter(models.User.id == self.user.id).first()
        self.assertIsNotNone(user_before.profile_image_url)
        self.assertEqual(user_before.profile_image_url, "http://10.0.2.2:18080/static/profile_images/sample_avatar.png")

        # 2. Call DELETE /users/me/profile-image
        response = self.client.delete("/users/me/profile-image", headers=self.headers)

        # 3. Assert HTTP 200 OK (no 500 ResponseValidationError)
        self.assertEqual(response.status_code, 200, f"Expected 200 OK, got {response.status_code}: {response.text}")
        data = response.json()

        # 4. Assert profile_image_url in response is null
        self.assertIsNone(data["profile_image_url"])

        # 5. Assert schemas.UserOut composite fields serialize correctly
        self.assertEqual(data["id"], self.user.id)
        self.assertEqual(data["email"], self.user.email)
        self.assertEqual(data["nickname"], "이미지테스터")
        self.assertIn("CUSTOMER", data["roles"])
        self.assertIn("CUSTOMER", data["available_app_modes"])
        self.assertIn("business_application_status", data)
        self.assertIn("business_memberships", data)
        self.assertIn("capabilities", data)

        # 6. Verify in DB directly that profile_image_url is None
        self.db.expire_all()
        user_after = self.db.query(models.User).filter(models.User.id == self.user.id).first()
        self.assertIsNone(user_after.profile_image_url)

if __name__ == "__main__":
    unittest.main()
