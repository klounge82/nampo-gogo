# Nampo GoGo Production Secret 관리 체크리스트 (PRODUCTION_SECRET_CHECKLIST)

본 문서는 Nampo GoGo 서비스 운영에 필수적인 환경변수 목록 및 보안 수준, 그리고 호스팅별 주입 규격을 기술합니다.

---

## 1. 운영 환경변수 명세 및 점검 테이블

| 변수명 | 필수 여부 | Dev 필요 | Prod 필요 | Secret 여부 | 권장 주입 방식 | 현재 확보 상태 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **APP_ENV** | 예 | 예 | 예 | 아니오 | Docker / OS Env | `production` 확정 |
| **DATABASE_URL** | 예 | 예 | 예 | **예 (HIGH)** | 호스팅 Provider Env | **MISSING** (실 운영 주소 미지정) |
| **POSTGRES_DB** | 예 | 예 | 예 | 아니오 | docker-compose Env | `nampo_gogo_prod` |
| **POSTGRES_USER** | 예 | 예 | 예 | 아니오 | docker-compose Env | `nampo_admin_prod` |
| **POSTGRES_PASSWORD**| 예 | 예 | 예 | **예 (HIGH)** | 호스팅 Provider Env | **MISSING** (실 암호 미지정) |
| **JWT_SECRET** | 예 | 예 | 예 | **예 (HIGH)** | 호스팅 Provider Env | **MISSING** (실 암호 미지정) |
| **ALLOWED_ORIGINS** | 예 | 예 | 예 | 아니오 | docker-compose Env | `https://nampo-gogo.netlify.app` |
| **PAYMENT_MODE** | 예 | 예 | 예 | 아니오 | docker-compose Env | `mock` (안전 락업 유지) |
| **LOG_LEVEL** | 아니오 | 예 | 예 | 아니오 | docker-compose Env | `info` |

---

## 2. 보안 비밀정보(Secret) 입력 가이드
- **호스팅 플랫폼 주입 (우선권장)**: Render, AWS ECS 등 관리형 호스팅을 쓸 때 설정 파일(.env 등)에 비밀 값을 직접 기록하지 않고, **호스팅 제공사 설정의 "Environment Variables / Secret Settings"** 화면에 `JWT_SECRET`, `POSTGRES_PASSWORD` 등을 기재하여 메모리 상에 주입시킵니다.
- **서버 내부 격리 파일**: VPS 등을 쓰는 경우, `.env.production` 파일 권한을 `chmod 600` 으로 부여하여 비루트 계정의 접근을 제한합니다.

---

## 3. Secret 주입 시 필수 금지사항 (Guards)
1. **버전 제어 도구(Git) 커밋 절대 금지**: 어떠한 경우에도 실제 비밀번호가 포함된 `.env` 또는 키스토어 설정 파일이 Git 리포지토리에 올라가서는 안 됩니다.
2. **소프트웨어 번들(AAB/APK) 내포 금지**: JWT_SECRET 이나 Database 패스워드는 클라이언트 코드에 절대 내장되지 않아야 합니다.
3. **취약한 Secret 사용 금지**: 실 운영 주입 시 `change-me`, `dummy`, `your-secret` 과 같은 문자열 사용을 코드 수준에서 적극 차단하며, 32자 이상의 무작위 난수 문자열 생성을 강제합니다. (예: `openssl rand -hex 32`)
4. **로그 노출 금지**: 에러 응답 및 액세스 로그에 Secret 또는 암호가 노출되지 않도록 `mask_sensitive_data` 파싱 모듈을 통과시킵니다.
