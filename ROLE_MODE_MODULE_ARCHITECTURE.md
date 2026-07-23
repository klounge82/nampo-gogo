# ROLE, APP MODE & MODULE ARCHITECTURE ARCHITECTURE SPECIFICATION

 본 문서는 **Nampo GoGo (남포 GoGo)** 서비스의 계정 역할(`CUSTOMER`, `BUSINESS`, `ADMIN`), 이용자/사업자 AppShell 분리, 데이터 접근 권한(Capability), 모듈/대시보드 레지스트리 및 사업자 신청/승인 구조에 대한 종합 아키텍처 명세서입니다.

---

## 1. 계정 및 역할 원칙 (Account & Role Principles)

1. **단일 계정 원칙 (Single Identity)**:
   - 한 사용자는 시스템 내 단 **하나의 `user_id`**만을 할당받아 사용합니다.
   - 관광객(고객)용 계정과 사업자용 계정을 별도로 나누어 회원가입하지 않습니다.

2. **다중 역할 원칙 (Multiple Roles Support)**:
   - 한 계정은 복수의 역할을 동시에 가질 수 있습니다.
   - 예:
     - 일반 이용자: `['CUSTOMER']`
     - 승인된 매장 사업자: `['CUSTOMER', 'BUSINESS']`
     - 총관리자: `['CUSTOMER', 'ADMIN']` 또는 `['CUSTOMER', 'BUSINESS', 'ADMIN']`

3. **기본 가입 & 공개 가입 제한 (Registration Guard)**:
   - 일반 회원가입 시 항상 `CUSTOMER` 역할만 기본 부여됩니다.
   - 회원가입 요청 Body로 `BUSINESS` 또는 `ADMIN` 역할을 전달하더라도 백엔드에서 일체 부여하지 않고 거부 처리합니다.
   - 공개 `ADMIN` 가입 또는 생성 API는 엄격히 금지되며 모바일 메뉴에 관리자 웹 접근점을 노출하지 않습니다.

---

## 2. 역할 및 Capability 데이터 구조 (Role & Capability Data Model)

### DB 테이블 연동
- **`users`**: 기본 사용자 정보 (`id`, `email`, `nickname`, `status` 등)
- **`user_roles`**: 계정별 역할 보유 (`user_id`, `role` [`CUSTOMER`, `BUSINESS`, `ADMIN`]). `(user_id, role)` 유니크 제약.
- **`business_applications`**: 사업자 회원 신청 내역 (`id`, `user_id`, `business_name`, `business_registration_number`, `representative_name`, `phone`, `requested_store_id`, `status` [`PENDING`, `APPROVED`, `REJECTED`, `SUSPENDED`], `rejection_reason`, `reviewed_by`, `reviewed_at`)
- **`business_memberships`**: 사업자-매장 다대다 연결 (`id`, `user_id`, `store_id`, `membership_role` [`OWNER`, `MANAGER`, `STAFF`], `status` [`ACTIVE`, `SUSPENDED`, `REVOKED`]). `(user_id, store_id)` 유니크 제약.

### Capability 권한 매핑
| 역할 | 보유 Capability |
|---|---|
| **CUSTOMER** | `place.read`, `favorite.manage`, `course.manage`, `review.manage`, `reservation.create` |
| **BUSINESS** | `business.dashboard.read`, `store.own.read`, `store.own.update`, `product.own.manage`, `review.own.read`, `reservation.own.manage`, `recommendation.own.read` |
| **ADMIN** | `business.approve`, `user.manage`, `store.manage_all`, `review.moderate`, `system.audit` |

---

## 3. 사업자 신청 및 원자적 승인 흐름 (Business Application & Approval Flow)

```
[CUSTOMER 회원] --(신청서 작성: POST /business/applications)--> [status: PENDING]
                                                                        |
                                                               (관리자 검토)
                                                                        v
[status: APPROVED] <-- (원자적 DB 트랜잭션: POST /admin/business/applications/{id}/approve)
 ├─ 1. BusinessApplication status = APPROVED
 ├─ 2. user_roles 에 BUSINESS 역할 추가
 └─ 3. business_memberships 에 해당 store_id의 OWNER active 멤버십 추가
```

---

## 4. AppShell & Theme 분리 (AppShell & Role Themes)

1. **`CustomerAppShell`**:
   - 하단 탭: 홈 / 탐색 / 코스 / 저장 / 내 정보
   - Theme: **CustomerTheme** (밝고 따뜻한 오렌지/앰버 톤, 라운디드 카드)

2. **`BusinessAppShell`**:
   - 하단 탭: 대시보드 / 예약 관리 / 매장 관리 / 손님 리뷰 / 더보기
   - Theme: **BusinessTheme** (신뢰감 있는 틸/슬레이트 톤, 운영중심 컴팩트 UI)
   - AppBar 상단 모드 전환 버튼 제공: `[이용자 모드로 전환]`

3. **`AppModeProvider`**:
   - 현재 활성화된 화면 모드 (`AppMode.customer`, `AppMode.business`, `AppMode.admin`) 관리.
   - 사용자 권한이 멈추거나(`SUSPENDED`, `REVOKED`) 로그아웃 시 자동으로 `CustomerAppShell`로 동기화 복귀.

---

## 5. 모듈 및 대시보드 위젯 레지스트리 (Module & Widget Registries)

- **Feature Module Registry**:
  - `CustomerModuleRegistry`, `BusinessModuleRegistry`, `AdminModuleRegistry`
  - 미구현 기능 모듈은 `enabled: false`, `comingSoon: true` 설정으로 안전하게 "준비 중인 기능입니다" 처리.
- **Dashboard Widget Registry**:
  - `CustomerDashboardWidgetRegistry`, `BusinessDashboardWidgetRegistry`, `AdminDashboardWidgetRegistry`
  - 실제 서버 데이터가 없는 항목은 "데이터 수집 중" 또는 "준비 중" 표기로 가짜 난수 출력을 완전 배제.

---

## 6. 향후 확장 백로그 (Expansion Backlog)

아래 항목은 확장 가능하도록 DB schema(`business_memberships` 다대다 구조)를 완료하였으며, 향후 고도화 시 기능 추가 예정입니다:
- 한 사용자의 다사업장(Multi-store) 관리 및 스위처 UI
- 사업장 공동사업자 지분율 관리
- 사업장 이전·폐업·휴업·재오픈 처리
- 직원(STAFF/MANAGER) 세부 접근 권한 제어
- 실제 정산 및 AI 추천 전환 통계 보고서
