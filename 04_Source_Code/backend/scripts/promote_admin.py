"""
One-off Admin Promotion CLI Script
Usage: python scripts/promote_admin.py <target_user_email_or_id>
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Attempt loading .env if available without logging secrets
try:
    from dotenv import load_dotenv
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
    if os.path.exists(env_path):
        load_dotenv(env_path)
except ImportError:
    pass

from app.database import SessionLocal
from app import models

def mask_email_str(email: str) -> str:
    if not email or "@" not in email:
        return "미등록"
    user_part, domain = email.split("@", 1)
    if len(user_part) <= 2:
        masked_user = user_part[0] + "*" * (len(user_part) - 1)
    else:
        masked_user = user_part[:2] + "*" * (len(user_part) - 2)
    return f"{masked_user}@{domain}"

def promote_user_to_admin(target_identifier: str) -> bool:
    db = SessionLocal()
    try:
        user = db.query(models.User).filter(
            (models.User.email == target_identifier) | (models.User.id == target_identifier)
        ).first()

        if not user:
            print(f"[-] Error: User '{target_identifier}' not found.")
            return False

        email_masked = mask_email_str(user.email)
        print(f"[*] Target User: {email_masked} (ID: {user.id})")

        # Check existing roles before update
        existing_roles = [r.role for r in db.query(models.UserRole).filter_by(user_id=user.id).all()]
        if not existing_roles and user.role:
            existing_roles = [user.role.upper()]

        print(f"[*] Pre-update roles: {existing_roles}")

        # Idempotent role update: set primary role and add ADMIN UserRole
        user.role = "admin"

        existing_admin_role = db.query(models.UserRole).filter(
            models.UserRole.user_id == user.id,
            models.UserRole.role == "ADMIN"
        ).first()

        rows_added = 0
        if not existing_admin_role:
            db.add(models.UserRole(user_id=user.id, role="ADMIN"))
            rows_added = 1

        db.commit()

        # Re-verify roles in read-only mode after commit
        updated_roles = [r.role for r in db.query(models.UserRole).filter_by(user_id=user.id).all()]
        print(f"[SUCCESS] User '{email_masked}' (ID: {user.id}) updated successfully.")
        print(f"[*] Post-update roles: {updated_roles} (Rows added to user_roles: {rows_added})")
        return True
    except Exception as e:
        db.rollback()
        print(f"[-] Error during admin promotion: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/promote_admin.py <user_email_or_id>")
        sys.exit(1)
    
    target = sys.argv[1]
    promote_user_to_admin(target)
