import unittest
import io
import json
import contextlib
from fastapi import FastAPI, HTTPException, status
from fastapi.testclient import TestClient
from app.main import RequestLoggingMiddleware

class TestStructuredRequestLogging(unittest.TestCase):

    def setUp(self):
        # Create minimal isolated test app
        self.app = FastAPI()
        self.app.add_middleware(RequestLoggingMiddleware)

        @self.app.get("/test-normal")
        def normal_endpoint():
            return {"message": "hello world"}

        @self.app.post("/test-login")
        def sensitive_endpoint():
            return {"token": "dummy_auth_token"}

        @self.app.get("/test-error")
        def error_endpoint():
            raise RuntimeError("downstream_test_failure")

        self.client = TestClient(self.app, raise_server_exceptions=False)

    def _get_access_logs(self, buf_value: str):
        logs = []
        for line in buf_value.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                if isinstance(data, dict) and data.get("event") == "access_log":
                    logs.append(data)
            except Exception:
                continue
        return logs

    def test_l1_emits_valid_json(self):
        """L1: Normal request emits at least one valid JSON access_log line"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.get("/test-normal")

        self.assertEqual(res.status_code, 200)
        logs = self._get_access_logs(buf.getvalue())
        self.assertGreaterEqual(len(logs), 1)

    def test_l2_required_fields(self):
        """L2: Log payload contains all required fields"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.get("/test-normal")

        logs = self._get_access_logs(buf.getvalue())
        self.assertGreaterEqual(len(logs), 1)
        log = logs[0]

        expected_keys = {"event", "request_id", "method", "path", "status_code", "duration_ms", "is_sensitive"}
        self.assertTrue(expected_keys.issubset(set(log.keys())))

    def test_l3_field_types(self):
        """L3: Field types conform to specification"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.get("/test-normal")

        log = self._get_access_logs(buf.getvalue())[0]
        self.assertEqual(log["event"], "access_log")
        self.assertIsInstance(log["request_id"], str)
        self.assertTrue(len(log["request_id"]) > 0)
        self.assertEqual(log["method"], "GET")
        self.assertEqual(log["path"], "/test-normal")
        self.assertEqual(log["status_code"], 200)
        self.assertIsInstance(log["duration_ms"], (int, float))
        self.assertGreaterEqual(log["duration_ms"], 0)
        self.assertIsInstance(log["is_sensitive"], bool)

    def test_l4_request_id_preserved(self):
        """L4: request_id in log matches X-Request-ID response header"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.get("/test-normal")

        log = self._get_access_logs(buf.getvalue())[0]
        header_req_id = res.headers.get("X-Request-ID")
        self.assertIsNotNone(header_req_id)
        self.assertEqual(log["request_id"], header_req_id)

    def test_l5_sensitive_path_flag(self):
        """L5: Request to sensitive path sets is_sensitive=True"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.post("/test-login")

        log = self._get_access_logs(buf.getvalue())[0]
        self.assertTrue(log["is_sensitive"])

    def test_l6_sensitive_data_not_logged(self):
        """L6: Authorization, cookies, request bodies, and query params are strictly not logged"""
        buf = io.StringIO()
        headers = {"Authorization": "Bearer dummy_auth_marker", "Cookie": "session=dummy_cookie_marker"}
        with contextlib.redirect_stdout(buf):
            res = self.client.post(
                "/test-normal?query_val=dummy_query_marker",
                json={"body_key": "dummy_body_marker"},
                headers=headers
            )

        log = self._get_access_logs(buf.getvalue())[0]
        log_str = json.dumps(log)

        self.assertNotIn("dummy_auth_marker", log_str)
        self.assertNotIn("dummy_cookie_marker", log_str)
        self.assertNotIn("dummy_query_marker", log_str)
        self.assertNotIn("dummy_body_marker", log_str)

        forbidden_keys = {"Authorization", "Cookie", "request_body", "response_body", "query_params", "token", "password", "user_id"}
        for k in forbidden_keys:
            self.assertNotIn(k, log)

    def test_l7_response_nonregression(self):
        """L7: Downstream response body and status code are returned intact"""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = self.client.get("/test-normal")

        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json(), {"message": "hello world"})

    def test_l8_exception_propagation(self):
        """L8: Downstream handler exception propagates through middleware"""
        client_strict = TestClient(self.app, raise_server_exceptions=True)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            with self.assertRaises(RuntimeError) as ctx:
                client_strict.get("/test-error")
            self.assertIn("downstream_test_failure", str(ctx.exception))

if __name__ == "__main__":
    unittest.main()
