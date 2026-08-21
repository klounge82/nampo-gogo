# 🛡️ NAMPO GOGO MASTER CONTROL GUARD RULES

## RULE-01: NO UNAPPROVED DELETE / MOVE / RENAME
- Files marked `PROTECTED` in `FILE_REGISTRY.json` cannot be deleted, moved, or renamed without 2-Key authorization (`AUTOMATED_SAFE_TO_DELETE == True` AND `PM_DELETE_APPROVAL == True`).

## RULE-02: NO SILENT MOCK FALLBACK IN RELEASE
- Repository catch blocks in Flutter must rethrow exceptions or yield explicit Error states. Mock balances and mock histories must never be returned in Release mode.

## RULE-03: NO FIRST USER FALLBACK
- Backend endpoints must never fall back to `db.query(models.User).first()` for authenticated point requests. Unauthenticated or missing user tokens must return HTTP 401 or 404.

## RULE-04: QUALIFYING EARN ONLY FOR LIFETIME
- `lifetime_earned_points` increments strictly on completed mission, review, or visit rewards. Signup bonuses increment `current_points` only.
