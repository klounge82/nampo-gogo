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

print("--- 0. 추천 회원가입 계정 준비 ---")
ts = int(time.time())
user_email = f"ai_user_{ts}@gogo.com"
status_signup, user_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": user_email, "password": "aipwd123", "nickname": f"AI테스터_{ts}"}
)
user_id = user_info['id']
print("User ID Created:", user_id)

print("\n--- 1. POST /recommendations/courses AI 코스 추천 생성 API 검증 ---")
status_rec, res_rec = make_request(
    f"{base_url}/recommendations/courses",
    method="POST",
    data={
        "user_id": user_id,
        "travel_type": "COUPLE",
        "travel_duration": "HALF_DAY",
        "categories": ["FOOD", "CAFE"],
        "transport_mode": "WALK",
        "latitude": 35.0987,
        "longitude": 129.0289
    }
)
print("Rec Status (Expected 201):", status_rec)
rec_id = res_rec['id']
print("Recommended Course ID:", rec_id)
print("Items Count (Expected 3):", len(res_rec['items']))
print("First Item Store Name:", res_rec['items'][0]['store']['name'])
print("First Item Reason Code:", res_rec['items'][0]['recommend_reason_code'])

print("\n--- 2. PATCH /recommendations/{id}/save 코스 보관함 저장 API 검증 ---")
status_save, res_save = make_request(
    f"{base_url}/recommendations/{rec_id}/save?is_saved=true",
    method="PATCH"
)
print("Save Status (Expected 200):", status_save)
print("Is Saved value (Expected True):", res_save['is_saved'])

print("\n--- 3. GET /recommendations/history 보관 내역 리스트 API 검증 ---")
status_history, res_history = make_request(f"{base_url}/recommendations/history?user_id={user_id}")
print("History Status (Expected 200):", status_history)
print("Saved History Count (Expected 1):", len(res_history))
print("History First Item ID:", res_history[0]['id'])

print("\n--- 4. DELETE /recommendations/{id} 추천 이력 삭제 API 검증 ---")
status_delete, res_delete = make_request(f"{base_url}/recommendations/{rec_id}", method="DELETE")
print("Delete Status (Expected 200):", status_delete)
print("Delete Response Message:", res_delete['message'])
