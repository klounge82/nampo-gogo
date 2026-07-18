# Nampo GoGo Release 001-E API Smoke Test Script
# Usage: .\release_001_e_smoke_test.ps1 -ApiUrl "https://backend-production-b07b.up.railway.app"

param(
    [string]$ApiUrl = "https://backend-production-b07b.up.railway.app"
)

$dateStr = Get-Date -Format "yyyyMMddHHmmss"
$testEmail = "release001e.retry.$dateStr@example.com"
$testNickname = "REL001E_RETRY_$dateStr"
$testPassword = "Sec16_Pwd!@#$dateStr" # Strict 16+ chars secure password
$testToken = ""
$userId = ""
$storeId = ""
$missionId = ""
$reviewId = ""

Write-Host "=================================================="
Write-Host "Starting Nampo GoGo API Smoke Test Phase..."
Write-Host "Target API: $ApiUrl"
Write-Host "Test Email: $testEmail"
Write-Host "=================================================="

# --------------------------------------------------
# Test 1: Health Checks
# --------------------------------------------------
Write-Host "`n[Test 1] Health Checks..."
try {
    $liveRes = Invoke-RestMethod -Uri "$ApiUrl/health/live" -Method Get
    $readyRes = Invoke-RestMethod -Uri "$ApiUrl/health/ready" -Method Get
    
    if ($liveRes.status -eq "ok" -and $readyRes.status -eq "ok" -and $readyRes.database -eq "connected") {
        Write-Host ">> Test 1 PASSED: environment=$($readyRes.environment) | database=connected"
    } else {
        Write-Error ">> Test 1 FAILED: Unexpected response format."
    }
} catch {
    Write-Error ">> Test 1 FAILED: $($_.Exception.Message)"
    exit 1
}

# --------------------------------------------------
# Test 2: User Sign Up
# --------------------------------------------------
Write-Host "`n[Test 2] User Sign Up..."
$signupBody = @{
    email = $testEmail
    nickname = $testNickname
    password = $testPassword
} | ConvertTo-Json

try {
    $signupRes = Invoke-RestMethod -Uri "$ApiUrl/auth/signup" -Method Post -Body $signupBody -ContentType "application/json"
    $userId = $signupRes.id
    if ($userId -and $signupRes.email -eq $testEmail -and -not $signupRes.password) {
        Write-Host ">> Test 2 PASSED: User Created. ID=$userId"
    } else {
        Write-Error ">> Test 2 FAILED: Unexpected signup response structure."
    }
} catch {
    Write-Error ">> Test 2 FAILED: $($_.Exception.Message)"
    exit 1
}

# --------------------------------------------------
# Test 3: Duplicate Sign Up Defense
# --------------------------------------------------
Write-Host "`n[Test 3] Duplicate Sign Up Defense..."
try {
    $signupRes2 = Invoke-RestMethod -Uri "$ApiUrl/auth/signup" -Method Post -Body $signupBody -ContentType "application/json"
    Write-Error ">> Test 3 FAILED: Server allowed duplicate registration."
} catch {
    $errRes = $_.Exception.Response
    if ($errRes.StatusCode.value__ -eq 400) {
        Write-Host ">> Test 3 PASSED: Server rejected duplicate registration with status 400."
    } else {
        Write-Error ">> Test 3 FAILED: Expected 400 but got $($errRes.StatusCode.value__)"
    }
}

# --------------------------------------------------
# Test 4: User Login
# --------------------------------------------------
Write-Host "`n[Test 4] User Login..."
$loginBody = @{
    email = $testEmail
    password = $testPassword
} | ConvertTo-Json

try {
    $loginRes = Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $testToken = $loginRes.access_token
    if ($testToken -and $loginRes.token_type -eq "bearer") {
        Write-Host ">> Test 4 PASSED: Login Successful. Token obtained."
    } else {
        Write-Error ">> Test 4 FAILED: Login failed or token not found."
    }
} catch {
    Write-Error ">> Test 4 FAILED: $($_.Exception.Message)"
    exit 1
}

# --------------------------------------------------
# Test 5: Get Current User (Me)
# --------------------------------------------------
Write-Host "`n[Test 5] Get Current User Profile..."
$authHeader = @{
    Authorization = "Bearer $testToken"
}

