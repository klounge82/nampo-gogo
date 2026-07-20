# 남포 GoGo 운영 인수인계 체크리스트

본 문서는 남포 GoGo 서비스 론칭 후 실무 개발자 및 시스템 운영 담당자에게 넘겨주기 위한 시스템 인수인계 지침서입니다.

---

## 1. 운영 조직의 역할 및 책임 정의

- **운영 책임자 (Service Owner)**: 서비스 전체 통제, 정책 변경 승인, 외부 장애 공지 시점 판단.
- **최고 관리자 (Super Admin)**: Firebase Console 소유주, Google Play Console 소유주, 도메인/SSL 결제 권한 보유.
- **Backend 담당 역할 (SRE / Tech Lead)**:
  - 서버 가동 및 롤백 스크립트 실행.
  - 마이그레이션(Alembic) 형상 관리 통제.
  - 일일 백업 로그 주기적 확인.
- **고객지원 담당 역할 (CS Manager)**:
  - Play Store 리뷰 의견 수집 및 피드백 처리.
  - 회원 탈퇴 및 계정 삭제(개인정보 삭제 요청) 웹상 문의 수동 대장 관리.

---

## 2. 장애 복구 및 일일 점검 흐름

### 1) 일일 모니터링 수칙
- **헬스 체크 경로**:
  - Liveness 점검: `GET https://backend-production-b07b.up.railway.app/health/live`
  - Readiness 점검: `GET https://backend-production-b07b.up.railway.app/health/ready`
- **로그 및 백업 확인**:
  - Gunicorn/FastAPI 통합 로그: `/var/log/nampogogo_access.log` 및 `/var/log/nampogogo_error.log`
  - 데이터베이스 백업 로그: `/var/log/nampogogo_backup.log`
  - 데이터베이스 복원 로그: `/var/log/nampogogo_restore.log`

### 2) 비상 롤백 지침
- 백엔드 컨테이너 장애 시 롤백 프로세스: `docs/ROLLBACK_GUIDE.md`를 참조하여 직전 배포 태그 이미지 원복.
- 마이그레이션 롤백 시, 데이터 손실 위험이 있으므로 **반드시 수동 백업(`db_backup.sh`) 가동을 마친 뒤** `alembic downgrade` 명령어를 수행할 것.

---

## 3. 키 정보 보안 관리 및 갱신 수칙

- **JWT_SECRET 및 DB 비밀번호**: `.env.production` 파일은 Git 버전 관리에 절대 포함하지 않으며, 접근 권한이 통제된 보안 서버 내에만 적치하여 로딩.
- **Android Signing Key**: 실제 릴리즈 빌드를 유도하는 `key.properties` 파일 및 `.jks` 파일은 빌드 서버 로컬 디스크 내의 격리된 절대 경로에 배치하고 Git ignore 처리.
- **Firebase 및 Maps Key**: API 키의 도용 방지를 위해 Google Cloud Console 및 Firebase Console 에서 반드시 `com.nampogogo.app` 패키지 제한 및 SHA 서명 지문 결합 제한을 필수로 적용하여 관리할 것.

---

## 4. 실 배포 API 검증 및 인수인계 현황 (`RELEASE-001-E-RETRY-02`)
- **Backend 배포 상태**: Railway ACTIVE 배포 완료 (`https://backend-production-b07b.up.railway.app`).
- **테이블명 불일치 이슈**: `UserAuth` -> `user_auths` 해소 완료.
- **인증 및 계정 관리 API**: 회원가입, 중복 방어(400), 로그인, 내 정보 조회(`GET /users/me`), 계정 논리 탈퇴(`DELETE /users/me`) 및 탈퇴 사용자 로그인 차단(403) 정상 검증 완료.
- **매장 시드 데이터**: 현재 `stores` 0건으로 매장 Seed Data 투입 작업(`RELEASE-001-E-SEED-01`) 예정.
