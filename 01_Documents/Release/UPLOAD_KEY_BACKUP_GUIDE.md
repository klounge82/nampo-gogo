# 남포고고 Upload Key 백업 및 복구 가이드 (UPLOAD_KEY_BACKUP_GUIDE)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  

---

## 1. Upload Key 분실 위험 및 백업의 중요성
Google Play Console 배포 시 개발자가 생성한 Upload Key는 AAB 업로드용 서명으로 사용됩니다. Upload Key 또는 비밀번호를 분실하면 새 버전의 AAB를 Play Store에 업로드할 수 없게 되므로, 다중 물리 매체에 안전하게 백업해야 합니다.

---

## 2. 보관 및 백업 체계 (3-2-1 백업 원칙)

| 구분 | 저장 매체 | 저장 경로 / 방식 | 비고 |
| :--- | :--- | :--- | :--- |
| **Primary (원본)** | 개발 PC 로컬 디스크 | `C:\Users\Master\NampoGoGo_Keys\nampo-gogo-upload-key.jks` | Git 영역 외부 |
| **Secondary (외장)** | 암호화된 USB / 외장 SSD | `E:\NampoGoGo_Key_Backup\nampo-gogo-upload-key.jks` | 물리적 격리 보관 |
| **Password (비밀번호)**| 비밀번호 볼트 (KeePass/Bitwarden) | 별도 암호화 저장소 | 별칭 `nampo-gogo-upload` 포함 |

---

## 3. 키 복구 및 재설정 절차

### 만약 개발 PC의 원본 키 파일이 손상된 경우:
1. 백업 외장 매체에서 `nampo-gogo-upload-key.jks` 파일을 `C:\Users\Master\NampoGoGo_Keys\` 복사.
2. `04_Source_Code\frontend\android\key.properties` 파일 내 `storeFile` 경로 재확인.
3. `flutter build appbundle --release` 명령을 실행하여 AAB 정상 생성 여부 검증.

### 만약 Upload Key를 완전히 분실한 경우 (Play App Signing 수신 절차):
1. Google Play Console 관리자 접속 $\rightarrow$ [앱 서명] 메뉴 이동.
2. "업로드 키 분실" 문의 제출.
3. 새 Upload Key를 `keytool`로 생성 후 생성된 `PEM` 서명 인증서를 Google Play 지원팀에 전송하여 Upload Key 교체 승인 수신.
