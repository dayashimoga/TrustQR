$ErrorActionPreference = "Stop"

Write-Host "=== Subphase 1.1.1 Verification Harness ===" -ForegroundColor Cyan

$requiredFiles = @(
    "AGENTS.md",
    "GEMINI.md",
    "README.md",
    "CHANGELOG.md",
    "TODO.md",
    ".gitignore",
    ".agents/rules/security-rbac-contract.md",
    ".agents/rules/quality-gates-contract.md",
    ".agents/skills/architecture-governance/SKILL.md",
    ".agents/skills/cross-platform-frontend/SKILL.md",
    ".agents/skills/rbac-backend-persistence/SKILL.md",
    ".agents/skills/qr-security-threat-audit/SKILL.md",
    ".agents/skills/automated-testing-coverage/SKILL.md",
    ".agents/skills/ci-cd-release-matrix/SKILL.md",
    ".agents/skills/futuristic-uiux-accessibility/SKILL.md",
    ".agents/skills/performance-profiling/SKILL.md",
    ".agents/skills/subphase-verification-docs/SKILL.md",
    "docs/REQUIREMENTS.md",
    "docs/ARCHITECTURE.md",
    "docs/ROADMAP.md",
    "docs/PROGRESS_TRACKER.md"
)

$passed = 0
foreach ($relPath in $requiredFiles) {
    $fullPath = Join-Path "h:\qrscanner" $relPath
    if (-not (Test-Path $fullPath)) {
        throw "Missing required file: $relPath"
    }
    $item = Get-Item $fullPath
    if ($item.Length -lt 100) {
        throw "File is unexpectedly small or empty: $relPath ($($item.Length) bytes)"
    }
    $passed++
}

# Verify YAML frontmatter on all 9 SKILL.md files
$skillFiles = Get-ChildItem "h:\qrscanner\.agents\skills\*\SKILL.md"
if ($skillFiles.Count -ne 9) {
    throw "Expected 9 workspace skills, found $($skillFiles.Count)"
}
foreach ($sf in $skillFiles) {
    $text = Get-Content $sf.FullName -Raw
    if ($text -notmatch "(?s)^---\r?\nname:\s+[a-z0-9\-]+\r?\ndescription:") {
        throw "Invalid YAML frontmatter in skill file: $($sf.FullName)"
    }
}

Write-Host "[PASS] Verified $passed required governance, documentation, rule, and skill files." -ForegroundColor Green
Write-Host "[PASS] Verified valid YAML frontmatter across all 9 Antigravity workspace skills." -ForegroundColor Green
exit 0
