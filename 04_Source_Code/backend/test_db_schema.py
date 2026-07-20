import sys
import os

def test_db_schema():
    print("=== STARTING DATABASE SCHEMA VERIFICATION TESTS ===")
    try:
        from app.models import UserAuth, Base, User
        
        # 1. UserAuth.__table__.name이 최종 기준 테이블명과 일치
        table_name = UserAuth.__table__.name
        print(f"UserAuth table name: {table_name}")
        assert table_name == "user_auths", f"UserAuth.__table__.name must be 'user_auths', but got '{table_name}'"
        print("[PASS] UserAuth.__table__.name matches 'user_auths'.")
        
        # 2. SQLAlchemy Metadata에 인증 테이블이 중복되지 않음
        # 3. users_auth와 user_auths가 동시에 생성되지 않음
        metadata_tables = Base.metadata.tables.keys()
        print(f"Tables in SQLAlchemy Metadata: {list(metadata_tables)}")
        
        assert "user_auths" in metadata_tables, "Metadata must contain 'user_auths'"
        assert "users_auth" not in metadata_tables, "Metadata must NOT contain duplicate 'users_auth' table"
        print("[PASS] No duplicate authentication tables in Metadata.")
        
        # 4. Foreign Key 대상이 실제 모델과 일치
        # UserAuth.user_id should have a foreign key to users.id
        user_id_column = UserAuth.__table__.columns.get("user_id")
        assert user_id_column is not None, "UserAuth must have 'user_id' column"
        
        foreign_keys = list(user_id_column.foreign_keys)
        assert len(foreign_keys) == 1, "UserAuth.user_id must have exactly one Foreign Key constraint"
        fk = foreign_keys[0]
        assert fk.target_fullname == "users.id", f"Foreign Key must target 'users.id', but targets '{fk.target_fullname}'"
        print("[PASS] Foreign Key constraint target is correct ('users.id').")
        
        # 5. Repository/앱 코드 전체에서 존재하지 않는 테이블명('users_auth')을 참조하지 않는지 검증
        # We can search the app source code directory to ensure there are no literal references to "users_auth"
        # as a string in database queries (except maybe comments/docs or in this test file itself)
        app_dir = os.path.join(os.path.dirname(__file__), "app")
        invalid_references = []
        for root, dirs, files in os.walk(app_dir):
            for file in files:
                if file.endswith(".py"):
                    filepath = os.path.join(root, file)
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                        if "users_auth" in content:
                            invalid_references.append(filepath)
                            
        assert len(invalid_references) == 0, f"Found invalid references to 'users_auth' in: {invalid_references}"
        print("[PASS] No invalid 'users_auth' references in app directory.")
        
    except AssertionError as e:
        print(f"[FAIL] Assertion error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"[FAIL] Unexpected error: {e}")
        sys.exit(1)
        
    print("=== ALL DATABASE SCHEMA VERIFICATION TESTS PASSED ===")

if __name__ == "__main__":
    test_db_schema()
