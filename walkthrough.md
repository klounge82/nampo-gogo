# Walkthrough - 회원가입·로그인·현재 사용자 API 재검증 및 매장 Seed Data 필요성 판정 (RELEASE-001-E-RETRY-02)

본 문서는 `RELEASE-001-E-REMEDY-02` 작업에 따른 `UserAuth` 테이블명 정합 완료 후, 실제 운영 Railway API에서 진행된 `RELEASE-001-E-RETRY-02` 스모크 테스트 및 검증 결과를 기록한 종합 문서입니다.

---

## 1. 개요 및 변경 사항 (Overview)

Railway ACTIVE 운영 서버(`https://backend-production-b07b.up.railway.app`)를 대상으로 인증 Flow 전체(회원가입, 중복 가입 방어, 로그인, 현재 사용자 Profile 조회, 계정 탈퇴)와 매장 데이터 존재 여부를 실제 API 호출을 통해 재검증했습니다.

---

## 2. API 스모크 테스트 실행 결과 (Smoke Test Results)

`05_Release/scripts/release_001_e_smoke_test.ps1` 및 파이썬 검증 스크립트를 통해 전체 15개 항목에 대한 검증을 수행했습니다.

| 테스트 번호 | 검증 항목 | 대상 API / Endpoint | 결과 | 상세 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **Test 1** | Health Checks | `GET /health/live`, `GET /health/ready` | **PASSED** | status=ok, environment=production, database=connected |
| **Test 2** | 회원가입 (Sign Up) | `POST /auth/signup` | **PASSED** | HTTP 500 오류 해소, `relation "users_auth" does not exist` 발생하지 않음 |
| **Test 3** | 중복 회원가입 방어 | `POST /auth/signup` | **PASSED** | 동일 이메일 재가입 시 HTTP 400 정상 차단 |
| **Test 4** | 로그인 (Login) | `POST /auth/login` | **PASSED** | Access Token (Bearer) 발급 정상 |
| **Test 5** | 현재 사용자 프로필 조회 | `GET /users/me` | **PASSED** | HTTP 200 OK, 비밀번호/해시 미노출 보안 검증 |
| **Test 6** | 잘못된 Token 방어 | `GET /users/me` | **PASSED** | HTTP 401 Unauthorized 거절 |
| **Test 7 & 8** | 매장 목록 및 상세 | `GET /stores` | **SKIPPED** | 매장 데이터 0건 (`NO_STORE_DATA` / `SKIPPED_NO_STORE_DATA`) |
| **Test 9~11** | 즐겨찾기 CRUD | `POST/DELETE /favorites` | **SKIPPED** | 매장 데이터 미존재로 Skip |
| **Test 12~13**| 미션 검증 & 리뷰 | `POST /stores/{id}/reviews` | **SKIPPED** | 매장 데이터 미존재로 Skip |
| **Test 14** | 재로그인 및 데이터 유지 | `POST /auth/login` | **PASSED** | 재로그인 및 유저 정보 유지 확인 |
| **Test 15** | 계정 논리 탈퇴 (Withdraw) | `DELETE /users/me` | **PASSED** | 탈퇴 성공 후 해당 계정 재로그인 시 HTTP 403 차단 |

---

## 3. Flutter 클라이언트 검증 결과 (Frontend Checks)

Backend API 정합 완료 후 Flutter 클라이언트 분석 및 테스트를 수행하였습니다.
- `flutter pub get`: Got dependencies! 성공
- `flutter analyze`: **0 Errors** (110 info/warning 경고 항목만 존재)
- `flutter test`: **All tests passed!**

---

## 4. 최종 판단 및 다음 단계 (Final Status & Next Steps)

- **최종 상태**: **`NO_STORE_DATA`**
  - 회원가입, 로그인, 현재 사용자 조회, 계정 탈퇴 등 모든 인증 API는 HTTP 500 없이 100% 정상 가동함을 확인했습니다.
  - 다만 `GET /stores` 호출 결과 운영 DB의 `stores` 테이블이 비어 있어(0건), 즐겨찾기/리뷰/미션 관련 E2E 테스트가 진행되지 못했습니다.
- **다음 작업 ID**: **`RELEASE-001-E-SEED-01`** (매장 Seed Data 투입 작업)
