import os
import json
import hashlib
import subprocess

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def get_git_commit():
    try:
        res = subprocess.run(["git", "rev-parse", "HEAD"], cwd=REPO_DIR, capture_output=True, text=True)
        return res.stdout.strip()
    except Exception:
        return "UNKNOWN"

def get_git_status():
    try:
        res = subprocess.run(["git", "status", "--porcelain"], cwd=REPO_DIR, capture_output=True, text=True)
        return "DIRTY" if res.stdout.strip() else "CLEAN"
    except Exception:
        return "UNKNOWN"

def calculate_file_hash(filepath):
    abs_path = os.path.join(REPO_DIR, filepath)
    if not os.path.exists(abs_path):
        return None
    hasher = hashlib.sha256()
    with open(abs_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hasher.update(chunk)
    return hasher.hexdigest()

def scan_project_fingerprint():
    cache_dir = os.path.join(os.path.dirname(__file__), ".cache")
    os.makedirs(cache_dir, exist_ok=True)
    
    commit = get_git_commit()
    status = get_git_status()
    
    protected_files = [
        "04_Source_Code/backend/app/main.py",
        "04_Source_Code/frontend/lib/providers/auth_provider.dart",
        "04_Source_Code/frontend/pubspec.yaml"
    ]
    
    hashes = {}
    for pf in protected_files:
        hashes[pf] = calculate_file_hash(pf)
        
    fingerprint = {
        "current_git_commit": commit,
        "git_dirty_status": status,
        "protected_file_hashes": hashes,
        "scan_time": "2026-08-20T20:00:00+09:00"
    }
    
    with open(os.path.join(cache_dir, "project_fingerprint.json"), "w", encoding="utf-8") as f:
        json.dump(fingerprint, f, indent=2, ensure_ascii=False)
        
    return fingerprint

if __name__ == "__main__":
    fp = scan_project_fingerprint()
    print("Project Fingerprint Scanned:", json.dumps(fp, indent=2))
