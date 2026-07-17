import requests
import sys
import uuid

BASE_URL = "http://localhost:18080"

def test_payment_system():
    print("=== STARTING PAYMENT SYSTEM INTEGRATION TESTS ===")
    
    unique_id = str(uuid.uuid4())[:8]
    
    # 1. Signup test user
    signup_data = {
        "email": f"tester_payment_{unique_id}@nampo.gogo",
        "nickname": f"PayTester_{unique_id}",
        "password": "Password123!"
    }
    signup_res = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    assert signup_res.status_code in [200, 201], f"Signup failed: {signup_res.text}"
    
    # 2. Login to get access token
    login_res = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": signup_data["email"], "password": signup_data["password"]}
    )
    assert login_res.status_code == 200, f"Login failed: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 3. Create Payment (10,000 KRW for POINT_CHARGE)
    idempotency_key = str(uuid.uuid4())
    payment_data = {
        "amount": 10000,
        "payment_method": "CARD",
        "target_type": "POINT_CHARGE",
        "target_id": "dummy_charge_id_123",
        "idempotency_key": idempotency_key
    }
    create_res = requests.post(f"{BASE_URL}/payments/create", json=payment_data, headers=headers)
    assert create_res.status_code == 201, f"Create payment failed: {create_res.text}"
    payment_json = create_res.json()
    payment_id = payment_json["id"]
    print(f"[PASS] CREATE payment verified: {payment_json}")
    
    # 4. Idempotency enforcement check
    duplicate_res = requests.post(f"{BASE_URL}/payments/create", json=payment_data, headers=headers)
    assert duplicate_res.status_code == 201, f"Duplicate key didn't return 201: {duplicate_res.text}"
    assert duplicate_res.json()["id"] == payment_id, "Duplicate idempotency key returned different transaction ID!"
    print(f"[PASS] IDEMPOTENCY KEY enforcement verified.")
    
    # 5. Confirm Payment
    confirm_data = {
        "payment_id": payment_id,
        "mock_token": "mock_auth_token_xyz"
    }
    confirm_res = requests.post(f"{BASE_URL}/payments/confirm", json=confirm_data, headers=headers)
    assert confirm_res.status_code == 200, f"Confirm payment failed: {confirm_res.text}"
    confirmed_json = confirm_res.json()
    assert confirmed_json["status"] == "paid", f"Payment status not paid: {confirmed_json['status']}"
    print(f"[PASS] CONFIRM payment verified: {confirmed_json}")
    
    # 6. Refund Payment
    refund_data = {
        "payment_id": payment_id,
        "refund_amount": 10000,
        "reason": "테스트 환불 요청"
    }
    refund_res = requests.post(f"{BASE_URL}/payments/refund", json=refund_data, headers=headers)
    assert refund_res.status_code == 201, f"Refund request failed: {refund_res.text}"
    refund_json = refund_res.json()
    assert refund_json["status"] == "completed"
    print(f"[PASS] REFUND payment verified: {refund_json}")
    
    # 7. Get Payment Detail (Receipt)
    detail_res = requests.get(f"{BASE_URL}/payments/{payment_id}", headers=headers)
    assert detail_res.status_code == 200, f"Get payment detail failed: {detail_res.text}"
    detail_json = detail_res.json()
    assert detail_json["status"] == "refunded", f"Payment status not refunded after refund: {detail_json['status']}"
    print(f"[PASS] GET payment detail verified: {detail_json}")
    
    print("=== ALL PAYMENT SYSTEM TESTS PASSED SUCCESSFULLY ===")

if __name__ == "__main__":
    test_payment_system()
