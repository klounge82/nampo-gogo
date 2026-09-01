import unittest
from unittest.mock import MagicMock, patch
from types import SimpleNamespace
from fastapi import HTTPException
from app.main import get_owner_or_admin_user

class TestDeclarativeRBAC(unittest.TestCase):

    def setUp(self):
        self.mock_user = SimpleNamespace(id="u123", status="active", role=None)
        self.mock_db = MagicMock()

    @patch("app.main.get_user_roles")
    def test_r1_owner_only_allowed(self, mock_get_roles):
        """R1: OWNER role alone is allowed"""
        mock_get_roles.return_value = ["OWNER"]
        res = get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertIs(res, self.mock_user)

    @patch("app.main.get_user_roles")
    def test_r2_admin_only_allowed(self, mock_get_roles):
        """R2: ADMIN role alone is allowed (also covers case insensitivity)"""
        mock_get_roles.return_value = ["admin"]
        res = get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertIs(res, self.mock_user)

    @patch("app.main.get_user_roles")
    def test_r3_business_only_denied(self, mock_get_roles):
        """R3: BUSINESS role alone is denied with 403"""
        mock_get_roles.return_value = ["BUSINESS"]
        with self.assertRaises(HTTPException) as ctx:
            get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertEqual(ctx.exception.status_code, 403)

    @patch("app.main.get_user_roles")
    def test_r4_customer_business_denied(self, mock_get_roles):
        """R4: CUSTOMER + BUSINESS combination is denied with 403"""
        mock_get_roles.return_value = ["CUSTOMER", "BUSINESS"]
        with self.assertRaises(HTTPException) as ctx:
            get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertEqual(ctx.exception.status_code, 403)

    @patch("app.main.get_user_roles")
    def test_r5_customer_business_owner_allowed(self, mock_get_roles):
        """R5: CUSTOMER + BUSINESS + OWNER combination is allowed because OWNER exists"""
        mock_get_roles.return_value = ["CUSTOMER", "BUSINESS", "OWNER"]
        res = get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertIs(res, self.mock_user)

    @patch("app.main.get_user_roles")
    def test_r6_customer_admin_allowed(self, mock_get_roles):
        """R6: CUSTOMER + ADMIN combination is allowed because ADMIN exists"""
        mock_get_roles.return_value = ["CUSTOMER", "ADMIN"]
        res = get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertIs(res, self.mock_user)

    @patch("app.main.get_user_roles")
    def test_r7_manager_only_denied(self, mock_get_roles):
        """R7: MANAGER role alone is denied with 403"""
        mock_get_roles.return_value = ["MANAGER"]
        with self.assertRaises(HTTPException) as ctx:
            get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertEqual(ctx.exception.status_code, 403)

    @patch("app.main.get_user_roles")
    def test_r8_staff_only_denied(self, mock_get_roles):
        """R8: STAFF role alone is denied with 403"""
        mock_get_roles.return_value = ["STAFF"]
        with self.assertRaises(HTTPException) as ctx:
            get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertEqual(ctx.exception.status_code, 403)

    @patch("app.main.get_user_roles")
    def test_r9_denial_contract_preserved(self, mock_get_roles):
        """R9: Denial contract preserves exact 403 status and message"""
        mock_get_roles.return_value = ["CUSTOMER"]
        with self.assertRaises(HTTPException) as ctx:
            get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertEqual(ctx.exception.status_code, 403)
        self.assertEqual(
            ctx.exception.detail,
            "이용 권한이 없습니다. 사업자(Owner) 또는 관리자(Admin) 계정만 접근할 수 있습니다."
        )

    @patch("app.main.get_user_roles")
    def test_r10_return_current_user_identity_preserved(self, mock_get_roles):
        """R10: Returned object identity is identical to current_user"""
        mock_get_roles.return_value = ["OWNER"]
        res = get_owner_or_admin_user(current_user=self.mock_user, db=self.mock_db)
        self.assertIs(res, self.mock_user)

if __name__ == "__main__":
    unittest.main()
