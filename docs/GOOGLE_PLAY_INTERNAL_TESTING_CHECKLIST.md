# Google Play Internal Testing 배포 체크리스트

본 문서는 Google Play 내부 테스팅(Internal Testing) 릴리즈 전 확인해야 하는 점검 목록입니다.

---

## 1. 사전 릴리즈 빌드 패키지
- [x] **Application ID**: `com.nampogogo.app` 적용 확인.
- [x] **Version Name**: `1.0.0`
- [x] **Version Code**: `1` (Play Console 빌드 업로드 시마다 순차 1씩 증가 확인).
- [ ] **AAB 파일 빌드**: `flutter build appbundle` 명령어 가동. **(REQUIRED_BEFORE_RELEASE)**
- [ ] **Android App Bundle 난독화 매핑**: Proguard/R8 난독화 적용 시 `mapping.txt` 업로드 확인. **(READY)**

---

## 2. Play Console 정책 및 URL 설정
- [x] **개인정보처리방침 URL**: `https://nampo-gogo.netlify.app/privacy/` 적용 및 연결 완료.
- [x] **이용약관 URL**: `https://nampo-gogo.netlify.app/terms/` 적용 및 연결 완료.
- [x] **계정 삭제 링크**: `https://nampo-gogo.netlify.app/delete-account/` 적용 및 연동 완료 (구글 데이터 삭제 정책 준수).
- [x] **앱 내부 회원탈퇴 메뉴**: 프로필 메뉴 하단에 회원탈퇴(FCM 토큰 제거 및 계정 비활성화/정보 삭제) 동작 적용 완료.
- [ ] **콘텐츠 등급 설문**: Play Console 설문 작성을 통해 연령 제한 등급(3세 이상 권장) 부여. **(REQUIRED_BEFORE_RELEASE)**

---

## 3. 내부 테스트 진행 구성
- [ ] **테스터 이메일 그룹 구성**: 구글 Play Console 내부 테스팅 메뉴에 테스터 이메일 등록. **(REQUIRED_BEFORE_RELEASE)**
- [ ] **테스트 계정 준비**: 스토어 심사위원이 임의 로그인하여 기능을 둘러볼 수 있도록 데모용 테스트 계정(ID/PW) 확보. **(REQUIRED_BEFORE_RELEASE)**
- [ ] **가상 결제 준비**: 모의 PG(Mock PG)를 활용한 예약 테스트에 한해, Play Console의 '라이선스 테스트' 설정 활용 권장. **(READY)**
