# 남포 GoGo 실배포 필수 입력 자격정보 요구서 (RELEASE_001)

본 문서는 남포 GoGo 서비스의 실 운영 환경 배포 및 Google Play Console 내부 테스팅(Internal Testing) 빌드를 실행하기 위해 사전에 확보되어야 하는 필수 운영 자격정보 목록입니다.

---

## 1. 운영 인프라 및 도메인 자격정보

### 1) PRODUCTION_DOMAIN & PRODUCTION_API_BASE_URL
- **필요한 이유**: 모바일 클라이언트(Flutter)가 통신할 정식 백엔드 호스트 및 프록시 SSL 연결 종단점 확보.
- **현재 상태**: `PLACEHOLDER` (현재 실도메인 미구매 상태)
- **준비 방법**: 가비아, 가비아 또는 AWS Route 53 등에서 `nampogogo.com` 과 같은 정식 도메인을 구매하고, API 서버용 서브도메인(`api.nampogogo.com`)을 네임서버 DNS 에 매핑.
- **입력할 파일/위치**:
  - Backend: `docker-compose.prod.yml` 내 `ALLOWED_ORIGINS` 및 `.env.production`
  - Flutter: Production `dart-define` 빌드 옵션 `API_BASE_URL`
- **우선순위**: **HIGH**

---

## 2. 안드로이드 서명 (Android Signing configs)

### 1) Keystore 파일 (.jks 또는 .keystore)
- **필요한 이유**: Google Play Console 에 앱 빌드(AAB)를 업로드하기 위해 필수적인 배포용 서명 서명키 확보.
- **현재 상태**: `MISSING` (실제 Keystore 미생성 상태)
- **준비 방법**: `keytool -genkey -v -keystore nampo_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nampo_alias` 명령어를 실행하여 릴리즈 키 생성.
- **보안 주의사항**: **비밀번호와 키스토어 파일은 버전 제어 도구(Git)에 절대 노출되거나 커밋되어서는 안 되며, 격리된 개발 머신 로컬 절대경로 또는 비밀 보관소(AWS Secrets Manager 등)에 백업 보관되어야 함.**
- **입력할 파일/위치**: `frontend/android/app/key.properties` 에 alias 및 패스워드를 지정하고 빌드 머신의 안전한 디렉토리에 적치.
- **우선순위**: **HIGH**

---

## 3. 서드파티 운영 계정 및 API Key

### 1) Production Firebase google-services.json
- **필요한 이유**: Production 알림 수신(FCM), 분석(Analytics), 비정상 종료 추적(Crashlytics) 연동을 위한 Firebase 연동 규격 파일.
- **현재 상태**: `MISSING` (Firebase 운영 프로젝트 미생성 상태)
- **준비 방법**: Firebase Console 에 접속하여 새 프로젝트 `Nampo GoGo (Production)` 을 생성하고, Android 앱 등록 시 패키지명 `com.nampogogo.app` 및 생성한 Keystore 의 SHA-1/SHA-256 서명 지문을 등록하여 `google-services.json` 다운로드.
- **입력할 파일/위치**: `frontend/android/app/google-services.json` 에 덮어쓰기.
- **우선순위**: **HIGH**

### 2) Google Maps Release API Key
- **필요한 이유**: 실 운영 환경에서 구글 지도 지도 타일 렌더링 및 위치 검색 기능 제공.
- **현재 상태**: `PLACEHOLDER` (현재 실 API 키 미설정 상태)
- **준비 방법**: Google Cloud Console 에 접속하여 Maps SDK for Android API 를 활성화하고, 신규 API 키를 생성한 뒤 **애플리케이션 제한사항(Android 패키지 com.nampogogo.app 및 SHA-1 인증서 지문 등록)을 설정하여 권한을 엄격히 제한.**
- **입력할 파일/위치**: `frontend/android/local.properties` 또는 gradle properties 내 `MAPS_API_KEY` 바인딩.
- **우선순위**: **HIGH**

---

## 4. 스토어 공개 URL 및 정책 문서
 
 ### 1) 약관·개인정보처리방침·계정삭제 URL
 - **필요한 이유**: Google Play 스토어 심사 통과 및 데이터 안전성 선언을 위해 전 세계 누구에게나 로그인 없이 접근 가능한 공개 링크 확보 필수.
 - **현재 상태**: **COMPLETED** (Netlify 정적 패키지 배포로 실제 링크 확보 완료)
 - **확정된 자산**:
   - 공개 웹사이트 URL: `https://nampo-gogo.netlify.app`
   - 개인정보처리방침 URL: `https://nampo-gogo.netlify.app/privacy/`
   - 이용약관 URL: `https://nampo-gogo.netlify.app/terms/`
   - 계정삭제 안내 URL: `https://nampo-gogo.netlify.app/delete-account/`
   - 고객지원 센터 URL: `https://nampo-gogo.netlify.app/support/`
   - 고객지원 이메일: `klounge@kakao.com` (베타 임시 이메일이며 출시 전 교체 예정)
 - **우선순위**: **HIGH** (검증 통과)
