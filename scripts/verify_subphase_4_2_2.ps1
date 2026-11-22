# ==============================================================================
# Subphase 4.2.2 Verification Gate Script
# Restricted User App: Offline Vault, Smart Collections, Privacy Mode & Isolation Gate
# ==============================================================================

$ErrorActionPreference = "Stop"
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ">>> Starting Subphase 4.2.2 Automated Verification Gate" -ForegroundColor Cyan
Write-Host ">>> Target Application: apps/user_app" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Step 1: Binary Isolation Audit
Write-Host "`n[1/4] Auditing Compile-Time Binary Isolation Invariant..." -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "Binary isolation check FAILED!"
    exit 1
}
Write-Host "[PASS] Binary isolation check passed (zero generator/admin leaks in user_app)." -ForegroundColor Green

# Step 2: Static Analysis
Write-Host "`n[2/4] Running Static Analysis across Monorepo..." -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Static analysis FAILED with warnings or errors!"
    exit 1
}
Write-Host "[PASS] 0 errors, 0 warnings, 0 infos across entire monorepo." -ForegroundColor Green

# Step 3: Run User App Tests with Coverage
Write-Host "`n[3/4] Running All User App Tests (Vault, Collections, Settings, HUD, Actions)..." -ForegroundColor Yellow
Set-Location apps/user_app
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Set-Location ../..
    Write-Error "Flutter tests in apps/user_app FAILED!"
    exit 1
}
Set-Location ../..
Write-Host "[PASS] All user_app tests passed cleanly." -ForegroundColor Green

# Step 4: Line Coverage Gate Verification (>= 95.0%)
Write-Host "`n[4/4] Verifying Mandatory >= 95.0% Line Coverage Gate..." -ForegroundColor Yellow
$lcovFile = "apps/user_app/coverage/lcov.info"
if (-not (Test-Path $lcovFile)) {
    Write-Error "Coverage file $lcovFile does not exist!"
    exit 1
}

$lines = Get-Content $lcovFile
$lf = 0
$lh = 0
foreach ($line in $lines) {
    if ($line -match "^LF:(\d+)") { $lf += [int]$matches[1] }
    if ($line -match "^LH:(\d+)") { $lh += [int]$matches[1] }
}

if ($lf -eq 0) {
    Write-Error "No instrumented lines found in $lcovFile!"
    exit 1
}

$coverage = [math]::Round(($lh / $lf) * 100, 2)
Write-Host "Instrumented Lines: $lf" -ForegroundColor Gray
Write-Host "Hit Lines: $lh" -ForegroundColor Gray
Write-Host "Line Coverage: $coverage%" -ForegroundColor Cyan

if ($coverage -lt 95.0) {
    Write-Error "Coverage $coverage% is below mandatory 95.0% threshold!"
    exit 1
}

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host ">>> SUBPHASE 4.2.2 VERIFICATION GATE: ALL CHECKS PASSED ($coverage%)" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
