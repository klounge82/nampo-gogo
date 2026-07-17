import urllib.request
import json

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

print("--- 0. 테스트 유저 사전 회원가입 ---")
signup_status, signup_res = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": "point_test@gogo.com", "password": "securepwd123", "nickname": "포인트테스터"}
)
print("Signup Status:", signup_status)

print("\n--- 1. 현재 사용자 및 보유 포인트 조회 ---")
status, info = make_request(f"{base_url}/users/points")
print("Status:", status)
print("UserInfo:", info)

user_id = info['user_id']

print("\n--- 2. 포인트 적립 API 테스트 (300 P) ---")
earn_status, earn_res = make_request(
    f"{base_url}/users/points/earn",
    method="POST",
    data={"points": 300, "activity": "보너스 웰컴 포인트 적립", "user_id": user_id}
)
print("Status:", earn_status)
print("Result:", earn_res)

print("\n--- 3. 포인트 사용 API 테스트 (100 P) ---")
spend_status, spend_res = make_request(
    f"{base_url}/users/points/spend",
    method="POST",
    data={"points": 100, "activity": "자갈치 카페 쿠폰 교환", "user_id": user_id}
)
print("Status:", spend_status)
print("Result:", spend_res)

print("\n--- 4. 포인트 거래 상세 이력 조회 ---")
hist_status, histories = make_request(f"{base_url}/users/points/history?user_id={user_id}")
print("Status:", hist_status)
print("최신 3개 내역:")
for h in histories[:3]:
    print(f" - [{h['created_at']}] {h['activity']}: {h['points']} P")

print("\n--- 5. 포인트 사용 실패 테스트 (과다 사용 시 잔고 부족 차단) ---")
big_points = earn_res['current_points'] + 1000
fail_status, fail_res = make_request(
    f"{base_url}/users/points/spend",
    method="POST",
    data={"points": big_points, "activity": "호화 크루즈 탑승권 교환", "user_id": user_id}
)
print("Status (Expected 400):", fail_status)
print("Response:", fail_res)
