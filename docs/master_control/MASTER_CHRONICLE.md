# 📜 NAMPO GOGO MASTER DEVELOPMENT CHRONICLE (개발사 연대기) v2

> **원칙**: 어플개발마스터 1~6의 전체 개발사를 증거 기반으로 빠짐없이 기록한다.
> 추측에 의한 시각 생성 금지 (`TIMESTAMP_SOURCE=GIT_COMMIT` 또는 `날짜/시간 미상` 표기).

| DATE / TIME | MASTER | MAJOR / VC | ACTION | PROBLEM | FIX | RESULT | STATUS | EVIDENCE_ID |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| 2026-07-07 시간 미상 | MASTER1 | VC01 | Initial Nampo GoGo Concept & Project Definition | Busan tourism point economy definition | Flutter & FastAPI architecture chosen | PASS | PASS | EV-0001 |
| 2026-07-17 11:16:12 | MASTER1 | VC05 | Baseline Folder & Project Structure Setup | Initial folder conventions and release baseline | Established project layout | PASS | PASS | EV-0001 |
| 2026-07-18 10:47:15 | MASTER2 | VC08 | Core Database Models & Test Environment | Initial SQLite/PostgreSQL models setup | Database schema baseline locked | PASS | PASS | EV-0001 |
| 2026-07-20 23:35:27 | MASTER2 | VC09 | UserAuth Table Fix & Auth API Baseline | UserAuth relation mismatch after auth refactor | Fixed UserAuth foreign keys | PASS | PASS | EV-0001 |
| 2026-07-21 22:26:50 | MASTER2 | VC10 | Store Seed & Schema Idempotence | Duplicate store seeds during backend restart | Added idempotent store seeding script | PASS | PASS | EV-0001 |
| 2026-07-22 12:39:28 | MASTER2 | VC11 | Store Favorite & Review Flow Tests | Favorite toggle state synchronization | Added store review verification gates | PASS | PASS | EV-0001 |
| 2026-07-23 17:42:41 | MASTER2 | VC12 | Guest Data Link to User Account | Guest mission history lost upon registration | Linked guest device ID to new user | PASS | PASS | EV-0001 |
| 2026-07-23 18:59:46 | MASTER3 | VC13 | Role Shells & Module Registries | Role boundaries across Customer/Business/Admin | Extensible role theme shells added | PASS | PASS | EV-0001 |
| 2026-07-24 05:55:51 | MASTER3 | VC15 | Secure Authentication & Business Core | Token expiration & role verification | Added role-aware business core flows | PASS | PASS | EV-0001 |
| 2026-07-24 22:37:03 | MASTER3 | VC16 | Admin Business Approval Workflow | Pending business registration approval UI | Admin approval API & status badge | PASS | PASS | EV-0001 |
| 2026-07-24 23:26:40 | MASTER3 | VC17 | Review Identity Ownership Fix | Review author user_id missing on creation | Enforced JWT token user_id binding | PASS | PASS | EV-0001 |
| 2026-07-28 09:00:00 | MASTER3 | VC20 | App Startup R8 Crash & ProGuard Restoration | Release APK crashed on launch due to R8 tree shaking | Added keep rules for FlutterSecureStorage in ProGuard | PASS | SUPERSEDED | EV-0001 |
| 2026-07-30 07:43:19 | MASTER4 | VC23 | Attraction Visit Review Verification Gate | Fake reviews submitted for unvisited locations | Location & date verification gate added | PASS | PASS | EV-0001 |
| 2026-07-30 08:52:07 | MASTER4 | VC24 | Yongdusan Park Verification Data | GPS radius check failed on hilly terrain | Adjusted Yongdusan Park GPS threshold | PASS | PASS | EV-0001 |
| 2026-07-30 14:27:29 | MASTER4 | VC25 | Reservation UI & Build Info Marker | Reservation time rules and build version tag | Exposed production build info marker | PASS | PASS | EV-0001 |
| 2026-08-01 08:16:05 | MASTER4 | VC27 | Reservation UI Stability Fix | Time parsing error on reservation list | Enforced ISO-8601 format | PASS | PASS | EV-0001 |
| 2026-08-01 08:49:56 | MASTER4 | VC28 | Standards Compliant Reservation QR | Scanners failed on non-standard QR payload | Formatted standard JSON payload | PASS | PASS | EV-0001 |
| 2026-08-01 11:09:29 | MASTER4 | VC29 | Formal Golden Release VC29 | Account deletion API & Privacy Policy pages | Baseline Golden VC29 locked | PASS | PASS | EV-0001 |
| 2026-08-03 08:14:06 | MASTER5 | VC30 | Security & Release Signing Docs | Release signing key instructions missing | Created signing documentation | PASS | PASS | EV-0001 |
| 2026-08-07 00:36:21 | MASTER5 | VC31 | Customer Signup 1,000P Award Code | Backend signup API awarded 1000P and PointHistory | Earliest found code commit `5c64575` | PASS | PASS | EV-0001 |
| 2026-08-09 22:05:27 | MASTER5 | VC33 | Deploy-Beta-Data & Server Verification | Offline test data mismatched server schemas | Added deploy-beta-data endpoint | PASS | PASS | EV-0001 |
| 2026-08-15 10:00:00 | MASTER5 | VC35 | Suyeong River Linear Spatial Range Incident | Single point pin failed GPS verification along river bank | Implemented linear polygon buffer spatial validator | PASS | PASS | EV-0001 |
| 2026-08-18 10:46:49 | MASTER5 | VC40 | Photo Mission Flow & Local QA Refresh | Photo verification flow & point refresh | Multi-auth mission engine | PASS | PASS | EV-0001 |
| 2026-08-20 08:05:41 | MASTER6 | VC46 | Point Economy V2 Migration | Local test script audited local fixture `nampo_gogo_test.db` (700P) | Added lifetime_earned_points & typed ledger | PASS | SUPERSEDED | EV-0005 |
| 2026-08-20 09:40:18 | MASTER6 | VC47 | VC46-B Device Acceptance Rework | Live Railway backend ran pre-VC46 code (pending deploy) | Pushed commit `b9a1b3a` to trigger Railway auto-deploy | PASS | SUPERSEDED | EV-0002 |
| 2026-08-20 10:41:41 | MASTER6 | VC49-A | Production Data Truth Reconciliation | Audit revealed 700P was local fixture & live signup bonus is 1000P | Reconciled data truth (current: 1000, lifetime: 0) | PASS | PASS | EV-0004 |
| 2026-08-20 10:49:56 | MASTER6 | VC50 | Mock Fallback Elimination | `PointRepository` silent fallback `_mockBalance` & `_mockHistories` | Removed silent mock data, rendered clean Error UI | PASS | SUPERSEDED | EV-0004 |
| 2026-08-20 18:20:35 | MASTER6 | VC51 | Current Points 1000->300 Fix | GET `/users/points` defaulted to first user (300P) when token unassigned | Extracted `current_user` from token, returning 1000P | PASS | PASS | EV-0003 |
| 2026-08-20 20:00:00 | MASTER6 | MC-01 | Master Control Foundation v2 | Initial MC-01 structure passed; PM requested coverage expansion | Created Master Control system & Constitution | PASS | SUPERSEDED_PARTIALLY | EV-0004 |
| 2026-08-20 20:15:00 | MASTER6 | MC-01R | Coverage Expansion & Evidence Hardening | Registry coverage was shallow; epistemic evidence required hardening | Expanded Registries (27 files, 14 features, 15 edges) | PASS | PASS | EV-0006 |
| 2026-08-20 21:20:00 | MASTER6 | MC-02 | Change Preflight Gate & Device Mismatch Control | Samsung physical device renders 300P while server is 1000P | Formalized INC-DEVICE-POINT-MISMATCH-001 & MC-CHANGE-0002 Preflight Gate | PASS | PASS | EV-0004 |
| 2026-08-20 21:35:00 | MASTER6 | VC52 | Device Point Forensic Audit & Verification | Mismatch 1000P vs 300P forensic trace | Confirmed Category A root cause; verified VC51 fix (commit efa1d68) & Railway API | PASS | TECHNICAL_PASS_PENDING_PM_VERIFICATION | EV-0003 |
| 2026-08-20 22:05:00 | MASTER6 | VC53 | Official Signup Bonus Policy Lock (300P) & VC53 Release | PM locked signup bonus at 300P; backend updated, QA account 2abb6e52 reconciled to 300P (-700P entry) | PASS | PASS_PENDING_PM_DEVICE_VERIFICATION | EV-0006 |
| 2026-08-20 22:25:00 | MASTER6 | VC54 | Point History/Lifetime Acceptance Reconciliation & VC54 Release | Audited live DB (user 2abb6e52 net 300P/0P; user e1d38954 3x +100P missions); restored Lifetime tile onTap feedback | PASS | PASS_PENDING_PM_DEVICE_VERIFICATION | EV-0006 |
| 2026-08-20 22:32:00 | MASTER6 | MC-CHANGE-0004-R | Final Point Ledger Forensic Audit | Confirmed duplicate -700P row b0979e69 (SUM=-400 vs current_points=300). Prepared append-only +700P offset plan. | PASS | HOLD_PENDING_PM_WRITE_APPROVAL | EV-0006 |
| 2026-08-20 22:54:00 | MASTER6 | MC-CHANGE-0004-W | Single Ledger Offset & Point Work Closure | Live DB PointHistory sum locked to 300P (LEDGER_MATCH=YES); 0 rows deleted; Point 300/1000 investigation CLOSED | PASS | CLOSED | EV-0006 |
| 2026-08-20 23:00:00 | MASTER6 | MC-03 | Master Control Enforcement Layer & Runtime Safety Finalization | Removed PM/QA auto-reconciliation functions from backend (commit 1ea5f86); built Execution Guard & Report Validator | PASS | PASS | EV-0006 |
| 2026-08-20 23:14:00 | MASTER6 | MC-03K | Korean PM Dashboard Finalization & PM Acceptance | PM confirmed physical VC54 screen (300P current, 0P lifetime, SnackBar works); Point work 100% CLOSED | PASS | CLOSED | EV-0006 |
| 2026-08-22 00:12:00 | MASTER6 | MC-CHANGE-0005 | MAP/SPATIAL Linear & Area Destination Preflight | Root cause classified (Suyeong River stored as single point); implementation scope defined; K-Lounge protected | PASS | HOLD_PENDING_PM_IMPLEMENTATION_APPROVAL | EV-0001 |
