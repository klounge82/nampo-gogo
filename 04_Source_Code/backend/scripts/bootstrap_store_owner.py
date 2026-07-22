import os
import sys
import getpass
import logging
from typing import Dict, Any, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure app module can be imported
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import models, auth

logger = logging.getLogger("store_owner_bootstrap")

K_LOUNGE_DEFAULT_STORE_ID = "31b96920-2eb3-4f93-ab51-546fd8d933d1"

def bootstrap_store_owner(
    db: Session,
    email: str,
    password: str,
    nickname: Optional[str] = None,
    store_id: Optional[str] = None,
    role: str = "owner"
) -> Tuple[str, Optional[models.User], str]:
    """
    Idempotent store owner / admin bootstrap helper.
    
    Returns:
        Tuple[status, user_instance, message]
        status can be:
          - "CREATED"
          - "ALREADY_CONFIGURED"
          - "EXISTING_MEMBER_REQUIRES_APPROVAL"
          - "INPUT_REQUIRED"
          - "FAILED"
    """
    if not email or not email.strip() or not password or not password.strip():
        msg = "운영자 이메일과 비밀번호는 필수 입력 항목입니다."
        logger.warning(msg)
        return "INPUT_REQUIRED", None, msg

    clean_email = email.strip()
    target_store_id = store_id or K_LOUNGE_DEFAULT_STORE_ID

    # Verify target store exists if specified
    if target_store_id:
        target_store = db.query(models.Store).filter(models.Store.id == target_store_id).first()
        if not target_store:
            # Fallback check by name K-Lounge
            target_store = db.query(models.Store).filter(models.Store.name == "K-Lounge").first()
            if not target_store:
                msg = f"대상 매장(ID: {target_store_id})을 찾을 수 없습니다."
                logger.warning(msg)
                return "INPUT_REQUIRED", None, msg

    try:
        existing_user = db.query(models.User).filter(models.User.email == clean_email).first()

        if existing_user:
            if existing_user.role in ["owner", "admin"]:
                msg = f"계정 '{clean_email}'은(는) 이미 '{existing_user.role}' 권한으로 설정되어 있습니다."
                logger.info(msg)
                return "ALREADY_CONFIGURED", existing_user, msg

            if existing_user.role == "member":
                msg = f"계정 '{clean_email}'은(는) 일반 회원(member)입니다. 보안을 위해 자동 승격하지 않으며 수동 승인이 필요합니다."
                logger.warning(msg)
                return "EXISTING_MEMBER_REQUIRES_APPROVAL", existing_user, msg

        # Create new owner user
        assigned_nickname = nickname.strip() if nickname and nickname.strip() else "K-Lounge Owner"
        assigned_role = role.strip() if role in ["owner", "admin"] else "owner"

        new_user = models.User(
            email=clean_email,
            nickname=assigned_nickname,
            role=assigned_role,
            status="active"
        )
        db.add(new_user)
        db.flush()

        hashed_pwd = auth.get_password_hash(password)
        new_auth = models.UserAuth(
            user_id=new_user.id,
            hashed_password=hashed_pwd
        )
        db.add(new_auth)
        db.commit()
        db.refresh(new_user)

        msg = f"운영자 계정 '{clean_email}'이(가) 성공적으로 생성되었습니다 (Role: {assigned_role})."
        logger.info(msg)
        return "CREATED", new_user, msg

    except Exception as e:
        db.rollback()
        msg = f"Bootstrap 실행 중 오류 발생: {str(e)}"
        logger.error(msg)
        return "FAILED", None, msg

def main():
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("RESULT: INPUT_REQUIRED - DATABASE_URL 환경변수가 설정되지 않았습니다.")
        sys.exit(1)

    email = os.environ.get("OPERATOR_EMAIL")
    password = os.environ.get("OPERATOR_PASSWORD")

    # If interactive session and missing env vars, prompt securely
    if not email and sys.stdin.isatty():
        email = input("운영자 이메일 주소: ").strip()

    if not password and sys.stdin.isatty():
        password = getpass.getpass("운영자 비밀번호: ").strip()

    if not email or not password:
        print("RESULT: INPUT_REQUIRED - OPERATOR_EMAIL 및 OPERATOR_PASSWORD 환경변수 또는 대화형 입력이 필요합니다.")
        sys.exit(1)

    nickname = os.environ.get("OPERATOR_DISPLAY_NAME", "K-Lounge Owner")
    store_id = os.environ.get("OPERATOR_STORE_ID", K_LOUNGE_DEFAULT_STORE_ID)
    role = os.environ.get("OPERATOR_ROLE", "owner")

    engine = create_engine(database_url)
    SessionMaker = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionMaker()

    try:
        status, user, message = bootstrap_store_owner(db, email, password, nickname, store_id, role)
        print(f"RESULT: {status} - {message}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
