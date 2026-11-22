# Changelog — Universal QR Code Scanner & Generator Platform

> **Policy**: This file is an **append-only** historical ledger. Never delete or overwrite prior entries.

---

## [0.1.0-subphase.1.1.2] - 2026-11-22

### Added
- **Monorepo Package Scaffolding (`packages/*`, `services/*`, `apps/*`)**:
  - `packages/qr_core`: Core domain models, 15-format payload type enums, threat levels, and base entities.
  - `packages/qr_scanner_engine`: Universal decoding pipeline contract and baseline scanner engine.
  - `packages/qr_generator_engine` (Admin Only): Matrix options, Reed-Solomon levels, module shapes, and scannability evaluation engine.
  - `packages/qr_admin_analytics` (Admin Only): Fleet telemetry aggregator and usage statistics service.
  - `packages/qr_design_system`: CyberTokens design palette, dark cyber theme, and glassmorphic card component.
  - `services/rbac_api`: Server-side RBAC claims model and HTTP server with role-checking middleware.
  - `apps/user_app`: Restricted scanner-only application with zero QR generator dependencies.
  - `apps/admin_app`: Full-featured admin and premium QR studio application with generator controls and fleet telemetry.
- **Automated Binary Isolation Auditor**:
  - `scripts/verify_binary_isolation.dart` & `scripts/verify_binary_isolation.ps1`: AST and `pubspec.yaml` scanner enforcing zero dependency leakage from `qr_generator_engine` or `qr_admin_analytics` into `apps/user_app`.
  - Built-in fail-safe self-test verifying breach detection logic against synthetic mock fixtures.
- **Verification Runner**:
  - `scripts/run_monorepo_checks.ps1`: Automated runner executing binary isolation audit, pub resolution, strict static analysis (`--fatal-infos --fatal-warnings`), and unit/widget test suites across all 8 targets.

---

## [0.1.0-subphase.1.1.1] - 2026-11-22

### Added
- **Global Engineering Contract (`AGENTS.md`, `GEMINI.md`)**: Established non-negotiable standards for physical compile-time binary separation between `apps/user_app` (Scanner Only) and `apps/admin_app` (Full Premium Studio), server-side Ed25519 cryptographic RBAC enforcement, zero placeholders, and `>=95%` automated test coverage gates.
- **Antigravity Multi-Agent Framework (`.agents/`)**:
  - Defined 9 specialized subagents (`architect-agent`, `frontend-agent`, `backend-agent`, `security-agent`, `testing-agent`, `devops-agent`, `uiux-agent`, `performance-agent`, `docs-agent`).
  - Added always-on workspace rule contracts: `.agents/rules/security-rbac-contract.md` and `.agents/rules/quality-gates-contract.md`.
  - Added 9 specialized workspace skills under `.agents/skills/*/SKILL.md`.
- **Core Technical Documentation (`docs/`)**:
  - Created `docs/REQUIREMENTS.md` (Functional & Non-Functional SRS).
  - Created `docs/ARCHITECTURE.md` (Three-Layer Zero-Trust RBAC & Poly-Package Monorepo Blueprint).
  - Created `docs/ROADMAP.md` (6 Stages → 12 Phases → 24 Subphases with time budgets and acceptance criteria).
  - Created `docs/PROGRESS_TRACKER.md` (Live status ledger).
- **Verification Harness**:
  - Added `scripts/verify_subphase_1_1_1.ps1` to deterministically verify all governance contracts, skill frontmatter, roadmap structure, and Git initialization.
