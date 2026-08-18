INCIDENT ID:
INC-2026-08-GPS-VISIT-VERIFICATION-BYPASS

SEVERITY:
CRITICAL

STATUS:
OPEN (Negative test PASS / Pending positive <=50m test)

SYMPTOM:
K-Lounge existing Production QR scanned on Samsung device at HOME (outside 50m radius) completed mission and issued +100P.

ROOT CAUSE CLASS:
E = Backend permissive fallback / F = Verification endpoint lacked explicit composite policy enforcement.
Existing auth model lacked explicit composite QR+GPS policy. Verification endpoint matched QR string without checking explicit QR_GPS policy requirement.

REMEDIATION PLAN:
Defined explicit Mission.auth_type = QR_GPS policy. Deployed backend update and released VC28.

REAL DEVICE TEST:
VC28 HOME GPS REJECTION = PASS (QR scan PASS, GPS acquisition PASS, backend HTTP 400 rejection PASS, no mission completion, no points awarded). Remote QR-only reward bypass is blocked.

--------------------------------------------------

INCIDENT ID:
INC-2026-08-BUSINESS-MODE-SWITCH-NAVIGATION

SEVERITY:
MAJOR

STATUS:
RESOLVED

SYMPTOM:
My Info screen "사업자 모드로 전환" tapped on real device with valid jazzbj@naver.com account (isApprovedBusiness == true), but no screen navigation, dialog, or toast occurred.

ROOT CAUSE:
profile_screen.dart line 395 called AppModeProvider.switchMode(AppMode.business, user) which updated in-memory activeMode and secure storage, but lacked a Navigator route replacement call, leaving customer MainNavigationScreen in the foreground.

FIX:
Updated profile_screen.dart line 398 to await switchMode and execute Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootNavigationSelector()), (route) => false) in VC27.

REAL DEVICE TEST:
PASS (Confirmed on Samsung phone VC27).

PRODUCTION DB CHANGE:
NONE.

--------------------------------------------------

INCIDENT ID:
INC-2026-08-MOBILE-LOGIN-SECURE-STORAGE

SEVERITY:
CRITICAL

STATUS:
RESOLVED

SYMPTOM:
Real device displayed generic
"email or password incorrect"
despite correct credentials.

CONFIRMED SERVER EVIDENCE:
Direct Production /auth/login returned HTTP 200,
access token returned,
jazzbj@naver.com authenticated successfully.

REAL-DEVICE DIAGNOSTIC:
VC26 NG_LOGIN_DIAG showed:

UI_SUBMIT
FAILURE_STAGE=AUTH_PROVIDER_LOGIN
EXCEPTION_TYPE=PlatformException
UI_LOGIN_FAILED_DIALOG

REQUEST_START endpoint=/auth/login
was NOT reached.

ROOT PATH:
AuthProvider.login
→ AuthRepository.login
→ getOrCreateGuestId()
→ FlutterSecureStorage read guest_id
→ PlatformException

ROOT CAUSE CLASS:
stale/incompatible local FlutterSecureStorage /
Android KeyStore application state.

FINAL RESOLUTION:
Android Settings
→ Applications
→ NAMPO GOGO
→ Storage
→ Clear App Data

Then login with same valid jazzbj credentials:
PASS.

IMPORTANT LESSON:
Once Direct API succeeds and only phone fails,
mobile local state must become an early low-cost hypothesis.

FAST PATH ON RECURRENCE:
1. Direct API
2. distinguish server vs mobile
3. inspect local secure storage state
4. confirm local data can be safely cleared
5. app-data reset before build when appropriate
6. diagnostic build only if reset fails

AVOID:
- repeated DB password resets
- returning to Railway after server already proved healthy
- rebuilding before comparing low-cost reversible local reset
- assuming generic UI credential message means credential failure

Also record historical lesson:
Masked identity must never be expanded by guess
(e.g. s***@domain → guessed full address)
for Production write decisions.