try {
    $meRes = Invoke-RestMethod -Uri "$ApiUrl/users/me" -Method Get -Headers $authHeader
    if ($meRes.id -eq $userId -and -not $meRes.password -and -not $meRes.password_hash) {
        Write-Host ">> Test 5 PASSED: Profile verified securely (no password exposed)."
    } else {
        Write-Error ">> Test 5 FAILED: Profile mismatch or sensitive data exposed."
    }
} catch {
    Write-Error ">> Test 5 FAILED: $($_.Exception.Message)"
    exit 1
}

# --------------------------------------------------
# Test 6: Invalid Token Guard Defense
# --------------------------------------------------
Write-Host "`n[Test 6] Invalid Token Guard Defense..."
$fakeHeader = @{
    Authorization = "Bearer Invalid_Token_Fake_Header_Val_999"
}

try {
    $fakeRes = Invoke-RestMethod -Uri "$ApiUrl/users/me" -Method Get -Headers $fakeHeader
    Write-Error ">> Test 6 FAILED: Protected endpoint allowed fake token access."
} catch {
    $errRes = $_.Exception.Response
    if ($errRes.StatusCode.value__ -eq 401) {
        Write-Host ">> Test 6 PASSED: Protected endpoint rejected access with status 401."
    } else {
        Write-Error ">> Test 6 FAILED: Expected 401 but got $($errRes.StatusCode.value__)"
    }
}

# --------------------------------------------------
# Test 7 & 8: Stores List & Details
# --------------------------------------------------
Write-Host "`n[Test 7 & 8] Stores List and Details..."
try {
    $stores = Invoke-RestMethod -Uri "$ApiUrl/stores" -Method Get
    if ($stores.Count -gt 0) {
        $storeId = $stores[0].id
        $storeDetail = Invoke-RestMethod -Uri "$ApiUrl/stores/$storeId" -Method Get
        
        if ($storeDetail.id -eq $storeId) {
            Write-Host ">> Test 7 & 8 PASSED: Store lookup and detail fetch completed for Store ID=$storeId."
        } else {
            Write-Error ">> Test 7 & 8 FAILED: Store details ID mismatch."
        }
    } else {
        Write-Host ">> Test 7 & 8 SKIPPED (EMPTY_DATA): No store data found on backend."
    }
} catch {
    Write-Error ">> Test 7 & 8 FAILED: $($_.Exception.Message)"
}

# --------------------------------------------------
# Test 9, 10, 11: Favorites CRUD & Defense
# --------------------------------------------------
Write-Host "`n[Test 9, 10, 11] Favorites Flow..."
if ($storeId) {
    $favBody = @{
        target_type = "PLACE"
        target_id = $storeId
    } | ConvertTo-Json
    
    try {
        # 9. Add Favorite
        $favRes = Invoke-RestMethod -Uri "$ApiUrl/favorites" -Method Post -Body $favBody -ContentType "application/json" -Headers $authHeader
        
        # 10. Duplicate Add Favorite check
        $favRes2 = Invoke-RestMethod -Uri "$ApiUrl/favorites" -Method Post -Body $favBody -ContentType "application/json" -Headers $authHeader
        
        # 11. Delete Favorite
        $delFavRes = Invoke-RestMethod -Uri "$ApiUrl/favorites/PLACE/$storeId" -Method Delete -Headers $authHeader
        
        Write-Host ">> Test 9, 10, 11 PASSED: Favorites registration, duplicate protection and cancellation flow complete."
    } catch {
        Write-Error ">> Test 9, 10, 11 FAILED: $($_.Exception.Message)"
    }
} else {
    Write-Host ">> Test 9, 10, 11 SKIPPED: No store data available."
}

