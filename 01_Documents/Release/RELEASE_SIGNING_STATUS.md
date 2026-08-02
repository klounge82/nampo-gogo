# 남포고고 Android Release 서명 현황 및 키 정보 보고서 (RELEASE_SIGNING_STATUS)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  
**프로젝트**: 남포고고 (Nampo GoGo)  
**기준 Commit**: `b45f7b6`  

---

## 1. Release 서명키 기본 정보

| 항목 | 명세 및 설정값 | 비고 |
| :--- | :--- | :--- |
| **Keystore 저장 경로** | `C:\Users\Master\NampoGoGo_Keys\nampo-gogo-upload-key.jks` | **Git 외부 안전 보관** |
| **Key Alias** | `nampo-gogo-upload` | Upload Key 별칭 |
| **알고리즘 / 키 크기** | RSA 2048-bit | Google Play 표준 규격 |
| **유효기간** | 10,000일 (약 27년) | |
| **SHA-1 지문** | `5D:24:61:ED:C2:8B:85:A8:67:80:FD:F6:13:E9:A4:D1:80:55:E8:13` | Google Console / API 연동용 |
| **SHA-256 지문** | `DD:E7:83:12:E9:FF:E4:29:DF:1D:6F:7D:C2:44:6A:9B:7C:73:74:90:D2:AA:33:AC:C5:6B:1C:F6:62:4F:9A:F0` | App Signing 수신 지문 |

*※ 서명키 비밀번호는 암호화된 비밀번호 관리 도구에 별도 보관되며 본 문서나 로그에 출력되지 않습니다.*

---

## 2. 앱 버전 및 패키지 식별 정보

- **Package Name (applicationId / namespace)**: `com.nampogogo.app`
- **Version Name**: `1.0.0`
- **Version Code**: `1`
- **Minimum SDK (minSdk)**: `21` (Android 5.0 Lollipop 이상)
- **Target SDK (targetSdk)**: `35` / `36` (Android 15 최신 규격)

---

## 3. Security & Build Configuration Status

- **key.properties 설정 파일 위치**: `04_Source_Code\frontend\android\key.properties` (해당 파일은 `.gitignore`에 등록되어 Git 추적 방지 처리됨).
- **Gradle Release Signing 설정**: `build.gradle.kts` 내 `signingConfigs.create("release")` 구문으로 명시적 연결 완료. Missing 시 Debug signature로 fallback되지 않도록 `signingConfig = null` 안전 장치 적용.
- **Git 추적 상태**: `.gitignore`에 `key.properties`, `*.jks`, `*.keystore`, `*.aab`, `*.apk` 항목이 100% 등록되어 원격 저장소 노출 0건 확인 완료.
