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
        return e.code, json.loads(e.read().decode('utf-8'))

print("--- 1. 미션 목록 조회 및 QR 미션 획득 ---")
status, missions = make_request(f"{base_url}/missions")
print("Status:", status)

qr_mission = None
for m in missions:
    if m['auth_type'] == 'QR':
        qr_mission = m
        break

if not qr_mission:
    print("Error: QR 미션을 찾을 수 없습니다.")
    exit(1)

mission_id = qr_mission['id']
print(f"선택된 QR 미션: {qr_mission['title']} (ID: {mission_id})")

print("\n--- 2. QR 코드 검증 성공 케이스 (올바른 토큰) ---")
status_ok, res_ok = make_request(
    f"{base_url}/missions/{mission_id}/verify",
    method="POST",
    data={"qr_code": "QR_SUCCESS_TOKEN"}
)
print("Status:", status_ok)
print("Response:", json.dumps(res_ok, indent=2, ensure_ascii=False))

print("\n--- 3. QR 코드 검증 중복 실패 케이스 (이미 완료됨) ---")
status_dup, res_dup = make_request(
    f"{base_url}/missions/{mission_id}/verify",
    method="POST",
    data={"qr_code": "QR_SUCCESS_TOKEN"}
)
print("Status:", status_dup)
print("Response:", json.dumps(res_dup, indent=2, ensure_ascii=False))

print("\n--- 4. QR 코드 검증 유효하지 않은 토큰 실패 케이스 ---")
# 다른 미션 ID를 가진 새로운 미션 조회
other_mission = None
for m in missions:
    if m['id'] != mission_id:
        other_mission = m
        break

if other_mission:
    status_err, res_err = make_request(
        f"{base_url}/missions/{other_mission['id']}/verify",
        method="POST",
        data={"qr_code": "INVALID_TOKEN_ABC"}
    )
    print(f"다른 미션: {other_mission['title']} (ID: {other_mission['id']})")
    print("Status:", status_err)
    print("Response:", json.dumps(res_err, indent=2, ensure_ascii=False))
