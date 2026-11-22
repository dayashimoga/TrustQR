# ==============================================================================
# Subphase 5.1.1 Verification Gate Script
# Admin Analytics Engine: Time-Series Aggregations, Usage Breakdown, Threat Intelligence, Fleet Registry & Audit Log
# ==============================================================================

$ErrorActionPreference = "Stop"
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ">>> Starting Subphase 5.1.1 Automated Verification Gate" -ForegroundColor Cyan
Write-Host ">>> Target Package: packages/qr_admin_analytics" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Step 1: Binary Isolation Audit
Write-Host "`n[1/4] Auditing Compile-Time Binary Isolation Invariant..." -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "Binary isolation check FAILED!"
    exit 1
}
Write-Host "[PASS] Binary isolation check passed (zero generator/admin leaks in user_app)." -ForegroundColor Green

# Step 2: Static Analysis across Monorepo
Write-Host "`n[2/4] Running Static Analysis across Monorepo..." -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Static analysis FAILED with warnings or errors!"
    exit 1
}
Write-Host "[PASS] 0 errors, 0 warnings, 0 infos across entire monorepo." -ForegroundColor Green

# Step 3: Run Admin Analytics Tests with Coverage
Write-Host "`n[3/4] Running All Admin Analytics Tests..." -ForegroundColor Yellow
Set-Location packages/qr_admin_analytics
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Set-Location ../..
    Write-Error "Flutter tests in packages/qr_admin_analytics FAILED!"
    exit 1
}
Set-Location ../..
Write-Host "[PASS] All admin_analytics tests passed cleanly." -ForegroundColor Green

# Step 4: Line Coverage Gate Verification (>= 95.0%)
Write-Host "`n[4/4] Verifying Mandatory >= 95.0% Line Coverage Gate..." -ForegroundColor Yellow
$lcovFile = "packages/qr_admin_analytics/coverage/lcov.info"
if (-not (Test-Path $lcovFile)) {
    Write-Error "Coverage file $lcovFile does not exist!"
    exit 1
}

dart run scripts/measure_coverage.dart $lcovFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Line coverage failed threshold check!"
    exit 1
}

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host ">>> SUBPHASE 5.1.1 VERIFICATION GATE: ALL CHECKS PASSED" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
