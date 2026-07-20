import os
import sys

def test_production_guards():
    print("=== STARTING PRODUCTION GUARDS UNIT TESTS ===")
    
    # 1. Simulate production environment variables
    os.environ["APP_ENV"] = "production"
    os.environ["PAYMENT_MODE"] = "live"
    os.environ["ALLOWED_ORIGINS"] = "https://nampogogo.com,https://admin.nampogogo.com"
    os.environ["JWT_SECRET"] = "dummy_secret_for_testing_production_guards"
    
    # Import main under simulated environment variables
    try:
        from app.main import APP_ENV, allowed_origins
        import app.main as main_app
        
        # Test 1.1: APP_ENV is set correctly
        assert APP_ENV == "production", "APP_ENV must be production"
        print("[PASS] APP_ENV correctly set to production.")
        
        # Test 1.2: allowed_origins correctly parsed
        assert "https://nampogogo.com" in allowed_origins, "allowed_origins check failed"
        assert "https://admin.nampogogo.com" in allowed_origins, "allowed_origins check failed"
        assert "*" not in allowed_origins, "allowed_origins must not contain wildcard under production!"
        print("[PASS] CORS allowed_origins correctly restricted.")
        
    except AssertionError as e:
        print(f"[FAIL] Assertion error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"[FAIL] Unexpected error: {e}")
        sys.exit(1)
        
    print("=== ALL PRODUCTION GUARDS UNIT TESTS PASSED ===")

if __name__ == "__main__":
    test_production_guards()
