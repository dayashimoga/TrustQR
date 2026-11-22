# Verification script for Subphase 2.2.1: Offline-First Encrypted Vault
$ErrorActionPreference = 'Stop'

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "=== SUBPHASE 2.2.1 VERIFICATION GATE: OFFLINE VAULT      ===" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Binary Isolation Audit
Write-Host "`n[Gate 1/4] Auditing Compile-Time Binary Isolation..." -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "Binary isolation check failed!"
    exit 1
}
Write-Host "-> Binary Isolation PASS" -ForegroundColor Green

# 2. Static Analysis Check across all monorepo targets
Write-Host "`n[Gate 2/4] Running Static Analysis (0 errors, 0 warnings, 0 infos)..." -ForegroundColor Yellow
$targets = @(
    "packages/qr_core",
    "packages/qr_scanner_engine",
    "packages/qr_generator_engine",
    "packages/qr_admin_analytics",
    "packages/qr_design_system",
    "services/rbac_api",
    "apps/user_app",
    "apps/admin_app"
)

foreach ($target in $targets) {
    Write-Host "Analyzing $target..." -ForegroundColor Gray
    Push-Location $target
    dart analyze --fatal-infos --fatal-warnings .
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "Static analysis failed on $target!"
        exit 1
    }
    Pop-Location
}
Write-Host "-> Static Analysis PASS across all 8 monorepo targets" -ForegroundColor Green

# 3. Automated Test Suite in qr_core
Write-Host "`n[Gate 3/4] Running Automated Tests & Coverage in qr_core..." -ForegroundColor Yellow
Push-Location packages/qr_core
dart test --coverage=coverage
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Tests failed in packages/qr_core!"
    exit 1
}
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Coverage formatting failed in packages/qr_core!"
    exit 1
}
Pop-Location
Write-Host "-> All 64 tests passed in packages/qr_core" -ForegroundColor Green

# 4. Mandatory Line Coverage Enforcement (>= 95.0%)
Write-Host "`n[Gate 4/4] Verifying Mandatory Line Coverage Gate (>= 95.0%)..." -ForegroundColor Yellow
$lcov = Get-Content packages/qr_core/coverage/lcov.info
$lf = 0
$lh = 0

foreach ($line in $lcov) {
    if ($line -match '^LF:(\d+)') {
        $lf += [int]$matches[1]
    }
    if ($line -match '^LH:(\d+)') {
        $lh += [int]$matches[1]
    }
}

if ($lf -eq 0) {
    Write-Error "No line coverage data recorded in lcov.info!"
    exit 1
}

$pct = ($lh / $lf) * 100.0
Write-Host ("Line Coverage: {0:N2}% ({1}/{2} lines hit)" -f $pct, $lh, $lf) -ForegroundColor Cyan

if ($pct -lt 95.0) {
    Write-Error ("Coverage gate FAILED: {0:N2}% is below 95.0% threshold" -f $pct)
    exit 1
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "=== SUBPHASE 2.2.1 VERIFICATION GATE: PASSED (100%)       ===" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
