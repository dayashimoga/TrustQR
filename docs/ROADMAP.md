# Master Technical Roadmap (Stages → Phases → Subphases)
## Universal QR Code Scanner & Generator Platform

> **Execution Governance Rule**: Execute **ONLY ONE subphase at a time**. Every subphase must complete implementation, integration, automated testing (`>=95%` coverage target, `100%` passing), documentation, `CHANGELOG.md` and `TODO.md` append updates, and verification before pausing for explicit user confirmation.

---

## Roadmap Summary Matrix

| Stage | Phase | Subphase | Title | Max Time Budget | Dependencies |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stage 1** | **Phase 1.1** | **1.1.1** | Antigravity Multi-Agent Framework, Global Engineering Contract & Master Roadmap | 25 min | None |
| **Stage 1** | **Phase 1.1** | **1.1.2** | Monorepo Scaffolding (`packages/*`, `services/*`, `apps/*`) & Binary Isolation Auditor | 25 min | 1.1.1 |
| **Stage 1** | **Phase 1.2** | **1.2.1** | Multi-Format QR Payload Engine (15+ Formats), Parsers, Encoders & Schema Validators | 35 min | 1.1.2 |
| **Stage 1** | **Phase 1.2** | **1.2.2** | Ed25519 `TrustQR` Cryptographic Signing & Asymmetric Entitlement Tokens | 35 min | 1.2.1 |
| **Stage 2** | **Phase 2.1** | **2.1.1** | Zero-Trust QR Threat Firewall & Anti-Phishing Inspection Engine | 35 min | 1.2.2 |
| **Stage 2** | **Phase 2.1** | **2.1.2** | Threat Firewall Adversarial Benchmark & Security Verification Suite | 25 min | 2.1.1 |
| **Stage 2** | **Phase 2.2** | **2.2.1** | Offline-First Encrypted Vault (History, Favorites, Collections, Tags, FTS Search) | 35 min | 2.1.2 |
| **Stage 2** | **Phase 2.2** | **2.2.2** | Server-Side RBAC & Entitlement Service (`services/rbac_api`) + Penetration Tests | 40 min | 2.2.1 |
| **Stage 3** | **Phase 3.1** | **3.1.1** | Universal QR Decoding Pipeline (Camera, Image, File, Multi-QR Batch Matrix Vision) | 40 min | 2.2.2 |
| **Stage 3** | **Phase 3.1** | **3.1.2** | Integrated Scan-to-Firewall-to-Vault Pipeline & Decoding Performance Benchmarks | 30 min | 3.1.1 |
| **Stage 3** | **Phase 3.2** | **3.2.1** | Admin-Only Artistic QR Matrix Encoder, Shaders, Gradients, Logos & Branded Templates | 40 min | 3.1.2 |
| **Stage 3** | **Phase 3.2** | **3.2.2** | Real-Time Scannability & Contrast Simulator + PNG, Vector SVG, PDF & Batch Exporter | 35 min | 3.2.1 |
| **Stage 4** | **Phase 4.1** | **4.1.1** | Cyber-Precision Glassmorphic Design System, HUD Scanner Reticle & Adaptive Layouts | 35 min | 3.2.2 |
| **Stage 4** | **Phase 4.1** | **4.1.2** | WCAG Accessibility Semantics, Multi-Language Localization (i18n) & Widget Tests | 30 min | 4.1.1 |
| **Stage 4** | **Phase 4.2** | **4.2.1** | Restricted User App (`apps/user_app`): Live/File/Batch Scanner & Threat HUD | 40 min | 4.1.2 |
| **Stage 4** | **Phase 4.2** | **4.2.2** | Restricted User App: Offline Vault, Smart Collections, Privacy Mode & Isolation Gate | 35 min | 4.2.1 |
| **Stage 5** | **Phase 5.1** | **5.1.1** | Admin Analytics Engine (`packages/qr_admin_analytics`): Fleet, Telemetry & Reports | 35 min | 4.2.2 |
| **Stage 5** | **Phase 5.1** | **5.1.2** | Admin Analytics & Fleet Governance Verification Suite (`>=95%` Coverage) | 25 min | 5.1.1 |
| **Stage 5** | **Phase 5.2** | **5.2.1** | Admin App (`apps/admin_app`): Interactive QR Studio, Scannability Sim & TrustQR Signer | 45 min | 5.1.2 |
| **Stage 5** | **Phase 5.2** | **5.2.2** | Admin App: Batch Generator, Analytics Dashboard, RBAC Guard & Multi-Pane Workspace | 40 min | 5.2.1 |
| **Stage 6** | **Phase 6.1** | **6.1.1** | Cross-Platform Native Runner Configs & Standalone Packaging Scripts (5 OS Targets) | 35 min | 5.2.2 |
| **Stage 6** | **Phase 6.1** | **6.1.2** | GitHub Actions CI/CD Workflows (Full Matrix + On-Demand App/Platform Selector) | 35 min | 6.1.1 |
| **Stage 6** | **Phase 6.2** | **6.2.1** | Full-Ecosystem E2E Tests, `>=95%` Coverage Audit, RBAC Audit & Native Build Validation | 40 min | 6.1.2 |
| **Stage 6** | **Phase 6.2** | **6.2.2** | Complete Documentation Suite (`USER_GUIDE`, `SECURITY`, `INSTALL`) & Release Sign-Off | 30 min | 6.2.1 |

