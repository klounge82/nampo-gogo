# NAMPO GOGO DEVELOPMENT CONSTITUTION

## A. FIXED ROADMAP
Current fixed sequence:

Major-05A
→ Major-05B
→ Major-05C
→ Major-05D
→ Major-05E
→ Major-05F
→ Major-05G
→ Major-05H
→ Major-05I

Do not change this route without explicit PM/user approval,
except temporary technical detours required to unblock the current stage.

## B. NO SCOPE DRIFT
Do not inject unrelated:
- new features
- architecture redesign
- refactoring
- visual enhancements
- new services
- "while we're here" improvements

Record useful ideas in BACKLOG section only.
Do not execute them during the current goal.

## C. PROBLEM SEVERITY

CRITICAL:
- app cannot start
- login completely blocked
- Production data loss/corruption risk
- security/authentication integrity issue
- points/financial-like duplication
- dangerous Production write

Action:
Stop other work and resolve first.

MAJOR:
- core feature path blocked
- business/customer/admin mode unusable
- QR/visit verification core path blocked

Action:
Resolve within current Major stage.

MINOR:
- cosmetic UI issue
- spacing
- typo
- non-blocking translation
- minor layout problem

Action:
Add to MINOR QUEUE.
Batch-fix multiple MINOR issues together.
Do not create a separate build for each small issue.

## D. CONFIDENCE LABELS

CONFIRMED =
proved by real device, API, DB, source, logs, or reproducible result.

LIKELY =
strong evidence but not yet proven.

UNKNOWN =
not verified.

UNKNOWN must never be used as justification for a Production write.

## E. DECISION PROCESS

Before executing a meaningful operation:

1. Fix one goal.
2. Compare realistic options.
3. Estimate:
   - expected result
   - time
   - risk
   - reversibility
   - build requirement
   - Production impact
4. Choose the cheapest safe test capable of changing the decision.
5. Define expected output BEFORE execution.
6. Execute once.
7. Compare actual vs expected.
8. If the same approach fails twice, CHANGE METHOD.

## F. READ BEFORE WRITE

Default order:
READ ONLY
→ diagnosis
→ minimum diff
→ explicit approval if Production write
→ write
→ verify exact expected result

Prefer DIFF REPAIR over delete/recreate.

## G. PRODUCTION WRITE LOCK

No Production write without explicit PM/user approval.

Before any Production write define:
- exact target
- expected INSERT count
- expected UPDATE count
- expected DELETE count
- rollback condition

Never hardcode Production secrets in scripts or command lines.

## H. GOLDEN BASELINE

A build is NOT Golden merely because it compiled.

Golden requires:
- successful build
- valid signature
- successful device install
- required real-device PASS

Do not modify the current Golden baseline unnecessarily.

## I. BUILD DISCIPLINE

- one release build at a time
- unique versionCode
- no unnecessary flutter clean
- no parallel release builds
- diagnostic build must not secretly change behavior
- one root cause / one minimal fix where practical

## J. MOBILE FAILURE FAST PATH

When server/API works but phone fails:

1. prove server/API independently
2. inspect mobile-only local state
3. consider:
   - FlutterSecureStorage
   - Android KeyStore
   - SharedPreferences
   - stale session/cache
4. if local data is safe to remove, compare app-data reset before new build
5. only then create Diagnostic Build if required

## K. LOGGING / INCIDENT LEARNING

After every CRITICAL or important MAJOR incident record:

- symptom
- actual root cause
- false hypotheses
- wasted approaches
- decisive test
- final resolution
- fastest future path
- actions prohibited on recurrence

The purpose is to improve future decision-making,
not merely preserve history.

## L. USER ACTION FORMAT

Whenever PM/user action is required, clearly separate:

🚨 USER ACTION
⛔ DO NOT
✅ EXPECTED RESULT
📘 EXPLANATION

## M. PROGRESS MAP

Maintain stage progress in NAMPO_CURRENT_STATE.md.

Progress changes only when functional evidence changes.

Examples:
+ real-device PASS → progress may increase
+ newly discovered blocking regression → progress may decrease
+ documentation only → no percentage change

