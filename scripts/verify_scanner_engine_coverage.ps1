$ErrorActionPreference = "Stop"

Write-Host "=== Subphase 2.1.1 Verification & Coverage Harness ===" -ForegroundColor Cyan

Push-Location "h:\qrscanner\packages\qr_scanner_engine"
try {
    Write-Host "1. Running static analyzer in packages/qr_scanner_engine..." -ForegroundColor Yellow
    flutter analyze --fatal-infos --fatal-warnings
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed in packages/qr_scanner_engine" }

    Write-Host "2. Running unit test suite with coverage collection..." -ForegroundColor Yellow
    flutter test --coverage
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed in packages/qr_scanner_engine" }

    # Parse lcov.info to calculate line coverage percentage
    $lcovPath = "coverage/lcov.info"
    if (-not (Test-Path $lcovPath)) {
        throw "LCOV report not found at $lcovPath"
    }

    $linesFound = 0
    $linesHit = 0
    foreach ($line in Get-Content $lcovPath) {
        if ($line -match "^LF:(\d+)") {
            $linesFound += [int]$matches[1]
        } elseif ($line -match "^LH:(\d+)") {
            $linesHit += [int]$matches[1]
        }
    }

    if ($linesFound -eq 0) {
        throw "No lines found in coverage report!"
    }

    $coveragePercent = [math]::Round(($linesHit / $linesFound) * 100, 2)
    Write-Host "`n>>> Line Coverage: $coveragePercent% ($linesHit / $linesFound lines hit) <<<" -ForegroundColor Green

    if ($coveragePercent -lt 95.0) {
        throw "CRITICAL QUALITY GATE FAILURE: Line coverage ($coveragePercent%) is below mandatory threshold of 95.0%!"
    }

    Write-Host "[PASS] Subphase 2.1.1 meets and exceeds mandatory >=95% line coverage quality gate!" -ForegroundColor Green
} finally {
    Pop-Location
}
exit 0
