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

class TestPointStage14GiftReadApi(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db_url = os.getenv("DATABASE_URL", "postgresql://nampo_stage12_test:nampo_stage12_disposable_only@127.0.0.1:55432/nampo_stage12_test")
        cls.engine = create_engine(cls.db_url, pool_pre_ping=True)
        cls.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=cls.engine)

    def setUp(self):
        self.db = self.SessionLocal()
        self.client = TestClient(app)

        self.sender_id = f"usr_s_{uuid.uuid4().hex[:8]}"
        self.recipient_id = f"usr_r_{uuid.uuid4().hex[:8]}"
        self.stranger_id = f"usr_x_{uuid.uuid4().hex[:8]}"

        self.sender = models.User(
            id=self.sender_id,
            email=f"{self.sender_id}@test.com",
            nickname="Sender",
            current_points=10000,
            lifetime_earned_points=10000,
            role="member",
            status="active"
        )
        self.recipient = models.User(
            id=self.recipient_id,
            email=f"{self.recipient_id}@test.com",
            nickname="Recipient",
            current_points=0,
            lifetime_earned_points=0,
            role="member",
            status="active"
        )
        self.stranger = models.User(
            id=self.stranger_id,
            email=f"{self.stranger_id}@test.com",
            nickname="Stranger",
            current_points=5000,
            lifetime_earned_points=5000,
            role="member",
            status="active"
        )
        self.db.add_all([self.sender, self.recipient, self.stranger])
        self.db.commit()

        # Seed transferable lots for sender
        now = datetime.utcnow()
        lot = models.PointLot(
            id=str(uuid.uuid4()),
            user_id=self.sender_id,
            source_type="GENERAL",
            original_points=10000,
            remaining_points=10000,
            reserved_points=0,
            expires_at=now + timedelta(days=365),
            is_transferable=True,
            status="ACTIVE",
            created_at=now
        )
        self.db.add(lot)
        self.db.commit()

        self.sender_token = auth.create_access_token({"sub": self.sender_id, "email": self.sender.email})
        self.recipient_token = auth.create_access_token({"sub": self.recipient_id, "email": self.recipient.email})
        self.stranger_token = auth.create_access_token({"sub": self.stranger_id, "email": self.stranger.email})

    def tearDown(self):
        self.db.rollback()
        # Clean up test users
        self.db.query(models.PointGift).filter(models.PointGift.sender_id.in_([self.sender_id, self.recipient_id, self.stranger_id])).delete()
        self.db.query(models.PointAllocation).filter(
            models.PointAllocation.lot_id.in_(
                self.db.query(models.PointLot.id).filter(models.PointLot.user_id.in_([self.sender_id, self.recipient_id, self.stranger_id]))
            )
        ).delete(synchronize_session=False)
        self.db.query(models.PointLot).filter(models.PointLot.user_id.in_([self.sender_id, self.recipient_id, self.stranger_id])).delete()
        self.db.query(models.PointOperation).filter(models.PointOperation.actor_user_id.in_([self.sender_id, self.recipient_id, self.stranger_id])).delete()
        self.db.query(models.PointHistory).filter(models.PointHistory.user_id.in_([self.sender_id, self.recipient_id, self.stranger_id])).delete()
        self.db.query(models.User).filter(models.User.id.in_([self.sender_id, self.recipient_id, self.stranger_id])).delete()
        self.db.commit()
        self.db.close()

    def test_01_auth_required(self):
        """Proof 1: Unauthenticated request is rejected with 401"""
        res = self.client.get("/users/points/gifts")
        self.assertEqual(res.status_code, 401)

    def test_02_sender_sees_pending_gift(self):
        """Proof 2: Sender sees their own pending gift in list, safe fields only"""
        c_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(c_res.status_code, 200)
        gift_id = c_res.json()["gift_id"]

        res = self.client.get(
            "/users/points/gifts",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(data["total_count"], 1)
        gifts = data["gifts"]
        target = next((g for g in gifts if g["gift_id"] == gift_id), None)
        self.assertIsNotNone(target)
        self.assertEqual(target["direction"], "SENT")
        self.assertEqual(target["gross_points"], 1000)
        self.assertEqual(target["net_points"], 700)
        self.assertEqual(target["fee_points"], 300)
        self.assertEqual(target["status"], "PENDING")

        self.assertNotIn("gift_token_hash", target)
        self.assertNotIn("token_hash", target)
        self.assertNotIn("gift_token", target)
        self.assertNotIn("create_operation_id", target)
        self.assertNotIn("accept_operation_id", target)

    def test_03_recipient_sees_accepted_gift_stranger_sees_nothing(self):
        """Proof 3: Recipient sees claimed gift as RECEIVED; stranger sees empty list"""
        c_res = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        raw_token = c_res.json()["gift_token"]
        gift_id = c_res.json()["gift_id"]

        cl_res = self.client.post(
            "/users/points/gift/claim",
            json={"gift_token": raw_token},
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(cl_res.status_code, 200)

        r_res = self.client.get(
            "/users/points/gifts",
            headers={"Authorization": f"Bearer {self.recipient_token}"}
        )
        self.assertEqual(r_res.status_code, 200)
        r_data = r_res.json()
        target = next((g for g in r_data["gifts"] if g["gift_id"] == gift_id), None)
        self.assertIsNotNone(target)
        self.assertEqual(target["direction"], "RECEIVED")
        self.assertEqual(target["status"], "ACCEPTED")
        self.assertIsNotNone(target["accepted_at"])

        s_res = self.client.get(
            "/users/points/gifts",
            headers={"Authorization": f"Bearer {self.stranger_token}"}
        )
        self.assertEqual(s_res.status_code, 200)
        s_data = s_res.json()
        self.assertEqual(s_data["total_count"], 0)
        self.assertEqual(len(s_data["gifts"]), 0)

    def test_04_cancelled_and_expired_statuses(self):
        """Proof 4: CANCELLED and EXPIRED gifts return expected statuses"""
        c_res1 = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        gift_id1 = c_res1.json()["gift_id"]
        can_res = self.client.post(
            f"/users/points/gift/{gift_id1}/cancel",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(can_res.status_code, 200)

        c_res2 = self.client.post(
            "/users/points/gift/create",
            json={"gross_points": 1000},
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        gift_id2 = c_res2.json()["gift_id"]
        g2 = self.db.query(models.PointGift).filter(models.PointGift.id == gift_id2).first()
        g2.expires_at = datetime.utcnow() - timedelta(minutes=5)
        self.db.commit()

        res = self.client.get(
            "/users/points/gifts",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        gifts = res.json()["gifts"]

        g1_res = next((g for g in gifts if g["gift_id"] == gift_id1), None)
        self.assertIsNotNone(g1_res)
        self.assertEqual(g1_res["status"], "CANCELLED")

        g2_res = next((g for g in gifts if g["gift_id"] == gift_id2), None)
        self.assertIsNotNone(g2_res)
        self.assertEqual(g2_res["status"], "EXPIRED")

    def test_05_bounded_pagination(self):
        """Proof 5: Pagination limit and offset parameters are bounded properly"""
        res = self.client.get(
            "/users/points/gifts?limit=2&offset=0",
            headers={"Authorization": f"Bearer {self.sender_token}"}
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["limit"], 2)
        self.assertEqual(data["offset"], 0)
        self.assertLessEqual(len(data["gifts"]), 2)

if __name__ == "__main__":
    unittest.main()
