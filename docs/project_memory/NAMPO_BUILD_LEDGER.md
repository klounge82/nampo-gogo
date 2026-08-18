VC16
ROLE:
Historical known-good startup baseline / recovery reference.

VC21
RESULT:
Real-device startup crash.

ROOT EVIDENCE:
flutter_secure_storage related
NoClassDefFoundError involving KeyCipherAlgorithm.

VC22
RESULT:
Real-device startup crash persisted.

ROOT EVIDENCE:
StorageCipher18Implementation missing.

VC23
ROLE:
R8/ProGuard targeted secure-storage preservation attempt.
Startup issue not accepted as final Golden.

VC25
RESULT:
Release build success.
Signed.
ADB installed.
App startup PASS.
Login issue remained.

IMPORTANT BUILD CONDITIONS:
flutter_secure_storage 9.2.4
minify disabled
QR autoStart preserved.

VC26
ROLE:
Login diagnostic build.

FUNCTIONAL CHANGE:
No intended login behavior change;
NG_LOGIN_DIAG diagnostics added only.

RESULT:
Build SUCCESS
signature PASS
ADB install SUCCESS
versionCode=26 confirmed
startup PASS
after local app-data reset:
real-device login PASS

CURRENT GOLDEN:
VC27

VC27
ROLE:
MAJOR-01 Business mode switch navigation fix build.

FUNCTIONAL CHANGE:
Added RootNavigationSelector route replacement in profile_screen.dart line 398 upon business mode switch.

RESULT:
Build SUCCESS
signature PASS
ADB install SUCCESS
versionCode=27 confirmed
startup PASS
installed on real device (R3CX10KGMPV)
real-device business mode switch PASS (MAJOR-01 RESOLVED)

VC28
ROLE:
CRITICAL-02A Explicit QR_GPS policy enforcement release build.

FUNCTIONAL CHANGE:
Backend policy-driven verification requirements (QR_GPS explicit policy), frontend mission_card.dart & l10n_mappers.dart QR_GPS support.

RESULT:
Build SUCCESS
signature PASS
ADB install SUCCESS
versionCode=28 confirmed on connected Samsung device (R3CX10KGMPV)
Golden remains VC27 pending PM real-device test PASS

VC29
ROLE:
MAJOR-03 + MINOR-01 Client UX Batch release build.

FUNCTIONAL CHANGE:
1. QR_GPS action button label maps to QR-oriented label (🔍 QR 스캔하기) in mission_detail_screen.dart & mission_card.dart.
2. DioException response detail extraction in mission_detail_screen.dart displays clean localized friendly message for expected HTTP 400 rejection instead of raw Dio text.

RESULT:
Build SUCCESS
signature PASS
ADB install SUCCESS
versionCode=29 confirmed on connected Samsung device (R3CX10KGMPV)
Golden remains VC27 pending PM real-device test PASS
