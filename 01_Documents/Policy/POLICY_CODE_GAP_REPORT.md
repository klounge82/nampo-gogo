# 코드와 정책의 불일치 및 출시 보완 후보 보고서 (POLICY-001)

본 보고서는 코드 점검 결과와 개인정보/스토어 정책 간 갭(Gap)을 분석하고, 차기 구현 작업(`POLICY-IMPLEMENTATION-001`)으로 추진할 후보 항목을 정리한 보고서입니다.

---

### 코드 - 정책 갭(Gap) 분석표

| 번호 | 점검 항목 | 현재 코드/시스템 상태 | 정책상 필요한 상태 | 출시 필수 여부 | 예상 수정 범위 | DB/Migration | 추천 작업 ID |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **계정 삭제 앱 내 UI 및 API** | 계정 삭제 UI 및 `DELETE /auth/me` API 미구현 (Category D) | 앱 내 탈퇴 버튼 및 데이터 파기 백엔드 API | **출시 필수 (P0)** | Flutter UI + FastAPI backend | DB 변경 없음 (Soft/Hard delete) | `POLICY-IMPLEMENTATION-001` |
| 2 | **계정 삭제 외부 웹 URL** | 공개 웹 URL 없음 | Google Play Data Safety용 계정삭제 정적 안내 웹페이지 | **출시 필수 (P0)** | 정적 HTML 1개 생성 및 호스팅 | DB 변경 없음 | `POLICY-IMPLEMENTATION-001` |
| 3 | **약관 동의 버전 기록** | 회원가입 시약관 동의 내역/버전 DB 보관 테이블 없음 | 약관 버전, 동의 시각, 동의 여부 저장 | **출시 전 검토 (P1)** | `UserAgreement` 테이블 신규 | Migration 필요 | `POLICY-IMPLEMENTATION-001` |
| 4 | **앱내 전문 열람 화면** | 개인정보처리방침/이용약관 전문 보기 뷰어 화면 없음 | 설정/회원가입 화면 내 탭/웹뷰 연결 | **출시 전 검토 (P1)** | Flutter Screen 2개 | DB 변경 없음 | `POLICY-IMPLEMENTATION-001` |
| 5 | **마케팅 수신 선택 동의** | 마케팅 수신 동의 선택 및 설정 메뉴 없음 | 서비스 출시 후 광고성 메시지 발송 시 선택동의 | 출시 후 개선 (P2) | Flutter + Backend | DB 변경 없음 | `POLICY-EXPANSION-002` |

---

> [!IMPORTANT]
> **출시 차단 후보 (P0/P1)**: Google Play 스토어 심사 거절을 방지하기 위해 계정 삭제 기능(앱내 UI + 백엔드 API + 외부 웹 URL) 및 앱 내 약관 전문 보기 화면 구현이 필수적입니다.
