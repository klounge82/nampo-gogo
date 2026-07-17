# Nampo GoGo Backend 배포 운영 계획서 (BACKEND_DEPLOYMENT_PLAN)

본 문서는 Nampo GoGo FastAPI 백엔드를 실제 HTTPS 운영 환경에 안전하게 배포하기 위한 아키텍처 수립 및 런북 가이드라인입니다.

---

## 1. 백엔드 호스팅 방식 비교 분석
초기 MVP 릴리즈 단계에서 고려할 수 있는 세 가지 배포 방식의 장단점 비교 결과는 다음과 같습니다:

| 비교 항목 | A안. Docker 관리형 Application 호스팅 (Render, Fly.io 등) | B안. 일반 VPS / 클라우드 가상 서버 (AWS EC2, Lightsail) | C안. 관리형 백엔드 + DB 분리 (Render Web Service + AWS RDS) |
| :--- | :--- | :--- | :--- |
| **운영 난이도** | **낮음 (가장 쉬움)** | 중간 (리눅스 명령어 수동 관리) | 중간 (두 서비스 연동 및 방화벽 설정) |
| **초기 비용** | 낮음 (월 $7 ~ $15) | **매우 낮음** (AWS 프리티어 또는 월 $3.5) | 중간 (월 $25 이상) |
| **배포 편의성** | **매우 우수** (Git push 연동 자동 배포) | 보통 (수동 git pull 및 docker compose 빌드) | 우수 |
| **Database Backup** | 지원 가능 (플랫폼 내장 기능) | 수동 크론탭 쉘 스크립트 작성 필요 | 우수 (AWS RDS 자동 백업 내장) |
| **HTTPS (SSL)** | **자동 관리** (Let's Encrypt 기본 활성) | Certbot 수동 주입 및 Nginx 프록시 설정 필요 | 자동 관리 및 AWS ACM 매핑 |
| **장애 복구** | 자동 헬스체크 및 롤백 내장 | 모니터링 툴 및 수동 재기동 필요 | 우수 (DB/WAS 개별 복구) |
| **초기 적합성** | **최우수 (권장안)** | 우수 | 보통 |

### 최종 권장안: A안 (Docker 지원 관리형 Application 호스팅)
- **이유**: SSL 자동 발급 및 갱신, Git push 연동 배포(CD), 자동 헬스체크 기반 롤백 기능이 내장되어 있어 1인 개발/운영 리소스를 대폭 아낄 수 있으며 초기 비용 또한 Lightsail 수준으로 저렴하여 가장 적합합니다.

---

## 2. 권장 시스템 사양
- **CPU**: 1 vCPU (최소 0.5 vCPU)
- **Memory**: 1GB RAM (최소 512MB RAM)
- **Disk**: 10GB SSD 이상 (Persistent Disk 볼륨 마운트 필요 - 사용자 이미지 영구 보관용)

---

## 3. Docker 배포 및 HTTPS 구조
- **멀티 스테이지 빌드**: Python 3.12-slim 기반 `Dockerfile` 최적화 구조 기동.
- **Nginx Reverse Proxy**: Gunicorn WAS 앞단에 Nginx 컨테이너를 프록시로 배치하여 률 제한(Rate Limit - 10r/s) 및 static 에셋 직접 처리.
- **SSL (HTTPS)**: Let's Encrypt 무료 인증서를 활용하며, nginx.conf 에 주석 처리된 443 SSL server 블록을 실 배포 시 활성화.

---

## 4. API 도메인 및 헬스 체크
- **배포 도메인 예시**: `https://api.nampogogo.com` (또는 호스팅 업체 지정 HTTPS 기본 도메인)
- **생존 점검 (Liveness)**: `GET /health/live` (200 OK)
- **준비도 점검 (Readiness)**: `GET /health/ready` (PostgreSQL ping SELECT 1 검증)

---

## 5. 배포 순서 및 롤백 절차

### 신규 버전 배포 순서
1. 로컬 환경에서 소스 코드 정적 정합성 (`flutter analyze` 및 python compile) 검증 통과.
2. Production Database 백업 스크립트 (`db_backup.sh`) 수동 작동 및 0바이트 아님 확인.
3. 배포 브랜치에 Git commit 및 push.
4. 호스팅 빌드 로그 확인 및 `/health/live` 정상 응답 검사.
5. 신규 Alembic 마이그레이션 적용 (`alembic upgrade head`).
6. Core API 기능 3종 Smoke Test 기동.

### 롤백(Rollback) 절차
- 배포 직후 헬스 체크 실패, 로그인 불능, 5xx 에러 대량 발생 시 지체 없이 호스팅 콘솔을 통해 **이전 안정 버전(Previous Deploy)으로 원클릭 Rollback** 실행.
- 만약 DB 스키마 구조 변경(Migration) 이후 롤백이 불가피한 경우, 백업된 `.dump` 파일의 복원을 수동 승인 후 `db_restore.sh` 에 `--confirm-production-restore` 옵션을 인가하여 강제 덮어쓰기 기동.
