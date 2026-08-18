Date baseline: 2026-08-17

CURRENT_MAJOR:
Major-05B

MAJOR-05B_PROGRESS:
75%

GOLDEN_DEVICE_BUILD:
VC27

STARTUP:
PASS

LOGIN:
PASS

OFFICIAL_BUSINESS_ACCOUNT:
jazzbj@naver.com

K-LOUNGE:
business membership = OWNER / ACTIVE

CURRENT_OPEN_ISSUES:

MAJOR-04
Status: OPEN
Issue: Mission success / displayed reward reconciliation with persistent PointHistory and My Info balance.
Finding: Backend verification endpoint saves UserMission and PointHistory in a single DB transaction. Client success dialog reads points_awarded from verification API payload. Historical 100P discrepancy classified as B (persisted under gnsj@naver.com test account).

CRITICAL-02
Status: OPEN (Negative test PASS / Pending positive <=50m test)
VC28 HOME GPS REJECTION = PASS. Remote QR-only reward bypass is blocked. No mission/point awarded outside 50m.
Root Cause: Existing auth model lacked explicit composite QR+GPS policy. Fixed in backend & VC28 via explicit Mission.auth_type = QR_GPS.

MAJOR-03
Status: OPEN
Issue: Expected GPS distance rejection is shown as raw HTTP/Dio status code 400 exception string instead of friendly localized message.

MINOR-01
Status: OPEN
Issue: QR_GPS action button label displays "GPS 인증" instead of "QR 스캔하기".

MAJOR-02
QR scanner / real K-Lounge QR real-device E2E (Gate 1 PASS, Gate 2 PASS, Gate 3 CRITICAL-02 negative test PASS).

RECENT_RESOLVED_ISSUES:

CRITICAL-02A Negative Home Rejection:
STATUS: RESOLVED (VC28 real-device home GPS rejection PASS).

MAJOR-01: Business mode switch navigation
STATUS: RESOLVED
ROOT CAUSE: profile_screen.dart changed AppModeProvider to BUSINESS correctly, but no Navigator/root route refresh existed after switchMode(), leaving the user on customer MainNavigationScreen.
FIX: After successful switchMode(AppMode.business), navigate through existing RootNavigationSelector using pushAndRemoveUntil in VC27.
REAL_DEVICE_RESULT: PASS (Confirmed on Samsung phone VC27).

Mobile login failure:
RESOLVED.

NEXT_FIXED_WORK:
MAJOR-03 / MINOR-01 UX polish in VC29, followed by positive K-Lounge <=50m real-device test.

DO NOT REOPEN WITHOUT NEW EVIDENCE:
- jazzbj password reset
- Production login account recovery
- Railway login investigation
- K-Lounge QR reissue
- MAJOR-01 business mode navigation
- CRITICAL-02A negative home rejection

BACKLOG:
Keep future non-current ideas here only.
Do not execute without moving them into an approved Major goal.

PROGRESS_HISTORY:

2026-08-17
Major-05B = 75%
Delta = +10%p
Reason = VC28 real-device home GPS rejection PASS (Remote QR point bypass blocked)

2026-08-17
Major-05B = 65%
Delta = +10%p
Reason = VC27 real-device business mode switching PASS

2026-08-17
Major-05B = 55%
Delta = 0
Reason = Documentation baseline creation only.
