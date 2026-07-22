import requests
import json
import secrets
import string
import time

BASE_URL = "https://backend-production-b07b.up.railway.app"

def run_verification():
    results = {}
    print("==================================================")
    print("Starting Store Flow Verification (RELEASE-001-E-STORE-FLOW-01)")
    print("==================================================")

    # 1. Health Checks
    print("\n--- Step 1: Health Checks & Pre-validation ---")
    r_live = requests.get(f"{BASE_URL}/health/live")
    results['health_live_status'] = r_live.status_code
    results['health_live_body'] = r_live.json()
    print(f"Health Live ({r_live.status_code}): {r_live.json()}")

    r_ready = requests.get(f"{BASE_URL}/health/ready")
    results['health_ready_status'] = r_ready.status_code
    results['health_ready_body'] = r_ready.json()
    print(f"Health Ready ({r_ready.status_code}): {r_ready.json()}")

    # 2. Stores Pre-validation
    r_stores = requests.get(f"{BASE_URL}/stores")
    stores = r_stores.json()
    results['stores_count'] = len(stores)
    print(f"Stores count: {len(stores)}")
    
    k_lounge = next((s for s in stores if s.get('name') == 'K-Lounge'), None)
    results['k_lounge_found'] = k_lounge is not None
    if k_lounge:
        results['k_lounge_id'] = k_lounge['id']
        results['k_lounge_phone'] = k_lounge.get('phone_number')
        results['k_lounge_hours'] = k_lounge.get('operating_hours')
        print(f"K-Lounge Store ID: {k_lounge['id']}")
        print(f"Phone: {k_lounge.get('phone_number')}, Hours: {k_lounge.get('operating_hours')}")
        
        # Store Detail
        r_detail = requests.get(f"{BASE_URL}/stores/{k_lounge['id']}")
        results['store_detail_status'] = r_detail.status_code
        print(f"Store Detail ({r_detail.status_code}): {r_detail.json().get('name')}")

    # 3. Create Test Account
    print("\n--- Step 2: Test Account Registration & Login ---")
    timestamp = int(time.time())
    rand_suffix = ''.join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(6))
    test_email = f"storeflow01.{timestamp}.{rand_suffix}@example.com"
    test_nickname = f"STORE_FLOW_01_{timestamp}"
    test_password = "Sec!" + secrets.token_hex(8) + "1A"

    signup_payload = {
        "email": test_email,
        "password": test_password,
        "nickname": test_nickname
    }
    r_signup = requests.post(f"{BASE_URL}/auth/signup", json=signup_payload)
    results['signup_status'] = r_signup.status_code
    signup_data = r_signup.json()
    test_user_id = signup_data.get('id')
    results['test_user_id'] = test_user_id
    print(f"Signup ({r_signup.status_code}): user_id={test_user_id}")

    login_payload = {
        "email": test_email,
        "password": test_password
    }
    r_login = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
    results['login_status'] = r_login.status_code
    token = r_login.json().get('access_token')
    headers = {"Authorization": f"Bearer {token}"}
    print(f"Login ({r_login.status_code}): token obtained.")

    # Get profile
    r_me = requests.get(f"{BASE_URL}/users/me", headers=headers)
    results['me_status'] = r_me.status_code
    print(f"GET /users/me ({r_me.status_code}): email={r_me.json().get('email')}")

    # 4. Favorite Flow
    print("\n--- Step 3: Favorites Verification ---")
    store_id = k_lounge['id']
    fav_payload = {"target_type": "PLACE", "target_id": store_id}
    
    # Add favorite
    r_fav_add = requests.post(f"{BASE_URL}/favorites", json=fav_payload, headers=headers)
    results['favorite_add_status'] = r_fav_add.status_code
    print(f"Add Favorite ({r_fav_add.status_code}): {r_fav_add.json()}")

    # List favorites
    r_fav_list = requests.get(f"{BASE_URL}/favorites", headers=headers)
    results['favorite_list_count'] = len(r_fav_list.json())
    print(f"Get Favorites ({r_fav_list.status_code}): count={len(r_fav_list.json())}")

    # Duplicate favorite add attempt
    r_fav_dup = requests.post(f"{BASE_URL}/favorites", json=fav_payload, headers=headers)
    results['favorite_dup_status'] = r_fav_dup.status_code
    r_fav_list_after_dup = requests.get(f"{BASE_URL}/favorites", headers=headers)
    results['favorite_dup_count'] = len(r_fav_list_after_dup.json())
    print(f"Duplicate Favorite ({r_fav_dup.status_code}): count after dup={len(r_fav_list_after_dup.json())}")

    # Delete favorite
    r_fav_del = requests.delete(f"{BASE_URL}/favorites/PLACE/{store_id}", headers=headers)
    results['favorite_del_status'] = r_fav_del.status_code
    r_fav_list_after_del = requests.get(f"{BASE_URL}/favorites", headers=headers)
    results['favorite_del_count'] = len(r_fav_list_after_del.json())
    print(f"Delete Favorite ({r_fav_del.status_code}): count after del={len(r_fav_list_after_del.json())}")

    # Repeat favorite add and delete
    r_fav_add2 = requests.post(f"{BASE_URL}/favorites", json=fav_payload, headers=headers)
    r_fav_del2 = requests.delete(f"{BASE_URL}/favorites/PLACE/{store_id}", headers=headers)
    print(f"Repeat Favorite add ({r_fav_add2.status_code}) & delete ({r_fav_del2.status_code})")

    # 5. Reviews Verification
    print("\n--- Step 4: Reviews Verification ---")
    # Check unauthorized review write (before completing mission/reservation)
    rev_payload = {
        "user_id": test_user_id,
        "rating": 5,
        "content": "RELEASE-001-E-STORE-FLOW-01 임시 운영 검증 리뷰입니다. (권한 없는 테스트)"
    }
    r_rev_unauth = requests.post(f"{BASE_URL}/stores/{store_id}/reviews", json=rev_payload, headers=headers)
    results['review_unauth_status'] = r_rev_unauth.status_code
    print(f"Unauthorized Review Write ({r_rev_unauth.status_code}): {r_rev_unauth.json()}")

    # Check store missions
    r_missions = requests.get(f"{BASE_URL}/stores/{store_id}/missions")
    missions = r_missions.json()
    print(f"Store Missions count: {len(missions)}")

    if len(missions) > 0:
        mission_id = missions[0]['id']
        r_verify = requests.post(f"{BASE_URL}/missions/{mission_id}/verify", json={"qr_code": "QR_SUCCESS_TOKEN", "user_id": test_user_id}, headers=headers)
        results['mission_verify_status'] = r_verify.status_code
        print(f"Mission Verify ({r_verify.status_code}): {r_verify.json()}")
    else:
        print("No missions found on store. Checking other ways for review authority...")
        # Create reservation if mission is not available
        res_payload = {
            "store_id": store_id,
            "reservation_time": "2026-12-31T12:00:00",
            "party_size": 2,
            "user_id": test_user_id
        }
        r_res = requests.post(f"{BASE_URL}/reservations", json=res_payload, headers=headers)
        print(f"Reservation Created ({r_res.status_code}): {r_res.json()}")

    # Try creating valid review
    valid_rev_payload = {
        "user_id": test_user_id,
        "rating": 5,
        "content": "RELEASE-001-E-STORE-FLOW-01 임시 운영 검증 리뷰입니다. 정밀 테스트 중입니다."
    }
    r_rev_create = requests.post(f"{BASE_URL}/stores/{store_id}/reviews", json=valid_rev_payload, headers=headers)
    results['review_create_status'] = r_rev_create.status_code
    review_data = r_rev_create.json()
    print(f"Review Create ({r_rev_create.status_code}): {review_data}")

    review_id = review_data.get('id')
    results['review_id'] = review_id

    if review_id:
        # Get store reviews
        r_store_revs = requests.get(f"{BASE_URL}/stores/{store_id}/reviews")
        results['store_reviews_count'] = len(r_store_revs.json())
        print(f"Store Reviews Count ({r_store_revs.status_code}): {len(r_store_revs.json())}")

        # Get my reviews
        r_my_revs = requests.get(f"{BASE_URL}/reviews/me", headers=headers)
        results['my_reviews_count'] = len(r_my_revs.json())
        print(f"My Reviews Count ({r_my_revs.status_code}): {len(r_my_revs.json())}")

        # Check store rating update
        r_store_after_rev = requests.get(f"{BASE_URL}/stores/{store_id}")
        results['store_rating_after_create'] = r_store_after_rev.json().get('rating')
        print(f"Store Rating After Review Create: {r_store_after_rev.json().get('rating')}")

        # Duplicate review attempt
        r_rev_dup = requests.post(f"{BASE_URL}/stores/{store_id}/reviews", json=valid_rev_payload, headers=headers)
        results['review_dup_status'] = r_rev_dup.status_code
        print(f"Duplicate Review Attempt ({r_rev_dup.status_code}): {r_rev_dup.json()}")

        # Invalid rating attempt (rating=6)
        invalid_rating_payload = {
            "user_id": test_user_id,
            "rating": 6,
            "content": "RELEASE-001-E-STORE-FLOW-01 잘못된 별점 테스트 리뷰입니다."
        }
        r_invalid_rating = requests.post(f"{BASE_URL}/stores/{store_id}/reviews", json=invalid_rating_payload, headers=headers)
        results['invalid_rating_status'] = r_invalid_rating.status_code
        print(f"Invalid Rating 6 Attempt ({r_invalid_rating.status_code}): {r_invalid_rating.json()}")

        # Invalid content attempt (short content < 10 chars)
        short_content_payload = {
            "user_id": test_user_id,
            "rating": 5,
            "content": "짧은리뷰"
        }
        r_short_content = requests.post(f"{BASE_URL}/stores/{store_id}/reviews", json=short_content_payload, headers=headers)
        results['short_content_status'] = r_short_content.status_code
        print(f"Short Content Attempt ({r_short_content.status_code}): {r_short_content.json()}")

        # Patch review
        patch_payload = {
            "rating": 4,
            "content": "RELEASE-001-E-STORE-FLOW-01 수정된 테스트 리뷰 내용입니다. 4점으로 수정."
        }
        r_rev_patch = requests.patch(f"{BASE_URL}/reviews/{review_id}", json=patch_payload, headers=headers)
        results['review_patch_status'] = r_rev_patch.status_code
        print(f"Patch Review ({r_rev_patch.status_code}): {r_rev_patch.json()}")

        # Check store rating after patch
        r_store_after_patch = requests.get(f"{BASE_URL}/stores/{store_id}")
        results['store_rating_after_patch'] = r_store_after_patch.json().get('rating')
        print(f"Store Rating After Review Patch: {r_store_after_patch.json().get('rating')}")

        # Delete review
        r_rev_del = requests.delete(f"{BASE_URL}/reviews/{review_id}", headers=headers)
        results['review_del_status'] = r_rev_del.status_code
        print(f"Delete Review ({r_rev_del.status_code}): {r_rev_del.json()}")

        # Check store reviews after delete
        r_store_revs_after_del = requests.get(f"{BASE_URL}/stores/{store_id}/reviews")
        results['store_reviews_count_after_del'] = len(r_store_revs_after_del.json())
        print(f"Store Reviews Count After Delete: {len(r_store_revs_after_del.json())}")

        # Check store rating reset
        r_store_after_del = requests.get(f"{BASE_URL}/stores/{store_id}")
        results['store_rating_after_del'] = r_store_after_del.json().get('rating')
        print(f"Store Rating After Review Delete: {r_store_after_del.json().get('rating')}")

    # 6. Cleanup Test Account & Verification
    print("\n--- Step 5: Test Account Cleanup & Final Checks ---")
    r_del_user = requests.delete(f"{BASE_URL}/users/me", headers=headers)
    results['user_del_status'] = r_del_user.status_code
    print(f"Delete User Account ({r_del_user.status_code}): {r_del_user.json()}")

    # Check re-login blocked
    r_relogin = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
    results['relogin_after_del_status'] = r_relogin.status_code
    print(f"Re-login After User Delete ({r_relogin.status_code}): {r_relogin.json()}")

    # Check final stores count and K-Lounge integrity
    r_final_stores = requests.get(f"{BASE_URL}/stores")
    final_stores = r_final_stores.json()
    results['final_stores_count'] = len(final_stores)
    print(f"Final Stores Count: {len(final_stores)}")

    # Check remaining test reviews
    r_final_revs = requests.get(f"{BASE_URL}/stores/{store_id}/reviews")
    results['final_reviews_count'] = len(r_final_revs.json())
    print(f"Final Reviews Count for K-Lounge: {len(r_final_revs.json())}")

    print("\n==================================================")
    print("Verification Summary JSON:")
    print(json.dumps(results, indent=2, ensure_ascii=False))
    print("==================================================")
    return results

if __name__ == "__main__":
    run_verification()