---

## Detailed Stage, Phase & Subphase Specifications

### STAGE 1: Foundation, Multi-Agent Governance, Core Domain & Cryptographic RBAC

#### Phase 1.1: Multi-Agent Framework, Architecture Blueprint & Monorepo Foundation
- **Subphase 1.1.1: Antigravity Multi-Agent Framework, Global Engineering Contract & Master Roadmap**
  - **Time Budget**: 25 minutes
  - **Assigned Agents**: `architect-agent`, `docs-agent`
  - **Objectives & Deliverables**:
    - Define 9 specialized subagents and 9 workspace skills in `.agents/skills/`.
    - Establish `AGENTS.md`, `GEMINI.md`, `.agents/rules/security-rbac-contract.md`, and `.agents/rules/quality-gates-contract.md`.
    - Author `docs/REQUIREMENTS.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PROGRESS_TRACKER.md`, `CHANGELOG.md`, `TODO.md`, and initialize Git repository.
  - **Acceptance Criteria & Completion Evidence**:
    - All 9 skills and rule contracts exist and pass automated validation via `scripts/verify_subphase_1_1_1.ps1`.
    - Git repository initialized on branch `main` with clean status.

- **Subphase 1.1.2: Monorepo Scaffolding (`packages/*`, `services/*`, `apps/*`) & Binary Isolation Auditor**
  - **Time Budget**: 25 minutes
  - **Assigned Agents**: `architect-agent`, `devops-agent`
  - **Objectives & Deliverables**:
    - Scaffold Dart/Flutter package structure for `packages/qr_core`, `packages/qr_scanner_engine`, `packages/qr_generator_engine`, `packages/qr_admin_analytics`, `packages/qr_design_system`, `services/rbac_api`, `apps/user_app`, and `apps/admin_app`.
    - Create `scripts/verify_binary_isolation.dart` (and PowerShell/Bash wrapper) that parses `pubspec.yaml` and AST/imports across `apps/user_app` to guarantee zero dependency on `qr_generator_engine` or `qr_admin_analytics`.
  - **Acceptance Criteria & Completion Evidence**:
    - `dart analyze` succeeds across all workspace packages.
    - Binary isolation auditor passes and includes negative self-test verifying it catches forbidden imports.

#### Phase 1.2: Universal QR Domain Models, Multi-Format Parsers & Ed25519 TrustQR Cryptography
- **Subphase 1.2.1: Multi-Format QR Payload Engine (15+ Formats), Parsers, Encoders & Schema Validators**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `backend-agent`, `frontend-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement bidirectional parsing, normalization, validation, and canonical encoding in `packages/qr_core` for all 15 QR payload types (URL, Wi-Fi, vCard, MeCard, Geo, iCal Event, Email, SMS, Tel, OTPAuth/TOTP, UPI Payment, EPC Payment, Crypto URI, GS1 Digital Link, Plain Text).
  - **Acceptance Criteria & Completion Evidence**:
    - `dart analyze --fatal-infos --fatal-warnings` exits `0`.
    - Automated unit test suite covering all 15 formats passes 100% with `>= 95%` line coverage.

- **Subphase 1.2.2: Ed25519 `TrustQR` Cryptographic Signing & Asymmetric Entitlement Tokens**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `security-agent`, `backend-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement pure-Dart Ed25519 / HMAC-SHA256 cryptographic signing and verification in `packages/qr_core`.
    - Implement `TrustQrEnvelope` (signed QR payloads with issuer ID, timestamp, expiration, and signature) and `EntitlementToken` (asymmetric role & scope token for `admin` vs `user` with tamper detection).
  - **Acceptance Criteria & Completion Evidence**:
    - Tampering with a single byte of a `TrustQrEnvelope` or `EntitlementToken` deterministically fails signature verification.
    - Unit & cryptographic test suite passes 100% with `>= 95%` coverage.

