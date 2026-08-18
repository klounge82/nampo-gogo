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

### COORDINATE VALIDATION STANDARD

Permanent rules for all current and future place coordinate registration:

1. **No Arbitrary Geocoding**: Never approve a Production location coordinate solely from an arbitrary address geocode or district center.
2. **Geographic Identity Verification**: Verify what the place name geographically represents before assigning coordinates.
3. **POI / Official Priority**: Prefer actual POI / official location over district-center geocoding.
4. **Cross-Check**: Where possible cross-check: reference POI vs field device GPS.
5. **Field GPS Role**: Device GPS alone is supporting evidence, not automatically the canonical POI coordinate.
6. **Precision by Auth Type**: Narrow-radius `QR_GPS` locations require higher coordinate precision than broad attractions.
7. **No Hiding Bad Coordinates**: A bad coordinate must be corrected. Do NOT increase radius merely to hide a coordinate error.
8. **Spatial Extent Review**: For parks, markets, beaches, riversides and other spatially large places: review the real visitor area before determining center/radius.
9. **Mandatory Checklist Before Production Write**:
   - `PLACE_NAME=`
   - `SPATIAL_TYPE=`
   - `ACTUAL_AREA_REVIEWED=`
   - `REFERENCE_SOURCE=`
   - `REFERENCE_LAT=`
   - `REFERENCE_LONG=`
   - `FIELD_GPS_CHECK=`
   - `DB_TO_REFERENCE_DISTANCE_M=`
   - `GEOFENCE_TYPE=`
   - `RADIUS=`
   - `COORDINATE_APPROVED=`
10. **Mandatory Approval Gate**: `COORDINATE_APPROVED` must equal `YES` before new GPS-dependent Production place registration.

## Q. DATA LINEAGE, STORAGE, RETENTION & NON-DESTRUCTIVE DELETION STANDARD

This is a permanent NAMPO GOGO project rule for all persistent data and generated files.

### Q1. DATA LINEAGE REQUIRED
Every feature that creates, changes, stores, derives, archives, or removes persistent information must document:
- `DATA_NAME=`
- `CREATED_BY=`
- `SOURCE_OF_TRUTH=`
- `PRIMARY_STORAGE=`
- `DERIVED_STORAGE=`
- `CACHE_STORAGE=`
- `BACKUP_STORAGE=`
- `RELATED_TABLES=`
- `RELATED_FILES=`
- `RELATED_USER_ID=`
- `RELATED_STORE_ID=`
- `RELATED_MISSION_ID=`
- `RELATED_BUSINESS_ID=`
- `CREATES_DERIVED_DATA=`
- `DERIVED_DATA_LIST=`
- `SAFE_TO_MODIFY=`
- `MUST_NOT_TOUCH=`
- `RESTORE_METHOD=`
- `DELETE_BEHAVIOR=`

Unknown data lineage = STOP.

### Q2. SOURCE OF TRUTH
Every important Data Family must explicitly define its Source of Truth. Derived/cache/UI values must never silently overwrite it.
- Authentication identity -> validated JWT authenticated user
- Mission completion -> `UserMission` authoritative completion record
- Point transaction history -> `PointHistory`
- Current persisted point balance -> `users.current_points`
- Photo evidence -> documented canonical evidence storage (`static/mission_evidence/`)

### Q3. DATA FAMILY / DEPENDENCY
One logical event creates multiple related artifacts. For example, `MISSION_COMPLETION_FAMILY` includes `UserMission`, `PointHistory`, `users.current_points` delta, photo/QR evidence, and verification records. Never modify one family member blindly.

### Q4. NO ARBITRARY HARD DELETE
Production hard deletion is prohibited by default (`DELETE FROM`, `rm`, `unlink`, `shutil.rmtree`).
Preferred lifecycle: ACTIVE -> INACTIVE / ARCHIVED / DELETED_PENDING -> QUARANTINE / RETENTION -> dependency verification -> PM final approval -> physical purge only if safe.

