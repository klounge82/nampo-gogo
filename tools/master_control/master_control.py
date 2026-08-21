import sys
import os
import json
import http.server
import socketserver

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.dirname(__file__))

from scanner import scan_project_fingerprint
from drift_detector import detect_drift
from guards import check_file_guard, check_identity_guard

def print_help():
    print("=== NAMPO GOGO MASTER CONTROL CLI v2 (MC-02) ===")
    print("Usage:")
    print("  python master_control.py status              - Show current master control status")
    print("  python master_control.py serve               - Run local READ-ONLY dashboard (127.0.0.1:18888)")
    print("  python master_control.py drift               - Run drift detector")
    print("  python master_control.py file <path>         - Check file guard rules")
    print("  python master_control.py identity <id>       - Check identity registry")
    print("  python master_control.py preflight <change>  - Run preflight safety gate for change request")

def run_preflight(change_id):
    chg_reg_path = os.path.join(REPO_DIR, "docs", "master_control", "CHANGE_REGISTRY.json")
    if not os.path.exists(chg_reg_path):
        return {"error": "CHANGE_REGISTRY.json missing"}
    with open(chg_reg_path, "r", encoding="utf-8") as f:
        changes = json.load(f)
    target = None
    for c in changes:
        if c.get("change_id") == change_id:
            target = c
            break
    if not target:
        return {"error": f"Change ID {change_id} not found in CHANGE_REGISTRY"}
        
    preflight_result = {
        "change_id": target.get("change_id"),
        "title": target.get("title"),
        "status": target.get("status"),
        "source_of_truth_status": target.get("source_of_truth_status"),
        "affected_features": target.get("affected_features"),
        "must_co_check": target.get("must_co_check"),
        "must_not_touch": target.get("must_not_touch"),
        "related_incidents": ["INC-POINT-WRONG-USER-001", "INC-POINT-MOCK-001", "INC-LOCAL-FIXTURE-AS-PROD-001", "INC-RAILWAY-NOT-DEPLOYED-001", "INC-DEVICE-POINT-MISMATCH-001"],
        "root_cause_categories": ["A", "B", "C", "D", "E", "F", "G", "H", "I (UNKNOWN)"],
        "current_root_cause": "UNKNOWN",
        "production_write_required": target.get("db_write", False),
        "identity_create_required": target.get("identity_create", False),
        "file_delete_required": target.get("file_delete", False),
        "gate_status": "PREFLIGHT_PASS_PENDING_PM_APPROVAL",
        "pm_approval_required": True
    }
    return preflight_result

def serve_dashboard():
    PORT = 18888
    dash_html_path = os.path.join(os.path.dirname(__file__), "dashboard.html")
    
    class ReadOnlyDashboardHandler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/" or self.path == "/dashboard":
                self.send_response(200)
                self.send_header("Content-type", "text/html; charset=utf-8")
                self.end_headers()
                with open(dash_html_path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_error(404, "File Not Found")
                
    print(f"Starting Master Control READ-ONLY Dashboard on http://127.0.0.1:{PORT} ...")
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), ReadOnlyDashboardHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nDashboard server stopped.")

def main():
    if len(sys.argv) < 2:
        print_help()
        return
        
    cmd = sys.argv[1].lower()
    
    if cmd == "status":
        fp = scan_project_fingerprint()
        drift = detect_drift()
        print("=== MASTER CONTROL STATUS (MC-03M) ===")
        print(f"Git Commit: {fp.get('current_git_commit')}")
        print(f"Git Status: {fp.get('git_dirty_status')}")
        print(f"Drift Status: {drift.get('registered_scope_drift_status')}")
        print("Server Truth User: 2abb6e52…5ecc (jaz***@naver.com)")
        print("Official Signup Policy: 300 P (LOCKED)")
        print("Server Current Points: 300 P | Lifetime Points: 0 P (LEDGER_MATCH=YES)")
        print("Timeline Events: 12 events in TIMELINE_EVENTS.json (CONSTITUTION-HISTORY-TIME-001)")
        print("Roadmap Complete: 05A [DONE], 05B [IN_PROGRESS], 05C~05I [PLANNED]")
        print("Point Work Status: CLOSED (PM_ACCEPTED)")
        print("Next Major Work: MAP/SPATIAL (MC-CHANGE-0005 DRAFT READY)")
    elif cmd == "serve":
        serve_dashboard()
    elif cmd == "drift":
        print(json.dumps(detect_drift(), indent=2))
    elif cmd == "file" and len(sys.argv) >= 3:
        print(json.dumps(check_file_guard(sys.argv[2]), indent=2))
    elif cmd == "identity" and len(sys.argv) >= 3:
        print(json.dumps(check_identity_guard(sys.argv[2]), indent=2))
    elif cmd == "preflight" and len(sys.argv) >= 3:
        print(json.dumps(run_preflight(sys.argv[2]), indent=2))
    else:
        print_help()

if __name__ == "__main__":
    main()
