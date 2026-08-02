# 남포고고 (Nampo GoGo) 외부 보안진단 점검 범위 정의서 (EXTERNAL_SECURITY_SCOPE_KO)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  
**대상 시스템**: 남포고고 (Android Flutter 모바일 앱 & FastAPI 백엔드 API)  
**기준 Commit**: `b45f7b6`  

---

## 1. 점검 목적
본 진단은 남포고고(Nampo GoGo) 서비스의 Google Play 정식 출시 전, 모바일 앱(APK) 및 백엔드 REST API의 보안 취약점을 종합 점검하여 개인정보 유출, 권한 남용, 서비스 거부, 데이터 변조 등의 위험을 선제적으로 예방하고 완가하는 것을 목적으로 합니다.

---

## 2. 점검 대상 시스템 자산

| 구분 | 자산명 / URL | 주요 기술 스택 | 비고 |
| :--- | :--- | :--- | :--- |
| **Android App** | `com.nampo.gogo` (`NampoGoGo-ACCOUNT-DELETE-HOTFIX-b45f7b6-20260801.apk`) | Flutter (Dart 3.x) | Debug / Pre-Release APK |
| **Backend API** | `https://backend-production-b07b.up.railway.app` | Python FastAPI + SQLAlchemy | Railway PaaS 배포 |
| **Database** | PostgreSQL (Railway Managed) | PostgreSQL 18 | 격리된 Staging / 테스트 환경 권장 |
| **공개 웹페이지** | `/privacy`, `/terms`, `/account-deletion`, `/support` | HTML5 Static Pages | 로그인 불필요 접근 정적 페이지 |

---

## 3. 세부 점검 항목 (Detailed Audit Domains)

### A. Android APK 모바일 진단
1. **정적 분석 (Static Analysis)**:
   - APK 디컴파일 및 역공학(Decompilation) 난독화 상태 점검.
   - AndroidManifest.xml 내 과도한 권한 설정, `android:debuggable` 및 `android:allowBackup` 설정 검증.
   - 앱 바이너리 내 하드코딩된 Secret Key, API Token, 관리자 URL, 개발용 디버그 플래그 존재 여부.
2. **동적 분석 및 데이터 저장소 (Dynamic & Storage Analysis)**:
   - Rooting, Emulator, Frida 탐지 우회 가능성.
   - Shared Preferences 및 Local SQLite DB 내 JWT Token, 이메일, 개인정보 평문 저장 여부 (Secure Storage 적용 검증).
   - Custom Deep Link 및 Intent Interception 취약점.
   - Screen Capture 및 Clipboard 내 민감정보 노출 여부.

### B. 인증 / 세션 관리 (Authentication & Session Management)
1. 회원가입 및 로그인 절차의 인증 우회 (Authentication Bypass).
2. JWT Access Token (유효기간 30분) 및 Refresh Token (유효기간 7일)의 위조, 서명 검증 우회, 재사용 공격.
3. 회원탈퇴(`DELETE /users/me`, `/auth/me`) 완료 후 기존 토큰의 즉시 폐기 여부.
4. 비밀번호 Hash (bcrypt) 검증 및 강도 정책.
5. 계정 열거(Account Enumeration) 및 Brute Force 시도에 대한 차단 조치.

### C. 권한 검증 및 IDOR / BOLA (Broken Object Level Authorization)
1. **역할(Role) 기반 권한 제어**: `CUSTOMER`, `BUSINESS`, `ADMIN` 간 API 수평/수직 권한 상승 시도.
2. **사업장 소유권(Owner/Manager/Staff) 권한 제어**:
   - `CUSTOMER` 회원이 다른 회원의 예약 조회/취소/리뷰 수정 시도 (`reservation_id`, `review_id` 변조).
   - `BUSINESS` 회원이 자신이 소유하지 않은 타 사업장의 예약 승인/거절/완료 처리 시도 (`store_id` 변조).
   - 일반 회원의 관리자 전용 API (`/admin/*`) 호출 차단 여부.
   - 회원가입 시 `role` 파라미터 직접 주입을 통한 ADMIN 승격 공격.

### D. 예약 및 상태 전환 로직 (Reservation Logic Vulnerabilities)
1. 예약 상태 트랜잭션 수명주기(`PENDING` $\rightarrow$ `APPROVED` $\rightarrow$ `COMPLETED` / `CANCELLED` / `REJECTED` / `NO_SHOW`)의 비정상적 역전 및 상태 우회 시도.
2. 미승인 상태에서의 완료 처리, 승인 후 중복 승인, 이미 취소된 예약의 상태 변경 공격.
3. 과거 날짜/미래 날짜 예약 조작 및 예약 인원 수 범위 산정 오류 검증.

### E. 리뷰 작성 및 방문 인증 (Review & Visit Verification Integrity)
1. **점포 QR 코드 및 GPS 위치 인증 우회**:
   - 매장 BUSINESS_QR 토큰 재사용 및 타 매장 QR 스캔을 통한 위조 인증.
   - 관광지(Attraction) GPS 위도/경도 좌표 조작 및 반경(Radius m) 검증 우회.
   - 미래 방문일자 조작 및 수동 방문 일자 90일 제한 우회.
2. **리뷰 무결성**:
   - 미인증 회원의 방문 인증 뱃지(`BUSINESS_QR`, `ATTRACTION_GPS`) 강제 획득 시도.
   - 타인의 리뷰 수정/삭제 및 중복 리뷰 등록 시도.

### F. 파일 업로드 및 미디어 처리 (File Upload Security)
1. 파일 확장자 검증 우회 (이중 확장자, `.php`, `.jsp`, `.exe`, `.py` 등 실행파일 업로드).
2. Content-Type 및 MIME Type 위조 공격.
3. 대용량 파일 업로드 시도를 통한 Disk Full DoS (단, 초당 요청 속도 범위 내).
4. 업로드 파일명 경로 조작 (Directory Traversal) 및 악성 SVG/HTML 스크립트 실행 (Stored XSS).
5. 업로드 이미지 내 EXIF 개인정보(위치 메타데이터) 노출 여부.

### G. 관리자 및 시스템 보안 (Admin & Server Hardening)
1. 관리자 전용 경로 및 API 노출 여부.
2. 개인정보 조회 API 내 이메일, 전화번호, 주소 과다 노출 여부.
3. CORS Policy (`Access-Control-Allow-Origin`) 설정 검증.
4. FastAPI OpenAPI/Swagger Docs (`/docs`, `/redoc`) 운영 환경 비활성화 검증.
5. HTTPS / TLS 보안 헤더 및 HTTP Method 제한 (`OPTIONS`, `TRACE` 등).
