# 남포고고 Release AAB 빌드 결과 및 무결성 검증 보고서 (RELEASE_AAB_VERIFICATION)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  
**기준 Commit**: `b45f7b6`  

---

## 1. 생성된 Release AAB 아티팩트 정보

| 항목 | 검증 결과 | 비고 |
| :--- | :--- | :--- |
| **원본 생성 경로** | `04_Source_Code\frontend\build\app\outputs\bundle\release\app-release.aab` | `flutter build appbundle --release` |
| **루트 사본 경로** | `D:\dev\Nampo_GoGo_Project\NampoGoGo-RELEASE-1.0.0-vc1-b45f7b6-20260802.aab` | 배포 보관용 |
| **파일 크기** | `67,447,111` bytes (약 64.32 MB) | **정상 생성 (>0 bytes)** |
| **SHA-256 해시** | `e36758e26a1aad831c7ec0acb65202cc7886c468b22adbd5cc19f1eb2536b3c4` | 해시 검증 완료 |
| **Package Name** | `com.nampogogo.app` | |
| **Version Name** | `1.0.0` | |
| **Version Code** | `1` | |

---

## 2. AAB 내부 서명 및 구조 검증 결과 (ZIP Structure Check)

- **서명 블록 포함 여부 (META-INF/*.RSA / *.SF)**: **포함 완료 (True)**
- **Debug 서명 키 사용 여부**: **미사용 (Upload Key `nampo-gogo-upload` 정식 서명 적용 완료)**
- **AndroidManifest.xml 포함 여부**: **포함 완료 (`base/manifest/AndroidManifest.xml`)**
- **아티팩트 내 비밀번호/Private Key 포함 여부**: **0건 (없음)**

---

## 3. 연동 서비스 및 공개 정책 URL 설정 확인

- **Backend Production URL**: `https://backend-production-b07b.up.railway.app`
- **개인정보처리방침 URL**: `https://backend-production-b07b.up.railway.app/privacy`
- **이용약관 URL**: `https://backend-production-b07b.up.railway.app/terms`
- **계정 및 데이터 삭제 URL**: `https://backend-production-b07b.up.railway.app/account-deletion`
- **고객 지원 안내 URL**: `https://backend-production-b07b.up.railway.app/support`
