import urllib.request
import json
import time

base_url = "http://localhost:18080"

def make_request(url, method="GET", data=None):
    req_data = json.dumps(data).encode('utf-8') if data else None
    headers = {'Content-Type': 'application/json'} if data else {}
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            return res.status, json.loads(res.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        content = e.read().decode('utf-8')
        try:
            return e.code, json.loads(content)
        except:
            return e.code, content

print("--- 0. 관리자 및 일반 유저 생성 데이터 준비 ---")
ts = int(time.time())

# 1. Admin 유저 회원가입
admin_email = f"admin_{ts}@gogo.com"
status_ad, ad_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": admin_email, "password": "adminpwd123", "nickname": f"총괄관리자_{ts}"}
)
admin_id = ad_info['id']
print("Registered User ID (to be promoted):", admin_id)

# DB SessionLocal을 이용해서 가입한 admin 유저의 role 을 'admin' 으로 승격처리!
from .database import SessionLocal
from . import models
db = SessionLocal()
try:
    admin_obj = db.query(models.User).filter(models.User.id == admin_id).first()
    if admin_obj:
        admin_obj.role = "admin"
        db.commit()
        print("Successfully promoted role to 'admin' in database.")
finally:
    db.close()

# 2. 일반 멤버 유저 회원가입
member_email = f"member_{ts}@gogo.com"
status_mem, mem_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": member_email, "password": "memberpwd123", "nickname": f"일반회원_{ts}"}
)
member_id = mem_info['id']
print("Registered Member ID:", member_id)

print("\n--- 1. 관리자 대시보드 지표 통계 API 검증 ---")
status_stats, res_stats = make_request(f"{base_url}/admin/stats?admin_id={admin_id}")
print("Stats Status:", status_stats)
print("Stats Response:", res_stats)

print("\n--- 2. 관리자 회원 계정 목록 조회 API 검증 ---")
status_users, res_users = make_request(f"{base_url}/admin/users?admin_id={admin_id}")
print("Users Count in List:", len(res_users))
print("First User Email:", res_users[0]['email'])

print("\n--- 3. 일반 사용자(member) 계정 강제 정지(blocked) 처리 API 검증 ---")
status_block, res_block = make_request(
    f"{base_url}/admin/users/{member_id}/status?admin_id={admin_id}",
    method="PATCH",
    data={"status": "blocked"}
)
print("Status Update status:", status_block)
print("Updated User Status (Expected blocked):", res_block['status'])

print("\n--- 4. 정지된 일반 사용자 계정 로그인 시도 차단 검증 ---")
status_login, res_login = make_request(
    f"{base_url}/auth/login",
    method="POST",
    data={"email": member_email, "password": "memberpwd123"}
)
print("Blocked Login Status (Expected 403):", status_login)
print("Blocked Login Response:", res_login)

print("\n--- 5. 관리자 감사 로그(AdminAuditLog) 생성 및 로드 검증 ---")
status_logs, res_logs = make_request(f"{base_url}/admin/audit-logs?admin_id={admin_id}")
print("Audit Logs Count:", len(res_logs))
print("Last Log Action (Expected UPDATE_USER_STATUS):", res_logs[0]['action'])
print("Last Log Details:", res_logs[0]['details'])
print("Last Log Admin Nickname:", res_logs[0]['admin']['nickname'])
