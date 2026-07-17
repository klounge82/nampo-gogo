# 남포 GoGo Production 모니터링 체크리스트

본 문서는 남포 GoGo 서비스 운영 시 일별, 주별, 장애 시 점검해야 하는 인프라/애플리케이션 모니터링 체크리스트입니다.

---

## 1. 운영 모니터링 지표 및 경보 기준

| 지표 구역 | 모니터링 대상 항목 | 이상 징후 (경보 기준) | 대응 장애 등급 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **Application** | API Liveness / Readiness | ready API 응답 지연 5초 초과 또는 503 리턴 | **SEV-1** | 즉시 컨테이너 재시작 및 DB 점검 |
| **Application** | 5xx 에러율 (API 실패율) | 전체 API 트래픽 대비 5% 초과 발생 시 | **SEV-2** | 배포 형상 및 외부 연동 API 상태 점검 |
| **Application** | Slow Request 지연 시간 | 일반 API 1초 초과, 추천 API 2초 초과 | **SEV-3** | 데이터베이스 락업/인덱스 튜닝 필요성 진단 |
| **Database** | 커넥션 풀 사용률 | 활성 세션 점유율 90% 초과 | **SEV-2** | 백엔드 DB 세션 누수(db.close) 스캔 |
| **Backup** | 일일 백업 성공 여부 | 24시간 내 백업본 없음 또는 0바이트 크기 | **SEV-2** | db_backup.sh 실행 로그 진단 |
| **Storage** | 디스크 사용 용량 | 로컬 업로드 디스크 점유율 85% 초과 | **SEV-2** | 고아 파일 및 오래된 로그 정리 회전(Rotate) |
| **Security** | SSL 인증서 만료일 | 인증서 만료일 14일 임박 | **SEV-2** | Let's Encrypt 자동 갱신 크론 확인 |

---

## 2. 모니터링 체크리스트 목록

| ID | 구역 | 확인 항목 | 상태 | 담당 역할 | 완료일 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MON-001** | Application | `GET /health/ready` 200 OK | NOT_STARTED | Backend 담당자 | - | - |
| **MON-002** | Database | DB `SELECT 1` ping 10ms 이하 | NOT_STARTED | Backend 담당자 | - | - |
| **MON-003** | Backup | `nampogogo_backup.log` 에러 없음 | NOT_STARTED | Backend 담당자 | - | - |
| **MON-004** | Storage | `static/profile_images` 용량 확인 | NOT_STARTED | Backend 담당자 | - | - |
| **MON-005** | Security | auth/login 시 raw password 로그 미출력 | NOT_STARTED | Backend 담당자 | - | - |
| **MON-006** | Logging | `X-Request-ID` 가 응답 헤더에 전파됨 | NOT_STARTED | Backend 담당자 | - | - |

*(상태값 정의: `NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `READY_FOR_REVIEW`, `APPROVED`, `COMPLETED`)*
