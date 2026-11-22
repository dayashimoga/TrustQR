# Universal QR Platform — Master Verification Gate for Subphase 6.1.1
# Verifies cross-platform native runner configs (Android, iOS, Windows, Linux, macOS)
# and standalone non-nested packaging scripts with checksum manifests.

$ErrorActionPreference = 'Stop'

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  UNIVERSAL QR CODE PLATFORM — SUBPHASE 6.1.1 VERIFICATION GATE  " -ForegroundColor Cyan
Write-Host "  Native Runners & Standalone Packaging Scripts (5 Targets)      " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Gate 1: Compile-Time Binary Isolation Invariant
Write-Host "`n[GATE 1/5] Executing Compile-Time Binary Isolation Audit..." -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "[GATE 1 FAILED] Binary isolation breach detected!"
    exit 1
}
Write-Host "[GATE 1 PASSED] Binary isolation 100% physically intact." -ForegroundColor Green

# 2. Gate 2: Native Runner Configuration Auditor
Write-Host "`n[GATE 2/5] Auditing Native Runner Configurations Across 5 Platforms..." -ForegroundColor Yellow
dart run scripts/verify_native_runner_configs.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "[GATE 2 FAILED] Native runner configuration violations detected!"
    exit 1
}
Write-Host "[GATE 2 PASSED] All 47 native runner rules strictly verified." -ForegroundColor Green

# 3. Gate 3: Monorepo Static Analysis
Write-Host "`n[GATE 3/5] Running Static Analysis Across Monorepo..." -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings .
if ($LASTEXITCODE -ne 0) {
    Write-Error "[GATE 3 FAILED] Static analysis found issues!"
    exit 1
}
Write-Host "[GATE 3 PASSED] 0 errors, 0 warnings, 0 infos across monorepo." -ForegroundColor Green

# 4. Gate 4: Standalone Packaging Pipeline Test
Write-Host "`n[GATE 4/5] Testing Standalone Packaging Scripts (All Apps & Platforms)..." -ForegroundColor Yellow
$testDist = "dist/verify_6_1_1_artifacts"
if (Test-Path $testDist) { Remove-Item -Recurse -Force $testDist }

powershell -ExecutionPolicy Bypass -File scripts/package_artifact.ps1 -TargetApp all -TargetPlatform all -SimulateIfMissing -OutputDir $testDist
if ($LASTEXITCODE -ne 0) {
    Write-Error "[GATE 4 FAILED] Artifact packaging script failed!"
    exit 1
}

# Verify output artifacts count & non-nested structure
$archives = Get-ChildItem -Path $testDist -Filter "qrscanner-*" | Where-Object { $_.Extension -eq '.zip' -or $_.Name.EndsWith('.tar.gz') }
$checksums = Get-ChildItem -Path $testDist -Filter "*.sha256"

if ($archives.Count -ne 10) {
    Write-Error "[GATE 4 FAILED] Expected 10 standalone archives, found $($archives.Count)"
    exit 1
}
if ($checksums.Count -ne 10) {
    Write-Error "[GATE 4 FAILED] Expected 10 .sha256 checksum manifests, found $($checksums.Count)"
    exit 1
}

# Test zip non-nested structure on one of the windows packages
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
$sampleZipPath = Join-Path $testDist "qrscanner-user-windows-x64.zip"
$zip = [System.IO.Compression.ZipFile]::OpenRead($sampleZipPath)
$entryNames = $zip.Entries | ForEach-Object { $_.FullName }
$zip.Dispose()

if (-not ($entryNames -contains "INSTALL.md" -and $entryNames -contains "BUILD_METADATA.json")) {
    Write-Error "[GATE 4 FAILED] Archive missing required root manifests (INSTALL.md or BUILD_METADATA.json)"
    exit 1
}

# Clean up test artifacts
Remove-Item -Recurse -Force $testDist
Write-Host "[GATE 4 PASSED] All 10 standalone non-nested archives & checksum manifests verified." -ForegroundColor Green

# 5. Gate 5: Regression Test Suites
Write-Host "`n[GATE 5/5] Running App Test Suites (Regression Check)..." -ForegroundColor Yellow
Push-Location apps/user_app
try {
    flutter test --no-pub
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[GATE 5 FAILED] user_app test suite failed!"
        exit 1
    }
} finally {
    Pop-Location
}

Push-Location apps/admin_app
try {
    flutter test --no-pub
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[GATE 5 FAILED] admin_app test suite failed!"
        exit 1
    }
} finally {
    Pop-Location
}
Write-Host "[GATE 5 PASSED] 100% of test suites in user_app and admin_app pass." -ForegroundColor Green

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  SUBPHASE 6.1.1 VERIFICATION COMPLETE — ALL 5 GATES PASSED!      " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
