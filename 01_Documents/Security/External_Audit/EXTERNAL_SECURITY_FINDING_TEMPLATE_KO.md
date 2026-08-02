# 남포고고 외부 진단 취약점 보고서 양식 (EXTERNAL_SECURITY_FINDING_TEMPLATE_KO)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  

---

## 1. 취약점 위험 등급 산정 기준 (Severity Ratings)

| 위험 등급 | 정의 및 적용 기준 | 정식 출시 조치 기준 |
| :---: | :--- | :---: |
| **P0 (Critical)** | 관리자 권한 탈취, 전체 DB 노출, 원격 코드 실행(RCE), 인증 없이 개인정보 대량 유출, 서비스 결제 조작 | **출시 절대 불가 (0건 필수)** |
| **P1 (High)** | 타인 예약/리뷰 무단 수정·삭제(IDOR), 계정삭제 우회, 권한 상승, 지속 가능한 토큰 탈취 | **출시 절대 불가 (0건 필수)** |
| **P2 (Medium)** | Rate Limit 미흡, 부분적 정보 노출, 입력값 검증 미흡, 업로드 파일 메타데이터 노출, 보안 헤더 누락 | **위험 수용 또는 수정계획 수립** |
| **P3 (Low)** | 시스템 상세 에러 문구 노출, UI 정보 노출, 기타 정보보안 권장 설정 미흡 | **Backlog 등록 후 차기 개선** |

---

## 2. 취약점 상세 기술 서식 (Template for Vulnerability Findings)

*※ 외부 진단업체는 발견된 각 취약점에 대해 아래 서식을 반드시 작성해 주시기 바랍니다.*

```markdown
### [VULN-001] 취약점 제목 (예: 타인 예약 정보 조작 가능한 IDOR 취약점)

- **위험 등급**: [P0 / P1 / P2 / P3]
- **발견 영역**: [Android APK / REST API / 관리자 / 권한제어 / 파일업로드 / 기타]
- **영향 받는 Endpoint / 파일**: `POST /business/reservations/{res_id}/approve` (또는 APK 클래스명)
- **테스트 계정**: CUSTOMER 회원 계정 (`sec_customer_01`)
- **발견 시각**: 2026-08-XX 14:30 (KST)

#### 1. 취약점 개요 및 설명
(취약점이 발생하는 원인과 영향도에 대한 간략한 설명)

#### 2. 상세 재현 절차 (Steps to Reproduce)
1. `sec_customer_01` 계정으로 로그인 후 Access Token 획득.
2. Burp Suite를 통해 `POST /business/reservations/{res_id}/approve` 요청 캡처.
3. `res_id` 값을 타인의 예약 ID로 변경하여 요청 전송.
4. HTTP 200 OK 응답과 함께 타인 예약이 승인 처리됨 확인.

#### 3. 증적 자료 (Proof of Concept - PoC)
- **HTTP Request**:
  ```http
  POST /business/reservations/OTHER_USER_RES_ID/approve HTTP/1.1
  Host: backend-production-b07b.up.railway.app
  Authorization: Bearer eyJhbGciOi...
  ```
- **HTTP Response**:
  ```http
  HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"success": true, "message": "예약 승인 완료"}
  ```
*(주의: 증적 자료 내 실제 이메일, 전화번호, 개인정보는 반드시 마스킹 처리할 것)*

#### 4. 보안 조치 권고 (Remediation Recommendation)
- 백엔드 `approve_reservation` 함수 내에서 `current_user`가 해당 예약이 속한 사업장의 소유자(`OWNER`) 또는 권한자(`MANAGER`)인지 세션 DB 조회 검증 로직 추가.

#### 5. 이행 재점검 결과 (Retest Verification)
- **재점검 일시**: 2026-08-XX
- **결과**: [ 조치 완료 (Passed) / 미조치 (Failed) / Partial ]
- **확인자**: 진단원 OOO (서명)
```
