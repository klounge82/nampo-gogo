# 남포 GoGo Production 롤백 가이드

본 문서는 운영 배포 후 치명적 문제(서버 크래시, 데이터 비정합, 결제 승인 마비 등) 발생 시 이전 정상 상태로 안전하게 복구(Rollback)하기 위한 런북입니다.

---

## 1. 롤백 판단 기준 및 원칙

- **롤백 보류**: 마이너한 레이아웃 수정이나 우회 방법이 있는 SEV-3, SEV-4 장애는 롤백 대신 핫픽스 패치 배포를 우선합니다.
- **롤백 즉시 실행**: 핵심 결제 연동 마비, 로그인 인증 우회 발생, 혹은 Liveness가 5분 이상 복구되지 않는 경우 즉시 롤백을 실행합니다.
- **데이터베이스 롤백 경고**: **데이터베이스(Alembic Migration) 롤백은 수동 데이터 손실을 유발할 수 있으므로, 이전 코드만 되돌려 서비스가 정상화될 수 있다면 DB 스키마 롤백은 최후의 수단으로 미뤄둡니다.**

---

## 2. 영역별 롤백 실행 절차

### 1) 백엔드 애플리케이션 롤백
백엔드 서버에 새로운 버그가 유입된 경우, Docker Image 태그를 이전 정상 태그(예: `v1.2.0`)로 되돌립니다:
1. `docker-compose.prod.yml` 파일 내 backend image 태그 수정.
2. 컨테이너 재생성:
   ```bash
   # 실제 운영 환경 배포 시에만 가동
   docker compose -f docker-compose.prod.yml up -d --no-deps backend
   ```
3. `GET /health/live` 로 새 기동 프로세스의 정상 응답 대기.

### 2) 환경설정 (.env) 롤백
환경 변수(API Key, Secret 등) 오기입으로 인한 장애 시:
1. 백업본인 `.env.production.bak` 또는 정상 설정본을 확인하고 복사합니다.
2. 기동 설정을 재적재합니다.

### 3) 데이터베이스 마이그레이션 (Alembic) 롤백
Alembic 마이그레이션으로 인해 DB 스키마가 변경되었으나, 데이터 파손을 막고 이전 버전으로 되돌려야 할 때:
> [!CAUTION]
> 마이그레이션 롤백 실행 전, 반드시 `db_backup.sh` 를 호출하여 최종 데이터 스냅샷 백업을 수동 실행해야 합니다.

1. 수동 백업 가동:
   ```bash
   ./infrastructure/db_backup.sh
   ```
2. 이전 마이그레이션 버전 ID 확인:
   ```bash
   python -m alembic history
   ```
3. 특정 버전으로 downgrade 실행 (격리된 상태에서 수동 승인 후 가동):
   ```bash
   python -m alembic downgrade <이전_버전_ID>
   ```
4. 테이블 스키마 롤백 완료 후, 주요 API의 정상 쿼리 여부를 확인(Smoke Test)합니다.
