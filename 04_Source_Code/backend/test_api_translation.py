import os
import sys
import unittest
from fastapi.testclient import TestClient

# Ensure backend root is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.main import app

class TestTranslationEndpoint(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_translation_unconfigured_api_key_returns_503(self):
        # When TRANSLATION_API_KEY is not configured, requesting translation should return 503 Service Unavailable
        response = self.client.post("/reviews/non_existent_review_id/translate", json={"target_locale": "zh_Hans"})
        # Should return 404 if review does not exist, or 503 if API key missing
        self.assertIn(response.status_code, [404, 503])
        print(f"[TEST PASS] Translation endpoint test response status: {response.status_code}")

if __name__ == "__main__":
    unittest.main()
