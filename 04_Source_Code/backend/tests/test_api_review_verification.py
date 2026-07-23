import os
import unittest
from datetime import datetime, timedelta

# Set SQLite test DB before importing app modules
os.environ["DATABASE_URL"] = "sqlite:///./test_review_verification.db"

from app.database import SessionLocal, engine, Base
from app import models, schemas
from fastapi.testclient import TestClient
from app.main import app

class TestReviewVerification(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    def setUp(self):
        self.db = SessionLocal()
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.UserAuth).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # 1. Create Business Store (K-Lounge)
        self.business_store = models.Store(
            id="store_klounge_001",
            name="K-Lounge",
            category="체험",
            rating=0.0,
            address="부산 중구 구덕로 50-1 2층",
            description="K-Lounge 매장",
            review_verification_type="BUSINESS_QR",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )
        self.db.add(self.business_store)

        # 2. Create Attraction Store (용두산공원 부산타워)
        self.attraction_store = models.Store(
            id="store_tower_002",
            name="용두산공원 부산타워",
            category="볼거리",
            rating=0.0,
            address="부산 중구 용두산길 37-55",
            description="전망대 관광지",
            latitude=35.1006,
            longitude=129.0326,
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )
        self.db.add(self.attraction_store)

        # 3. Create Open Review Store
        self.open_store = models.Store(
            id="store_open_003",
            name="자유 리뷰 장소",
            category="기타",
            rating=0.0,
            address="부산 중구 남포동 1가",
            description="자유 리뷰 허용 매장",
            review_verification_type="OPEN_REVIEW",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )
        self.db.add(self.open_store)

        # 4. Create User
        self.test_user = models.User(
            id="usr_test_verification_01",
            email="test_verifier@example.com",
            nickname="리뷰검증자",
            role="member",
            status="active"
        )
        self.db.add(self.test_user)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_review_verification.db"):
            try:
                os.remove("./test_review_verification.db")
            except Exception:
                pass

    def test_business_qr_verification_flow(self):
        # 1. Reject review creation without QR verification
        res_no_v = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            json={
                "rating": 5,
                "content": "QR 인증 없이 생성을 시도하는 10자 이상의 리뷰 본문입니다.",
                "user_id": self.test_user.id
            }
        )
        self.assertEqual(res_no_v.status_code, 403)

        # 2. Reject invalid QR token
        res_invalid_qr = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": "INVALID_TOKEN_999", "user_id": self.test_user.id}
        )
        self.assertEqual(res_invalid_qr.status_code, 403)

        # 3. Verify valid QR token (TEST_QR_KLOUUNGE)
        res_qr = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": "TEST_QR_KLOUUNGE", "user_id": self.test_user.id}
        )
        self.assertEqual(res_qr.status_code, 201)
        v_data = res_qr.json()
        self.assertEqual(v_data["verification_method"], "BUSINESS_QR")
        self.assertEqual(v_data["status"], "ACTIVE")
        verification_id = v_data["id"]

        # 4. Post review with valid QR verification
        res_review = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            json={
                "rating": 5,
                "content": "K-Lounge 방문 마사지 서비스에 대만족했습니다! 10자 이상 본문.",
                "user_id": self.test_user.id,
                "verification_id": verification_id
            }
        )
        self.assertEqual(res_review.status_code, 201)
        rev_data = res_review.json()
        self.assertEqual(rev_data["verification_badge"], "QR 방문 인증")

        # 5. Prevent duplicate review submission with same verification / user
        res_dup = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            json={
                "rating": 4,
                "content": "중복 리뷰 작성을 시도하는 10자 이상의 테스트 본문입니다.",
                "user_id": self.test_user.id,
                "verification_id": verification_id
            }
        )
        self.assertIn(res_dup.status_code, [403, 409])

    def test_attraction_gps_and_manual_verification_flow(self):
        # 1. GPS verification - Fail when far away (lat=37.0, lon=127.0)
        res_far = self.client.post(
            f"/stores/{self.attraction_store.id}/verify-location",
            json={"latitude": 37.5665, "longitude": 126.9780, "user_id": self.test_user.id}
        )
        self.assertEqual(res_far.status_code, 400)

        # 2. GPS verification - Success when close (lat=35.1007, lon=129.0327)
        res_gps = self.client.post(
            f"/stores/{self.attraction_store.id}/verify-location",
            json={"latitude": 35.1007, "longitude": 129.0327, "user_id": self.test_user.id}
        )
        self.assertEqual(res_gps.status_code, 201)
        v_gps = res_gps.json()
        self.assertEqual(v_gps["verification_method"], "ATTRACTION_GPS")

        # 3. Post review with GPS verification
        res_gps_rev = self.client.post(
            f"/stores/{self.attraction_store.id}/reviews",
            json={
                "rating": 5,
                "content": "부산타워 전망대 뷰가 최고였어요! 10자 이상 훌륭한 후기입니다.",
                "user_id": self.test_user.id,
                "verification_id": v_gps["id"]
            }
        )
        self.assertEqual(res_gps_rev.status_code, 201)
        self.assertEqual(res_gps_rev.json()["verification_badge"], "위치 확인 방문")

        # 4. Manual Date verification - Fail for future date
        tomorrow_iso = (datetime.utcnow() + timedelta(days=2)).isoformat()
        res_future = self.client.post(
            f"/stores/{self.attraction_store.id}/verify-manual-visit",
            json={"visit_date": tomorrow_iso, "guest_id": "guest_attraction_99"}
        )
        self.assertEqual(res_future.status_code, 400)

        # 5. Manual Date verification - Success for yesterday
        yesterday_iso = (datetime.utcnow() - timedelta(days=1)).isoformat()
        res_manual = self.client.post(
            f"/stores/{self.attraction_store.id}/verify-manual-visit",
            json={"visit_date": yesterday_iso, "guest_id": "guest_attraction_99"}
        )
        self.assertEqual(res_manual.status_code, 201)
        v_man = res_manual.json()
        self.assertEqual(v_man["verification_method"], "ATTRACTION_MANUAL")

        # 6. Post review for guest with manual date verification
        res_man_rev = self.client.post(
            f"/stores/{self.attraction_store.id}/reviews",
            json={
                "rating": 4,
                "content": "지난주에 방문했던 부산타워의 수동 방문 후기입니다 10자 이상.",
                "guest_id": "guest_attraction_99",
                "verification_id": v_man["id"]
            }
        )
        self.assertEqual(res_man_rev.status_code, 201)
        self.assertEqual(res_man_rev.json()["verification_badge"], "일반 방문 후기")

    def test_store_qr_credential_security_and_expiry_flow(self):
        import hashlib
        # 1. Reject unregistered random token
        res_unreg = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": "UNREGISTERED_ATTACK_TOKEN_XYZ", "guest_id": "guest_sec_01"}
        )
        self.assertEqual(res_unreg.status_code, 403)

        # 2. Register valid StoreQrCredential (valid for 6 hours)
        valid_token = "SECURE_TEST_QR_TOKEN_2026"
        valid_hash = hashlib.sha256(valid_token.encode('utf-8')).hexdigest()
        now = datetime.utcnow()
        active_cred = models.StoreQrCredential(
            store_id=self.business_store.id,
            token_hash=valid_hash,
            issued_at=now,
            expires_at=now + timedelta(hours=6),
            status="ACTIVE",
            purpose="TEST_REVIEW_VISIT"
        )
        self.db.add(active_cred)

        # Register expired StoreQrCredential (expired 1 hour ago)
        expired_token = "EXPIRED_TEST_QR_TOKEN_2026"
        expired_hash = hashlib.sha256(expired_token.encode('utf-8')).hexdigest()
        expired_cred = models.StoreQrCredential(
            store_id=self.business_store.id,
            token_hash=expired_hash,
            issued_at=now - timedelta(hours=7),
            expires_at=now - timedelta(hours=1),
            status="ACTIVE",
            purpose="TEST_REVIEW_VISIT"
        )
        self.db.add(expired_cred)

        # Register revoked StoreQrCredential
        revoked_token = "REVOKED_TEST_QR_TOKEN_2026"
        revoked_hash = hashlib.sha256(revoked_token.encode('utf-8')).hexdigest()
        revoked_cred = models.StoreQrCredential(
            store_id=self.business_store.id,
            token_hash=revoked_hash,
            issued_at=now,
            expires_at=now + timedelta(hours=6),
            status="REVOKED",
            revoked_at=now,
            purpose="TEST_REVIEW_VISIT"
        )
        self.db.add(revoked_cred)
        self.db.commit()

        # 3. Verify valid QR token succeeds and creates 72-hour VisitVerification
        res_valid = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": valid_token, "guest_id": "guest_sec_01"}
        )
        self.assertEqual(res_valid.status_code, 201)
        v_data = res_valid.json()
        self.assertEqual(v_data["verification_method"], "BUSINESS_QR")
        self.assertEqual(v_data["status"], "ACTIVE")

        # 4. Verify expired QR token is rejected with 403
        res_expired = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": expired_token, "guest_id": "guest_sec_02"}
        )
        self.assertEqual(res_expired.status_code, 403)

        # 5. Verify revoked QR token is rejected with 403
        res_revoked = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": revoked_token, "guest_id": "guest_sec_03"}
        )
        self.assertEqual(res_revoked.status_code, 403)

        # 6. Verify QR token for business_store is rejected when attempted on attraction_store
        res_wrong_store = self.client.post(
            f"/stores/{self.attraction_store.id}/verify-qr",
            json={"qr_token": valid_token, "guest_id": "guest_sec_04"}
        )
        self.assertEqual(res_wrong_store.status_code, 403)

    def test_duplicate_qr_verification_and_review_guard_flow(self):
        token_str = "QR_SECRET_store_klounge_001"

        # 1. First QR scan for guest_dup_01 -> Success 201
        res1 = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": token_str, "guest_id": "guest_dup_01"}
        )
        self.assertEqual(res1.status_code, 201)
        v1_id = res1.json()["id"]

        # 2. Rescan before writing review -> Returns same active verification (idempotent)
        res2 = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": token_str, "guest_id": "guest_dup_01"}
        )
        self.assertEqual(res2.status_code, 201)
        self.assertEqual(res2.json()["id"], v1_id)

        # 3. Verify row count does not increase for rescan
        v_count = self.db.query(models.VisitVerification).filter(
            models.VisitVerification.guest_id == "guest_dup_01",
            models.VisitVerification.store_id == self.business_store.id
        ).count()
        self.assertEqual(v_count, 1)

        # 4. Submit first review -> Success 201 and marks verification USED
        res_rev1 = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            json={
                "rating": 5,
                "content": "첫 번째 방문 인증으로 남기는 정성 가득한 후기 10자 이상.",
                "guest_id": "guest_dup_01",
                "verification_id": v1_id
            }
        )
        self.assertEqual(res_rev1.status_code, 201)

        # 5. Rescan after submitting review within 72h -> HTTP 409 Conflict
        res_rescan_after = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": token_str, "guest_id": "guest_dup_01"}
        )
        self.assertEqual(res_rescan_after.status_code, 409)

        # 6. Attempt second review submission for same guest -> HTTP 409 Conflict
        res_rev2 = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            json={
                "rating": 5,
                "content": "두 번째 중복 제출을 시도하는 후기 10자 이상 내용입니다.",
                "guest_id": "guest_dup_01",
                "verification_id": v1_id
            }
        )
        self.assertEqual(res_rev2.status_code, 409)

        # 7. Another guest (guest_dup_02) CAN verify same QR credential successfully
        res_guest2 = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": token_str, "guest_id": "guest_dup_02"}
        )
        self.assertEqual(res_guest2.status_code, 201)
        self.assertNotEqual(res_guest2.json()["id"], v1_id)

        # 8. Another logged-in user CAN verify same QR credential successfully
        res_user = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": token_str, "user_id": self.test_user.id}
        )
        self.assertEqual(res_user.status_code, 201)

if __name__ == "__main__":
    unittest.main()
