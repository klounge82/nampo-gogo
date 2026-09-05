import os
import unittest
import base64
import ast

os.environ["DATABASE_URL"] = "sqlite:///./test_profile_image_url_res.db"

from app.database import Base, SessionLocal, engine
from app import models, schemas, auth
from fastapi.testclient import TestClient
from app.main import app

class TestProfileImageUrlResolution(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_profile_image_url_res.db"):
            try:
                os.remove("./test_profile_image_url_res.db")
            except OSError:
                pass

    def setUp(self):
        self.original_public_base = os.environ.get("PUBLIC_BASE_URL")
        self.db = SessionLocal()
        self.db.query(models.UserRole).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        self.user = models.User(
            id="usr_profile_url_001",
            email="url_tester@nampogogo.com",
            nickname="URL테스터",
            role="member",
            status="active",
            current_points=100,
            lifetime_earned_points=100,
            language_code="ko",
            profile_image_url=None
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

        # Valid 1x1 PNG image base64
        self.valid_png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

    def tearDown(self):
        if self.original_public_base is not None:
            os.environ["PUBLIC_BASE_URL"] = self.original_public_base
        else:
            os.environ.pop("PUBLIC_BASE_URL", None)
        self.db.close()

    def test_1_public_base_url_precedence(self):
        os.environ["PUBLIC_BASE_URL"] = "https://example.test"
        client = TestClient(app, base_url="http://testserver")

        payload = {
            "filename": "avatar.png",
            "base64_data": self.valid_png_b64
        }
        res = client.post("/users/me/profile-image", json=payload, headers=self.headers)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()
        self.assertTrue(data["success"])
        self.assertTrue(data["profile_image_url"].startswith("https://example.test/static/profile_images/"))
        self.assertTrue(data["profile_image_url"].endswith(".png"))

        # Verify DB persisted URL
        self.db.expire_all()
        user_db = self.db.query(models.User).filter(models.User.id == self.user.id).first()
        self.assertEqual(user_db.profile_image_url, data["profile_image_url"])

    def test_2_request_base_url_fallback(self):
        os.environ.pop("PUBLIC_BASE_URL", None)
        client = TestClient(app, base_url="http://192.168.35.140:18080")

        payload = {
            "filename": "avatar.png",
            "base64_data": self.valid_png_b64
        }
        res = client.post("/users/me/profile-image", json=payload, headers=self.headers)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()
        self.assertTrue(data["success"])
        self.assertTrue(data["profile_image_url"].startswith("http://192.168.35.140:18080/static/profile_images/"))
        self.assertTrue(data["profile_image_url"].endswith(".png"))

        # Verify DB persisted URL
        self.db.expire_all()
        user_db = self.db.query(models.User).filter(models.User.id == self.user.id).first()
        self.assertEqual(user_db.profile_image_url, data["profile_image_url"])

    def test_3_no_hardcoded_10_0_2_2_in_upload_profile_image(self):
        main_file = os.path.join(os.path.dirname(os.path.dirname(__file__)), "app", "main.py")
        with open(main_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Find upload_profile_image function definition and ensure 10.0.2.2 is not in it
        tree = ast.parse(content)
        found = False
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name == "upload_profile_image":
                found = True
                fn_source = ast.get_source_segment(content, node)
                self.assertNotIn("10.0.2.2", fn_source)
        self.assertTrue(found, "upload_profile_image function not found in main.py")

    def test_4_delete_profile_image_resets_to_none_and_returns_valid_user_out(self):
        client = TestClient(app, base_url="http://192.168.35.140:18080")

        # First upload
        os.environ.pop("PUBLIC_BASE_URL", None)
        payload = {"filename": "avatar.png", "base64_data": self.valid_png_b64}
        up_res = client.post("/users/me/profile-image", json=payload, headers=self.headers)
        self.assertEqual(up_res.status_code, 200)

        # Then delete
        del_res = client.delete("/users/me/profile-image", headers=self.headers)
        self.assertEqual(del_res.status_code, 200)
        data = del_res.json()
        self.assertIsNone(data["profile_image_url"])
        self.assertEqual(data["id"], self.user.id)
        self.assertEqual(data["email"], self.user.email)
        self.assertIn("CUSTOMER", data["roles"])

if __name__ == "__main__":
    unittest.main()
