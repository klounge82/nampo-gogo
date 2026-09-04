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


class TestAdminPointGiftReadApi(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db_url = os.getenv("DATABASE_URL", "postgresql://nampo_stage12_test:nampo_stage12_disposable_only@127.0.0.1:55432/nampo_stage12_test")
        cls.engine = create_engine(cls.db_url, pool_pre_ping=True)
        cls.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=cls.engine)

    def setUp(self):
        self.db = self.SessionLocal()
        self.client = TestClient(app)

        # 1. Admin User
        self.admin_id = f"usr_adm_{uuid.uuid4().hex[:8]}"
        self.admin_user = models.User(
            id=self.admin_id,
            email=f"{self.admin_id}@test.com",
            nickname="AdminMaster",
            role="admin",
            status="active",
            current_points=0,
            lifetime_earned_points=0
        )
        self.admin_role = models.UserRole(user_id=self.admin_id, role="ADMIN")

        # 2. Ordinary Customer User
        self.customer_id = f"usr_cus_{uuid.uuid4().hex[:8]}"
        self.customer_user = models.User(
            id=self.customer_id,
            email=f"{self.customer_id}@test.com",
            nickname="OrdinaryCustomer",
            role="member",
            status="active",
            current_points=5000,
            lifetime_earned_points=5000
        )
        self.customer_role = models.UserRole(user_id=self.customer_id, role="CUSTOMER")

        # 3. Business Owner (without ADMIN)
        self.biz_id = f"usr_biz_{uuid.uuid4().hex[:8]}"
        self.biz_user = models.User(
            id=self.biz_id,
            email=f"{self.biz_id}@test.com",
            nickname="BusinessOwner",
            role="owner",
            status="active",
            current_points=1000,
            lifetime_earned_points=1000
        )
        self.biz_role = models.UserRole(user_id=self.biz_id, role="BUSINESS_OWNER")

        # 4. TEST-only User (without ADMIN)
        self.testonly_id = f"usr_tst_{uuid.uuid4().hex[:8]}"
        self.testonly_user = models.User(
            id=self.testonly_id,
            email=f"{self.testonly_id}@test.com",
            nickname="TestOnlyGuy",
            role="member",
            status="active",
            current_points=2000,
            lifetime_earned_points=2000
        )
        self.testonly_role = models.UserRole(user_id=self.testonly_id, role="TEST")

        # 5. Target User A (with divergent cache & lots)
        self.target_a_id = f"usr_tgtA_{uuid.uuid4().hex[:8]}"
        self.target_a = models.User(
            id=self.target_a_id,
            email=f"{self.target_a_id}@test.com",
            nickname="TargetUserA",
            role="member",
            status="active",
            current_points=99999, # Intentionally stale cached balance
            lifetime_earned_points=15000
        )

        # 6. Target User B (gift recipient)
        self.target_b_id = f"usr_tgtB_{uuid.uuid4().hex[:8]}"
        self.target_b = models.User(
            id=self.target_b_id,
            email=f"{self.target_b_id}@test.com",
            nickname="TargetUserB",
            role="member",
            status="active",
            current_points=0,
            lifetime_earned_points=0
        )

        self.db.add_all([
            self.admin_user, self.admin_role,
            self.customer_user, self.customer_role,
            self.biz_user, self.biz_role,
            self.testonly_user, self.testonly_role,
            self.target_a, self.target_b
        ])
        self.db.commit()

        # Create PointLots for Target A:
        # Lot 1: Finite expiry (expires in 30 days), 3000 pts, reserved 500
        now = datetime.utcnow()
        self.lot1 = models.PointLot(
            id=str(uuid.uuid4()),
            user_id=self.target_a_id,
            source_type="MISSION",
            original_points=3000,
            remaining_points=3000,
            reserved_points=500, # usable: 2500
            expires_at=now + timedelta(days=30),
            is_transferable=True,
            status="ACTIVE"
        )
        # Lot 2: Legacy No-Expiry lot, 4000 pts, reserved 0
        self.lot2 = models.PointLot(
            id=str(uuid.uuid4()),
            user_id=self.target_a_id,
            source_type="LEGACY_MIGRATION",
            original_points=4000,
            remaining_points=4000,
            reserved_points=0, # usable: 4000
            expires_at=None,
            is_transferable=False,
            status="ACTIVE"
        )
        # Lot 3: Expired lot, 1000 pts (should NOT be usable)
        self.lot3 = models.PointLot(
            id=str(uuid.uuid4()),
            user_id=self.target_a_id,
            source_type="PROMOTION",
            original_points=1000,
            remaining_points=1000,
            reserved_points=0,
            expires_at=now - timedelta(days=1),
            is_transferable=True,
            status="ACTIVE" # expired by timestamp
        )

        # Point Histories for Target A
        self.hist1 = models.PointHistory(
            id=str(uuid.uuid4()),
            user_id=self.target_a_id,
            points=3000,
            activity="Mission completion reward",
            transaction_type="MISSION_REWARD",
            source_type="MISSION",
            source_id="m_101"
        )
        self.hist2 = models.PointHistory(
            id=str(uuid.uuid4()),
            user_id=self.target_a_id,
            points=4000,
            activity="Legacy migration balance",
            transaction_type="ADMIN_CREDIT",
            source_type="LEGACY_MIGRATION"
        )

        # Point History for Customer User (to prove no leak)
        self.hist_cus = models.PointHistory(
            id=str(uuid.uuid4()),
            user_id=self.customer_id,
            points=5000,
            activity="Customer signup reward",
            transaction_type="SIGNUP_BONUS",
            source_type="SIGNUP"
        )

        self.db.add_all([self.lot1, self.lot2, self.lot3, self.hist1, self.hist2, self.hist_cus])
        self.db.commit()

        # Create sample Gifts via PointService or mock
        # Gift 1: PENDING from Target A to Target B
        op1 = models.PointOperation(id=str(uuid.uuid4()), actor_user_id=self.target_a_id, operation_type="GIFT_CREATE", status="COMPLETED")
        self.db.add(op1)
        self.db.flush()
        self.gift1 = models.PointGift(
            id=str(uuid.uuid4()),
            sender_id=self.target_a_id,
            recipient_id=self.target_b_id,
            create_operation_id=op1.id,
            gift_token_hash="hash_secret_token_1234567890abcdef",
            gross_points=1000,
            fee_points=50,
            net_points=950,
            status="PENDING",
            expires_at=now + timedelta(days=7)
        )

        # Gift 2: ACCEPTED from Customer to Target A
        op2 = models.PointOperation(id=str(uuid.uuid4()), actor_user_id=self.customer_id, operation_type="GIFT_CREATE", status="COMPLETED")
        op2_acc = models.PointOperation(id=str(uuid.uuid4()), actor_user_id=self.target_a_id, operation_type="GIFT_CLAIM", status="COMPLETED")
        self.db.add_all([op2, op2_acc])
        self.db.flush()
        self.gift2 = models.PointGift(
            id=str(uuid.uuid4()),
            sender_id=self.customer_id,
            recipient_id=self.target_a_id,
            create_operation_id=op2.id,
            accept_operation_id=op2_acc.id,
            gift_token_hash="hash_secret_token_9876543210fedcba",
            gross_points=500,
            fee_points=0,
            net_points=500,
            status="ACCEPTED",
            expires_at=now + timedelta(days=7),
            accepted_at=now
        )

        self.db.add_all([self.gift1, self.gift2])
        self.db.commit()

        self.admin_token = auth.create_access_token(data={"sub": self.admin_id})
        self.customer_token = auth.create_access_token(data={"sub": self.customer_id})
        self.biz_token = auth.create_access_token(data={"sub": self.biz_id})
        self.testonly_token = auth.create_access_token(data={"sub": self.testonly_id})

    def tearDown(self):
        self.db.close()

    def test_01_unauthenticated_rejected(self):
        """Proof 1: Unauthenticated access rejected with 401"""
        res1 = self.client.get(f"/admin/points/users/{self.target_a_id}/summary")
        self.assertEqual(res1.status_code, 401)

        res2 = self.client.get(f"/admin/points/users/{self.target_a_id}/history")
        self.assertEqual(res2.status_code, 401)

        res3 = self.client.get(f"/admin/points/users/{self.target_a_id}/lots")
        self.assertEqual(res3.status_code, 401)

        res4 = self.client.get("/admin/gifts")
        self.assertEqual(res4.status_code, 401)

    def test_02_ordinary_user_rejected(self):
        """Proof 2: Ordinary customer rejected with 403"""
        headers = {"Authorization": f"Bearer {self.customer_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 403)

        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 403)

    def test_03_business_owner_without_admin_rejected(self):
        """Proof 3: Business owner without ADMIN role rejected with 403"""
        headers = {"Authorization": f"Bearer {self.biz_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 403)

        res = self.client.get(f"/admin/points/users/{self.target_a_id}/lots", headers=headers)
        self.assertEqual(res.status_code, 403)

    def test_04_test_only_user_rejected(self):
        """Proof 4: TEST-only user without ADMIN role rejected with 403"""
        headers = {"Authorization": f"Bearer {self.testonly_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 403)

        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 403)

    def test_05_admin_can_inspect_point_summary(self):
        """Proof 5: ADMIN can inspect target user point summary"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["user_id"], self.target_a_id)
        self.assertIn("authoritative_usable_points", data)
        self.assertIn("cached_current_points", data)

    def test_06_summary_uses_authoritative_lot_balance(self):
        """Proof 6: Summary calculates authoritative usable points from lots: 2500 + 4000 = 6500"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        # lot1: 3000 - 500 = 2500; lot2: 4000 - 0 = 4000; lot3: expired (0). Total = 6500
        self.assertEqual(data["authoritative_usable_points"], 6500)

    def test_07_cache_divergence_handled_truthfully(self):
        """Proof 7: Cache divergence (99999 vs 6500) is reported clearly without corrupting authoritative balance"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/summary", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["cached_current_points"], 99999)
        self.assertEqual(data["authoritative_usable_points"], 6500)

    def test_08_admin_history_returns_target_user_ledger_only(self):
        """Proof 8: Admin history returns target user's records only"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/history", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["user_id"], self.target_a_id)
        self.assertEqual(data["total_count"], 2)
        history_ids = [h["id"] for h in data["history"]]
        self.assertIn(self.hist1.id, history_ids)
        self.assertIn(self.hist2.id, history_ids)
        self.assertNotIn(self.hist_cus.id, history_ids)

    def test_09_no_stranger_history_leak(self):
        """Proof 9: Stranger history is never leaked across user queries"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.customer_id}/history", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["total_count"], 1)
        self.assertEqual(data["history"][0]["id"], self.hist_cus.id)

    def test_10_lot_read_shows_active_finite_expiry_lot(self):
        """Proof 10: Lot read shows active finite-expiry lot with remaining & expiry"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/lots", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        lot1_entry = next((l for l in data["lots"] if l["lot_id"] == self.lot1.id), None)
        self.assertIsNotNone(lot1_entry)
        self.assertEqual(lot1_entry["original_points"], 3000)
        self.assertEqual(lot1_entry["remaining_points"], 3000)
        self.assertEqual(lot1_entry["reserved_points"], 500)
        self.assertIsNotNone(lot1_entry["expires_at"])

    def test_11_lot_read_shows_no_expiry_legacy_lot(self):
        """Proof 11: Lot read shows NO_EXPIRY legacy lot (expires_at is null)"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/lots", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        lot2_entry = next((l for l in data["lots"] if l["lot_id"] == self.lot2.id), None)
        self.assertIsNotNone(lot2_entry)
        self.assertEqual(lot2_entry["source_type"], "LEGACY_MIGRATION")
        self.assertIsNone(lot2_entry["expires_at"])

    def test_12_reserved_points_visible_correctly(self):
        """Proof 12: Reserved points and calculated usable points are correctly surfaced"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/points/users/{self.target_a_id}/lots", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        lot1_entry = next(l for l in data["lots"] if l["lot_id"] == self.lot1.id)
        self.assertEqual(lot1_entry["reserved_points"], 500)
        self.assertEqual(lot1_entry["usable_points"], 2500)

    def test_13_lot_endpoint_zero_economic_mutation(self):
        """Proof 13: Lot endpoint performs strictly zero DB modification"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        before_lots = self.db.query(models.PointLot).filter(models.PointLot.user_id == self.target_a_id).all()
        before_state = [(l.id, l.remaining_points, l.reserved_points, l.status) for l in before_lots]

        res = self.client.get(f"/admin/points/users/{self.target_a_id}/lots", headers=headers)
        self.assertEqual(res.status_code, 200)

        self.db.expire_all()
        after_lots = self.db.query(models.PointLot).filter(models.PointLot.user_id == self.target_a_id).all()
        after_state = [(l.id, l.remaining_points, l.reserved_points, l.status) for l in after_lots]
        self.assertEqual(before_state, after_state)

    def test_14_admin_gift_list_sees_cross_user_gifts(self):
        """Proof 14: Admin gift list sees cross-user gifts"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        gift_ids = [g["gift_id"] for g in data["gifts"]]
        self.assertIn(self.gift1.id, gift_ids)
        self.assertIn(self.gift2.id, gift_ids)

    def test_15_gift_status_filter_works(self):
        """Proof 15: Admin gift status filter works properly"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res_pending = self.client.get("/admin/gifts?status_filter=PENDING", headers=headers)
        self.assertEqual(res_pending.status_code, 200)
        data_p = res_pending.json()
        for g in data_p["gifts"]:
            self.assertEqual(g["status"], "PENDING")

        res_acc = self.client.get("/admin/gifts?status_filter=ACCEPTED", headers=headers)
        self.assertEqual(res_acc.status_code, 200)
        data_a = res_acc.json()
        for g in data_a["gifts"]:
            self.assertEqual(g["status"], "ACCEPTED")

    def test_16_gift_user_filter_matches_sender_and_recipient(self):
        """Proof 16: User filter matches both sender and recipient safely"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get(f"/admin/gifts?user_id={self.target_b_id}", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        for g in data["gifts"]:
            self.assertTrue(g["sender_id"] == self.target_b_id or g["recipient_id"] == self.target_b_id)

    def test_17_raw_gift_token_absent(self):
        """Proof 17: Raw gift token is completely absent from all admin responses"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 200)
        for g in res.json()["gifts"]:
            self.assertNotIn("gift_token", g)
            self.assertNotIn("token", g)

    def test_18_token_hash_absent(self):
        """Proof 18: Token hash is strictly absent from admin response"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 200)
        for g in res.json()["gifts"]:
            self.assertNotIn("gift_token_hash", g)
            self.assertNotIn("token_hash", g)

    def test_19_operation_and_idempotency_fields_absent(self):
        """Proof 19: Internal operation IDs and idempotency fields are absent"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get("/admin/gifts", headers=headers)
        self.assertEqual(res.status_code, 200)
        for g in res.json()["gifts"]:
            self.assertNotIn("create_operation_id", g)
            self.assertNotIn("accept_operation_id", g)
            self.assertNotIn("idempotency_key", g)

    def test_20_pagination_bounded(self):
        """Proof 20: Pagination limit and offset parameters are bounded properly"""
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        res = self.client.get("/admin/gifts?limit=9999&offset=-10", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["limit"], 100) # Capped at max 100
        self.assertEqual(data["offset"], 0)  # Capped at min 0

    def test_21_customer_gift_api_unaffected(self):
        """Proof 21: Customer gift API continues to function unaffected"""
        headers = {"Authorization": f"Bearer {self.customer_token}"}
        res = self.client.get("/users/points/gifts", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("gifts", data)
        for g in data["gifts"]:
            self.assertIn("direction", g)
            self.assertNotIn("gift_token_hash", g)


if __name__ == "__main__":
    unittest.main()
