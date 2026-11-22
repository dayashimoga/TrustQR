$ErrorActionPreference = "Stop"

Write-Host "Running Binary Isolation Auditor..." -ForegroundColor Cyan
dart run "h:\qrscanner\scripts\verify_binary_isolation.dart"
if ($LASTEXITCODE -ne 0) {
    throw "Binary Isolation Audit failed with exit code $LASTEXITCODE"
}
Write-Host "Binary Isolation Audit verified successfully." -ForegroundColor Green
exit 0
