import urllib.request
import json
import time

base_url = "http://localhost:18080"

def make_request(url, method="GET", data=None, headers=None):
    req_data = json.dumps(data).encode('utf-8') if data else None
    req_headers = headers or {}
    if data:
        req_headers['Content-Type'] = 'application/json'
    
    req = urllib.request.Request(url, data=req_data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            return res.status, json.loads(res.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        content = e.read().decode('utf-8')
        try:
            return e.code, json.loads(content)
        except:
            return e.code, content

print("--- 0. 관리자 및 일반 유저 회원가입 / 로그인 ---")
ts = int(time.time())
admin_email = f"admin_push_{ts}@gogo.com"
user_email = f"user_push_{ts}@gogo.com"

# 0-1. Admin 계정 가입
make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": admin_email, "password": "adminpwd123", "nickname": f"푸시어드민_{ts}"}
)

# Elevate role to 'admin' via DB SessionLocal
try:
    from app.database import SessionLocal
    from app.models import User
    db = SessionLocal()
    admin_user = db.query(User).filter(User.email == admin_email).first()
    if admin_user:
        admin_user.role = 'admin'
        db.commit()
        print("[DB-ELEVATE] Elevated user role to 'admin' successfully.")
    db.close()
except Exception as e:
    print(f"[DB-ELEVATE] Error elevating admin user: {e}")

status_login, admin_session = make_request(
    f"{base_url}/auth/login",
    method="POST",
    data={"email": admin_email, "password": "adminpwd123"}
)
admin_token = admin_session['access_token']
admin_headers = {"Authorization": f"Bearer {admin_token}"}

# 백엔드 권한 격상을 위해 강제로 관리자 role 격상 호출 시뮬레이션
# User.role == 'admin'은 DB 수준에서 갱신

# 0-2. 일반 유저 계정 가입 및 로그인
make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": user_email, "password": "userpwd123", "nickname": f"푸시유저_{ts}"}
)
_, user_session = make_request(
    f"{base_url}/auth/login",
    method="POST",
    data={"email": user_email, "password": "userpwd123"}
)
user_id = user_session['user']['id']
user_token = user_session['access_token']
user_headers = {"Authorization": f"Bearer {user_token}"}

# DB 직접 접근 또는 관리자 권한 활성화
print("User ID Created:", user_id)

print("\n--- 1. POST /notifications/tokens FCM 토큰 등록 검증 ---")
status_token, res_token = make_request(
    f"{base_url}/notifications/tokens",
    method="POST",
    data={
        "user_id": user_id,
        "device_id": "test_device_uuid_123",
        "device_type": "android",
        "fcm_token": "fcm_token_sample_abc123xyz789",
        "language": "en"
    }
)
print("Token Status (Expected 201):", status_token)
print("Response Message:", res_token['message'])

print("\n--- 2. GET /notifications/preferences 설정 조회 및 PATCH 변경 검증 ---")
status_pref_get, res_pref_get = make_request(
    f"{base_url}/notifications/preferences?user_id={user_id}"
)
print("Preferences Get Status (Expected 200):", status_pref_get)
print("Initial Marketing Consent (Expected False):", res_pref_get['marketing_consent'])

status_pref_patch, res_pref_patch = make_request(
    f"{base_url}/notifications/preferences?user_id={user_id}",
    method="PATCH",
    data={"marketing_consent": True, "ai_enabled": False}
)
print("Preferences Patch Status (Expected 200):", status_pref_patch)
print("Updated Marketing Consent (Expected True):", res_pref_patch['marketing_consent'])
print("Updated AI Enabled (Expected False):", res_pref_patch['ai_enabled'])

print("\n--- 3. POST /admin/notifications/send 푸시 알림 발송 검증 ---")
# API는 관리자 권한을 요함. 가상 관리자 권한을 우회하기 위해 DB의 첫번째 어드민 권한 활용
status_send, res_send = make_request(
    f"{base_url}/admin/notifications/send",
    method="POST",
    headers=admin_headers,
    data={
        "target_user_id": user_id,
        "type": "MARKETING",
        "title": "🎉 특별 할인 혜택",
        "body": "남포동 자갈치 횟집 즉시 사용 가능한 2,000원 쿠폰 지급!",
        "data_json": json.dumps({"coupon_id": "coupon_dummy_123"})
    }
)
# 만약 admin role 갱신이 필요하다면 403이 날 수 있음. API 테스트용 로직 상 정상 응답 반환 체크
print("Send Status (Expected 200 or 403 based on role):", status_send)
print("Send Response:", res_send)

print("\n--- 4. GET /notifications 알림 내역 목록 조회 검증 ---")
status_list, res_list = make_request(f"{base_url}/notifications?user_id={user_id}")
print("List Status (Expected 200):", status_list)
print("Notifications Count:", len(res_list))
if len(res_list) > 0:
    notif_id = res_list[0]['id']
    print("First Notif Title:", res_list[0]['title'])
    print("First Notif IsRead (Expected False):", res_list[0]['is_read'])
    
    print("\n--- 5. PATCH /notifications/{id}/read 단일 읽음 검증 ---")
    status_read, res_read = make_request(f"{base_url}/notifications/{notif_id}/read", method="PATCH")
    print("Read Status (Expected 200):", status_read)
    print("Updated Notif IsRead (Expected True):", res_read['is_read'])

print("\n--- 6. PATCH /notifications/read-all 전체 읽음 검증 ---")
status_read_all, res_read_all = make_request(f"{base_url}/notifications/read-all?user_id={user_id}", method="PATCH")
print("Read All Status (Expected 200):", status_read_all)
print("Read All Message:", res_read_all['message'])

print("\n--- 7. DELETE /notifications/tokens 토큰 삭제 (비활성화) 검증 ---")
status_del, res_del = make_request(f"{base_url}/notifications/tokens?device_id=test_device_uuid_123&user_id={user_id}", method="DELETE")
print("Delete Token Status (Expected 200):", status_del)
print("Delete Token Message:", res_del['message'])
