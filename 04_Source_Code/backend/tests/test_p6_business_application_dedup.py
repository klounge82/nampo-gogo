import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException
from app.models import Base, User, BusinessApplication
from app.schemas import BusinessApplicationCreate, BusinessSignupCreate
from app.main import apply_business_account, signup_business

class TestBusinessApplicationDedup(unittest.TestCase):

    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine)
        self.db = self.Session()

        # Seed initial test users
        self.user_a = User(id="user_a", email="user_a@test.com", nickname="User A", status="active", role="member")
        self.user_b = User(id="user_b", email="user_b@test.com", nickname="User B", status="active", role="member")
        self.db.add_all([self.user_a, self.user_b])
        self.db.commit()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(self.engine)

    def test_a1_first_submission_succeeds(self):
        """A1: First submission with valid registration number succeeds and sets status PENDING"""
        req = BusinessApplicationCreate(
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678"
        )
        res = apply_business_account(req=req, current_user=self.user_a, db=self.db)
        self.assertIsNotNone(res.id)
        self.assertEqual(res.status, "PENDING")
        self.assertEqual(res.business_registration_number, "123-45-67890")

    def test_a2_pending_duplicate_blocked(self):
        """A2: Submitting same registration number while an application is PENDING raises 400 Bad Request"""
        app_existing = BusinessApplication(
            user_id="user_b",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="PENDING"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Nampo Cafe 2",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678"
        )
        with self.assertRaises(HTTPException) as ctx:
            apply_business_account(req=req, current_user=self.user_a, db=self.db)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "이미 등록되었거나 심사 중인 사업자등록번호입니다.")

    def test_a3_approved_duplicate_blocked(self):
        """A3: Submitting same registration number while an application is APPROVED raises 400 Bad Request"""
        app_existing = BusinessApplication(
            user_id="user_a",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="APPROVED"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Nampo Cafe Duplicate",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678"
        )
        with self.assertRaises(HTTPException) as ctx:
            apply_business_account(req=req, current_user=self.user_a, db=self.db)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "이미 등록되었거나 심사 중인 사업자등록번호입니다.")

    def test_a4_cross_user_duplicate_blocked(self):
        """A4: User B cannot submit same registration number already registered by User A"""
        app_existing = BusinessApplication(
            user_id="user_a",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="APPROVED"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Nampo Cafe by User B",
            business_registration_number="123-45-67890",
            representative_name="Kim Chul Soo",
            phone="010-9876-5432"
        )
        with self.assertRaises(HTTPException) as ctx:
            apply_business_account(req=req, current_user=self.user_b, db=self.db)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "이미 등록되었거나 심사 중인 사업자등록번호입니다.")

    def test_a5_different_registration_number_allowed(self):
        """A5: Submissions with different registration numbers are allowed"""
        app_existing = BusinessApplication(
            user_id="user_a",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="APPROVED"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Gwangbok Bakery",
            business_registration_number="987-65-43210",
            representative_name="Kim Chul Soo",
            phone="010-9876-5432"
        )
        res = apply_business_account(req=req, current_user=self.user_b, db=self.db)
        self.assertEqual(res.status, "PENDING")
        self.assertEqual(res.business_registration_number, "987-65-43210")

    def test_a6_rejected_resubmission_allowed(self):
        """A6: Resubmission of registration number that was REJECTED is allowed"""
        app_existing = BusinessApplication(
            user_id="user_a",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="REJECTED"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Nampo Cafe Resubmit",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678"
        )
        res = apply_business_account(req=req, current_user=self.user_a, db=self.db)
        self.assertEqual(res.status, "PENDING")
        self.assertEqual(res.business_registration_number, "123-45-67890")

    def test_a7_strip_normalization_blocks_duplicate(self):
        """A7: Surrounding whitespace is stripped and duplicate is blocked"""
        app_existing = BusinessApplication(
            user_id="user_b",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="PENDING"
        )
        self.db.add(app_existing)
        self.db.commit()

        req = BusinessApplicationCreate(
            business_name="Nampo Cafe Space",
            business_registration_number="  123-45-67890  ",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678"
        )
        with self.assertRaises(HTTPException) as ctx:
            apply_business_account(req=req, current_user=self.user_a, db=self.db)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "이미 등록되었거나 심사 중인 사업자등록번호입니다.")

    def test_a8_signup_business_duplicate_blocked(self):
        """A8: Duplicate registration number is also blocked in signup_business path"""
        app_existing = BusinessApplication(
            user_id="user_a",
            business_name="Nampo Cafe",
            business_registration_number="123-45-67890",
            representative_name="Hong Gil Dong",
            phone="010-1234-5678",
            status="APPROVED"
        )
        self.db.add(app_existing)
        self.db.commit()

        user_in = BusinessSignupCreate(
            email="new_business@test.com",
            password="password123!",
            nickname="New Owner",
            business_name="New Shop",
            business_registration_number="123-45-67890",
            representative_name="New Rep",
            phone="010-5555-5555"
        )
        with self.assertRaises(HTTPException) as ctx:
            signup_business(user_in=user_in, db=self.db)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "이미 등록되었거나 심사 중인 사업자등록번호입니다.")

if __name__ == "__main__":
    unittest.main()
