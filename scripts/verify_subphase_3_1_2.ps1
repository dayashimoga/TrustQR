$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "=== Subphase 3.1.2 Comprehensive Verification & Quality Gate ===" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Monorepo compile-time binary isolation audit
Write-Host "`n1. Auditing monorepo compile-time binary isolation..." -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) { throw "Binary isolation verification failed!" }
Write-Host "[PASS] Monorepo binary isolation verified." -ForegroundColor Green

# 2. Static analysis in packages/qr_scanner_engine
Write-Host "`n2. Running static analysis in packages/qr_scanner_engine..." -ForegroundColor Yellow
Push-Location "packages/qr_scanner_engine"
try {
    flutter analyze --fatal-infos --fatal-warnings
    if ($LASTEXITCODE -ne 0) { throw "Static analysis failed in packages/qr_scanner_engine" }
    Write-Host "[PASS] packages/qr_scanner_engine: 0 errors, 0 warnings, 0 infos." -ForegroundColor Green

    # 3. Test suite with coverage in packages/qr_scanner_engine
    Write-Host "`n3. Running unit, pipeline & benchmark tests with coverage..." -ForegroundColor Yellow
    flutter test --coverage
    if ($LASTEXITCODE -ne 0) { throw "Tests failed in packages/qr_scanner_engine" }
    Write-Host "[PASS] All tests passed in packages/qr_scanner_engine." -ForegroundColor Green
} finally {
    Pop-Location
}

# 4. Coverage threshold verification (>= 95.0%)
Write-Host "`n4. Verifying mandatory >=95.0% line coverage gate..." -ForegroundColor Yellow
dart run scripts/measure_coverage.dart packages/qr_scanner_engine/coverage/lcov.info
if ($LASTEXITCODE -ne 0) { throw "Coverage verification failed!" }
Write-Host "[PASS] Coverage gate passed." -ForegroundColor Green

# 5. Full workspace static analysis
Write-Host "`n5. Running workspace-wide static analysis..." -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings .
if ($LASTEXITCODE -ne 0) { throw "Workspace static analysis failed" }
Write-Host "[PASS] Entire workspace: 0 errors, 0 warnings, 0 infos." -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "=== SUBPHASE 3.1.2 FULLY VERIFIED & QUALITY GATES PASSED ===" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
exit 0
