# 초보자를 위한 Google Play App Signing 개념 안내서 (PLAY_APP_SIGNING_BEGINNER_GUIDE)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  

---

## 1. Google Play App Signing이란?
Google Play App Signing은 개발자가 빌드한 앱을 사용자에게 배포할 때, 앱 서명을 개발자 개인 컴퓨터 대신 Google의 보안 인프라에서 관리해 주는 서비스입니다. 2021년 8월 이후 출시되는 모든 신규 앱(AAB 포맷)의 필수 요구사항입니다.

---

## 2. 두 가지 키의 역할 구분 (Upload Key vs App Signing Key)

```
[개발자 PC]                                    [Google Play Console]                         [사용자 스마트폰]
 Upload Key로 서명 ──(업로드)──> AAB 수신 ──> Google App Signing Key로 재서명 ──(다운로드)──> APK 설치
```

1. **업로드 키 (Upload Key)**:
   - **역할**: 개발자가 작성한 AAB 빌드 파일이 개발자 본인이 작성한 파일임을 Google Play에 증명하는 서명 키.
   - **관리자**: 개발자 (황병준).
   - **분실 시**: Google에 승인을 요청하여 새로운 Upload Key로 재발급/교체 가능.

2. **앱 서명 키 (App Signing Key)**:
   - **역할**: 사용자 휴대폰에 최종 설치되는 APK를 서명하는 최상위 원본 키.
   - **관리자**: Google 보안 서버 (Google이 안전하게 분산 관리).
   - **장점**: 개발자의 컴퓨터가 고장나거나 키를 잃어버려도 사용자 앱 업데이트가 끊기지 않음.

---

## 3. 인증서 지문(SHA-1 / SHA-256) 활용처 구분

- **Google Login / Firebase / Naver / Kakao API 설정 시**:
  - 개발 중 테스트할 때: Debug Key SHA-1 등록.
  - Play Store 정식 출시 후: **Google Play Console에 등록된 [App Signing Key Certificate SHA-1]**을 Kakao/Naver/Google Developers 콘솔에 추가 등록해야 로그인/지도가 정상 작동합니다.
