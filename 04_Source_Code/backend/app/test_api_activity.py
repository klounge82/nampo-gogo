import requests
import uuid

BASE_URL = "http://localhost:18080"

def test_activity_system():
    # Setup test account with unique email using UUID
    unique_id = str(uuid.uuid4())[:8]
    signup_data = {
        "email": f"acttester_{unique_id}@example.com",
        "password": "Password123!",
        "nickname": f"ActTester_{unique_id}"
    }
    signup_res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    assert signup_res.status_code in [200, 201], f"Signup failed: {signup_res.text}"

    login_res = requests.post(f"{BASE_URL}/auth/login", json={"email": signup_data["email"], "password": signup_data["password"]})
    assert login_res.status_code in [200, 201], f"Login failed: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Verify SIGNUP activity log was automatically created during signup
    act_res = requests.get(f"{BASE_URL}/activity", headers=headers)
    assert act_res.status_code == 200
    activities = act_res.json()
    assert len(activities) > 0, "No activities returned after signup"
    assert activities[0]["activity_type"] == "SIGNUP", f"Expected SIGNUP type, got: {activities[0]['activity_type']}"
    print(f"[PASS] GET /activity verified SIGNUP log: {activities[0]}")

    # 2. Test GET /activity/today
    today_res = requests.get(f"{BASE_URL}/activity/today", headers=headers)
    assert today_res.status_code == 200
    today_acts = today_res.json()
    assert len(today_acts) > 0
    print(f"[PASS] GET /activity/today verified: {today_acts}")

if __name__ == "__main__":
    test_activity_system()
