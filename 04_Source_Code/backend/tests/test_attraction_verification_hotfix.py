import unittest
from datetime import datetime, timedelta
import uuid
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app, get_db
from app.database import Base
from app import models, auth

# Isolated in-memory SQLite database for attraction verification tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_attraction_verification.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


class TestAttractionVerificationHotfix(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        app.dependency_overrides[get_db] = override_get_db

    @classmethod
    def tearDownClass(cls):
        app.dependency_overrides.clear()
        Base.metadata.drop_all(bind=engine)

    def setUp(self):
        self.db = TestingSessionLocal()
        self.client = TestClient(app)

        # Clear tables
        self.db.query(models.ReviewImage).delete()
        self.db.query(models.Review).delete()
        self.db.query(models.VisitVerification).delete()
        self.db.query(models.StoreQrCredential).delete()
        self.db.query(models.Store).delete()
        self.db.query(models.User).delete()
        self.db.commit()

        # Create Test Users
        self.user1 = models.User(
            id="user_attr_001",
            email="attr1@test.com",
            nickname="관광객1",
            role="CUSTOMER",
            status="active"
        )
        self.user2 = models.User(
            id="user_attr_002",
            email="attr2@test.com",
            nickname="관광객2",
            role="CUSTOMER",
            status="active"
        )
        self.db.add_all([self.user1, self.user2])
        self.db.commit()

        # 1. Business Store (BUSINESS_QR)
        self.business_store = models.Store(
            id="store_biz_001",
            name="남포 숯불갈비",
            category="맛집",
            rating=4.8,
            address="부산 중구 남포길 12",
            description="사업장 매장입니다.",
            latitude=35.1010,
            longitude=129.0280,
            status="영업중",
            review_verification_type="BUSINESS_QR"
        )

        # 2. Attraction Store with Valid Coordinates (ATTRACTION_LOCATION)
        self.attraction_gps = models.Store(
            id="attraction_gps_001",
            name="용두산공원 부산타워",
            category="볼거리",
            rating=4.7,
            address="부산 중구 용두산길 37",
            description="남포동 중심에 위치한 부산 대표 관광지입니다.",
            latitude=35.1005,
            longitude=129.0326,
            status="영업중",
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )

        # 3. Attraction Store WITHOUT Coordinates (ATTRACTION_LOCATION)
        self.attraction_nocoords = models.Store(
            id="attraction_nocoords_001",
            name="부산 야경 명소 해안산책로",
            category="볼거리",
            rating=4.5,
            address="부산 중구 해안로 일대",
            description="좌표 미등록 관광지입니다.",
            latitude=None,
            longitude=None,
            status="영업중",
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=300,
            manual_visit_allowed=True
        )

        # 4. Attraction Store with Manual Visit Restricted (manual_visit_allowed = False)
        self.attraction_no_manual = models.Store(
            id="attraction_nomanual_001",
            name="엄격한 GPS 전용 전시관",
            category="체험",
            rating=4.6,
            address="부산 중구 전시관길 1",
            description="방문날짜 직접입력이 차단된 전시관입니다.",
            latitude=35.1020,
            longitude=129.0300,
            status="영업중",
            review_verification_type="ATTRACTION_LOCATION",
            review_location_radius_m=200,
            manual_visit_allowed=False
        )

        self.db.add_all([
            self.business_store,
            self.attraction_gps,
            self.attraction_nocoords,
            self.attraction_no_manual
        ])
        self.db.commit()

        self.token1 = auth.create_access_token({"sub": self.user1.id, "role": "CUSTOMER"})
        self.token2 = auth.create_access_token({"sub": self.user2.id, "role": "CUSTOMER"})

    def tearDown(self):
        self.db.close()

    # 1. Business store rejects attraction location / date verification
    def test_01_business_store_rejects_attraction_verification(self):
        # Try GPS verification on BUSINESS_QR store
        res = self.client.post(
            f"/stores/{self.business_store.id}/verify-location",
            json={"latitude": 35.1010, "longitude": 129.0280, "user_id": self.user1.id}
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("사업장", res.json()["detail"])

        # Try visit date verification on BUSINESS_QR store
        res2 = self.client.post(
            f"/stores/{self.business_store.id}/verify-manual-visit",
            json={"visit_date": datetime.utcnow().isoformat(), "user_id": self.user1.id}
        )
        self.assertEqual(res2.status_code, 400)
        self.assertIn("사업장", res2.json()["detail"])

    # 2. Attraction rejects QR scan requirement
    def test_02_attraction_rejects_qr_verification(self):
        res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-qr",
            json={"qr_token": "TEST_QR_TOKEN", "user_id": self.user1.id}
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("관광지", res.json()["detail"])

    # 3. Attraction GPS verification success
    def test_03_attraction_gps_verification_success(self):
        res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.1006,
                "longitude": 129.0325,
                "accuracy": 15.0,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["verification_method"], "ATTRACTION_GPS")
        self.assertEqual(data["user_id"], self.user1.id)
        self.assertEqual(data["status"], "ACTIVE")

    # 4. Out of range GPS verification blocked
    def test_04_attraction_gps_out_of_range_blocked(self):
        # 10km away from Yongdusan Park
        res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.2000,
                "longitude": 129.1000,
                "accuracy": 10.0,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.json()["detail"], "현재 위치에서는 이 관광지 방문을 확인할 수 없습니다.")

    # 5. Low accuracy location blocked
    def test_05_low_accuracy_location_blocked(self):
        res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.1005,
                "longitude": 129.0326,
                "accuracy": 800.0, # > 500m
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("정확도", res.json()["detail"])

    # 6. Future visit date blocked
    def test_06_future_visit_date_blocked(self):
        future_dt = datetime.utcnow() + timedelta(days=2)
        res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-manual-visit",
            json={
                "visit_date": future_dt.isoformat(),
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("미래", res.json()["detail"])

    # 7. Visit date verification restricted attraction blocked
    def test_07_visit_date_restricted_attraction_blocked(self):
        res = self.client.post(
            f"/stores/{self.attraction_no_manual.id}/verify-manual-visit",
            json={
                "visit_date": datetime.utcnow().isoformat(),
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("허용되지 않습니다", res.json()["detail"])

    # 8. Review creation after attraction verification success
    def test_08_review_creation_after_attraction_verification(self):
        v_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.1005,
                "longitude": 129.0326,
                "accuracy": 10.0,
                "user_id": self.user1.id
            }
        )
        v_id = v_res.json()["id"]

        r_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={
                "rating": 5,
                "content": "용두산 공원 타워 야경이 너무 아름답습니다!",
                "verification_id": v_id,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(r_res.status_code, 201)
        r_data = r_res.json()
        self.assertEqual(r_data["verification_id"], v_id)
        self.assertEqual(r_data["verification_badge"], "GPS 방문 인증")
        self.assertTrue(r_data["is_owner"])

    # 9. Edit/Delete/Restore existing review does not require re-verification
    def test_09_edit_delete_restore_without_reverification(self):
        # 1. Create verification & review
        v_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-manual-visit",
            json={
                "visit_date": (datetime.utcnow() - timedelta(days=1)).isoformat(),
                "user_id": self.user1.id
            }
        )
        v_id = v_res.json()["id"]

        r_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={
                "rating": 4,
                "content": "방문일자 인증으로 작성한 리뷰입니다.",
                "verification_id": v_id,
                "user_id": self.user1.id
            }
        )
        rev_id = r_res.json()["id"]

        # 2. Edit review (no re-verification)
        edit_res = self.client.patch(
            f"/reviews/{rev_id}",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={"content": "방문일자 인증 후 수정 완료된 내용입니다."}
        )
        self.assertEqual(edit_res.status_code, 200)

        # 3. Delete review (no re-verification)
        del_res = self.client.delete(
            f"/reviews/{rev_id}",
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        self.assertEqual(del_res.status_code, 200)

        # 4. Restore review (no re-verification)
        rest_res = self.client.post(
            f"/reviews/{rev_id}/restore",
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        self.assertEqual(rest_res.status_code, 200)

    # 10. Duplicate review within 72h blocked (HTTP 409)
    def test_10_duplicate_review_within_72h_blocked(self):
        v_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.1005,
                "longitude": 129.0326,
                "user_id": self.user1.id
            }
        )
        v_id = v_res.json()["id"]

        self.client.post(
            f"/stores/{self.attraction_gps.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={
                "rating": 5,
                "content": "첫 번째 리뷰 작성",
                "verification_id": v_id,
                "user_id": self.user1.id
            }
        )

        # Try second verification/review within 72h
        res2 = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={
                "latitude": 35.1005,
                "longitude": 129.0326,
                "user_id": self.user1.id
            }
        )
        self.assertEqual(res2.status_code, 409)

    # 11. User 1 review does not block User 2
    def test_11_user1_review_does_not_block_user2(self):
        # User 1 verifies and posts review
        v1_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={"latitude": 35.1005, "longitude": 129.0326, "user_id": self.user1.id}
        )
        v1_id = v1_res.json()["id"]
        self.client.post(
            f"/stores/{self.attraction_gps.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={"rating": 5, "content": "유저1 후기", "verification_id": v1_id, "user_id": self.user1.id}
        )

        # User 2 verifies and posts review
        v2_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/verify-location",
            json={"latitude": 35.1005, "longitude": 129.0326, "user_id": self.user2.id}
        )
        self.assertEqual(v2_res.status_code, 201)
        v2_id = v2_res.json()["id"]

        r2_res = self.client.post(
            f"/stores/{self.attraction_gps.id}/reviews",
            headers={"Authorization": f"Bearer {self.token2}"},
            json={"rating": 4, "content": "유저2 후기입니다. 용두산 타워 방문했습니다.", "verification_id": v2_id, "user_id": self.user2.id}
        )
        self.assertEqual(r2_res.status_code, 201)



    # 12. Business QR review workflow preserved
    def test_12_business_qr_workflow_preserved(self):
        v_res = self.client.post(
            f"/stores/{self.business_store.id}/verify-qr",
            json={"qr_token": f"QR_SECRET_{self.business_store.id}", "user_id": self.user1.id}
        )
        self.assertEqual(v_res.status_code, 201)
        self.assertEqual(v_res.json()["verification_method"], "BUSINESS_QR")

        r_res = self.client.post(
            f"/stores/{self.business_store.id}/reviews",
            headers={"Authorization": f"Bearer {self.token1}"},
            json={
                "rating": 5,
                "content": "사업장 QR 방문 인증 후기",
                "verification_id": v_res.json()["id"],
                "user_id": self.user1.id
            }
        )
        self.assertEqual(r_res.status_code, 201)
        self.assertEqual(r_res.json()["verification_badge"], "QR 방문 인증")

    # 13. Regression Test: BUSINESS_QR stores are strictly excluded from attraction audit
    def test_13_business_stores_excluded_from_attraction_audit(self):
        attractions_only = self.db.query(models.Store).filter(
            models.Store.review_verification_type == "ATTRACTION_LOCATION"
        ).all()
        # Verify business_store is NOT in ATTRACTION_LOCATION query
        attr_ids = [a.id for a in attractions_only]
        self.assertNotIn(self.business_store.id, attr_ids)

        # Verification options check for business_store
        opt_res = self.client.get(f"/stores/{self.business_store.id}/verification-options")
        self.assertEqual(opt_res.status_code, 200)
        opts = opt_res.json()
        self.assertTrue(opts["can_use_qr"])
        self.assertFalse(opts["can_use_gps"])
        self.assertFalse(opts["can_use_visit_date"])
        self.assertEqual(opts["review_verification_type"], "BUSINESS_QR")


if __name__ == "__main__":
    unittest.main()