Every progress change must record:
OLD %
NEW %
DELTA
REASON

## N. SCREENSHOT & TOKEN EFFICIENCY POLICY

1. **Screenshots & Media**:
   - For UI changes, visual layout verification, or real-device user flows, generate or embed relevant screenshots in walkthroughs/artifacts using standard `![caption](path)` format.
   - Screenshots must be placed in the artifacts directory before embedding.

2. **Token Efficiency**:
   - Keep responses, code edits, and artifact logs concise and focused.
   - Use targeted line ranges for `view_file` calls to avoid unnecessary context inflation.
   - Never print raw database passwords or credentials in stdout or command-line strings.

## O. POINT / REWARD VERIFICATION RULE

A reward is considered PASS only when:
1. Verification success response (`success = true`, `points_awarded`) is confirmed.
2. Persistent `PointHistory` row creation in DB is confirmed.
3. Visible point balance / history in My Info reflects the earned reward.

Success dialog alone is NOT sufficient evidence.

## P. TOURIST GEOFENCE REGISTRATION STANDARD

Never assign an arbitrary fixed GPS radius first.
For every new tourist attraction, the registration process MUST follow these steps:

1. Identify exact attraction name.
2. Research what geographic area that name actually represents.
3. Inspect the attraction's real physical extent/boundary.
4. Classify its spatial type.
5. Decide what area counts as a legitimate visit.
6. Select geofence method.
7. Select center/radius or area definition.
8. Evaluate false rejection risk.
9. Evaluate false acceptance risk.
10. Only then approve Production registration.

### Spatial Classifications
- **A. POINT**: Single building/object/facility (e.g. Busan Tower). Use relatively narrow GPS tolerance.
- **B. SITE**: Park, temple, museum, defined facility complex (e.g. Yongdusan Park). Cover the legitimate visitor area.
- **C. DISTRICT**: Market, village, commercial/cultural district (e.g. Gukje Market, Jagalchi Market). Inspect actual district boundaries before deciding radius.
- **D. LINEAR**: Riverfront, walking trail, coastal road (e.g. Suyeong riverside). Define a specific section or use multi-point/area verification.
- **E. LARGE_AREA**: Beach, large park, broad attraction (e.g. Gwangalli Beach). Use an appropriately broad area and prefer multi-point/polygon verification where a single circle is inaccurate.

### Core Principle
A genuine visitor inside the legitimate attraction area should normally PASS, while a person who did not meaningfully visit the attraction should normally FAIL. Do not maximize radius merely to reduce errors, and do not minimize radius merely to improve security. Radius/area must reflect the real-world attraction.

### Mandatory Registration Review Checklist
Before Production registration, record:
- `PLACE_NAME=`
- `SPATIAL_TYPE=` (POINT / SITE / DISTRICT / LINEAR / LARGE_AREA)
- `ACTUAL_AREA_REVIEWED=` (YES/NO)
- `ACTUAL_BOUNDARY_DESCRIPTION=`
- `CENTER_LAT=`
- `CENTER_LONG=`
- `GEOFENCE_TYPE=`
- `PROPOSED_RADIUS=`
- `RADIUS_REASON=`
- `FALSE_REJECTION_RISK=`
- `FALSE_ACCEPTANCE_RISK=`
- `NORMAL_VISITOR_CAN_VERIFY=` (YES/NO)
- `FINAL_GPS_POLICY=`

If `ACTUAL_AREA_REVIEWED != YES`, Production tourist GPS registration must NOT be approved.

### Current vs Future Technology
- Current implementation: `POINT + RADIUS`
- Future supported designs: `MULTI_POINT`, `POLYGON / AREA`

Large or elongated attractions that cannot be represented safely by one circle should either use a clearly defined sub-zone name or wait for multi-point/polygon capability. Do NOT silently solve bad geometry by using an excessively large radius.

### Permanent Examples
- **Busan Tower**: Small/narrow geofence around the tower.
- **Yongdusan Park**: Larger geofence representing the actual park area.
- **Gwangalli Beach**: Broad/elongated attraction requiring wider or future multi-point/area logic.
- **Suyeong Riverside**: Must define which riverside section is intended before GPS registration.

