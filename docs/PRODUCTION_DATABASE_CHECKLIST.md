# Nampo GoGo Production Database 검증 체크리스트 (PRODUCTION_DATABASE_CHECKLIST)

본 문서는 운영 환경 데이터베이스의 품질 향상 및 안정적인 마이그레이션 적용을 위한 점검 가이드라인입니다.

---

## 1. 운영 데이터베이스 설정 검증

| 점검 항목 | 기준 및 권장 요건 | 현재 상태 | 조치 요구사항 |
| :--- | :--- | :--- | :--- |
| **운영 인스턴스** | PostgreSQL 16.x 호환 클라우드/관리형 DB | **AVAILABLE** | Railway PostgreSQL 16.x 셋업 및 온라인 연동 성공 |
| **SSL 암호화 연결** | 외부 접속 시 SSL/TLS 통신 필수 (`sslmode=require`) | **AVAILABLE** | Railway 내부망/외부망 SSL 암호화 채널 확보 완료 |
| **Connection Pool** | `pool_pre_ping=True` (연결 유지성 실시간 모니터링) | **AVAILABLE** | `database.py` 적용 완료 |
| **Connection Limit**| 동시 커넥션 개수 제한 (WAS 워커 수 x 2) | **AVAILABLE** | default 설정 완료 |
| **자동/수동 백업** | 매일 자동 백업 기능 활성화 | **UNAVAILABLE** | Railway 무료 요금제 한계로 백업 기능 미지원 (Empty Database Baseline) |
| **Region (물리거리)** | 백엔드 WAS 서버와 동일한 IDC/Region에 배치 | **AVAILABLE** | Railway 동일 리전 가동으로 지연 최적화 |

---

## 2. Alembic Migration 적용 지침
운영 데이터베이스에 Alembic 마이그레이션 적용 시 다음 단계를 밟아야 합니다:
1. **DB 백업 실행**: 스키마 적용 직전 `db_backup.sh` 를 호출하여 최종 데이터 덤프 확보.
2. **백업 파일 유효성 검사**: 백업 파일 크기가 0바이트가 아닌지 무결성 확인.
3. **위험 명령(DROP COLUMN 등) 전수 검토**: `alembic history` 및 마이그레이션 스크립트 파일 내 파괴적인 테이블/컬럼 삭제 쿼리가 존재하는지 교차 점검.
4. **마이그레이션 실행**: `alembic upgrade head` 명령어 단독 실행.
5. **헬스체크 및 검증**: GET `/health/ready` 를 확인하여 백엔드 WAS 가 신규 스키마 DB와 정상 연결되는지 점검.

---

## 3. Database 복구 가이드라인 (Restore)
- **무조건적 덮어쓰기 금지**: 운영 DB 훼손 시 기존 DB를 바로 드롭하지 않고, 임시 복구용 데이터베이스(`nampo_recovery_db`)를 별도 생성하여 우선 restore 할 것을 강력 권장합니다.
- **RESTORE 강제 가드**: `db_restore.sh` 수행 시 Target 이 `production` 인 경우, 반드시 `--confirm-production-restore` 옵션을 직접 입력하도록 설계하여 관리자 실수에 따른 대형 사고를 방지합니다.