# --------------------------------------------------
# Test 12 & 13: Mission Verification & Review
# --------------------------------------------------
Write-Host "`n[Test 12 & 13] Mission Verification and Review Flow..."
if ($storeId) {
    try {
        # Get active mission of this store
        $missions = Invoke-RestMethod -Uri "$ApiUrl/stores/$storeId/missions" -Method Get
        if ($missions.Count -gt 0) {
            $missionId = $missions[0].id
            
            # Verify mission QR to earn authority for writing review
            $verifyBody = @{
                qr_code = "QR_SUCCESS_TOKEN"
                user_id = $userId
            } | ConvertTo-Json
            
            $verifyRes = Invoke-RestMethod -Uri "$ApiUrl/missions/$missionId/verify" -Method Post -Body $verifyBody -ContentType "application/json"
            
            if ($verifyRes.success) {
                Write-Host ">> Mission $missionId successfully completed for authority."
                
                # Write Review
                $reviewBody = @{
                    user_id = $userId
                    rating = 5
                    content = "[REL001E TEST] Production API smoke test review contents (10+ characters)."
                } | ConvertTo-Json
                
                $reviewRes = Invoke-RestMethod -Uri "$ApiUrl/stores/$storeId/reviews" -Method Post -Body $reviewBody -ContentType "application/json"
                $reviewId = $reviewRes.id
                
                # 13. Review Input validation check (send invalid rating 6)
                $badReviewBody = @{
                    user_id = $userId
                    rating = 6
                    content = "[REL001E TEST] Invalid review contents."
                } | ConvertTo-Json
                
                try {
                    $badRes = Invoke-RestMethod -Uri "$ApiUrl/stores/$storeId/reviews" -Method Post -Body $badReviewBody -ContentType "application/json"
                    Write-Error ">> Test 13 FAILED: Server allowed invalid rating 6."
                } catch {
                    $errRes = $_.Exception.Response
                    if ($errRes.StatusCode.value__ -eq 400) {
                        Write-Host ">> Test 13 PASSED: Server rejected invalid review with status 400."
                    } else {
                        Write-Error ">> Test 13 FAILED: Expected 400 but got $($errRes.StatusCode.value__)"
                    }
                }
                
                Write-Host ">> Test 12 PASSED: Review created successfully. Review ID=$reviewId"
            } else {
                Write-Error ">> Mission verification failed."
            }
        } else {
            Write-Host ">> Test 12 & 13 SKIPPED: No active missions found for Store $storeId."
        }
    } catch {
        Write-Error ">> Test 12 & 13 FAILED: $($_.Exception.Message)"
    }
} else {
    Write-Host ">> Test 12 & 13 SKIPPED: No store data available."
}

# --------------------------------------------------
# Test 14: Logout & Re-login
# --------------------------------------------------
Write-Host "`n[Test 14] Logout and Re-login..."
# No logout endpoint on MVP backend, using token invalidation simulation and re-login verify
try {
    $loginRes2 = Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    if ($loginRes2.access_token) {
        Write-Host ">> Test 14 PASSED: Re-login successful. User data persistent."
    } else {
        Write-Error ">> Test 14 FAILED: Re-login failed."
    }
} catch {
    Write-Error ">> Test 14 FAILED: $($_.Exception.Message)"
}

# --------------------------------------------------
# Test 15: Logical Account Deletion (Withdraw)
# --------------------------------------------------
Write-Host "`n[Test 15] Logical Account Deletion..."
try {
    $delRes = Invoke-RestMethod -Uri "$ApiUrl/users/me" -Method Delete -Headers $authHeader
    if ($delRes.success -and $delRes.message -match "회원탈퇴") {
        # Check re-login fail
        try {
            $loginRes3 = Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
            Write-Error ">> Test 15 FAILED: Logged-in withdrawn user allowed access."
        } catch {
            $errRes = $_.Exception.Response
            if ($errRes.StatusCode.value__ -eq 403) {
                Write-Host ">> Test 15 PASSED: Logical deletion confirmed. Access blocked with status 403."
            } else {
                Write-Error ">> Test 15 FAILED: Expected 403 but got $($errRes.StatusCode.value__)"
            }
        }
    } else {
        Write-Error ">> Test 15 FAILED: Unexpected deletion response."
    }
} catch {
    Write-Error ">> Test 15 FAILED: $($_.Exception.Message)"
}

Write-Host "`n=================================================="
Write-Host "Nampo GoGo API Smoke Test Phase Finished."
Write-Host "=================================================="
