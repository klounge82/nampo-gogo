import urllib.request
import json
import time
from datetime import datetime, timedelta
from .database import SessionLocal
from . import models

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

print("--- 0. 회원가입 및 매장 데이터 준비 ---")
ts = int(time.time())

# User A (권한 부여받을 유저)
ua_email = f"review_a_{ts}@gogo.com"
status_ua, ua_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": ua_email, "password": "securepwd123", "nickname": f"철수_{ts}"}
)
if status_ua != 201:
    print(f"Error signing up User A: {status_ua}, body: {ua_info}")
    exit(1)
user_a_id = ua_info['id']
print("User A ID:", user_a_id)

# User B (권한이 없는 유저)
ub_email = f"review_b_{ts}@gogo.com"
status_ub, ub_info = make_request(
    f"{base_url}/auth/signup",
    method="POST",
    data={"email": ub_email, "password": "securepwd123", "nickname": f"영희_{ts}"}
)
if status_ub != 201:
    print(f"Error signing up User B: {status_ub}, body: {ub_info}")
    exit(1)
user_b_id = ub_info['id']
print("User B ID:", user_b_id)

# 매장 조회
_, stores = make_request(f"{base_url}/stores")
target_store = stores[0]
store_id = target_store['id']
print(f"Target Store: {target_store['name']} (ID: {store_id})")

# User A 매장 예약 신청 생성 및 상태 완료(completed) 모의 셋팅
res_status, res_info = make_request(
    f"{base_url}/reservations",
    method="POST",
    data={
        "store_id": store_id,
        "reservation_time": (datetime.utcnow() + timedelta(days=2)).isoformat(),
        "party_size": 2,
        "user_id": user_a_id
    }
)
res_id = res_info['id']

# DB 조작
db = SessionLocal()
try:
    res_obj = db.query(models.StoreReservation).filter(models.StoreReservation.id == res_id).first()
    if res_obj:
        res_obj.status = "completed"
        db.commit()
        print("Set User A reservation status to completed.")
finally:
    db.close()

print("\n--- 1. 권한 없는 유저(User B) 리뷰 작성 차단 테스트 ---")
fail_status, fail_res = make_request(
    f"{base_url}/stores/{store_id}/reviews",
    method="POST",
    data={
        "rating": 5,
        "content": "이곳은 정말 맛있고 훌륭한 고깃집입니다. 추천합니다!",
        "user_id": user_b_id
    }
)
print("Status (Expected 403):", fail_status)
print("Response:", fail_res)

print("\n--- 2. 권한 있는 유저(User A) 리뷰 작성 성공 테스트 ---")
success_status, success_res = make_request(
    f"{base_url}/stores/{store_id}/reviews",
    method="POST",
    data={
        "rating": 5,
        "content": "이곳은 정말 맛있고 훌륭한 고깃집입니다. 추천합니다!",
        "user_id": user_a_id
    }
)
print("Status (Expected 201):", success_status)
print("Response Rating:", success_res['rating'], "Content:", success_res['content'])
review_id = success_res['id']

# 매장 정보 재조회하여 평점 5.0 반영 확인
_, updated_stores1 = make_request(f"{base_url}/stores")
target_st1 = next((s for s in updated_stores1 if s['id'] == store_id), None)
print("Store Rating after Create (Expected 5.0):", target_st1['rating'] if target_st1 else "Not Found")

print("\n--- 3. 동일 매장 중복 리뷰 차단 테스트 ---")
dup_status, dup_res = make_request(
    f"{base_url}/stores/{store_id}/reviews",
    method="POST",
    data={
        "rating": 4,
        "content": "두 번째 남기는 맛있는 후기입니다. 좋습니다.",
        "user_id": user_a_id
    }
)
print("Status (Expected 400):", dup_status)
print("Response:", dup_res)

print("\n--- 4. 리뷰 수정 및 매장 평균 평점 재계산 검증 (5점 -> 3점) ---")
edit_status, edit_res = make_request(
    f"{base_url}/reviews/{review_id}",
    method="PATCH",
    data={
        "rating": 3,
        "content": "음식이 생각보다 조금 짜서 평점을 수정합니다. 아쉬워요."
      }
)
print("Edit Status (Expected 200):", edit_status)

# 매장 정보 재조회하여 평점 3.0 변동 확인
_, updated_stores = make_request(f"{base_url}/stores")
target_st = next((s for s in updated_stores if s['id'] == store_id), None)
print("Updated Store Rating (Expected 3.0):", target_st['rating'] if target_st else "Not Found")

print("\n--- 5. 리뷰 삭제(Soft Delete) 및 매장 목록 조회 검증 ---")
del_status, del_res = make_request(f"{base_url}/reviews/{review_id}", method="DELETE")
print("Delete Status:", del_status)

# 매장 리뷰 리스트 GET 시 빈 배열 확인
list_status, list_res = make_request(f"{base_url}/stores/{store_id}/reviews")
print("Store Reviews Count (Expected 0):", len(list_res))

# 매장 평점이 0.0 으로 복구되었는지 확인
_, reset_stores = make_request(f"{base_url}/stores")
target_reset_st = next((s for s in reset_stores if s['id'] == store_id), None)
print("Reset Store Rating (Expected 0.0):", target_reset_st['rating'] if target_reset_st else "Not Found")
