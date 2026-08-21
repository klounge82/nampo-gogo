import os
import json

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def check_file_guard(filepath):
    reg_path = os.path.join(REPO_DIR, "docs", "master_control", "FILE_REGISTRY.json")
    if not os.path.exists(reg_path):
        return {"file": filepath, "safety_class": "UNKNOWN"}
    with open(reg_path, "r", encoding="utf-8") as f:
        reg = json.load(f)
    for entry in reg:
        if entry.get("path") == filepath:
            return entry
    return {
        "file": filepath,
        "safety_class": "PROTECTED" if "04_Source_Code" in filepath else "REVIEW_REQUIRED",
        "safe_to_delete": False,
        "pm_approval_required": True
    }

def check_identity_guard(identity_val):
    reg_path = os.path.join(REPO_DIR, "docs", "master_control", "IDENTITY_REGISTRY.json")
    if not os.path.exists(reg_path):
        return {"identity": identity_val, "status": "IDENTITY_NOT_FOUND"}
    with open(reg_path, "r", encoding="utf-8") as f:
        reg = json.load(f)
    for entry in reg:
        if entry.get("canonical_id") == identity_val or entry.get("email") == identity_val or identity_val in entry.get("aliases", []):
            return entry
    return {"identity": identity_val, "status": "IDENTITY_NOT_FOUND", "notes": "No implicit or guessed identity allowed"}
