# Android Release 배포 체크리스트

본 문서는 남포 GoGo Android 모바일 클라이언트 출시 배포 시 구성 필수 항목을 검증하기 위한 가이드라인입니다.

---

## 1. 릴리즈 필수 빌드 구성 상태

- [x] **Application ID**: `com.nampogogo.app` 적용 완료.
- [x] **Gradle namespace**: `com.nampogogo.app` 적용 완료.
- [x] **MainActivity package**: `com.nampogogo.app` 적용 완료.
- [x] **앱 표시 이름**: `Nampo GoGo` (`AndroidManifest.xml` label 적용 완료).
- [ ] **Android Keystore**: 실제 운영 배포 전 수동 생성 필요. **(REQUIRED_BEFORE_RELEASE)**
- [x] **signingConfigs release 우회 차단**: `key.properties` 누락 시 debug signing 으로 자동 우회되어 빌드되는 것 방지 조치 완료.
- [x] **Production Cleartext 차단**:usesCleartextTraffic 속성을 제거하여 HTTPS 통신 강제 적용 완료.
- [x] **네트워크 Base URL 로컬 차단**: Production 배포 시 localhost, 127.0.0.1, 10.0.2.2 차단 적용 완료.

---

## 2. API Key 및 서드파티 운영 준비 상태

### Firebase
- [x] **Package Name 매핑**: `com.nampogogo.app` 으로 패키지 등록 준비.
- [ ] **Release SHA-1/SHA-256**: Keystore 생성 후 Firebase Console 에 지문 등록 필수. **(REQUIRED_BEFORE_RELEASE)**
- [ ] **google-services.json**: 운영용 Firebase 프로젝트용 json 다운로드 및 frontend/android/app 적치 필요. **(REQUIRED_BEFORE_RELEASE)**

### Google Maps
- [ ] **Google Maps API Key**: 구글 클라우드 콘솔에서 Maps API 활성화 후 릴리즈 키 발급 필요. **(REQUIRED_BEFORE_RELEASE)**
- [ ] **Maps Key 제한**: 패키지명(`com.nampogogo.app`) 및 SHA-1 서명 지문으로 Google Maps Key 사용량 엄격히 제한 필수. **(REQUIRED_BEFORE_RELEASE)**

---

## 3. 스토어 심사 및 정책 URL 준비 상태
- [x] **공개 웹사이트 URL**: `https://nampo-gogo.netlify.app` 반영 완료.
- [x] **개인정보처리방침 URL**: `https://nampo-gogo.netlify.app/privacy/` 반영 완료.
- [x] **이용약관 URL**: `https://nampo-gogo.netlify.app/terms/` 반영 완료.
- [x] **계정삭제 안내 URL**: `https://nampo-gogo.netlify.app/delete-account/` 반영 완료.
- [x] **고객지원 센터 URL**: `https://nampo-gogo.netlify.app/support/` 반영 완료.
- [x] **고객지원 이메일**: `klounge@kakao.com` 반영 완료.
  - *비고*: 본 이메일은 베타 단계 임시 계정으로, 정식 론칭 시 도메인 메일로 교체 예정.
- [x] **앱 내부 URL 매핑**: `ProductionConfig`를 통해 설정, 이용약관, 개인정보처리방침, 고객지원, 탈퇴 메뉴가 실공개 URL에 연결됨 확인 완료.
