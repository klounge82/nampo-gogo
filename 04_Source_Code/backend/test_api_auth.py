import urllib.request
import json

base_url = "http://localhost:18080"

# 1. Signup test
signup_data = json.dumps({
    "email": "test_user@nampo.com",
    "password": "password123",
    "nickname": "남포동주민"
}).encode('utf-8')

req = urllib.request.Request(
    f"{base_url}/auth/signup",
    data=signup_data,
    headers={'Content-Type': 'application/json'}
)

print("--- 회원가입 API 테스트 ---")
try:
    with urllib.request.urlopen(req) as res:
        print("Status Code:", res.status)
        response_body = res.read().decode('utf-8')
        print("Response:", json.dumps(json.loads(response_body), indent=2, ensure_ascii=False))
except Exception as e:
    print("Signup error (possibly already registered):", e)

# 2. Login test
login_data = json.dumps({
    "email": "test_user@nampo.com",
    "password": "password123"
}).encode('utf-8')

req_login = urllib.request.Request(
    f"{base_url}/auth/login",
    data=login_data,
    headers={'Content-Type': 'application/json'}
)

print("\n--- 로그인 API 테스트 ---")
try:
    with urllib.request.urlopen(req_login) as res:
        print("Status Code:", res.status)
        response_body = res.read().decode('utf-8')
        data_json = json.loads(response_body)
        
        # Security: mask tokens
        if 'access_token' in data_json:
            data_json['access_token'] = data_json['access_token'][:15] + "..."
        if 'refresh_token' in data_json:
            data_json['refresh_token'] = data_json['refresh_token'][:15] + "..."
            
        print("Response (Tokens + UserInfo):", json.dumps(data_json, indent=2, ensure_ascii=False))
except Exception as e:
    print("Login error:", e)
