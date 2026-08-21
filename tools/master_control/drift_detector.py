import os
import json

try:
    from .scanner import scan_project_fingerprint
except ImportError:
    from scanner import scan_project_fingerprint

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def detect_drift():
    fp = scan_project_fingerprint()
    file_reg_path = os.path.join(REPO_DIR, "docs", "master_control", "FILE_REGISTRY.json")
    
    if not os.path.exists(file_reg_path):
        return {
            "registered_scope_drift_status": "DRIFT_DETECTED",
            "project_coverage_status": "PARTIAL",
            "full_project_drift_status": "UNKNOWN",
            "reason": "FILE_REGISTRY.json missing"
        }
        
    with open(file_reg_path, "r", encoding="utf-8") as f:
        file_reg = json.load(f)
        
    missing_files = []
    for entry in file_reg:
        rel_path = entry.get("path")
        abs_path = os.path.join(REPO_DIR, rel_path)
        if not os.path.exists(abs_path):
            missing_files.append(rel_path)
            
    if missing_files:
        return {
            "registered_scope_drift_status": "DRIFT_DETECTED",
            "project_coverage_status": "COMPLETE_FOR_CORE",
            "full_project_drift_status": "DRIFT_DETECTED",
            "missing_registered_files": missing_files,
            "git_commit": fp.get("current_git_commit")
        }
        
    return {
        "registered_scope_drift_status": "NO_DRIFT",
        "project_coverage_status": "COMPLETE_FOR_CORE",
        "full_project_drift_status": "NO_DRIFT_ON_REGISTERED_SCOPE",
        "git_commit": fp.get("current_git_commit"),
        "dirty_status": fp.get("git_dirty_status")
    }

if __name__ == "__main__":
    res = detect_drift()
    print("Drift Detector Result:", json.dumps(res, indent=2))