---

### STAGE 2: Zero-Trust Threat Firewall, Offline-First Vault & Server-Side RBAC Backend

#### Phase 2.1: Zero-Trust QR Security & Malicious-Link Detection Engine
- **Subphase 2.1.1: Zero-Trust QR Threat Firewall & Anti-Phishing Inspection Engine**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `security-agent`, `backend-agent`
  - **Objectives & Deliverables**:
    - Implement `QrThreatFirewall` in `packages/qr_scanner_engine` (or `packages/qr_core/security`):
      - Dangerous scheme blocking (`javascript:`, `data:`, `vbscript:`, `file:`).
      - IDN Homograph / Punycode (`xn--`) and mixed Unicode script detector.
      - Raw IPv4/IPv6, hex/octal IP obfuscation, credential-in-URL (`user:pass@host`), URL shortener warning, high-entropy phishing domain detector, insecure HTTP login/payment warning, Open-Redirect parameter detector, and Wi-Fi open/WEP evil-twin alert.
      - Computed `ThreatAssessment` (0–100 Safety Score, Severity Level, triggered rule codes, and remediation guidance).
  - **Acceptance Criteria & Completion Evidence**:
    - Deterministic classification across benign and malicious payload vectors with zero false negatives on critical exploit vectors.

- **Subphase 2.1.2: Threat Firewall Adversarial Benchmark & Security Verification Suite**
  - **Time Budget**: 25 minutes
  - **Assigned Agents**: `security-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Build an exhaustive adversarial test corpus (100+ attack and benign vectors including Cyrillic homographs, XSS `javascript:` URIs, SSRF private IPs, tampered `TrustQR` envelopes, and Wi-Fi injection payloads).
  - **Acceptance Criteria & Completion Evidence**:
    - 100% passing adversarial tests and `>= 95%` line coverage on the security engine.

#### Phase 2.2: Offline-First Encrypted Vault & Server-Side RBAC Service (`services/rbac_api`)
- **Subphase 2.2.1: Offline-First Encrypted Vault (History, Favorites, Collections, Tags, FTS Search)**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `backend-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement offline-first local storage engine in `packages/qr_core` supporting scan history, generated QR items, favorites, custom collections, tags, full-text search, multi-criteria filtering, batch import/export, and privacy auto-purge policies.
    - Include HMAC/checksum integrity guard on stored records.
  - **Acceptance Criteria & Completion Evidence**:
    - Full CRUD, search, filtering, collection assignment, and persistence tests pass 100% with `>= 95%` line coverage.