### Q5. QUARANTINE / ARCHIVE
Files considered obsolete must not immediately disappear. Use controlled quarantine/archive first with metadata (`ORIGINAL_PATH`, `QUARANTINE_PATH`, `REASON`, `CHECKSUM`, `RESTORE_TARGET`, `PURGE_APPROVED=NO`).

### Q6. DATABASE RETENTION
Prefer flags (`status`, `is_active`, `deleted_at`, tombstone) before physical row deletion. Never delete a Production row merely because it appears unused.

### Q7. THREE-STAGE DELETE
- Stage 1: LOGICAL HIDE / DEACTIVATE
- Stage 2: QUARANTINE / ARCHIVE / RETAIN
- Stage 3: PHYSICAL PURGE (Requires explicit PM approval, no active references, backup verified, production impact none).

### Q8. INCIDENT / ERROR EVIDENCE RETENTION
Erroneous Production data must not be erased merely to make the database look clean. User-facing financial/point state must be corrected while preserving sufficient audit evidence for investigation.
*(Rule Application Note: The QA Gampo wrong-user +100P incident is governed by Section Q. Future correction must restore correct user financial state and preserve incident audit evidence without arbitrary hard deletion).*

### Q9. AUTOMATIC CLEANUP RESTRICTION
No automatic destructive cleanup without PM review. All file/media/database cleanup scripts must support `DRY_RUN`, `CANDIDATE_LIST`, `DEPENDENCY_CHECK`, and `PM_REVIEW`.

### Q10. DATA / FILE IMPACT REPORT
Significant persistent-data tasks must report created/modified/archived/deleted files and DB rows, primary vs derived storage, and restore path.

### Q11. GENERATED ARTIFACT LOCATION
Whenever files are generated (QR PNG, photo evidence, APK artifacts, translations), document canonical output path, derived paths, temp paths, consumers, and `SAFE_TO_REGENERATE` status. Important files must never survive only in undocumented scratch/temp folders.

### Q12. TEMP / SCRATCH RULE
`scratch`, `temp`, `.tmp`, and Antigravity brain scratch are NOT canonical permanent storage. Every important artifact there must be classified as `TEMPORARY` or `CANONICAL_COPY_EXISTS_ELSEWHERE`.

### Q13. PRODUCTION WRITE PREVIEW
Before every Production persistent-data mutation, report target, source of truth, expected inserts/updates/archives/deletes, affected files, and rollback/restore method.

### Q14. USER / BUSINESS SCALE SAFETY
Never rely on first database user, first matching record, arbitrary fallback user, or unverified relationship for financial, ownership, authorization, or destructive operations. Identity and ownership must be explicit and verifiable.

### Q15. MANDATORY DELETION EXCEPTION
If legal, privacy, security, or mandatory policy requires actual deletion: identify exact scope, verify target identity, avoid unrelated deletion, and confirm completion without violating mandatory rules.

## R. OFFICIAL VERIFICATION MATRIX & POLICY

Verification modes in Nampo GoGo are explicitly governed by `Mission.auth_type`. Never re-interpret completed historical missions, and never make `store.review_verification_type` silently override an explicit `Mission.auth_type`.

### Official Verification Modes
1. **`QR`**:
   - Requires authenticated JWT user + valid QR token.
   - GPS is NOT required unless explicitly part of policy.

2. **`GPS_VERIFICATION`**:
   - Requires authenticated JWT user + current GPS coordinates within configured geofence.

3. **`QR_GPS`**:
   - Requires authenticated JWT user + valid QR token + current GPS coordinates within configured geofence.

4. **`PHOTO_VERIFICATION`**:
   - Requires authenticated JWT user + valid image proof.
   - GPS is NOT required.

5. **`PHOTO_GPS`**:
   - Requires authenticated JWT user + current GPS coordinates within configured geofence + valid newly captured image proof.
   - ALL conditions (Auth, Dup Check, GPS within radius, Image, Duplicate protection) are strictly required.
