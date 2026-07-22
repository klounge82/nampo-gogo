# 남포 GoGo Release Gate 체크리스트

본 문서는 남포 GoGo 서비스의 Production 오픈 최종 승인 여부를 판정하기 위한 게이트 심사 체크리스트입니다.

---

## 1. 릴리즈 게이트 점검 목록 및 상태

| Gate ID | 구역 | 확인 항목 | 상태 | 필요한 조치 | 관련 작업 ID |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **REL-PROD-001** | Product | Mock Payment 가 운영 환경에서 완전히 가드 되는가 | **COMPLETED** | - | PRODUCTION-001-C |
| **REL-PROD-002** | Product | 앱 설정 메뉴 하단에 회원탈퇴(계정삭제) 연동 완료 여부 | **COMPLETED** | - | PRODUCTION-001-G |
| **REL-BACK-001** | Backend | Production 기동 시 Swagger API 문서 노출 비활성화 여부 | **COMPLETED** | - | PRODUCTION-001-D |
| **REL-BACK-002** | Backend | CORS origins 와일드카드 기동 차단 검증 여부 | **COMPLETED** | - | PRODUCTION-001-D |
| **REL-DB-001** | Database | 24개 테이블 생성 순서 및 Alembic env.py 가드 완결 여부 | **COMPLETED** | - | PRODUCTION-001-E |
| **REL-DB-002** | Database | db_backup.sh 빈파일 감지 실패 Exit Code 처리 작동 여부 | **COMPLETED** | - | PRODUCTION-001-E |
| **REL-DB-003** | Database | db_restore.sh 에 --confirm-production-restore 가드 작동 여부 | **COMPLETED** | - | PRODUCTION-001-E |
| **REL-SEC-001** | Security | JWT_SECRET 의 Gunicorn/Production 기동 락업 작동 여부 | **COMPLETED** | - | PRODUCTION-001-D |
| **REL-SEC-002** | Security | 로그 출력 시 비밀번호, 이메일, 전화번호 마스킹 작동 여부 | **COMPLETED** | - | PRODUCTION-001-F |
| **REL-AND-001** | Android | Application ID 및 namespace com.nampogogo.app 적용 여부 | **COMPLETED** | - | PRODUCTION-001-G |
| **REL-AND-002** | Android | key.properties 가 Git 추적에서 확실히 제외되었는지 여부 | **COMPLETED** | - | PRODUCTION-001-G |
| **REL-STORE-001**| Store | 스토어 정보 등록용 Metadata 및 Data Safety 명세 확보 여부 | **COMPLETED** | - | PRODUCTION-001-G |
| **REL-001-POLICY**| Store | 공개 정책 URL 4종 및 고객지원 이메일 연결 상태 | **COMPLETED** | Netlify 정적 에셋 및 Flutter ProductionConfig 바인딩 완료 | RELEASE-001-B |
| **REL-OPER-001**| Operations| 장애 대응 런북, 모니터링 체크리스트, 롤백 가이드 수립 여부 | **COMPLETED** | - | PRODUCTION-001-F |

---

## 2. 출시 전 잔여 게이트 항목 (RELEASE-001 단계 필수 완료)

