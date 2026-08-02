# 남포고고 진단용 모바일 앱(APK) 상세 정보서 (EXTERNAL_SECURITY_APK_INFO_KO)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  

---

## 1. 진단 대상 APK 기본 정보

| 항목 | 상세 정보 |
| :--- | :--- |
| **파일 경로** | `D:\dev\Nampo_GoGo_Project\NampoGoGo-ACCOUNT-DELETE-HOTFIX-b45f7b6-20260801.apk` |
| **파일명** | `NampoGoGo-ACCOUNT-DELETE-HOTFIX-b45f7b6-20260801.apk` |
| **파일 크기** | `176,660,128` bytes (약 168.4 MB) |
| **SHA-256 해시** | `4aa660322e2db20221f0004ee13540cb410cc7756d698c78418cddfd8ce94e82` |
| **Package Name** | `com.nampo.gogo` |
| **Build Target / Mode** | Debug Build (`flutter build apk --debug`) |
| **기준 Commit** | `b45f7b6` |
| **Backend Base URL** | `https://backend-production-b07b.up.railway.app` |

---

## 2. Debug APK 사용 적합성 및 한계점 보고

### 1차 진단 (현재 준비된 Debug APK)
- **적합성**: REST API 엔드포인트 연동, JWT 인증/세션, 권한 검증(IDOR), business/admin 업무 로직 점검 등 **API 기반 보안진단에 100% 적합**.
- **한계점**: Debug 빌드 특성상 `android:debuggable="true"` 설정이 활성화되어 있으며, 코드 난독화(Proguard/R8)가 적용되지 않아 정적 분석 시 역공학(Decompilation)이 용이함.

### 최종 정식 출시 전 진단 (권장사항)
- 정식 Google Play Console 출시 직전에는 **Release 서명(Signed Release APK / AAB)** 기반 빌드를 별도 작성하여 APK 난독화, 루팅 탐지, 디버깅 방지 기능의 작동 여부를 최종 검증할 것을 권장합니다.

---

## 3. APK 바이너리 내부 임베딩 검증 상태

- `kernel_blob.bin` 내 회원탈퇴 UI 및 오류 처리 로직 100% 포함 확인 (`account_delete_screen.dart` / `SnackBarBehavior`).
- 하드코딩된 서비스 관리자 비밀번호, DB 접속 URL, Firebase Admin Service Account Key 등 **민감한 Secret 포함 여부 0건 확인 완료**.
- 백엔드 통신 통로: HTTPS (TLS 1.2/1.3 적용).
