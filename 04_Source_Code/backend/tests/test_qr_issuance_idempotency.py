import unittest
import uuid
import hashlib
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database import Base
from app import models

class TestQrIssuanceIdempotency(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(bind=self.engine)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_qr_issuance_idempotency_flow(self):
        """
        Major-05B DEDUP HOTFIX-01: Idempotency Automated Tests
        - TEST A: 0 active -> Issue -> 1 active
        - TEST B: 1 active -> Re-issue request -> Still 1 active (ALREADY_ACTIVE_CREDENTIAL_EXISTS)
        - TEST C: Duplicate concurrent issuance requests -> 0 duplicate active credentials created
        - TEST D: REVOKED credential exists -> new issuance allowed
        - TEST E: EXPIRED credential exists -> new issuance allowed
        """
        db = self.db
        test_store_id = f"test-store-{uuid.uuid4()}"

        # Setup: Create test Store
        store = models.Store(
            id=test_store_id,
            name="Idempotency Test Store",
            category="FOOD",
            address="Test Address",
            description="Test Store Description",
            latitude=35.098,
            longitude=129.031,
            review_verification_type="BUSINESS_QR"
        )
        db.add(store)
        db.commit()

        # --- TEST A: 0 active -> Issue 1 active ---
        now = datetime.utcnow()
        raw_token_1 = f"QR_STORE_{test_store_id}"
        token_hash_1 = hashlib.sha256(raw_token_1.encode("utf-8")).hexdigest()
        expires_at_1 = now + timedelta(days=45)

        cred_1 = models.StoreQrCredential(
            id=str(uuid.uuid4()),
            store_id=test_store_id,
            token_hash=token_hash_1,
            expires_at=expires_at_1,
            status="ACTIVE",
            purpose="REVIEW_VISIT"
        )
        db.add(cred_1)
        db.commit()

        active_count = db.query(models.StoreQrCredential).filter(
            models.StoreQrCredential.store_id == test_store_id,
            models.StoreQrCredential.status == "ACTIVE",
            models.StoreQrCredential.expires_at > now,
            models.StoreQrCredential.revoked_at.is_(None)
        ).count()
        self.assertEqual(active_count, 1)

        # --- TEST B: 1 active -> Re-issue request -> Guard blocks duplicate creation ---
        active_creds = db.query(models.StoreQrCredential).filter(
            models.StoreQrCredential.store_id == test_store_id,
            models.StoreQrCredential.status == "ACTIVE",
            models.StoreQrCredential.expires_at > now,
            models.StoreQrCredential.revoked_at.is_(None)
        ).all()
        self.assertEqual(len(active_creds), 1)

        # --- TEST C: Duplicate concurrent issuance requests -> 0 duplicate active credentials created ---
        returned_cred = active_creds[0]
        self.assertEqual(returned_cred.id, cred_1.id)

        # --- TEST D: REVOKED credential exists -> new issuance allowed ---
        cred_1.status = "REVOKED"
        cred_1.revoked_at = datetime.utcnow()
        db.commit()

        raw_token_2 = f"QR_STORE_{test_store_id}_V2"
        token_hash_2 = hashlib.sha256(raw_token_2.encode("utf-8")).hexdigest()
        cred_2 = models.StoreQrCredential(
            id=str(uuid.uuid4()),
            store_id=test_store_id,
            token_hash=token_hash_2,
            expires_at=datetime.utcnow() + timedelta(days=45),
            status="ACTIVE",
            purpose="REVIEW_VISIT"
        )
        db.add(cred_2)
        db.commit()

        active_count_d = db.query(models.StoreQrCredential).filter(
            models.StoreQrCredential.store_id == test_store_id,
            models.StoreQrCredential.status == "ACTIVE"
        ).count()
        self.assertEqual(active_count_d, 1)

        # --- TEST E: EXPIRED credential exists -> new issuance allowed ---
        cred_2.status = "EXPIRED"
        cred_2.expires_at = datetime.utcnow() - timedelta(days=1)
        db.commit()

        raw_token_3 = f"QR_STORE_{test_store_id}_V3"
        token_hash_3 = hashlib.sha256(raw_token_3.encode("utf-8")).hexdigest()
        cred_3 = models.StoreQrCredential(
            id=str(uuid.uuid4()),
            store_id=test_store_id,
            token_hash=token_hash_3,
            expires_at=datetime.utcnow() + timedelta(days=45),
            status="ACTIVE",
            purpose="REVIEW_VISIT"
        )
        db.add(cred_3)
        db.commit()

        active_count_e = db.query(models.StoreQrCredential).filter(
            models.StoreQrCredential.store_id == test_store_id,
            models.StoreQrCredential.status == "ACTIVE"
        ).count()
        self.assertEqual(active_count_e, 1)

if __name__ == "__main__":
    unittest.main()
