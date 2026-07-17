import requests
import sys

BASE_URL = "http://localhost:18080"

def test_analytics_system():
    print("=== STARTING OWNER ANALYTICS SYSTEM INTEGRATION TESTS ===")
    
    # 1. Sign up a new owner test user
    signup_data = {
        "email": "owner_test_analytics@nampo.gogo",
        "nickname": "사장님테스트",
        "password": "Password123!",
        "role": "owner"
    }
    signup_res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    if signup_res.status_code not in [200, 201, 400]:
        print(f"[FAIL] Signup returned status: {signup_res.status_code}")
        sys.exit(1)
        
    # 2. Login to get access token
    login_res = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": signup_data["email"], "password": signup_data["password"]}
    )
    if login_res.status_code != 200:
        print(f"[FAIL] Login failed: {login_res.status_code} -> {login_res.text}")
        sys.exit(1)
        
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 3. GET /analytics/dashboard
    dash_res = requests.get(f"{BASE_URL}/analytics/dashboard", headers=headers)
    if dash_res.status_code != 200:
        print(f"[FAIL] GET /analytics/dashboard failed: {dash_res.status_code}")
        sys.exit(1)
    dash_json = dash_res.json()
    print(f"[PASS] GET /analytics/dashboard verified: {dash_json}")
    assert dash_json["this_month_revenue"] >= 3250000
    assert dash_json["app_contributed_total_revenue"] >= 3250000
    assert dash_json["roi_percentage"] > 0
    
    # 4. GET /analytics/revenue
    rev_res = requests.get(f"{BASE_URL}/analytics/revenue", headers=headers)
    if rev_res.status_code != 200:
        print(f"[FAIL] GET /analytics/revenue failed: {rev_res.status_code}")
        sys.exit(1)
    print(f"[PASS] GET /analytics/revenue verified: {rev_res.json()}")
    
    # 5. GET /analytics/reservation
    res_res = requests.get(f"{BASE_URL}/analytics/reservation", headers=headers)
    if res_res.status_code != 200:
        print(f"[FAIL] GET /analytics/reservation failed: {res_res.status_code}")
        sys.exit(1)
    print(f"[PASS] GET /analytics/reservation verified: {res_res.json()}")
    
    # 6. GET /analytics/ai
    ai_res = requests.get(f"{BASE_URL}/analytics/ai", headers=headers)
    if ai_res.status_code != 200:
        print(f"[FAIL] GET /analytics/ai failed: {ai_res.status_code}")
        sys.exit(1)
    print(f"[PASS] GET /analytics/ai verified: {ai_res.json()}")

    print("=== ALL OWNER ANALYTICS SYSTEM TESTS PASSED SUCCESSFULLY ===")

if __name__ == "__main__":
    test_analytics_system()
