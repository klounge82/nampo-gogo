import urllib.request
import json
from datetime import datetime, timedelta

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

print("--- 0. 회원가입 및 매장 데이터 확인 ---")
signup_status, user_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": "res_test@gogo.com", "password": "securepwd123", "nickname": "예약테스터"}
)
user_id = user_info['id']
print("User ID:", user_id)

# 매장 목록 조회
store_status, stores = make_request(f"{base_url}/stores")
if not stores:
    print("Error: Seeding된 매장 정보가 없습니다.")
    exit(1)
target_store = stores[0]
print(f"Target Store: {target_store['name']} (ID: {target_store['id']})")

print("\n--- 1. 예약 신청 API 테스트 ---")
# 내일 오후 6시 예약 설정
tomorrow_6pm = (datetime.utcnow() + timedelta(days=1)).replace(hour=18, minute=0, second=0, microsecond=0)
res_time_str = tomorrow_6pm.isoformat()

res_status, res_info = make_request(
    f"{base_url}/reservations",
    method="POST",
    data={
        "store_id": target_store['id'],
        "reservation_time": res_time_str,
        "party_size": 4,
        "user_id": user_id
    }
)
print("Create Reservation Status (Expected 201):", res_status)
print("Response:", res_info)
reservation_id = res_info['id']

print("\n--- 2. 내 예약 목록 조회 API 테스트 ---")
list_status, list_res = make_request(f"{base_url}/users/reservations?user_id={user_id}")
print("Status:", list_status)
for r in list_res:
    print(f" - [Res ID: {r['id']}] Status: {r['status']}, Store: {r['store']['name']}, Time: {r['reservation_time']}")

print("\n--- 3. 예약 취소 API 테스트 ---")
cancel_status, cancel_res = make_request(
    f"{base_url}/reservations/{reservation_id}/cancel",
    method="POST",
    data={"user_id": user_id}
)
print("Cancel Status:", cancel_status)
print("Response:", cancel_res)

print("\n--- 4. 중복 취소 차단 및 예외 테스트 ---")
dup_status, dup_res = make_request(
    f"{base_url}/reservations/{reservation_id}/cancel",
    method="POST",
    data={"user_id": user_id}
)
print("Duplicate Cancel Status (Expected 400):", dup_status)
print("Response:", dup_res)
