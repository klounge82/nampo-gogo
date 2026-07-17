import requests
import uuid

BASE_URL = "http://localhost:18080"

def test_personalization_system():
    # Setup test account with unique email using UUID
    unique_id = str(uuid.uuid4())[:8]
    signup_data = {
        "email": f"tester_{unique_id}@example.com",
        "password": "Password123!",
        "nickname": f"Tester_{unique_id}"
    }
    signup_res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    assert signup_res.status_code in [200, 201], f"Signup failed: {signup_res.text}"

    login_res = requests.post(f"{BASE_URL}/auth/login", json={"email": signup_data["email"], "password": signup_data["password"]})
    assert login_res.status_code in [200, 201], f"Login failed: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Verify GET /recommendations/preferences returns default values
    pref_get_res = requests.get(f"{BASE_URL}/recommendations/preferences", headers=headers)
    if pref_get_res.status_code != 200:
        print(f"FAILED RAW BODY: {pref_get_res.content.decode('utf-8')}")
    assert pref_get_res.status_code == 200, f"Preference get failed: {pref_get_res.text}"
    pref_data = pref_get_res.json()
    assert pref_data["use_personalization"] is True
    print(f"[PASS] GET /recommendations/preferences verified: {pref_data}")

    # 2. Verify PATCH /recommendations/preferences updates values
    patch_payload = {
        "use_personalization": True,
        "prefer_new_places": True,
        "prefer_rewards": True,
        "disliked_categories": ["SHOPPING"]
    }
    pref_patch_res = requests.patch(f"{BASE_URL}/recommendations/preferences", json=patch_payload, headers=headers)
    assert pref_patch_res.status_code == 200, f"Preference patch failed: {pref_patch_res.text}"
    patched_data = pref_patch_res.json()
    assert "SHOPPING" in patched_data["disliked_categories"]
    print(f"[PASS] PATCH /recommendations/preferences verified: {patched_data}")

    # 3. Verify POST /recommendations/courses with personalization flags
    course_payload = {
        "user_id": signup_res.json()["id"],
        "travel_type": "SOLO",
        "travel_duration": "HALF_DAY",
        "categories": ["FOOD", "CAFE"],
        "transport_mode": "WALK",
        "latitude": 35.0987,
        "longitude": 129.0289,
        "use_personalization": True,
        "exclude_visited": True,
        "prefer_new_places": True,
        "prefer_rewards": True
    }
    course_res = requests.post(f"{BASE_URL}/recommendations/courses", json=course_payload, headers=headers)
    assert course_res.status_code in [200, 201], f"Course creation failed: {course_res.text}"
    course_data = course_res.json()
    assert len(course_data["items"]) > 0
    print(f"[PASS] POST /recommendations/courses verified. Course item sample: {course_data['items'][0]}")

    # 4. Verify POST /recommendations/feedback succeeds
    feedback_payload = {
        "target_type": "PLACE",
        "target_id": course_data["items"][0]["store_id"],
        "feedback_type": "LIKE"
    }
    feedback_res = requests.post(f"{BASE_URL}/recommendations/feedback", json=feedback_payload, headers=headers)
    assert feedback_res.status_code in [200, 201], f"Feedback failed: {feedback_res.text}"
    feedback_data = feedback_res.json()
    assert feedback_data["feedback_type"] == "LIKE"
    print(f"[PASS] POST /recommendations/feedback verified: {feedback_data}")

if __name__ == "__main__":
    test_personalization_system()
