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
| **REL-001-BACKEND** | Backend  | Backend 실제 호스팅 및 실 배포 기동 완료 | **COMPLETED** | - |
| **REL-GATE-RUN-06** | Operations | 실 백업 자동 크론 구동 및 UptimeRobot 활성화 | **REQUIRED_BEFORE_RELEASE** | 스케줄러 등록 및 모니터링 링크 확인 |

*(상태값 정의 기준: `COMPLETED`, `READY`, `REQUIRED_BEFORE_RELEASE`, `BLOCKED`, `NOT_APPLICABLE`)*
