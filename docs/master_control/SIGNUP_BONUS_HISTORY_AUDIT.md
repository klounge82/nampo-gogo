# 🔍 SIGNUP BONUS 300 ↔ 1000 EPISTEMIC HISTORY AUDIT REPORT

- **AUDIT DATE**: 2026-08-20T20:15:00+09:00
- **AUDITOR**: NAMPO GOGO MASTER CONTROL
- **EPISTEMIC HARDENING LEVEL**: **HIGH (STRICTLY DISAMBIGUATED)**

---

## 1. Epistemic Category Separation

| Category | Value | Source / Evidence | Truth Lock Status |
| :--- | :--- | :--- | :---: |
| **A. ORIGINAL_PRODUCT_POLICY** | `UNKNOWN` (PM Recollection: `300 P`) | Initial product design documents (EV-0006) | `UNLOCKED (NO)` |
| **B. EARLIEST_FOUND_CODE_IMPLEMENTATION** | `1,000 P` | Commit `5c64575` on 2026-08-07T00:36:21+09:00 (EV-0001) | `LOCKED (YES)` |
| **C. CURRENT_CODE_VALUE** | `1,000 P` | Backend `signup` endpoint (`app/main.py` line 526) | `LOCKED (YES)` |
| **D. CURRENT_LIVE_USER_OBSERVED_VALUE** | `1,000 P` | Live Railway API `/auth/me` for user `2abb6e52` (EV-0004) | `LOCKED (YES)` |
| **E. LIVE_1000_EXACT_CREATION_ORIGIN** | `UNPROVEN` | Requires exact SQL creation trace | `UNLOCKED (NO)` |

---

## 2. 300P Historical Context Classification

- **Context 1 (Mock Artifact)**: `_mockBalance = 300` in legacy `PointRepository.dart` fallback.
- **Context 2 (Default Frontend State)**: `currentPoints = 300` in initial Flutter model constructor prototypes.
- **Context 3 (First DB User Fallback)**: Backend `get_user_points` returned user `e1d38954` (`current_points = 300`) when unauthenticated.
- **Context 4 (PM Recollection)**: Initial concept policy memory of 300P welcome points.

---

## 3. Epistemic Lock Summary

- **BACKEND_IMPLEMENTATION_TRUTH_LOCKED**: `YES`
- **PRODUCT_POLICY_TRUTH_LOCKED**: `NO`
- **LIVE_ROW_ORIGIN_LOCKED**: `NO`
