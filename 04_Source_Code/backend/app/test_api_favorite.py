import requests
import uuid

BASE_URL = "http://localhost:18080"

def test_favorite_system():
    # Setup test account with unique email using UUID
    unique_id = str(uuid.uuid4())[:8]
    signup_data = {
        "email": f"favtester_{unique_id}@example.com",
        "password": "Password123!",
        "nickname": f"FavTester_{unique_id}"
    }
    signup_res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    assert signup_res.status_code in [200, 201], f"Signup failed: {signup_res.text}"

    # Use email instead of username in login payload
    login_res = requests.post(f"{BASE_URL}/auth/login", json={"email": signup_data["email"], "password": signup_data["password"]})
    assert login_res.status_code in [200, 201], f"Login failed: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch store_id for testing
    store_res = requests.get(f"{BASE_URL}/stores")
    assert store_res.status_code == 200
    stores = store_res.json()
    assert len(stores) > 0
    store_id = stores[0]["id"]

    # 1. Test POST /favorites (Add Place favorite)
    add_res = requests.post(f"{BASE_URL}/favorites", json={"target_type": "PLACE", "target_id": store_id}, headers=headers)
    assert add_res.status_code == 200
    print(f"[PASS] POST /favorites added: {add_res.json()}")

    # 2. Test GET /favorites (List)
    list_res = requests.get(f"{BASE_URL}/favorites", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json()
    assert len(items) > 0
    assert items[0]["target_id"] == store_id
    print(f"[PASS] GET /favorites verified: {items}")

    # 3. Test DELETE /favorites/{target_type}/{target_id}
    del_res = requests.delete(f"{BASE_URL}/favorites/PLACE/{store_id}", headers=headers)
    assert del_res.status_code == 200
    print(f"[PASS] DELETE /favorites success: {del_res.json()}")

    # Verify deleted
    list_res2 = requests.get(f"{BASE_URL}/favorites", headers=headers)
    assert len(list_res2.json()) == 0
    print(f"[PASS] GET /favorites empty verified after delete.")

    # 4. Test POST /favorites/merge (Merge local items)
    merge_data = {
        "local_items": [
            {"target_type": "PLACE", "target_id": store_id}
        ]
    }
    merge_res = requests.post(f"{BASE_URL}/favorites/merge", json=merge_data, headers=headers)
    assert merge_res.status_code == 200
    print(f"[PASS] POST /favorites/merge verified: {merge_res.json()}")

    # Verify merged item in list
    list_res3 = requests.get(f"{BASE_URL}/favorites", headers=headers)
    assert len(list_res3.json()) == 1
    print(f"[PASS] Verification list after merge returned: {list_res3.json()}")

if __name__ == "__main__":
    test_favorite_system()
