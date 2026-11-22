# Universal QR Platform — Master Verification Gate for Subphase 6.2.2
# Verifies Complete Documentation Suite, Cross-Links, Final Release Sign-Off,
# Binary Isolation, Native Runner Configs, CI/CD Workflows, Static Analysis, and Ecosystem Coverage.

$ErrorActionPreference = 'Stop'

Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '  UNIVERSAL QR CODE PLATFORM — SUBPHASE 6.2.2 VERIFICATION GATE  ' -ForegroundColor Cyan
Write-Host '  Complete Documentation Suite, Quality Gates & Release Sign-Off ' -ForegroundColor Cyan
Write-Host '=================================================================' -ForegroundColor Cyan

# Gate 1: Compile-Time Binary Isolation Audit
Write-Host ''
Write-Host '[GATE 1/6] Auditing Compile-Time Binary Isolation Invariant...' -ForegroundColor Yellow
dart run scripts/verify_binary_isolation.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 1 FAILED] Binary isolation breach detected.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 1 PASSED] 100% binary isolation strictly verified.' -ForegroundColor Green

# Gate 2: Native Runner Configuration Auditor
Write-Host ''
Write-Host '[GATE 2/6] Auditing Cross-Platform Native Runner Configurations...' -ForegroundColor Yellow
dart run scripts/verify_native_runner_configs.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 2 FAILED] Native runner configuration issues found.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 2 PASSED] All 47 native runner rules strictly verified.' -ForegroundColor Green

# Gate 3: GitHub Actions CI/CD Workflow Auditor
Write-Host ''
Write-Host '[GATE 3/6] Auditing GitHub Actions CI/CD Workflows...' -ForegroundColor Yellow
dart run scripts/verify_github_workflows.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 3 FAILED] GitHub Actions workflow schema issues found.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 3 PASSED] All 26 workflow rules strictly verified.' -ForegroundColor Green

# Gate 4: Monorepo Static Analysis
Write-Host ''
Write-Host '[GATE 4/6] Running Monorepo Static Analysis...' -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings .
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 4 FAILED] Static analyzer reported issues.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 4 PASSED] Static analysis clean (0 errors, 0 warnings, 0 infos).' -ForegroundColor Green

# Gate 5: Master Ecosystem Coverage Audit
Write-Host ''
Write-Host '[GATE 5/6] Auditing Master Ecosystem Coverage (>=95% across all 8 modules)...' -ForegroundColor Yellow
dart run scripts/verify_ecosystem_coverage.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 5 FAILED] Ecosystem coverage quality gate unmet.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 5 PASSED] Ecosystem coverage >=95% across all 8 components verified.' -ForegroundColor Green

# Gate 6: Complete Documentation Suite Auditor
Write-Host ''
Write-Host '[GATE 6/6] Auditing Complete Documentation Suite & Cross-Link Integrity...' -ForegroundColor Yellow
dart run scripts/verify_documentation_suite.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host '[GATE 6 FAILED] Documentation suite auditor detected defects.' -ForegroundColor Red
    exit 1
}
Write-Host '[GATE 6 PASSED] All documentation files, size thresholds, and links verified.' -ForegroundColor Green

Write-Host ''
Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '  SUBPHASE 6.2.2 VERIFICATION COMPLETE — ALL 6 GATES PASSED!      ' -ForegroundColor Green
Write-Host '  PLATFORM READY FOR FINAL RELEASE SIGN-OFF (24/24 SUBPHASES)    ' -ForegroundColor Green
Write-Host '=================================================================' -ForegroundColor Cyan
