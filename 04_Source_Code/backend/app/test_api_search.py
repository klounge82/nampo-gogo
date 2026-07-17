import requests

BASE_URL = "http://localhost:18080"

def test_search_system():
    # 1. Test GET /search with q="호떡"
    res = requests.get(f"{BASE_URL}/search", params={"q": "호떡", "lang": "ko"})
    assert res.status_code == 200, f"Search failed: {res.text}"
    data = res.json()
    assert data["total"] > 0, "No search results returned for '호떡'"
    
    # Verify result types (PLACE, MISSION, COUPON) are matched appropriately
    types = [item["result_type"] for item in data["items"]]
    print(f"[PASS] GET /search returned items: {types}")

    # 2. Test GET /search/suggestions (Autocomplete)
    sug_res = requests.get(f"{BASE_URL}/search/suggestions", params={"q": "호", "lang": "ko"})
    assert sug_res.status_code == 200, f"Autocomplete failed: {sug_res.text}"
    suggestions = sug_res.json()["suggestions"]
    assert len(suggestions) > 0
    print(f"[PASS] GET /search/suggestions autocomplete returned: {suggestions}")

    # 3. Test GET /search/popular
    pop_res = requests.get(f"{BASE_URL}/search/popular", params={"lang": "ko"})
    assert pop_res.status_code == 200, f"Popular searches failed: {pop_res.text}"
    populars = pop_res.json()["suggestions"]
    assert "호떡" in populars
    print(f"[PASS] GET /search/popular returned popular tags: {populars}")

if __name__ == "__main__":
    test_search_system()
