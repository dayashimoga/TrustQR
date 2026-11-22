# Global Engineering Contract — Universal QR Code Scanner & Generator Platform

This document is the binding **Global Engineering Contract** for all human and AI agents operating within the `qrscanner` workspace. Every line of code, test, architectural decision, UI component, and CI/CD workflow must strictly comply with these standards.

---

## 1. Core Architectural Invariant: Physical & Cryptographic Separation of Apps

The platform builds **two distinct cross-platform applications** targeting **Android, iOS, Windows, Linux, and macOS** (across phone, tablet, laptop, and desktop form factors):

1. **Admin App (`apps/admin_app` — Premium / Full Access)**:
   - Full access to QR scanning, single & batch QR generation, artistic customization (colors, gradients, module shapes, embedded logos, branded frames/templates), Scannability & Contrast Simulator, Ed25519 TrustQR cryptographic signing, fleet/usage analytics, template management, and export pipelines (PNG, SVG, PDF).
2. **User App (`apps/user_app` — Restricted / Scanner Only)**:
   - Strictly restricted to QR scanning (live camera, uploaded images, screenshots, files, batch image detection), Malicious-Link & Threat Firewall inspection, TrustQR signature verification, and personal scan history/favorites/collections/search.
   - **Compile-Time Isolation Invariant**: `apps/user_app/pubspec.yaml` must **NEVER** depend on `packages/qr_generator_engine` or `packages/qr_admin_analytics`. Any violation fails the architectural gate immediately.
   - **Server-Side & Cryptographic RBAC Invariant**: `services/rbac_api` enforces signed Ed25519 JWT/entitlement tokens (`role: admin` vs `role: user`). Every generation, template, batch, and analytics API endpoint rejects `role: user` or unsigned/tampered tokens with `HTTP 403 Forbidden`. Local storage tampering cannot unlock premium or admin capabilities.

---

## 2. Non-Negotiable Quality & Implementation Standards

1. **Zero Placeholders or Mock Features**:
   - No dummy, mock, simulated, hardcoded, or `TODO: implement later` logic may be presented as a completed feature.
   - No decorative UI buttons, toggles, or menu items that do nothing or merely show a placeholder snackbar. Every interactive control must execute real, verified domain logic.
2. **Static Analysis & Code Hygiene**:
   - `dart analyze --fatal-infos --fatal-warnings` / `flutter analyze` must pass with **0 errors, 0 warnings, and 0 infos** across all packages, services, and applications.
3. **Mandatory Automated Testing & Coverage Gate**:
   - Every subphase must include automated unit, widget, integration, or security tests covering all newly introduced code paths.
   - **Target >= 95% meaningful line coverage** on core domain, engine, security, and backend packages, with **100% of mandatory tests passing** before a subphase is marked `VERIFIED`.
4. **Append-Only Historical Ledgers**:
   - `CHANGELOG.md` and `TODO.md` are **append-only ledgers**. Never overwrite or delete historical entries; always append timestamped subphase records and status transitions.

---

## 3. Execution Control Protocol (One Subphase at a Time)

1. **Hierarchy**: Development is organized strictly as **Stages → Phases → Subphases** in [docs/ROADMAP.md](docs/ROADMAP.md) and tracked in [docs/PROGRESS_TRACKER.md](docs/PROGRESS_TRACKER.md).
2. **Single-Subphase Rule**:
   - Execute **only ONE subphase at a time**.
   - Complete implementation, integration, automated testing, documentation updates, `CHANGELOG.md` / `TODO.md` append entries, and verification checks for the current subphase before stopping.
   - **Wait for explicit user confirmation** before starting the next subphase.
3. **Time Budget & Course Correction**:
   - Every subphase has an assigned maximum time budget and measurable acceptance criteria.
   - If a blocker, architectural deviation, security flaw, or time overrun is detected, immediately halt, diagnose the root cause, report transparently to the user, and propose a corrective adjustment.

---

## 4. Multi-Agent Roster & Domain Responsibilities

| Agent Name | Role | Primary Scope & Quality Gate Ownership |
| :--- | :--- | :--- |
| `architect-agent` | Principal System Architect | Monorepo dependency graph, compile-time binary isolation audit, course correction |
| `frontend-agent` | Lead Cross-Platform Engineer | Flutter/Dart apps (`user_app`, `admin_app`), scanner & generator engine integration |
| `backend-agent` | Lead Backend & Persistence Engineer | `services/rbac_api`, Ed25519 JWT/entitlement server, SQLite offline-first storage |
| `security-agent` | Lead Security & Threat Auditor | Anti-phishing QR firewall, homograph/scheme checks, TrustQR signatures, RBAC pen-tests |
| `testing-agent` | Principal QA & Coverage Engineer | Unit/widget/integration/E2E tests, >=95% coverage verification, regression detection |
| `devops-agent` | Lead DevOps & Release Engineer | GitHub Actions matrix & on-demand workflows, standalone artifact packaging, checksums |
| `uiux-agent` | Principal UI/UX & Accessibility Lead | `packages/qr_design_system`, futuristic glassmorphic UI, responsive layouts, WCAG, i18n |
| `performance-agent` | Principal Performance Engineer | Frame-rate stability, isolate offloading, startup time, memory & battery benchmarks |
| `docs-agent` | Lead Technical Chronicler | `docs/*`, `PROGRESS_TRACKER.md`, append-only `CHANGELOG.md` and `TODO.md` |
