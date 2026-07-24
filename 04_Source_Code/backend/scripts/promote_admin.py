"""
One-off Admin Promotion CLI Script
Usage: python scripts/promote_admin.py <target_user_email_or_id>
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal
from app import models

def promote_user_to_admin(target_identifier: str) -> bool:
    db = SessionLocal()
    try:
        user = db.query(models.User).filter(
            (models.User.email == target_identifier) | (models.User.id == target_identifier)
        ).first()

        if not user:
            print(f"[-] Error: User '{target_identifier}' not found in database.")
            return False

        # Idempotent role update
        user.role = "admin"

        existing_role = db.query(models.UserRole).filter(
            models.UserRole.user_id == user.id,
            models.UserRole.role == "ADMIN"
        ).first()

        if not existing_role:
            db.add(models.UserRole(user_id=user.id, role="ADMIN"))
            print(f"[+] Granted 'ADMIN' role in user_roles table for user ID: {user.id}")
        else:
            print(f"[*] User ID: {user.id} already has 'ADMIN' role in user_roles table.")

        db.commit()
        # Output masked user info
        email_masked = user.email[:2] + "***@" + user.email.split("@")[-1] if "@" in user.email else "***"
        print(f"[SUCCESS] User '{email_masked}' (ID: {user.id}) has been promoted to ADMIN.")
        return True
    except Exception as e:
        db.rollback()
        print(f"[-] Error promoting user: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/promote_admin.py <user_email_or_id>")
        sys.exit(1)
    
    target = sys.argv[1]
    promote_user_to_admin(target)
