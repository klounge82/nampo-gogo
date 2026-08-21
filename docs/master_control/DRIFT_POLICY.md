# 🔄 DRIFT POLICY & MONITORING

- Master Control monitors protected file hashes, API route declarations, and DB schemas against registry definitions.
- If a drift is detected, Master Control reports `DRIFT_DETECTED` with `EXPECTED` vs `ACTUAL` values.
- Master Control **NEVER** automatically mutates production code or database tables to fix a drift.