- **Subphase 2.2.2: Server-Side RBAC & Entitlement Service (`services/rbac_api`) + Penetration Tests**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `backend-agent`, `security-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement `services/rbac_api` HTTP server with authentication (`/api/v1/auth/token`), entitlement verification (`/api/v1/auth/verify`), scanner telemetry/verification endpoints (accessible to `user` and `admin`), and strictly protected admin endpoints (`/api/v1/admin/qr/generate`, `/api/v1/admin/qr/batch`, `/api/v1/admin/qr/sign`, `/api/v1/admin/templates`, `/api/v1/admin/analytics`, `/api/v1/admin/audit`).
    - Implement automated RBAC penetration tests verifying that `role: user`, anonymous callers, expired tokens, revoked tokens, and tampered payloads receive `401`/`403` on every admin/generation endpoint.
  - **Acceptance Criteria & Completion Evidence**:
    - 100% of RBAC integration and adversarial penetration tests pass; `>= 95%` coverage on `services/rbac_api`.

---

### STAGE 3: High-Speed QR Scanner Engine & Admin-Only QR Generator Engine

#### Phase 3.1: Multi-Source & Batch QR Scanner Engine (`packages/qr_scanner_engine`)
- **Subphase 3.1.1: Universal QR Decoding Pipeline (Camera, Image, File, Multi-QR Batch Matrix Vision)**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `frontend-agent`, `performance-agent`
  - **Objectives & Deliverables**:
    - Implement `packages/qr_scanner_engine` with pure-Dart + hardware-accelerated decoding support for raw RGBA image buffers, PNG/JPEG/BMP/WebP files, screenshots, and multi-QR grid/batch detection within a single image or batch of files.
    - Offload heavy image decoding to background Dart isolates.
  - **Acceptance Criteria & Completion Evidence**:
    - Successfully decodes single and multi-QR test images across various rotations, contrast levels, and error-correction levels.

- **Subphase 3.1.2: Integrated Scan-to-Firewall-to-Vault Pipeline & Decoding Performance Benchmarks**
  - **Time Budget**: 30 minutes
  - **Assigned Agents**: `performance-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Connect the scanner engine to the 15-format parser, `TrustQR` signature verifier, `QrThreatFirewall`, and Offline Vault deduplication/recording pipeline.
    - Execute automated latency benchmarks (`< 25 ms` average decode + firewall assessment) and unit/integration tests.
  - **Acceptance Criteria & Completion Evidence**:
    - `>= 95%` line coverage on `packages/qr_scanner_engine` and benchmark assertions passing.

#### Phase 3.2: Admin-Only Artistic QR Generator, Scannability Simulator & Export Engine (`packages/qr_generator_engine`)
- **Subphase 3.2.1: Admin-Only Artistic QR Matrix Encoder, Shaders, Gradients, Logos & Branded Templates**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `frontend-agent`, `uiux-agent`
  - **Objectives & Deliverables**:
    - Implement ISO/IEC 18004 QR matrix generation in `packages/qr_generator_engine` supporting Reed-Solomon levels `L`, `M`, `Q`, `H`.
    - Implement customizable styling: 6 module shapes (`square`, `rounded`, `dots`, `diamond`, `liquid`, `cyber_grid`), custom finder eye styles, solid & multi-stop linear/radial gradients, center logo embedding with automatic quiet-zone cutout, and reusable branded templates.
  - **Acceptance Criteria & Completion Evidence**:
    - Generated QR matrices are 100% standards-compliant and round-trip decodable by `packages/qr_scanner_engine`.

- **Subphase 3.2.2: Real-Time Scannability & Contrast Simulator + PNG, Vector SVG, PDF & Batch Exporter**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `frontend-agent`, `performance-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement `ScannabilitySimulator` computing Michelson contrast, WCAG luminance ratio, logo area vs. Reed-Solomon recovery budget, quiet-zone sufficiency, and round-trip decode verification score (`0–100`).
    - Implement high-DPI PNG rasterizer, standalone Vector SVG writer, print-ready PDF document generator, and batch CSV/JSON-to-QR archive generator.
  - **Acceptance Criteria & Completion Evidence**:
    - Every generated PNG/SVG/batch output passes automated round-trip decoding and `>= 95%` test coverage in `packages/qr_generator_engine`.

---

### STAGE 4: Futuristic Cyber-Precision Design System & Restricted User Application (`apps/user_app`)

#### Phase 4.1: Futuristic Glassmorphic UI/UX Design System, Accessibility & Localization (`packages/qr_design_system`)
- **Subphase 4.1.1: Cyber-Precision Glassmorphic Design System, HUD Scanner Reticle & Adaptive Layouts**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `uiux-agent`, `frontend-agent`
  - **Objectives & Deliverables**:
    - Implement `packages/qr_design_system`: dark/light cyber-precision themes, glassmorphic cards, animated laser HUD scanner reticle, Threat Safety Score gauge, TrustQR verification badge, and `AdaptiveWorkspaceShell` supporting Compact Mobile (`<600px`), Medium Tablet (`600–1024px`), and Expanded Desktop (`>1024px`) breakpoints with keyboard shortcut bindings.
  - **Acceptance Criteria & Completion Evidence**:
    - Zero analyzer warnings; responsive layout transitions verified across phone, tablet, and desktop viewport dimensions.

- **Subphase 4.1.2: WCAG Accessibility Semantics, Multi-Language Localization (i18n) & Widget Tests**
  - **Time Budget**: 30 minutes
  - **Assigned Agents**: `uiux-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement multi-language localization support (English, Spanish, French, German, Hindi, Japanese) and WCAG screen-reader semantics, high-contrast toggle, and reduced-motion accessibility support.
    - Achieve `>= 95%` widget test coverage across `packages/qr_design_system`.
  - **Acceptance Criteria & Completion Evidence**:
    - 100% passing widget and accessibility semantic tests with `>= 95%` coverage.

