# Google Play Console 내부 테스트 업로드 점검 체크리스트 (PLAY_CONSOLE_UPLOAD_CHECKLIST)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  

---

## 1. Google Play Console 등록 항목 점검표

| 번호 | 등록 및 확인 항목 | 입력 예정 값 / 상태 | 비고 |
| :---: | :--- | :--- | :--- |
| 1 | **내부 테스트 트랙 AAB 업로드** | `NampoGoGo-RELEASE-1.0.0-vc1-b45f7b6-20260802.aab` | 64.32 MB |
| 2 | **패키지명 검증** | `com.nampogogo.app` | |
| 3 | **버전 코드 / 버전 이름** | Version Code `1` / Version Name `1.0.0` | |
| 4 | **개인정보처리방침 URL** | `https://backend-production-b07b.up.railway.app/privacy` | HTTP 200 OK 확인 |
| 5 | **계정 및 데이터 삭제 URL** | `https://backend-production-b07b.up.railway.app/account-deletion` | HTTP 200 OK 확인 |
| 6 | **앱 액세스 권한 (App Access)** | 로그인 필요 항목 설명 등록 | 테스트 계정 정보 준비 |
| 7 | **타겟 연령대** | 만 14세 이상 (만 18세 이상 권장) | |
| 8 | **데이터 보안 (Data Safety)** | 수집 항목: 위치(GPS), 계정정보, 리뷰 사진 | 백엔드 처리 명시 |
| 9 | **내부 테스터 이메일 목록** | 개발자 및 관계자 테스트 이메일 등록 | |

---

## 2. 내부 테스트 착수 순서

1. Google Play Console 접속 $\rightarrow$ [내부 테스트(Internal Testing)] 트랙 선택.
2. `NampoGoGo-RELEASE-1.0.0-vc1-b45f7b6-20260802.aab` 파일 드래그 앤 드롭 업로드.
3. 개시 노트를 입력하고 저장 후 테스터에게 테스트 참여 링크 전송.
