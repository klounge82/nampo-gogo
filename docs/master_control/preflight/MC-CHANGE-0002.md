# 🛡️ MASTER CONTROL PREFLIGHT REPORT: MC-CHANGE-0002

- **CHANGE ID**: `MC-CHANGE-0002`
- **TITLE**: VC52 Device Point 300 vs Server 1000 Forensic Investigation
- **PREFLIGHT DATE**: 2026-08-20T21:26:48+09:00
- **PREFLIGHT GATE STATUS**: **PREFLIGHT_PASS_PENDING_PM_APPROVAL**
- **VC52 EXECUTION STATUS**: **STOPPED**

---

## 1. Executive Summary & Observations

- **Server Source of Truth**: Authenticated live Railway API (`/auth/me` & `/users/points`) for user `2abb6e52-d447-4338-8beb-e638890a5ecc` returns `current_points = 1000` and `lifetime_earned_points = 0`.
- **Samsung Physical Device Observation**: Physical Samsung device renders `300 P` current balance and `0 P` lifetime balance (persisted after logout -> login).
- **Mismatch Evaluation**: `1000 P ≠ 300 P`. Linked Incident: `INC-DEVICE-POINT-MISMATCH-001` (Status: `OPEN`).

---

## 2. Mandatory Preflight Controls

### A. Affected Features
`AUTH`, `USER`, `POINT`, `MISSION`

### B. Must Co-Check (20 Forensic Check Items)
1. Device authenticated user identity (`user_id`, `email`)
2. Login JSON `current_points`
3. Login JSON `lifetime_earned_points`
4. Flutter `User.fromJson` parse
5. `AuthProvider` initial `currentUser`
6. `/auth/me` response DTO
7. `AuthService.getMe` parse
8. `AuthProvider.refreshUser` result
9. `/users/points` response
10. `PointService` parse
11. `PointHistoryScreen` balance card
12. Every `updatePoints` call site
13. Every `currentUser.copyWith(currentPoints...)`
14. `MissionScreen` point update path
15. `ProfileScreen` (My Info) final render source
16. Local default/mock/fallback 300 paths
17. `FlutterSecureStorage` token key consistency
18. Actual release API base URL (`ApiConfig.baseUrl`)
19. Actual package version installed on Samsung (`dumpsys package com.nampogogo.app`)
20. Backend first-user fallback absence verification

### C. Must Not Touch (Protected Areas)
- QR & K-Lounge QR
- Spatial Geometry (`POINT_RADIUS`, `LINE_BUFFER`, `POLYGON_AREA`, `MULTI_AREA`)
- Review & Business core flows
- Reservation module
- Production DB `users.current_points` & `users.lifetime_earned_points` values
- Historical `PointHistory` rows

---

## 3. Root Cause Category Templates for VC52 Forensic Audit

- **Category A**: Device login/auth response itself is 300.
- **Category B**: Device receives 1000, but Flutter parsing/state converts it to 300.
- **Category C**: Point balance endpoint returns 300.
- **Category D**: Incorrect token / user / session identity.
- **Category E**: Device connects to a different backend/environment.
- **Category F**: Samsung APK / version / signature mismatch.
- **Category G**: Local storage / cache / default 300 fallback.
- **Category H**: Other runtime overwrite path.
- **Category I**: UNKNOWN (Default).

> **Current Confirmed Category**: `UNKNOWN` (Root cause not yet proven).

---

## 4. Release Gate Decision

```text
PREFLIGHT_STATUS = PASS
SOURCE_OF_TRUTH_IDENTIFIED = YES
MUST_CO_CHECK_DEFINED = YES
MUST_NOT_TOUCH_DEFINED = YES
PRODUCTION_WRITE_REQUIRED = NO
IDENTITY_CREATE_REQUIRED = NO
DELETE_REQUIRED = NO
PM_APPROVAL_REQUIRED = YES

GATE RESULT: PREFLIGHT PASS. IMPLEMENTATION BLOCKED PENDING PM APPROVAL.
```