#### Phase 4.2: Restricted User Application (`apps/user_app` — Scanner Only)
- **Subphase 4.2.1: Restricted User App (`apps/user_app`): Live/File/Batch Scanner & Threat HUD**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `frontend-agent`, `security-agent`
  - **Objectives & Deliverables**:
    - Build `apps/user_app` Scanner Workspace: live camera viewport, image/screenshot/file picker, batch multi-QR image inspection, real-time Threat Firewall HUD modal, `TrustQR` authenticity badge, and context-aware payload actions (copy, Wi-Fi details, vCard inspect, TOTP code viewer, safe URL launch gate).
  - **Acceptance Criteria & Completion Evidence**:
    - All scanner actions are genuinely wired and tested via Flutter widget/integration tests.

- **Subphase 4.2.2: Restricted User App: Offline Vault, Smart Collections, Privacy Mode & Isolation Gate**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `frontend-agent`, `security-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Complete `apps/user_app` History, Favorites, Smart Collections, Full-Text Search/Filter Bar, Settings (Theme, Locale, High-Contrast, Privacy Incognito Mode), and Restricted Entitlement Status view.
    - Run compile-time and runtime verification proving `apps/user_app` has zero QR generation UI, zero admin routes, and zero dependency on `qr_generator_engine` or `qr_admin_analytics`.
  - **Acceptance Criteria & Completion Evidence**:
    - `flutter test --coverage` passes 100% with `>= 95%` coverage in `apps/user_app` and `verify_binary_isolation.dart` passes.

---

### STAGE 5: Full-Featured Admin/Premium Application (`apps/admin_app`) & Analytics Suite

#### Phase 5.1: Admin Analytics Engine & Fleet Management Package (`packages/qr_admin_analytics`)
- **Subphase 5.1.1: Admin Analytics Engine (`packages/qr_admin_analytics`): Fleet, Telemetry & Reports**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `backend-agent`, `frontend-agent`
  - **Objectives & Deliverables**:
    - Implement `packages/qr_admin_analytics`: scan & generation volume time-series aggregator, payload format breakdown, Threat Firewall detection metrics, signed `TrustQR` fleet registry (with revocation support), audit log inspector, and CSV/JSON analytics report exporter.
  - **Acceptance Criteria & Completion Evidence**:
    - Real computation over vault and server telemetry records (zero hardcoded dummy charts).

- **Subphase 5.1.2: Admin Analytics & Fleet Governance Verification Suite (`>=95%` Coverage)**
  - **Time Budget**: 25 minutes
  - **Assigned Agents**: `testing-agent`
  - **Objectives & Deliverables**:
    - Write comprehensive unit and widget tests for analytics aggregation, fleet revocation, filtering, and CSV/JSON export.
  - **Acceptance Criteria & Completion Evidence**:
    - 100% passing tests and `>= 95%` line coverage in `packages/qr_admin_analytics`.

#### Phase 5.2: Admin/Premium Application (`apps/admin_app`)
- **Subphase 5.2.1: Admin App (`apps/admin_app`): Interactive QR Studio, Scannability Sim & TrustQR Signer**
  - **Time Budget**: 45 minutes
  - **Assigned Agents**: `frontend-agent`, `uiux-agent`, `security-agent`
  - **Objectives & Deliverables**:
    - Implement the Admin App **QR Creation & Customization Studio**: 15-format structured payload forms, artistic module/eye shape selector, color & gradient editor, center logo uploader, branded template presets, live `ScannabilitySimulator` gauge, `TrustQR` Ed25519 signing toggle, and instant PNG/SVG/PDF export.
  - **Acceptance Criteria & Completion Evidence**:
    - Every customization control updates the rendered QR canvas and scannability score in real time and exports valid, decodable files.

- **Subphase 5.2.2: Admin App: Batch Generator, Analytics Dashboard, RBAC Guard & Multi-Pane Workspace**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `frontend-agent`, `security-agent`, `testing-agent`
  - **Objectives & Deliverables**:
    - Implement Admin Batch QR Generator Studio (CSV/JSON import -> bulk styled QR generation & round-trip verification), Universal Scanner tab, Fleet & Analytics Dashboard tab, Offline Vault & Collections tab, and Cryptographic RBAC Session Guard verifying `role: admin` entitlement token.
  - **Acceptance Criteria & Completion Evidence**:
    - `flutter test --coverage` passes 100% with `>= 95%` coverage in `apps/admin_app`, including negative tests confirming non-admin tokens are locked out of `admin_app`.

---

### STAGE 6: Cross-Platform Packaging, GitHub Actions CI/CD Matrix & End-to-End Verification

#### Phase 6.1: Cross-Platform Native Runners & Automated GitHub Actions Build/Release Matrix
- **Subphase 6.1.1: Cross-Platform Native Runner Configs & Standalone Packaging Scripts (5 OS Targets)**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `devops-agent`, `frontend-agent`
  - **Objectives & Deliverables**:
    - Configure native platform directories (`android`, `ios`, `windows`, `linux`, `macos`) for both `apps/user_app` and `apps/admin_app` with distinct application IDs (`com.universalqr.user` vs `com.universalqr.admin`), app names, permissions, and window sizing constraints.
    - Create `scripts/package_artifact.ps1` and `scripts/package_artifact.sh` to assemble standalone, non-nested downloadable artifacts with embedded `INSTALL.md`, `BUILD_METADATA.json`, and `.sha256` checksums.
  - **Acceptance Criteria & Completion Evidence**:
    - Platform configurations validated and packaging scripts verified locally.

- **Subphase 6.1.2: GitHub Actions CI/CD Workflows (Full Matrix + On-Demand App/Platform Selector)**
  - **Time Budget**: 35 minutes
  - **Assigned Agents**: `devops-agent`, `architect-agent`
  - **Objectives & Deliverables**:
    - Implement `.github/workflows/ci-quality-gate.yml` (binary isolation audit, analyzer, full test suite, `>=95%` coverage enforcement, RBAC security suite).
    - Implement `.github/workflows/build-release-matrix.yml` supporting both full builds and `workflow_dispatch` inputs (`target_app`: `all|admin_app|user_app`, `target_platform`: `all|android|ios|windows|linux|macos`, `build_mode`: `release|debug|profile`, `publish_release`: `true|false`), uploading standalone artifacts without nested ZIP archives.
  - **Acceptance Criteria & Completion Evidence**:
    - Workflow YAML schema and matrix filter logic verified via automated workflow validator tests.

#### Phase 6.2: Comprehensive End-to-End, Security, Performance & Documentation Final Audit
- **Subphase 6.2.1: Full-Ecosystem E2E Tests, `>=95%` Coverage Audit, RBAC Audit & Native Build Validation**
  - **Time Budget**: 40 minutes
  - **Assigned Agents**: `testing-agent`, `security-agent`, `performance-agent`
  - **Objectives & Deliverables**:
    - Execute the master verification harness across all packages, `services/rbac_api`, `apps/user_app`, and `apps/admin_app`.
    - Run native release build validation on the host platform and verify standalone artifact output, checksums, and `>= 95%` aggregate test coverage.
  - **Acceptance Criteria & Completion Evidence**:
    - 100% test pass rate across all suites, `>= 95%` coverage verified, native artifact built and validated.

- **Subphase 6.2.2: Complete Documentation Suite (`USER_GUIDE`, `SECURITY`, `INSTALL`) & Release Sign-Off**
  - **Time Budget**: 30 minutes
  - **Assigned Agents**: `docs-agent`, `architect-agent`
  - **Objectives & Deliverables**:
    - Complete `docs/SECURITY.md`, `docs/TESTING.md`, `docs/USER_GUIDE.md`, `docs/ONBOARDING.md`, and `docs/INSTALL.md`.
    - Perform final Git commit hygiene check, append final sign-off to `CHANGELOG.md` and `TODO.md`, and mark all 24 subphases `VERIFIED` in `docs/PROGRESS_TRACKER.md`.
  - **Acceptance Criteria & Completion Evidence**:
    - All documentation links, coverage reports, and build artifacts verified end-to-end.
