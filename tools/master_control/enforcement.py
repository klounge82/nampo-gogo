import os
import json
import subprocess

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

class ExecutionGuard:
    def __init__(self, manifest_path=None):
        if manifest_path is None:
            manifest_path = os.path.join(REPO_DIR, "docs", "master_control", "EXECUTION_MANIFEST.json")
        self.manifest_path = manifest_path
        self.records = self._load_manifest()

    def _load_manifest(self):
        if os.path.exists(self.manifest_path):
            try:
                with open(self.manifest_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def save_manifest(self):
        with open(self.manifest_path, "w", encoding="utf-8") as f:
            json.dump(self.records, f, indent=2, ensure_ascii=False)

    def check_idempotency(self, change_id, target_id, operation_type, idempotency_key):
        for rec in self.records:
            if (rec.get("change_id") == change_id and
                rec.get("target_entity_id_masked") == target_id and
                rec.get("operation_type") == operation_type and
                rec.get("idempotency_key") == idempotency_key and
                rec.get("status") in ["SUCCESS", "TECHNICAL_PASS", "CLOSED"]):
                return {
                    "gate_status": "BLOCKED_ALREADY_EXECUTED",
                    "reason": f"Execution with idempotency_key '{idempotency_key}' already completed for {change_id}."
                }
        return {"gate_status": "ALLOWED"}

    def record_execution(self, record_dict):
        self.records.append(record_dict)
        self.save_manifest()

def validate_expected_vs_actual(expected_insert, actual_insert, expected_update, actual_update, expected_delete, actual_delete):
    if expected_insert != actual_insert or expected_update != actual_update or expected_delete != actual_delete:
        return {
            "status": "FAIL",
            "reason": f"Count mismatch: Insert (exp {expected_insert}/act {actual_insert}), Update (exp {expected_update}/act {actual_update}), Delete (exp {expected_delete}/act {actual_delete})"
        }
    return {"status": "PASS"}

def validate_arithmetic(ledger_history_points, users_current_points):
    calc_sum = sum(ledger_history_points)
    match = (calc_sum == users_current_points)
    return {
        "expected": users_current_points,
        "actual": calc_sum,
        "match": match,
        "status": "PASS" if match else "FAIL"
    }

def validate_completion_report(report_dict, actual_git_modified_files, actual_build_count, actual_db_writes):
    contradictions = []
    rep_files_changed = report_dict.get("source_files_changed", -1)
    if rep_files_changed == 0 and len(actual_git_modified_files) > 0:
        contradictions.append(f"SOURCE_FILES_CHANGED reported 0 but git modified: {actual_git_modified_files}")

    rep_build_count = report_dict.get("build_count", 0)
    rep_build_result = report_dict.get("build_result", "")
    if rep_build_count == 0 and rep_build_result == "PASS" and actual_build_count == 0:
        pass # Build not performed, valid if build_required=NO

    rep_device_ver = report_dict.get("final_device_verified", "NO")
    rep_incident_stat = report_dict.get("incident_status", "")
    if rep_device_ver == "NO" and rep_incident_stat == "RESOLVED":
        contradictions.append("Incident marked RESOLVED while FINAL_DEVICE_VERIFIED is NO")

    return {
        "report_validation": "PASS" if len(contradictions) == 0 else "FAIL",
        "report_contradictions_count": len(contradictions),
        "details": contradictions
    }