| Gate ID | 구역 | 확인 항목 | 상태 | 필요한 조치 |
| :--- | :--- | :--- | :--- | :--- |
| **REL-GATE-RUN-01** | Security | Nginx Let's Encrypt SSL 주석 활성화 | **REQUIRED_BEFORE_RELEASE** | 실제 인증서 갱신 연동 필요 |
| **REL-GATE-RUN-02** | Android | 실제 Android Keystore 생성 및 signingConfigs 탑재 | **REQUIRED_BEFORE_RELEASE** | 운영 업로드 인증 키 파일 생성 필요 |
| **REL-GATE-RUN-03** | Firebase | Production Firebase SDK Config 주입 및 AAB 빌드 | **REQUIRED_BEFORE_RELEASE** | google-services.json 실파일 적치 |
| **REL-GATE-RUN-04** | Google Maps | 구글 콘솔 SHA-1 패키지 사용량 제한 릴리즈 키 매핑 | **REQUIRED_BEFORE_RELEASE** | Maps Key 빌드 파라미터 적용 필요 |
| **REL-001-DOMAIN**  | Network  | Backend API Domain과 HTTPS 암호화 확보 | **COMPLETED** | Railway HTTPS Endpoint 실주소 연동 및 헬스 통과 완료 |
| **REL-001-SECRET**  | Security | Production Secret 안전 주입 상태 | **REQUIRED_BEFORE_RELEASE** | JWT_SECRET, DB 패스워드 등 안전 보관소 등록 필요 |
| **REL-001-DATABASE**| Database | 실제 Production 데이터베이스 서버 기동 및 연결 확보 | **COMPLETED** | 초기 Alembic Migration(001_initial_schema) 적용 완료 |
| **REL-001-STORAGE** | Storage  | 사용자 이미지 영구 보관 (Persistent Disk) 매핑 | **REQUIRED_BEFORE_RELEASE** | 컨테이너 볼륨 Persistent Storage 연동 필요 |
| **REL-001-BACKEND** | Backend  | Backend 실제 호스팅 및 실 배포 기동 완료 | **COMPLETED** | UserAuth 테이블명 정합 완료 및 인증 API Smoke Test 100% 통과 |
| **REL-001-SEED**    | Database  | Production 최초 운영 매장 K-Lounge Seed 등록 실행 | **COMPLETED** | K-Lounge 운영 매장 1건 정상 등록 및 상세 조회 통과 | RELEASE-001-E-SEED-02 |
| **REL-001-STORE-FLOW**| Backend | K-Lounge 매장 상세·즐겨찾기·리뷰 운영 API 검증 | **REVIEW_FLOW_BLOCKED** | 즐겨찾기 CUD 및 중복 방어 100% 통과, K-Lounge 미션 Seed/예약완료 API 추가 필요 | RELEASE-001-E-STORE-FLOW-01 |
| **REL-001-RES-REMEDY**| Backend | 예약 완료 상태 전환 운영 API 및 리뷰 권한 연동 검증 | **COMPLETED** | PATCH /admin/reservations/{id}/status 및 PATCH /reservations/{id}/status 권한·전환 가드 구축 및 리뷰 자격 100% 검증 | RELEASE-001-E-REVIEW-REMEDY-01 |
| **REL-001-OWNER-BOOTSTRAP**| Backend | K-Lounge 공식 Owner 계정 안전 생성 방식 구축 | **READY** | 멱등 CLI Bootstrap 스크립트(bootstrap_store_owner.py) 및 단위 테스트 구현 완료, 1회 운영 실행 준비 완료 | RELEASE-001-E-OPERATOR-BOOTSTRAP-01 |
| **REL-001-OWNER-SCOPE**| Backend | Store–Owner 소유권 관계 스키마 및 매장 단위 예약 관리 권한 가드 구축 | **READY** | StoreOwner 모델 및 Alembic 마이그레이션(002_add_store_owners.py) 구축 / require_store_owner_or_admin 매장 단위 권한 가드 100% 회귀 테스트 통과 | RELEASE-001-E-OWNER-SCOPE-REMEDY-01 |
| **REL-001-REVIEW-RETRY**| Backend | 완료 예약 기반 리뷰 작성·조회·수정·삭제 운영 API 최종 검증 | **COMPLETED** | K-Lounge Owner 계정 로그인·예약상태 전환(pending->confirmed->completed) 및 완료 예약 기반 리뷰 CUD/4xx 예외방어 100% 운영 검증 완료 (GET /reviews/me 빈 배열 반환 잔여 경고) | RELEASE-001-E-REVIEW-RETRY-01 |

*(상태값 정의 기준: `COMPLETED`, `READY`, `REQUIRED_BEFORE_RELEASE`, `INPUT_REQUIRED`, `BLOCKED`, `NOT_APPLICABLE`)*
