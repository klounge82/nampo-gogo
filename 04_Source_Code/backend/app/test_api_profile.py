import requests
import uuid

BASE_URL = "http://localhost:18080"

def test_profile_flow():
    # 1. Sign up a new user
    email = f"test_profile_{uuid.uuid4().hex[:6]}@profile.com"
    pwd = "password123!"
    nick = "ProfileTester"
    
    signup_res = requests.post(
        f"{BASE_URL}/auth/signup",
        json={"email": email, "password": pwd, "nickname": nick}
    )
    assert signup_res.status_code == 201, f"Signup failed: {signup_res.text}"
    user_id = signup_res.json()["id"]
    print(f"[PASS] Signup succeeded. User ID: {user_id}")

    # 2. Login to get token
    login_res = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": pwd}
    )
    assert login_res.status_code == 200, f"Login failed: {login_res.text}"
    tokens = login_res.json()
    token = tokens["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("[PASS] Login succeeded, token received.")

    # 3. GET /users/me (Verify profile retrieval)
    me_res = requests.get(f"{BASE_URL}/users/me", headers=headers)
    assert me_res.status_code == 200, f"Get profile failed: {me_res.text}"
    assert me_res.json()["nickname"] == nick
    print(f"[PASS] GET /users/me verified nickname: {nick}")

    # 4. PATCH /users/me (Update nickname)
    new_nick = "NewNickName1"
    patch_res = requests.patch(
        f"{BASE_URL}/users/me",
        json={"nickname": new_nick},
        headers=headers
    )
    assert patch_res.status_code == 200, f"Update profile failed: {patch_res.text}"
    assert patch_res.json()["nickname"] == new_nick
    print(f"[PASS] PATCH /users/me updated nickname: {new_nick}")

    # 5. POST /users/me/profile-image (Mock Image Upload)
    upload_res = requests.post(
        f"{BASE_URL}/users/me/profile-image",
        json={"filename": "test_avatar.png", "base64_data": "ZHVtbXlfcG5nX2RhdGE="},
        headers=headers
    )
    assert upload_res.status_code == 200, f"Upload image failed: {upload_res.text}"
    img_url = upload_res.json()["profile_image_url"]
    assert "static/profile_images" in img_url
    print(f"[PASS] POST /users/me/profile-image verified image URL: {img_url}")

    # 6. DELETE /users/me/profile-image (Remove Image)
    remove_res = requests.delete(f"{BASE_URL}/users/me/profile-image", headers=headers)
    assert remove_res.status_code == 200, f"Remove image failed: {remove_res.text}"
    assert remove_res.json()["profile_image_url"] is None
    print("[PASS] DELETE /users/me/profile-image removed URL.")

    # 7. POST /auth/change-password (Change Password)
    new_pwd = "newPassword123!"
    change_res = requests.post(
        f"{BASE_URL}/auth/change-password",
        json={"current_password": pwd, "new_password": new_pwd},
        headers=headers
    )
    assert change_res.status_code == 200, f"Change password failed: {change_res.text}"
    print("[PASS] POST /auth/change-password succeeded.")

    # 8. Verify login with old password fails
    old_login = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": pwd}
    )
    assert old_login.status_code == 400
    print("[PASS] Login with old password successfully rejected.")

    # 9. Verify login with new password succeeds
    new_login = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": new_pwd}
    )
    assert new_login.status_code == 200
    new_token = new_login.json()["access_token"]
    new_headers = {"Authorization": f"Bearer {new_token}"}
    print("[PASS] Login with new password succeeded.")

    # 10. DELETE /users/me (Withdrawal)
    withdraw_res = requests.delete(f"{BASE_URL}/users/me", headers=new_headers)
    assert withdraw_res.status_code == 200, f"Withdrawal failed: {withdraw_res.text}"
    print("[PASS] DELETE /users/me withdrawal succeeded.")

    # 11. Verify withdrawn account cannot log in or make calls
    login_after_withdraw = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": new_pwd}
    )
    assert login_after_withdraw.status_code == 403
    assert "탈퇴 처리된 사용자 계정입니다" in login_after_withdraw.json()["detail"]
    print("[PASS] Login attempt for withdrawn account successfully blocked (403 Forbidden).")

if __name__ == "__main__":
    test_profile_flow()
