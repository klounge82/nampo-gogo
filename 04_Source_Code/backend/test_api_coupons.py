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

print("--- 0. 회원가입 및 포인트 2000P 충전 ---")
signup_status, user_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": "coupon_test@gogo.com", "password": "securepwd123", "nickname": "쿠폰테스터"}
)
user_id = user_info['id']
print("User ID:", user_id)

# 2000P 충전
earn_status, earn_res = make_request(
    f"{base_url}/users/points/earn",
    method="POST",
    data={"points": 2000, "activity": "테스트용 포인트 충전", "user_id": user_id}
)
print("Earn Points Status:", earn_status, "Current Points:", earn_res['current_points'])

print("\n--- 1. 상점 쿠폰 상품 목록 조회 ---")
status, coupons = make_request(f"{base_url}/coupons")
print("Status:", status)
print("Seeded Coupons:")
coffee_coupon = None
for c in coupons:
    print(f" - [{c['cost_points']} P] {c['title']} ({c['description'][:20]}...)")
    if "아메리카노" in c['title']:
        coffee_coupon = c

if not coffee_coupon:
    print("Error: 아메리카노 쿠폰이 없습니다.")
    exit(1)

print("\n--- 2. 쿠폰 교환 API 테스트 (아메리카노 -500P) ---")
exch_status, exch_res = make_request(
    f"{base_url}/coupons/{coffee_coupon['id']}/exchange",
    method="POST",
    data={"user_id": user_id}
)
print("Status:", exch_status)
print("Exchange Response:", exch_res)
user_coupon_id = exch_res['user_coupon_id']

print("\n--- 3. 보유 쿠폰 목록 조회 ---")
owned_status, owned_list = make_request(f"{base_url}/users/coupons?user_id={user_id}&status=unused")
print("Status:", owned_status)
print("Owned Unused Coupons:")
for uc in owned_list:
    print(f" - [UserCoupon ID: {uc['id']}] Status: {uc['status']}, Coupon: {uc['coupon']['title']}")

print("\n--- 4. 쿠폰 사용 API 테스트 (직원 확인용) ---")
use_status, use_res = make_request(
    f"{base_url}/users/coupons/{user_coupon_id}/use",
    method="POST",
    data={"user_id": user_id}
)
print("Status:", use_status)
print("Response:", use_res)

print("\n--- 5. 이미 사용 완료된 쿠폰 중복 사용 차단 테스트 ---")
fail_status, fail_res = make_request(
    f"{base_url}/users/coupons/{user_coupon_id}/use",
    method="POST",
    data={"user_id": user_id}
)
print("Status (Expected 400):", fail_status)
print("Response:", fail_res)
