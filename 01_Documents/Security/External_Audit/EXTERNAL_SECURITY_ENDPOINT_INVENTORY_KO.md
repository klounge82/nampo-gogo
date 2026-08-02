# 남포고고 외부 진단 대상 REST API 엔드포인트 목록 (EXTERNAL_SECURITY_ENDPOINT_INVENTORY_KO)

**문서 버전**: v1.0  
**작성일자**: 2026-08-02  
**백엔드 Base URL**: `https://backend-production-b07b.up.railway.app`  

---

## 1. 공개 엔드포인트 (Unauthenticated Endpoints)

| HTTP Method | Endpoint | 기능 설명 | 주요 점검 내용 |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | 서버 헬스 체크 | 서버 버전 및 상태 노출 여부 |
| `GET` | `/privacy` | 개인정보처리방침 웹페이지 | HTML5 정적 인젝션 |
| `GET` | `/terms` | 이용약관 웹페이지 | 정적 리소스 노출 |
| `GET` | `/account-deletion` | 계정삭제 안내 웹페이지 | 외부 안내 페이지 수신 |
| `GET` | `/support` | 고객지원 안내 웹페이지 | 지원 정보 노출 |
| `POST` | `/auth/signup` | 회원가입 | `role` 파라미터 승격, 이메일 중복 체크 |
| `POST` | `/auth/login` | 로그인 (Sensitive) | Rate Limit, 토큰 발급 무결성 |
| `POST` | `/auth/refresh` | 토큰 재발급 | Refresh Token 서명 검증 |
| `GET` | `/search` | 매장 및 장소 검색 | SQL Injection, XSS 입력값 검증 |
| `GET` | `/stores/{store_id}` | 매장 상세 정보 조회 | 매장 데이터 노출 |
| `GET` | `/stores/{store_id}/reviews` | 매장 리뷰 목록 조회 | 삭제된 리뷰 노출 여부 |

---

## 2. 회원 전용 인증 엔드포인트 (Authenticated CUSTOMER Endpoints)

| HTTP Method | Endpoint | 기능 설명 | 주요 점검 내용 |
| :--- | :--- | :--- | :--- |
| `GET` | `/auth/me` | 본인 프로필 조회 | 토큰 만료 및 타인 프로필 노출 (IDOR) |
| `DELETE` | `/users/me` | 회원탈퇴 | 본인 확인, OWNER 탈퇴 차단, 토큰 폐기 |
| `DELETE` | `/auth/me` | 회원탈퇴 (별칭) | `/users/me`와 동일 로직 무결성 |
| `POST` | `/reservations` | 예약 신청 생성 | 입력 파라미터 검증, 과거/미래 날짜 |
| `GET` | `/reservations/{res_id}` | 본인 예약 상세 조회 | **IDOR / BOLA** (타인 reservation_id 접근) |
| `POST` | `/reservations/{res_id}/cancel` | 예약 취소 | 타인 예약 취소 시도 |
| `POST` | `/stores/{store_id}/verify-qr` | 매장 QR 방문 인증 | **QR 코드 위조/재사용**, 유효시간 검증 |
| `POST` | `/stores/{store_id}/verify-location`| GPS 위치 인증 | **위도/경도 좌표 조작**, 허용 반경 우회 |
| `POST` | `/stores/{store_id}/reviews` | 리뷰 작성 | **방문 인증 뱃지 강제 획득**, 파일 업로드 |
| `PATCH` | `/reviews/{review_id}` | 리뷰 수정 | **타인 리뷰 수정 (IDOR)** |
| `DELETE` | `/reviews/{review_id}` | 리뷰 삭제 | **타인 리뷰 삭제 (IDOR)** |

---

## 3. 사업자 전용 엔드포인트 (BUSINESS Endpoints)

| HTTP Method | Endpoint | 기능 설명 | 주요 점검 내용 |
| :--- | :--- | :--- | :--- |
| `GET` | `/business/stores/{store_id}/reservations` | 사업장 예약 목록 조회 | **권한 검증** (타 매장 store_id 접근) |
| `POST` | `/business/reservations/{res_id}/approve` | 예약 승인 | **STAFF/MANAGER/OWNER 권한격차** |
| `POST` | `/business/reservations/{res_id}/reject` | 예약 거절 | 상태 조작, 사유 인젝션 |
| `POST` | `/business/reservations/{res_id}/complete` | 서비스 완료 처리 | 조기 완료 처리 우회 |
| `POST` | `/business/reservations/{res_id}/no-show` | 노쇼 처리 | 상태 역전 공격 |
| `PUT` | `/business/stores/{store_id}/reservation-settings` | 예약 가능 조건 설정 | 타 사업장 설정 변경 시도 |

---

## 4. 관리자 전용 엔드포인트 (ADMIN Endpoints)

| HTTP Method | Endpoint | 기능 설명 | 주요 점검 내용 |
| :--- | :--- | :--- | :--- |
| `GET` | `/admin/business-applications` | 사업자 신청 목록 조회 | **수직적 권한 상승** (일반회원 접근) |
| `POST` | `/admin/business-applications/{app_id}/approve` | 사업자 신청 승인 | 관리자 토큰 검증 |
| `POST` | `/admin/business-applications/{app_id}/reject` | 사업자 신청 반려 | 관리자 권한 검증 |
| `GET` | `/admin/users` | 전체 회원 관리 | 개인정보 과다 노출 여부 |
