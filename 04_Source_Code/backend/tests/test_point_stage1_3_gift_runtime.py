import unittest
import os
import sys
import uuid
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, get_db
from app import models, auth
from app.services.point_service import PointService

class TestPointStage13GiftRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db_url = os.getenv("DATABASE_URL", "postgresql://nampo_stage12_test:nampo_stage12_disposable_only@127.0.0.1:55432/nampo_stage12_test")
        cls.engine = create_engine(cls.db_url, pool_pre_ping=True)
        cls.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=cls.engine)

    def setUp(self):
        self.db = self.SessionLocal()
        self.client = TestClient(app)

        # Setup test sender and recipient
        self.sender_id = f"usr_s_{uuid.uuid4().hex[:8]}"
        self.recipient_id = f"usr_r_{uuid.uuid4().hex[:8]}"

        self.sender = models.User(
            id=self.sender_id,
            email=f"{self.sender_id}@test.com",
            nickname="SenderUser",
            role="member",
            status="active",
            current_points=5000,
            language_code="ko",
            lifetime_earned_points=5000
        )
        self.recipient = models.User(
            id=self.recipient_id,
            email=f"{self.recipient_id}@test.com",
            nickname="RecipientUser",
            role="member",
            status="active",
            current_points=0,
            language_code="ko",
            lifetime_earned_points=0
        )
        self.db.add_all([self.sender, self.recipient])

        # Give sender transferable lot
        self.sender_lot = models.PointLot(
            id=f"lot_s_{uuid.uuid4().hex[:8]}",
            user_id=self.sender_id,
            source_type="MISSION",
            original_points=5000,
            remaining_points=5000,
            reserved_points=0,
            expires_at=datetime.utcnow() + timedelta(days=365),
            is_transferable=True,
            status="ACTIVE"
        )
        self.db.add(self.sender_lot)
        self.db.commit()

        # Token for sender & recipient
        self.sender_token = auth.create_access_token({"sub": self.sender_id, "email": self.sender.email})
        self.recipient_token = auth.create_access_token({"sub": self.recipient_id, "email": self.recipient.email})

    def tearDown(self):
        self.db.rollback()
        # Clean up test user lots, allocations, gifts, operations
        self.db.query(models.PointGift).filter(models.PointGift.sender_id == self.sender_id).delete()
        self.db.query(models.PointAllocation).filter(
            models.PointAllocation.lot_id.in_(
                self.db.query(models.PointLot.id).filter(models.PointLot.user_id.in_([self.sender_id, self.recipient_id]))
            )
        ).delete(synchronize_session=False)
        self.db.query(models.PointLot).filter(models.PointLot.user_id.in_([self.sender_id, self.recipient_id])).delete()
        self.db.query(models.PointOperation).filter(models.PointOperation.actor_user_id.in_([self.sender_id, self.recipient_id])).delete()
        self.db.query(models.PointHistory).filter(models.PointHistory.user_id.in_([self.sender_id, self.recipient_id])).delete()
        self.db.query(models.User).filter(models.User.id.in_([self.sender_id, self.recipient_id])).delete()
        self.db.commit()
        self.db.close()

    def test_01_valid_create_100(self):
        res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 100},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["gross_points"], 100)
        self.assertEqual(data["net_points"], 70)
        self.assertEqual(data["fee_points"], 30)
        self.assertEqual(data["status"], "PENDING")

    def test_02_valid_create_110(self):
        res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 110},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["gross_points"], 110)
        self.assertEqual(data["net_points"], 77)
        self.assertEqual(data["fee_points"], 33)

    def test_03_valid_create_5000(self):
        res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 5000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["gross_points"], 5000)
        self.assertEqual(data["net_points"], 3500)
        self.assertEqual(data["fee_points"], 1500)

    def test_04_reject_invalid_amounts(self):
        for bad_amount in [99, 101, 5010]:
            res = self.client.post(
                "/users/points/gift/create",
                json={"gross_points": bad_amount},
                headers={"Authorization": f"Bearer {self.sender_token}"}
            )
            self.assertEqual(res.status_code, 400)

    def test_05_claim_1000_economic_conservation(self):
        # Create 1000P gift
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(create_res.status_code, 200)
        token = create_res.json()["gift_token"]

        # Claim gift
        claim_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(claim_res.status_code, 200)
        data = claim_res.json()
        self.assertEqual(data["gross_points"], 1000)
        self.assertEqual(data["net_points"], 700)
        self.assertEqual(data["fee_points"], 300)

        # Check sender & recipient balances
        self.db.expire_all()
        sender_db = self.db.query(models.User).filter(models.User.id == self.sender_id).first()
        recipient_db = self.db.query(models.User).filter(models.User.id == self.recipient_id).first()

        self.assertEqual(sender_db.current_points, 4000)
        self.assertEqual(recipient_db.current_points, 700)

        # Authoritative balance check
        self.assertEqual(PointService.get_authoritative_usable_points(self.db, self.sender_id), 4000)
        self.assertEqual(PointService.get_authoritative_usable_points(self.db, self.recipient_id), 700)

    def test_06_cancel_gift_releases_reservation(self):
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        gift_id = create_res.json()["gift_id"]

        cancel_res = self.client.post(
            f"/users/points/gift/{gift_id}/cancel",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(cancel_res.status_code, 200)
        self.assertEqual(cancel_res.json()["status"], "CANCELLED")

        # Sender should still have 5000 spendable points and 0 reserved points
        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertEqual(lot.reserved_points, 0)
        self.assertEqual(lot.remaining_points, 5000)

    def test_07_idempotency_claim(self):
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 500},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        token = create_res.json()["gift_token"]

        # First claim
        res1 = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token, "idempotency_key": "claim_idem_1"},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(res1.status_code, 200)

        # Second claim with same token
        res2 = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token, "idempotency_key": "claim_idem_1"},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(res2.status_code, 200)
        self.assertTrue(res2.json().get("idempotent_replay", False))

        # Recipient must not be double credited (350P once)
        self.db.expire_all()
        recipient_db = self.db.query(models.User).filter(models.User.id == self.recipient_id).first()
        self.assertEqual(recipient_db.current_points, 350)

    def test_08_self_gift_rejected(self):
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 200},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        token = create_res.json()["gift_token"]

        # Sender attempts to claim their own gift
        claim_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(claim_res.status_code, 400)
        self.assertIn("본인이 보낸 선물은 직접 수령할 수 없습니다", claim_res.json()["detail"])

    def test_09_expiry_and_reservation_release(self):
        # Create 1000P gift
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        gift_id = create_res.json()["gift_id"]
        token = create_res.json()["gift_token"]

        # Manually backdate expires_at to simulate 7-day expiry
        gift = self.db.query(models.PointGift).filter(models.PointGift.id == gift_id).first()
        gift.expires_at = datetime.utcnow() - timedelta(minutes=5)
        self.db.commit()

        # Attempt to claim expired gift
        claim_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(claim_res.status_code, 400)
        self.assertIn("만료", claim_res.json()["detail"])

        # Verify status is EXPIRED and reservation released
        self.db.expire_all()
        gift_db = self.db.query(models.PointGift).filter(models.PointGift.id == gift_id).first()
        self.assertEqual(gift_db.status, "EXPIRED")

        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertEqual(lot.reserved_points, 0)
        self.assertEqual(lot.remaining_points, 5000)

        # Second expiry processing attempt should be no-op
        res = PointService.process_expired_gift(self.db, gift_id)
        self.assertFalse(res)
        self.assertEqual(lot.reserved_points, 0)

    def test_10_cancel_invariants(self):
        # Create gift
        create_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 500},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        gift_id = create_res.json()["gift_id"]

        # Cancel 1st time
        cancel1 = self.client.post(
            f"/users/points/gift/{gift_id}/cancel",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(cancel1.status_code, 200)

        # Cancel 2nd time (idempotent replay, no double release)
        cancel2 = self.client.post(
            f"/users/points/gift/{gift_id}/cancel",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(cancel2.status_code, 200)
        self.assertTrue(cancel2.json().get("idempotent_replay", False))

        self.db.expire_all()
        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertEqual(lot.reserved_points, 0)

    def test_11_daily_limits(self):
        # 1. 3 successful gifts allowed
        tokens = []
        for _ in range(3):
            c_res = self.client.post(
                "/users/points/gift/create",
                json={"gross_points": 100},
                headers={"Authorization": f"Bearer {self.sender_token}"}
            )
            tokens.append(c_res.json()["gift_token"])

        # Claim all 3
        for token in tokens:
            cl_res = self.client.post(
                "/users/points/gift/claim",
                json={"gift_token": token},
                headers={"Authorization": f"Bearer {self.recipient_token}"}
            )
            self.assertEqual(cl_res.status_code, 200)

        # 4th gift create is allowed, but CLAIM must be rejected due to daily 3-count limit
        c4_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 100},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        t4 = c4_res.json()["gift_token"]

        cl4_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": t4},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(cl4_res.status_code, 400)
        self.assertIn("3회", cl4_res.json()["detail"])

    def test_12_daily_5000_amount_boundary(self):
        # Create a single 5000P gift
        c_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 5000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        token = c_res.json()["gift_token"]

        # Claim 5000P gift -> exactly 5000P accepted
        cl_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": token},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(cl_res.status_code, 200)

        # Give sender another 1000P lot
        extra_lot = models.PointLot(
            id=f"lot_extra_{uuid.uuid4().hex[:8]}",
            user_id=self.sender_id,
            source_type="MISSION",
            original_points=1000,
            remaining_points=1000,
            reserved_points=0,
            expires_at=datetime.utcnow() + timedelta(days=365),
            is_transferable=True,
            status="ACTIVE"
        )
        self.db.add(extra_lot)
        self.db.commit()

        # Create another 100P gift
        c2_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 100},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        t2 = c2_res.json()["gift_token"]

        # Claim attempt makes daily gross 5100P (>5000P) -> must be rejected
        cl2_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": t2},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(cl2_res.status_code, 400)
        self.assertIn("5,000P", cl2_res.json()["detail"])

    def test_13_concurrent_gift_create_overreservation_safety(self):
        import concurrent.futures

        # Sender has 5000P. Try two concurrent creates of 3000P each (total 6000P > 5000P)
        def create_attempt():
            db_thread = self.SessionLocal()
            try:
                res = PointService.create_gift(db_thread, self.sender_id, 3000)
                db_thread.commit()
                return "SUCCESS", res
            except Exception as e:
                db_thread.rollback()
                return "ERROR", str(e)
            finally:
                db_thread.close()

        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            f1 = executor.submit(create_attempt)
            f2 = executor.submit(create_attempt)
            r1 = f1.result()
            r2 = f2.result()

        results = [r1[0], r2[0]]
        # Exactly one must succeed and one must fail with insufficient balance
        self.assertEqual(results.count("SUCCESS"), 1)
        self.assertEqual(results.count("ERROR"), 1)

        self.db.expire_all()
        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertEqual(lot.reserved_points, 3000)
        self.assertLessEqual(lot.reserved_points, lot.remaining_points)

    def test_14_concurrent_claim_double_claim_safety(self):
        import concurrent.futures

        c_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        token = c_res.json()["gift_token"]

        # Create two recipients
        r1_id = f"usr_c1_{uuid.uuid4().hex[:8]}"
        r2_id = f"usr_c2_{uuid.uuid4().hex[:8]}"
        u1 = models.User(id=r1_id, email=f"{r1_id}@test.com", nickname="U1", role="member", status="active", current_points=0, language_code="ko", lifetime_earned_points=0)
        u2 = models.User(id=r2_id, email=f"{r2_id}@test.com", nickname="U2", role="member", status="active", current_points=0, language_code="ko", lifetime_earned_points=0)
        self.db.add_all([u1, u2])
        self.db.commit()

        def claim_attempt(recipient_id):
            db_thread = self.SessionLocal()
            try:
                res = PointService.claim_gift(db_thread, recipient_id, token)
                db_thread.commit()
                return "SUCCESS", res
            except Exception as e:
                db_thread.rollback()
                return "ERROR", str(e)
            finally:
                db_thread.close()

        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            f1 = executor.submit(claim_attempt, r1_id)
            f2 = executor.submit(claim_attempt, r2_id)
            res1 = f1.result()
            res2 = f2.result()

        outcomes = [res1[0], res2[0]]
        self.assertEqual(outcomes.count("SUCCESS"), 1)
        self.assertEqual(outcomes.count("ERROR"), 1)

        # Verify sender debited exactly once (1000P)
        self.db.expire_all()
        sender_db = self.db.query(models.User).filter(models.User.id == self.sender_id).first()
        self.assertEqual(sender_db.current_points, 4000)

        # Cleanup extra users
        self.db.query(models.PointLot).filter(models.PointLot.user_id.in_([r1_id, r2_id])).delete()
        self.db.query(models.PointHistory).filter(models.PointHistory.user_id.in_([r1_id, r2_id])).delete()
        self.db.query(models.User).filter(models.User.id.in_([r1_id, r2_id])).delete()
        self.db.commit()

    def test_15_spend_vs_gift_reservation_race_safety(self):
        import concurrent.futures

        # Sender has 5000P. Spend 4000P and Gift 3000P concurrently (Total 7000P > 5000P)
        def spend_action():
            db_thread = self.SessionLocal()
            try:
                PointService.mutate_points(db_thread, self.sender_id, -4000, "Race Spend", transaction_type="POINT_SPEND")
                db_thread.commit()
                return "SPEND_SUCCESS"
            except Exception as e:
                db_thread.rollback()
                return "SPEND_ERROR"
            finally:
                db_thread.close()

        def gift_action():
            db_thread = self.SessionLocal()
            try:
                PointService.create_gift(db_thread, self.sender_id, 3000)
                db_thread.commit()
                return "GIFT_SUCCESS"
            except Exception as e:
                db_thread.rollback()
                return "GIFT_ERROR"
            finally:
                db_thread.close()

        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            f_spend = executor.submit(spend_action)
            f_gift = executor.submit(gift_action)
            r_spend = f_spend.result()
            r_gift = f_gift.result()

        # Both cannot succeed simultaneously because combined demand exceeds 5000P
        self.assertFalse(r_spend == "SPEND_SUCCESS" and r_gift == "GIFT_SUCCESS")

        self.db.expire_all()
        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertGreaterEqual(lot.remaining_points, 0)
        self.assertGreaterEqual(lot.reserved_points, 0)
        self.assertLessEqual(lot.reserved_points, lot.remaining_points)

    def test_16_transaction_rollback_atomicity(self):
        # Trigger an intentional error midway during gift creation
        db_fail = self.SessionLocal()
        try:
            PointService.create_gift(db_fail, self.sender_id, 1000)
            # Intentionally rollback
            db_fail.rollback()
        finally:
            db_fail.close()

        self.db.expire_all()
        lot = self.db.query(models.PointLot).filter(models.PointLot.id == self.sender_lot.id).first()
        self.assertEqual(lot.reserved_points, 0)
        self.assertEqual(lot.remaining_points, 5000)

        # No orphan allocations or operations
        orphan_ops = self.db.query(models.PointOperation).filter(models.PointOperation.actor_user_id == self.sender_id, models.PointOperation.operation_type == "GIFT_CREATE").all()
        self.assertEqual(len(orphan_ops), 0)

if __name__ == "__main__":
    unittest.main()
