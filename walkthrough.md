# Walkthrough - UserAuth SQLAlchemy 모델과 Production Migration 테이블명 불일치 수정 (RELEASE-001-E-REMEDY-02)

본 문서는 `RELEASE-001-E-REMEDY-02` 작업에 따른 변경 사항, 테스트 방법 및 검증 결과를 기록한 문서입니다.

---

## 1. 개요 및 변경 사항 (Changes Made)

운영 환경 배포 및 마이그레이션 적용 후, 회원가입 API 호출 시 `relation "users_auth" does not exist` 에러와 함께 HTTP 500 응답이 발생하는 블로커 이슈가 식별되었습니다.
이는 SQLAlchemy `UserAuth` 모델의 테이블명(`users_auth`)과 실제 운영 DB의 테이블명(`user_auths`)이 상이하여 발생한 현상입니다.

실제 DB 스키마 및 Alembic 마이그레이션 이력(`001_initial_schema.py`)에서 `user_auths`가 표준으로 적용되어 있으므로, SQLAlchemy 모델의 정의를 다음과 같이 수정하여 일관성을 확보했습니다.

### 수정 파일:
- **[MODIFY]** [models.py](file:///D:/dev/Nampo_GoGo_Project/04_Source_Code/backend/app/models.py#L55)
  - `UserAuth` 모델의 `__tablename__` 값을 기존 `"users_auth"`에서 `"user_auths"`로 변경하였습니다.

---

## 2. 테스트 및 검증 결과 (Validation Results)

### 1) Python 컴파일 및 Alembic 마이그레이션 점검
로컬 환경에서 Python 컴파일 검사 및 Alembic 상태 점검을 성공적으로 수행하였습니다.
- **Python 컴파일 결과**: 구문 오류 없음 (`python -m compileall app` 성공)
- **Alembic HEAD 상태**: 단일 HEAD (`001_initial_schema`가 최신 HEAD로 정상 작동)

### 2) 데이터베이스 스키마 및 모델 무결성 회귀 테스트 추가
[test_db_schema.py](file:///D:/dev/Nampo_GoGo_Project/04_Source_Code/backend/test_db_schema.py) 파일을 작성하여 회귀 테스트를 보완하였습니다. 검증 항목은 다음과 같습니다.
1. `UserAuth.__table__.name`이 최종 기준인 `'user_auths'`와 일치하는가?
2. SQLAlchemy Metadata에 인증 테이블이 중복으로 존재하지 않는가? (`users_auth`와 `user_auths` 동시 생성 차단)
3. 외래키(Foreign Key) 제약 조건이 실제 `users.id` 테이블을 정상적으로 바라보고 있는가?
4. 백엔드 `app/` 코드 내에 더 이상 존재하지 않는 테이블명인 `'users_auth'` 문자열을 참조하는 로직이 없는가?

### 3) 테스트 실행 결과
- `test_production_guards.py` 및 신규 추가된 `test_db_schema.py`가 모두 에러 없이 **PASS** 하였습니다.
```
=== STARTING PRODUCTION GUARDS UNIT TESTS ===
[PASS] APP_ENV correctly set to production.
[PASS] CORS allowed_origins correctly restricted.
=== ALL PRODUCTION GUARDS UNIT TESTS PASSED ===

=== STARTING DATABASE SCHEMA VERIFICATION TESTS ===
UserAuth table name: user_auths
[PASS] UserAuth.__table__.name matches 'user_auths'.
[PASS] No duplicate authentication tables in Metadata.
[PASS] Foreign Key constraint target is correct ('users.id').
[PASS] No invalid 'users_auth' references in app directory.
=== ALL DATABASE SCHEMA VERIFICATION TESTS PASSED ===
```

---

## 3. 관련 문서 갱신

- **[MODIFY]** [RELEASE_GATE_CHECKLIST.md](file:///D:/dev/Nampo_GoGo_Project/docs/RELEASE_GATE_CHECKLIST.md#L40)
  - `REL-001-BACKEND` 항목의 상태를 `BLOCKED`에서 `COMPLETED`로 업데이트하였습니다.
- **[MODIFY]** [PRODUCTION_READINESS_REPORT.md](file:///D:/dev/Nampo_GoGo_Project/docs/PRODUCTION_READINESS_REPORT.md#L52)
  - 백엔드 실 배포 및 주소 연동 준비 상태를 `COMPLETED`로 변경하고 테이블명 불일치 해소를 기록했습니다.
- **[MODIFY]** [10_Change_Log.csv](file:///D:/dev/Nampo_GoGo_Project/02_CSV/10_Change_Log.csv#L53)
  - `CHG-038-E-R2` 작업 내역을 반영하여 상태를 `READY_FOR_DEPLOY`로 갱신했습니다.
