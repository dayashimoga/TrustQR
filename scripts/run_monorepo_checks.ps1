$ErrorActionPreference = "Stop"

Write-Host "=== Monorepo Scaffolding & Verification Runner ===" -ForegroundColor Cyan

# 1. Run Binary Isolation Auditor
& "h:\qrscanner\scripts\verify_binary_isolation.ps1"

# 2. List of packages to test & analyze
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
    $fullPath = "h:\qrscanner\$target"
    Write-Host "`n>>> Checking $target..." -ForegroundColor Yellow
    Push-Location $fullPath
    try {
        if ($target -match "^packages/qr_core" -or $target -match "^services/rbac_api") {
            dart pub get
            if ($LASTEXITCODE -ne 0) { throw "dart pub get failed in $target" }
            dart analyze --fatal-infos --fatal-warnings
            if ($LASTEXITCODE -ne 0) { throw "dart analyze failed in $target" }
            dart test
            if ($LASTEXITCODE -ne 0) { throw "dart test failed in $target" }
        } else {
            flutter pub get
            if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed in $target" }
            flutter analyze --fatal-infos --fatal-warnings
            if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed in $target" }
            flutter test
            if ($LASTEXITCODE -ne 0) { throw "flutter test failed in $target" }
        }
    } finally {
        Pop-Location
    }
}

Write-Host "`n[SUCCESS] All monorepo packages, services, and apps verified cleanly!" -ForegroundColor Green
exit 0
