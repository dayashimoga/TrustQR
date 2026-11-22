# Changelog — Universal QR Code Scanner & Generator Platform

> **Policy**: This file is an **append-only** historical ledger. Never delete or overwrite prior entries.

---

## [0.1.0-subphase.6.2.2] - 2026-11-22

### Added
- **Complete Documentation Suite (`USER_GUIDE`, `SECURITY`, `INSTALL`, `TESTING`, `ONBOARDING`) & Platform Release Sign-Off**:
  - **Security & Threat Defense Architecture Specification (`docs/SECURITY.md`)**:
    - Comprehensive threat model covering IDN homograph attacks, malicious protocol handlers, IP obfuscation, high-abuse TLDs, URL shorteners, Wi-Fi configuration exploits, and fake QR credentials.
    - Zero-Trust Threat Firewall deep-dive: heuristic inspection rules, 0-100 safety scoring, quarantine enforcement, and 150-vector adversarial corpus validation (0 false negatives, 0.0133 ms latency).
    - Ed25519 `TrustQR` cryptographic specification (RFC 8032): envelope structure, digital signature verification, timestamp anti-replay, and institutional key authority.
    - Compile-time binary isolation invariant formalization and server-side asymmetric entitlement token architecture (`services/rbac_api`).
    - Offline encrypted vault HMAC-SHA256 integrity verification, auto-purge privacy retention policies, and administrative audit trail non-repudiation.
  - **Automated Testing & Coverage Verification Guide (`docs/TESTING.md`)**:
    - Complete test matrix across all 8 monorepo packages, services, and applications (33 test suites, 570 tests passing, 0 failures).
    - Monorepo coverage ledger documenting **98.03% aggregate coverage** (10,642 / 10,856 lines covered), with every component exceeding the mandatory `>=95.0%` line coverage gate.
    - Guides for unit, widget, integration, adversarial benchmark, RBAC penetration, and E2E test execution.
  - **Platform User & Administrator Guide (`docs/USER_GUIDE.md`)**:
    - End-user operational manual for `Universal QR Scanner` (`apps/user_app`): viewfinder reticle HUD, multi-source ingestion (camera, gallery, files, multi-QR batch vision), Threat Firewall alerts, TrustQR verified badge, and personal encrypted vault management.
    - Administrator manual for `Universal QR Admin Studio` (`apps/admin_app`): RBAC token unlock, 15 structured payload formats, artistic customizer (presets, shapes, gradients, logos), live Scannability Simulator, TrustQR signer, multi-format export (PNG 300 DPI, SVG, PDF, BMP), high-throughput batch generator, fleet telemetry dashboard, and HMAC-SHA256 verified audit trail.
  - **Developer Onboarding & Contribution Guide (`docs/ONBOARDING.md`)**:
    - Toolchain setup (Flutter, Dart, C++, Xcode, Android SDK), monorepo architecture, compile-time binary isolation enforcement, running apps locally, and automated quality gate workflows.
  - **Cross-Platform Installation & Binary Distribution Guide (`docs/INSTALL.md`)**:
    - Platform-specific deployment guides for Android (APK), iOS (IPA/Runner), Windows (standalone ZIP / EXE), Linux (GTK3 desktop bundle), and macOS (universal Apple Silicon / Intel bundle).
    - Detached SHA-256 checksum verification instructions and standalone non-nested artifact layout specification.
  - **Automated Documentation Suite Auditor (`scripts/verify_documentation_suite.dart`)**:
    - 27 automated validation rules inspecting mandatory file existence, byte size thresholds, and cross-link resolution.
  - **Master Verification Gate Orchestrator (`scripts/verify_subphase_6_2_2.ps1`)**:
    - Orchestrated 6 master gates passing 100%: Binary Isolation (Gate 1), Native Runners (Gate 2, 47/47), CI/CD Workflows (Gate 3, 26/26), Monorepo Static Analysis (Gate 4, 0 issues), Ecosystem Coverage (Gate 5, 98.03%), and Documentation Suite (Gate 6, 27/27).
  - **Full Platform Release Milestone**:
    - All 24 subphases across 6 stages and 12 phases successfully completed and verified.

---

## [0.1.0-subphase.6.2.1] - 2026-11-22

### Added
- **Full-Ecosystem E2E Tests, Master Coverage Audit (98.03%), RBAC Audit & Native Build Validation**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-verified that `apps/user_app` remains 100% physically and compile-time isolated from `packages/qr_generator_engine` and `packages/qr_admin_analytics`. Binary isolation audit script passed with 0 violations.
  - **User App End-to-End Integration Journey (`apps/user_app/test/e2e/user_e2e_journey_test.dart`)**:
    - Journey 1: Live QR decoding of deceptive URL (`http://paypa1-update.com/login`), Zero-Trust Threat Firewall heuristic classification (ThreatLevel.high, safety score 25), quarantine alert, and encrypted vault recording.
    - Journey 2: Institutionally signed Ed25519 `TrustQR` payload decoding, cryptographic signature verification with public key registry, verified badge attribution, encrypted vault persistence, and multi-criteria FTS search retrieval.
    - Journey 3: High-throughput batch multi-QR ingestion (10 distinct payloads across URL, Wi-Fi, vCard, Email, OTP), automated categorization, tag filtering, and instant vault collection aggregation.
  - **Admin App End-to-End Integration Journey (`apps/admin_app/test/e2e/admin_e2e_journey_test.dart`)**:
    - Journey 1: Interactive QR Studio payload authoring (Wi-Fi, vCard, Crypto, OTP), artistic styling (Obsidian Stealth preset, dot modules, leaf eyes, dual-color gradients), real-time Scannability & Contrast Simulator execution (Michelson/WCAG 18.2:1 contrast ratio, 100% scannability score), and multi-format export pipeline (PNG 32-bit, SVG XML, print PDF).
    - Journey 2: Institutional Ed25519 `TrustQR` keypair generation, structured vCard signing, cryptographic signature embedding, canonical URI formatting, and round-trip verification badge check.
    - Journey 3: High-throughput batch generator executing 5-item batch run (URL, PlainText, Wi-Fi, Geo, Email), individual scannability scoring, pure-Dart PKZIP archive assembly, and detached SHA-256 fingerprint generation.
    - Journey 4: Server-side RBAC entitlement token validation (`admin` vs `user` vs `unauthenticated`), multi-pane navigation (`studio`, `batch`, `analytics`, `audit`, `settings`), fleet telemetry dashboard sync, and HMAC-SHA256 verified audit trail.
  - **Master Ecosystem Coverage Aggregator (`scripts/verify_ecosystem_coverage.dart`)**:
    - Audited all 8 monorepo packages, services, and applications against the mandatory `>=95.0%` line coverage gate:
      - `packages/qr_core`: 97.83% (1,530 / 1,564 lines hit)
      - `packages/qr_scanner_engine`: 99.31% (1,433 / 1,443 lines hit)
      - `packages/qr_generator_engine`: 98.37% (1,571 / 1,597 lines hit)
      - `packages/qr_design_system`: 99.19% (737 / 743 lines hit)
      - `packages/qr_admin_analytics`: 98.92% (912 / 922 lines hit)
      - `services/rbac_api`: 98.06% (455 / 464 lines hit)
      - `apps/user_app`: 97.58% (1,696 / 1,738 lines hit)
      - `apps/admin_app`: 96.77% (2,308 / 2,385 lines hit)
      - **AGGREGATE ECOSYSTEM TOTAL**: **98.03% line coverage** (10,642 / 10,856 lines covered across 8 components). All 8 components strictly surpass the `>=95.0%` quality gate.
  - **Master Verification Gate Orchestrator (`scripts/verify_subphase_6_2_1.ps1`)**:
    - Gate 1: Compile-time binary isolation audit (100% passed).
    - Gate 2: Native runner configuration auditor (47/47 rules passed).
    - Gate 3: GitHub Actions CI/CD workflow auditor (26/26 rules passed).
    - Gate 4: Monorepo static analysis (`flutter analyze --fatal-infos --fatal-warnings .` — 0 issues found).
    - Gate 5: Master ecosystem coverage audit (98.03% aggregate coverage, all 8 modules >=95%).
    - Gate 6: Full-ecosystem E2E journeys (7/7 tests passed).
    - Gate 7: Standalone non-nested packaging and release checksums (10/10 standalone archives & SHA-256 manifests verified).

---

## [0.1.0-subphase.6.1.2] - 2026-11-22

### Added
- **GitHub Actions CI/CD Workflows (Full Matrix + On-Demand App/Platform Selector)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-verified that `apps/user_app` remains 100% physically and compile-time isolated from `packages/qr_generator_engine` and `packages/qr_admin_analytics`. Binary isolation audit script passed with 0 violations.
  - **Comprehensive CI Quality Gate & Security Enforcement (`.github/workflows/ci-quality-gate.yml`)**:
    - Automatic triggers on `push` and `pull_request` to `main`, plus manual `workflow_dispatch`.
    - Gate 1: Compile-time binary isolation audit preventing forbidden dependency bleed.
    - Gate 2: Cross-platform native runner configuration auditor verifying application IDs, display names, and sandboxed entitlements.
    - Gate 3: Monorepo static analysis (`flutter analyze --fatal-infos --fatal-warnings .`).
    - Gate 4: Security threat firewall verification using the 150-vector adversarial corpus and server-side RBAC penetration suite.
    - Gate 5: Automated test suites across all packages, backend services, and applications enforcing the mandatory `>=95%` line coverage gate with `lcov`.
    - Gate 6: Standalone non-nested packaging pipeline verification.
  - **Full Matrix & On-Demand Release Workflow (`.github/workflows/build-release-matrix.yml`)**:
    - Dual triggers: release tags (`v*`) and selective `workflow_dispatch` executions.
    - Interactive dispatch inputs:
      - `target_app`: `all`, `admin_app`, `user_app`.
      - `target_platform`: `all`, `android`, `ios`, `windows`, `linux`, `macos`.
      - `build_mode`: `release`, `debug`, `profile`.
      - `publish_release`: boolean switch for automated GitHub Releases.
    - Architectural preflight governance gate (`preflight-audit`) running on `ubuntu-latest` before any platform compilation begins.
    - Multi-runner platform matrix:
      - `windows-latest`: Windows x64 native compilation & packaging via `scripts/package_artifact.ps1`.
      - `ubuntu-latest`: Linux x64 (GTK3/CMake/Ninja) & Android APK builds via `scripts/package_artifact.sh`.
      - `macos-latest`: Apple universal builds (macOS desktop bundle & iOS app bundle) via `scripts/package_artifact.sh`.
    - Standalone artifact upload via `actions/upload-artifact@v4` with zero nested ZIP archives.
    - Automated release aggregation job (`publish-release`) packaging standalone archives, detached `.sha256` checksum manifests, and master `SHA256SUMS.txt` into GitHub Releases via `softprops/action-gh-release@v2`.
  - **Automated Workflow Schema Validator (`scripts/verify_github_workflows.dart`)**:
    - 26 strict automated validation rules inspecting triggers, input schemas, runner mappings, preflight dependencies, packaging calls, and release publishing steps.
  - **Master Verification Gate (`scripts/verify_subphase_6_1_2.ps1`)**:
    - Orchestrated 6 verification gates (Binary Isolation, Native Runners, GitHub Workflows, Static Analysis, Standalone Packaging, and Monorepo Regression Test Suites) passing 100%.

---

## [0.1.0-subphase.6.1.1] - 2026-11-22

### Added
- **Cross-Platform Native Runner Configs & Standalone Packaging Scripts (5 OS Targets)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-verified that `apps/user_app` remains 100% physically and compile-time isolated from `packages/qr_generator_engine` and `packages/qr_admin_analytics`. Binary isolation audit script passed with 0 violations.
  - **Native Platform Runner Configurations (`apps/user_app` & `apps/admin_app`)**:
    - Configured native runner directories across all 5 operating systems: Android, iOS, Windows, Linux, and macOS.
    - **Distinct Application Identifiers**:
      - User App: Android `applicationId = "com.universalqr.user"`, iOS `PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user;`, macOS `PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user`, Linux `set(APPLICATION_ID "com.universalqr.user")`.
      - Admin App: Android `applicationId = "com.universalqr.admin"`, iOS `PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin;`, macOS `PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin`, Linux `set(APPLICATION_ID "com.universalqr.admin")`.
    - **Display Names & Window Branding**:
      - User App: Display name "Universal QR Scanner" across Android manifest, iOS Info.plist, macOS Info.plist/AppInfo, Windows main.cpp/Runner.rc, and Linux GTK header bar / title.
      - Admin App: Display name "Universal QR Admin" across Android manifest, iOS Info.plist, macOS Info.plist/AppInfo, Windows main.cpp/Runner.rc, and Linux GTK header bar / title.
    - **Permissions & Sandboxed Entitlements**:
      - Android: `CAMERA`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `INTERNET`, plus `WRITE_EXTERNAL_STORAGE` on Admin App for export pipelines.
      - iOS: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` strings for camera and screenshot inspection.
      - macOS: `NSCameraUsageDescription` in Info.plist; sandboxed runtime entitlements (`com.apple.security.device.camera`, `com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write`) in `Release.entitlements` and `DebugProfile.entitlements`.
    - **Window Sizing Constraints**:
      - User App: Default 1200x750 desktop layout on Windows and Linux.
      - Admin App: Default 1280x850 desktop layout on Windows and Linux for multi-pane studio & analytics workspaces.
  - **Standalone Non-Nested Artifact Packaging Pipeline (`scripts/package_artifact.ps1`, `scripts/package_artifact.sh`)**:
    - Assembles standalone, non-nested downloadable archives (ZIP for Windows/Android/iOS; TAR.GZ for Linux/macOS) with direct root-level payload extraction.
    - Automatically embeds customized `INSTALL.md` with OS-specific installation, permissions, and launch steps.
    - Automatically embeds `BUILD_METADATA.json` capturing commit SHA, UTC build timestamp, application ID, target platform, build mode, security role scope, and packaging schema.
    - Generates standalone `<archive>.sha256` checksum manifests for release integrity verification.
    - Supports selective or full matrix packaging (`-TargetApp all|user_app|admin_app`, `-TargetPlatform all|windows|linux|macos|android|ios`, `-BuildMode release|debug|profile`).
  - **Automated Verification Harness (`scripts/verify_native_runner_configs.dart`, `scripts/verify_subphase_6_1_1.ps1`)**:
    - Created `scripts/verify_native_runner_configs.dart` with 47 automated rules covering existence, bundle IDs, app labels, permissions, and sandboxed entitlements across all 5 platforms.
    - Created `scripts/verify_subphase_6_1_1.ps1` orchestrating 5 strict verification gates:
      - Gate 1: Compile-Time Binary Isolation Audit (PASS).
      - Gate 2: Native Runner Configuration Auditor (47/47 rules pass).
      - Gate 3: Monorepo Static Analysis (0 errors, 0 warnings, 0 infos).
      - Gate 4: Standalone Packaging Pipeline Test (10/10 archives & SHA-256 manifests verified).
      - Gate 5: Regression Test Suites (100% pass rate: 132/132 tests in user_app & admin_app).

---

## [0.1.0-subphase.5.2.2] - 2026-11-22

### Added
- **Admin App: Batch Generator, Analytics Dashboard, RBAC Guard & Multi-Pane Workspace (`apps/admin_app`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-verified that `apps/user_app` does not import or depend on `packages/qr_generator_engine` or `packages/qr_admin_analytics`. Binary isolation audit script passed with 0 violations.
  - **Cryptographic RBAC Entitlement Guard (`lib/src/state/auth_controller.dart`, `lib/src/views/rbac_guard_view.dart`)**:
    - Pure-Dart Ed25519 cryptographic token issuance, validation, and session lifecycle management.
    - Strict `UserRole` enforcement: allows `UserRole.admin` access while intercepting `UserRole.user` or unauthenticated sessions.
    - Futuristic cyber access denial screen featuring shield icon, reason banner, quick operator sign-in, user simulation test button, and custom token validation dialog.
  - **Adaptive Multi-Pane Navigation Shell (`lib/src/state/admin_nav_controller.dart`, `lib/src/views/admin_shell_view.dart`)**:
    - Multi-pane workspace navigation managing 5 distinct admin consoles: QR Studio, Batch Generator, Fleet Analytics, Audit Trail, and Admin Settings.
    - Dual responsive layout utilizing `AdaptiveWorkspaceShell`: compact navigation bar for mobile/tablet and wide persistent navigation rail for desktop/laptop.
    - Integrated operator identity card, active role badge (`ADMIN`), and session termination action in top app bar.
  - **High-Throughput Batch QR Generator (`lib/src/state/batch_controller.dart`, `lib/src/views/batch_generator_view.dart`)**:
    - Dual ingestion pipeline supporting structured CSV and JSON input with syntax validation and line error diagnostics.
    - 3 enterprise preset loaders: Corporate Asset Tags, Employee Security Badges, and Branch Office Wi-Fi Stations.
    - Automated batch generation with individual scannability scoring via `ScannabilitySimulator` (WCAG contrast, module dimensions, warning flags).
    - Multi-format archive export pipeline (PNG, SVG, PDF) packaging generated codes into pure-Dart uncompressed/deflate PKZIP archives with SHA-256 fingerprint verification card.
  - **Executive Fleet Telemetry & Threat Dashboard (`lib/src/state/analytics_controller.dart`, `lib/src/views/analytics_dashboard_view.dart`)**:
    - Direct integration with `AdminAnalyticsFacade` populated with multi-device telemetry across 15 QR payload formats and 5 OS platforms.
    - 4 high-level KPI summary cards: Total Scans, Total Generations, Active Fleet Devices, and Threats Mitigated.
    - Interactive time-series bar chart with hourly/daily/weekly aggregation and automated anomaly markers.
    - 15-format distribution breakdown bars and threat risk severity histogram (0.0 to 1.0).
    - Malicious domain intelligence table highlighting high-risk targets (`malicious-pay.top`, `phishing-credential-harvest.ru`, etc.).
    - Fleet device management card with remote token revocation, device quarantine, and restoration actions.
    - Canonical export toolbar triggering instant downloads of unified JSON telemetry and 4 canonical CSV reports.
  - **Cryptographic HMAC-SHA256 Audit Trail Browser (`lib/src/views/audit_trail_view.dart`)**:
    - Administrative action history viewer with tamper-detection verification button evaluating cryptographic HMAC-SHA256 integrity chains.
    - Real-time search filter by action type or actor identifier.
    - Detailed event inspection cards with actor metadata, timestamp stamps, and full cryptographic SHA-256 integrity hashes.
  - **Admin Security & Settings Console (`lib/src/views/admin_settings_view.dart`)**:
    - Operator session profile with signed token preview and expiration countdown.
    - Institutional trust anchor card displaying active Ed25519 issuer identity and base64 public key fingerprint.
    - System security posture status card verifying binary isolation, token signing, and tamper detection.
    - Interactive penetration testing simulation controls: switch to restricted user role, simulate token expiration, and sign out.
  - **Comprehensive Verification Suite (`scripts/verify_subphase_5_2_2.ps1`)**:
    - 79 passing automated unit, widget, and integration tests across `apps/admin_app` (100% pass rate).
    - **96.77% line coverage** (2,308 / 2,385 lines hit across `apps/admin_app`), exceeding the mandatory `>= 95.0%` quality gate.
    - 0 static analyzer issues across the entire monorepo (`flutter analyze --fatal-infos --fatal-warnings .`).
    - 100% physical and cryptographic binary isolation confirmed by automated checks.

---

## [0.1.0-subphase.5.2.1] - 2026-11-22

### Added
- **Admin App: Interactive QR Studio, Scannability Simulator & TrustQR Signer (`apps/admin_app`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-verified that `apps/user_app` does not import or depend on `packages/qr_generator_engine` or `packages/qr_admin_analytics`. Binary isolation audit script passed with 0 violations.
  - **15-Format Structured Payload Creation Forms (`lib/src/widgets/payload_forms/*`)**:
    - `PayloadFormDispatcher`: Dynamic form routing for all 15 supported formats (`url`, `wifi`, `vcard`, `mecard`, `geo`, `event`, `email`, `sms`, `tel`, `otp`, `upi`, `epc`, `crypto`, `gs1`, `plainText`).
    - Raw manual payload override switch allowing administrators to inject custom or raw QR data strings directly into the matrix.
    - Specialized input controllers with real-time payload generation, format validation, and immediate studio canvas synchronization.
  - **Artistic QR Customization Studio (`lib/src/widgets/artistic_customization_panel.dart`)**:
    - 4 branded presets: `cyberpunkNeon`, `corporateNavy`, `emeraldTrust`, and `highContrastMono`.
    - 6 custom module shape selectors: `square`, `circle`, `roundedSquare`, `diamond`, `dot`, `hexagonal`.
    - 4 error correction levels (`L` ~7%, `M` ~15%, `Q` ~25%, `H` ~30%).
    - Custom eye frame and pupil shape pickers (`square`, `rounded`, `circle`, `diamond`, `cyberGrid`).
    - Solid and multi-stop gradient modes (`linear`, `radial`) with gradient angle slider (0°–360°) and interactive color swatches.
    - Embedded center logo toggle with quiet zone cutout and logo size ratio adjustment (5%–30%).
  - **Live Scannability & Contrast Simulator (`lib/src/widgets/scannability_simulator_card.dart`)**:
    - Real-time scannability score gauge (0%–100%) with status badge (`OPTIMAL`, `ACCEPTABLE`, `DEGRADED`, `CRITICAL`).
    - Scientific contrast metrics: WCAG contrast ratio (with AAA/AA compliance badges) and Michelson contrast index.
    - Module count, version, and logo occlusion percentage calculation.
    - 5 simulated environmental stress test bars: Studio Light, Glare & Reflection, Dim & Low-Light, 30° Off-Axis Tilt, and Defocus Blur.
    - Actionable automated warnings and corrective recommendations (e.g., contrast boosting, logo scaling, error correction elevation).
  - **Cryptographic TrustQR Ed25519 Signer (`lib/src/widgets/trust_qr_signer_card.dart`)**:
    - Institutional authority signing toggle wrapping raw QR matrices into cryptographic `TrustQrEnvelope` containers (`trustqr://v1?...`).
    - Configurable issuer identifier (`auth.qrscanner.corp`) and cryptographic key ID (`ed25519-key-2026`).
    - Pure-Dart deterministic Ed25519 keypair regeneration with instantaneous public key fingerprint inspection.
    - Live verified signature status badge and copyable canonical signed payload URI.
  - **Live Preview Canvas & Multi-Format Exporter (`lib/src/widgets/qr_studio_preview_canvas.dart`)**:
    - High-fidelity `CustomPaint` engine rendering real-time matrix modules, gradient fills, styled eye frames/pupils, and embedded logo quiet cutouts.
    - Multi-format export toolbar: 300 DPI PNG, scalable vector SVG XML, print-ready PDF-1.4, and 24-bit raw BMP.
    - Visual export notification banner with file size and timestamp confirmation.
    - Collapsible ASCII matrix diagnostics for terminal debugging and low-level matrix inspection.
  - **Responsive Dual-Layout Workspace (`lib/src/views/studio_workspace_view.dart`)**:
    - Wide-screen multi-column desktop layout (canvas on left, configuration accordion on right for viewports >= 950px).
    - Compact vertical layout with auto-scroll and overflow protection for mobile/tablet viewports (< 950px).
    - Cyber-precision glassmorphic aesthetics, neon accents, and interactive fleet telemetry summary dialog.
  - **Automated Verification Gate (`scripts/verify_subphase_5_2_1.ps1`)**:
    - 4-step quality gate: Binary Isolation, Static Analysis (`0 errors, 0 warnings, 0 infos`), 29/29 tests passing (100%), and **97.04% line coverage** (1,114 / 1,148 lines hit across `apps/admin_app`).

## [0.1.0-subphase.5.1.2] - 2026-11-22

### Added
- **Admin Analytics & Fleet Governance Verification Suite (`packages/qr_admin_analytics`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Re-audited and strictly confirmed compile-time isolation invariant: `apps/user_app` is 100% physically isolated from `packages/qr_admin_analytics` and `packages/qr_generator_engine`.
    - Negative breach detection self-test passed cleanly (`dart run scripts/verify_binary_isolation.dart`).
  - **High-Density Fleet Governance & Lifecycle Stress Suite (`test/fleet_governance_stress_test.dart`)**:
    - Simulated fleet environment of 1,200 hardware devices across Android, iOS, Windows, Linux, and macOS platforms.
    - Verified ingestion of 1,200 concurrent telemetry heartbeats recording scan volumes and security threats.
    - Simulated 3,000 TrustQR tokens issued across multiple regional cryptographic authorities (`auth_us_east`, `auth_eu_central`, `auth_ap_south`).
    - Benchmarked batch cryptographic token revocation of compromised authorities (1,000 tokens revoked simultaneously in < 50 ms).
    - Verified individual device revocation, unrevocation/restoration, and query filtering by OS and role.
    - Tested registry edge cases: non-existent device/token queries, double-revocation idempotency, and zero-match batch revocations.
  - **Time-Series Anomaly & Timeline Stress Suite (`test/time_series_anomaly_stress_test.dart`)**:
    - Simulated 365-day transaction timeline with 100-day zero-activity gap to verify continuous gap-padding without off-by-one errors.
    - Tested extreme outlier injection (650-volume spike with 100 threats) and validated z-score anomaly detection ($|x_i - \mu|/\sigma \ge \text{threshold}$).
    - Verified peak volume and peak timestamp tracking across `daily`, `weekly`, and `monthly` aggregation intervals.
    - Evaluated boundary conditions: zero generations (scan-only ratio = 1.0), zero scans (generation-only ratio = 0.0), and 100% threat detection rates.
  - **Adversarial Audit Log Tampering Pen-Tests (`test/adversarial_audit_tamper_test.dart`)**:
    - 12-vector adversarial attack test suite verifying that HMAC-SHA256 integrity verification rejects all unauthorized mutations:
      1. *Vector 1*: Action string tampering (`REVOKE_DEVICE` -> `UNREVOKE_DEVICE`).
      2. *Vector 2*: Actor ID forgery (`admin@secops.corp` -> `attacker@evil.corp`).
      3. *Vector 3*: Actor role privilege escalation (`admin` -> `super_root`).
      4. *Vector 4*: Target resource spoofing (`device_rogue_01` -> `device_critical_db_server`).
      5. *Vector 5*: Details dictionary payload tampering (quarantine level mutation & injected backdoor keys).
      6. *Vector 6*: IP address spoofing (`192.168.10.55` -> `10.0.0.99`).
      7. *Vector 7*: Microsecond timestamp alteration (+1 ms shift).
      8. *Vector 8*: Single bit-flip attack on the 64-character hexadecimal HMAC signature.
      9. *Vector 9*: Truncated / malformed hex signature attack.
      10. *Vector 10*: Signature replay attack between distinct valid log entries.
      11. *Vector 11*: Anti-chronological timestamp rollback attack breaching chronological ledger integrity.
      12. *Vector 12*: Public key substitution attack with untrusted cryptographic key pair.
  - **Canonical Exporter Fuzzing & Schema Validation (`test/canonical_export_fuzz_test.dart`)**:
    - Fuzz-tested RFC 4180 CSV escaping for fields with embedded quotes, commas, multiline line breaks (`\n`, `\r\n`), and international Unicode characters (Japanese Kanji, Hindi Devanagari, emojis).
    - Verified graceful generation of empty datasets across all 4 CSV exports (Time Series, Payload Distribution, Threat Firewall, Fleet Inventory).
    - Tested payload distribution edge cases (100% single format, 15-way even split).
    - Validated deterministic SHA-256 canonical report fingerprint reproducibility over 500 iterations and single-byte mutation sensitivity.
  - **Automated Verification Gate (`scripts/verify_subphase_5_1_2.ps1`)**:
    - 4-step quality gate: Binary Isolation, Static Analysis (`0 errors, 0 warnings, 0 infos`), 46/46 unit/integration/stress tests passing (100%), and **98.92% line coverage** (912 / 922 lines hit).

---

## [0.1.0-subphase.5.1.1] - 2026-11-22

### Added
- **Admin Analytics Engine: Fleet Telemetry, Usage Insights, Threat Intelligence & Reports (`packages/qr_admin_analytics`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Strictly verified `apps/user_app` maintains zero compile-time or runtime dependencies on `qr_admin_analytics`.
    - Automated negative breach test suite verified with 100% pass rate (`scripts/verify_binary_isolation.dart`).
  - **Time-Series Aggregation & Anomaly Detection (`lib/src/time_series/*`)**:
    - `TimeSeriesBucketInterval`: Support for continuous zero-padded buckets across `hourly`, `daily`, `weekly`, and `monthly` intervals with UTC boundary truncation, stepwise incrementation, and human-readable labeling.
    - `TimeSeriesPoint`: Encapsulates `scanCount`, `generationCount`, `threatCount`, total volume, threat rate percentage, moving average, and anomaly flag.
    - `TimeSeriesMetrics`: Aggregated summary statistics including average volume per bucket, sample standard deviation $\sigma$, peak volume with timestamp, and anomalous buckets list.
    - `TimeSeriesAggregator`: Ingests vault items and generation timestamps, constructs continuous gap-padded timeline buckets, computes Simple Moving Average (SMA), and flags anomalous activity via z-score statistical thresholding ($|x_i - \mu|/\sigma \ge \text{threshold}$).
  - **15-Format Payload Distribution Breakdown (`lib/src/breakdown/*`)**:
    - `PayloadDistribution`: Aggregated count and percentage breakdown for all 15 supported QR payload formats (`url`, `wifi`, `vcard`, `mecard`, `geo`, `event`, `email`, `sms`, `tel`, `otpauth`, `upi`, `epc`, `crypto`, `gs1`, `plainText`). Detects top format and top non-URL format.
    - `PayloadDistributionCalculator`: Computes distribution from vault item collections or incrementally recorded telemetry events.
  - **Threat Intelligence & Risk Histograms (`lib/src/security/*`)**:
    - `ThreatAnalyticsSummary`: Consolidated security overview capturing safe, caution, suspicious, and critical scan volumes, overall threat detection rate, and average safety score.
    - Risk score histogram compiling counts across 5 discrete risk buckets (`0-19`, `20-39`, `40-59`, `60-79`, `80-100`).
    - Attack category mapping: Classifies threats into Phishing / Social Engineering, URL Shortener Cloaking, IDN Homograph / Spoofing, SSRF / Local Network Probe, Dangerous URI Scheme, Insecure Wi-Fi Network, Algorithmic DGA Domain, and custom threat flags.
    - Top malicious domains ranking sorted descending by detection frequency.
    - `ThreatAnalyticsEngine`: Analyzes vault item lists or live inspection streams.
  - **Fleet Hardware & TrustQR Token Lifecycle Registry (`lib/src/fleet/*`)**:
    - `FleetDevice`: Hardware device record with OS, app version, registration timestamp, last active timestamp, activity counters, and revocation status.
    - `TrustQrTokenRecord`: Cryptographic token record tracking subject, `UserRole` (admin/user), issuer authority, issue/expiration timestamps, validity, and revocation status.
    - `FleetRegistry`: In-memory registry supporting device registration, telemetry heartbeat tracking, single/batch device revocation, unrevocation, token enrollment, and multi-criteria batch token revocations by issuer, role, or expiry.
    - `FleetSummary`: Real-time fleet metrics consolidating active/revoked device counts, active/revoked/expired token counts, and OS breakdown.
  - **Tamper-Evident Cryptographic Audit Trail (`lib/src/audit/*`)**:
    - `AuditLogEntry`: Verifiable administrative audit entry (`id`, `timestamp`, `action`, `actorId`, `actorRole`, `targetId`, `details`, `ipAddress`, `integrityHash`).
    - Deterministic canonical bytes serialization and HMAC-SHA256 signing and verification using `CryptoPrivateKey` and `CryptoPublicKey`.
    - `AuditLogFilter`: Multi-criteria query filter supporting action, actor role, actor ID, target ID, date ranges, and keyword search with `copyWith`.
    - `AuditLogEngine`: Signs and logs administrative actions, supports paginated queries, and provides comprehensive cryptographic and chronological integrity verification (`verifyAll()`).
  - **Consolidated Reporting & Multi-Format Exporters (`lib/src/reports/*`)**:
    - `AnalyticsReport`: Consolidates time-series metrics, payload distribution, threat summary, fleet summary, and audit log count with an automated cryptographic SHA-256 fingerprint.
    - `AnalyticsReportExporter`: Pure-Dart exporter generating:
      1. Deterministic JSON (raw or formatted).
      2. Time-series bucket CSV with moving averages and anomaly flags.
      3. 15-format payload distribution breakdown CSV.
      4. Comprehensive threat firewall audit summary CSV with category breakdown, risk histogram, and top malicious domains.
      5. Fleet registered hardware devices and TrustQR tokens inventory CSV with RFC 4180 escaping.
      6. Canonical SHA-256 fingerprint generator for arbitrary exported reports.
  - **Unified Administrative Facade (`lib/src/admin_analytics_facade.dart`)**:
    - `AdminAnalyticsFacade`: Coordinates telemetry ingestion, threat analysis, fleet hardware/token tracking, cryptographic audit logs, and report exports into a cohesive interface.
  - **Automated Verification Harness (`scripts/verify_subphase_5_1_1.ps1`)**:
    - 4-step automated gate executing binary isolation audit, monorepo static analysis, full automated test suite, and line coverage check.
    - Quality Gates: **99.02% line coverage** (913 / 922 lines hit), 26/26 tests passing (100%), 0 static analyzer issues (`flutter analyze --fatal-infos --fatal-warnings .`).

---

## [0.1.0-subphase.4.2.2] - 2026-11-22

### Added
- **Restricted User App: Offline Vault, Smart Collections, Privacy Mode & Isolation Gate (`apps/user_app`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Strictly verified `apps/user_app` has zero compile-time or runtime dependencies on `qr_generator_engine` or `qr_admin_analytics`.
    - Automated negative breach test suite verified with 100% pass rate (`scripts/verify_binary_isolation.dart`).
  - **Vault State Coordinator (`apps/user_app/lib/src/state/vault_controller.dart`)**:
    - Reactive `ChangeNotifier` state coordinator wrapping `QrVault`.
    - Manages filtered items list, user collections, unique tag vocabulary, multi-selection state, metrics, and tamper detection audits.
    - Full-text search and multi-criteria filter dispatch: `searchQuery`, `isFavorite`, `threatLevels`, `payloadTypes`, `collectionId`, `tags`, and `sortBy`.
    - Item mutation and cryptographic routines: `toggleFavorite`, `deleteItem`, `deleteSelected`, `updateTitle`, `updateNotes`, `setTags`, `assignCollection`, and `verifyIntegrity`.
    - Collection management routines: `createCollection`, `deleteCollection` (with optional cascade deletion).
    - Cryptographic data management: `exportSelectedOrAllToJson`, `importFromJson`, `purgeHistory`, `clearAllHistory`, and `updatePrivacyPolicy`.
  - **Offline Vault View (`apps/user_app/lib/src/views/vault_view.dart`)**:
    - Full-text search bar querying title, raw payload content, notes, and tags in real time with quick clear button.
    - Quick category filter chips: All, Favorites, Safe, Caution/Threat.
    - Dynamic tag carousel displaying all unique tags across the vault with toggleable filter selection.
    - Sort selector supporting Newest First, Oldest First, Title (A-Z), and Safety Score (High).
    - Multi-selection batch action bar displaying selected count with Select All, Deselect, Export Selected to JSON, and Delete Selected actions.
    - Rich item card components displaying payload format icon, title/summary, format pill, timestamp, threat score badge, TrustQR badge, collection indicator, and instant favorite toggle.
    - Empty state view handling both unpopulated vault and zero-match search/filter conditions with clear filters action.
  - **Smart Collections View (`apps/user_app/lib/src/views/collections_view.dart`)**:
    - Folder management interface rendering collection cards with color-coded accent badges, descriptions, and dynamic record counts.
    - Interactive "New Collection" modal dialog with name, description, and multi-color accent picker (Cyan, Emerald, Amber, Crimson, Purple, Electric Blue).
    - "View Records" action filtering Vault view to the target collection.
    - Deletion dialog supporting folder deletion with option to preserve or purge contained records.
    - Empty state card with quick creation action.
  - **Record Detail & Cryptographic Inspector Modal (`apps/user_app/lib/src/widgets/vault_item_detail_modal.dart`)**:
    - `CyberGlassSheet` inspection modal displaying full item attributes with favorite toggle and close actions.
    - Prominent Cryptographic HMAC-SHA256 Integrity Verification banner displaying green "INTACT // UNTAMPERED" or red "SECURITY ALERT: TAMPERED RECORD // INVALID SIGNATURE".
    - Threat overview card featuring `ThreatScoreGauge`, semantic `CyberBadge`, and `TrustQrBadge` institutional authority card.
    - Raw payload box with selectable monospace text and clipboard copy action.
    - Comprehensive metadata grid (Record ID, Origin, Created timestamp, Updated timestamp).
    - Collection assignment dropdown selector.
    - Interactive tag manager with chip deletion and new tag addition input.
    - User notes editor with persistent encrypted note saving.
    - Single-record deletion action with confirmation.
  - **Security, Privacy & Settings View (`apps/user_app/lib/src/views/settings_view.dart`)**:
    - Appearance & Accessibility card: High-Contrast Theme (WCAG AAA 21:1) toggle.
    - Privacy & Retention card: Privacy Incognito Mode switch, Auto-Purge History retention threshold selector (Disabled, 7 Days, 30 Days, 90 Days), Preserve Favorites on Purge switch, "Purge Expired Scans Now" action, and "Clear All Scan History" action with danger confirmation dialog.
    - Cryptographic Backup & Portability card: "Export Vault (JSON)" modal with copy-to-clipboard, and "Restore Vault (JSON)" modal with paste input, overwrite toggle, and HMAC-verified import results.
    - Security Posture & RBAC Entitlement card: Displays Role: `RESTRICTED USER`, Binary Isolation: `VERIFIED // ZERO GENERATOR`, Scanner Engine: `ACTIVE`, Generator Studio: `COMPILE-TIME EXCLUDED`, and Admin Analytics: `COMPILE-TIME EXCLUDED`.
  - **Application Shell & Secondary Inspector Integration (`apps/user_app/lib/main.dart`)**:
    - Configured 4 primary workspace tabs: Scanner (`scan`), Vault (`vault`), Collections (`collections`), and Settings (`settings`).
    - Wired search shortcut (`Ctrl+F` / `Cmd+F`) to navigate directly to the Vault tab.
    - Secondary inspector pane updated with live encrypted vault statistics (Total Records, Favorites, Collections, and Tampered Audit status) alongside firewall engine status and action dispatch log.
- **Quality Gates & Coverage**:
  - Achieved **97.58% line coverage** (1696 / 1738 lines hit) across `apps/user_app`.
  - 100% test pass rate across 89 unit, widget, and integration tests (`apps/user_app/test/*`).
  - 0 static analysis errors, warnings, or infos across entire monorepo (`flutter analyze --fatal-infos --fatal-warnings .`).
  - 100% compile-time binary isolation confirmed (`dart run scripts/verify_binary_isolation.dart`).
  - Automated verification script: `scripts/verify_subphase_4_2_2.ps1`.

---

## [0.1.0-subphase.4.2.1] - 2026-11-22

### Added
- **Restricted User App Core (`apps/user_app`)**:
  - **Compile-Time Binary Isolation Invariant**:
    - Strictly verified `apps/user_app` has zero compile-time or runtime dependencies on `qr_generator_engine` or `qr_admin_analytics`.
    - Automated negative breach tests pass with 100% enforcement (`scripts/verify_binary_isolation.dart`).
  - **Live Scanner Viewfinder & Workspace (`apps/user_app/lib/src/views/scanner_workspace_view.dart`)**:
    - Live HUD viewfinder with `HudScannerReticle` displaying laser sweep animation and state transition feedback (idle, scanning, safe, warning, threat).
    - Top telemetry bar with live firewall operational status, camera torch/flashlight toggle, and privacy incognito mode toggle (bypassing vault storage).
    - Bottom control dock featuring image file decoder button, batch multi-QR button, and manual payload text input with instant inspection.
    - Responsive layout handling across compact, medium, and expanded desktop breakpoints without flex overflow.
  - **Zero-Trust Threat Firewall HUD Modal (`apps/user_app/lib/src/widgets/threat_hud_modal.dart`)**:
    - Interactive modal sheet presenting real-time safety score gauge (0–100), security threat rating (`safe`, `caution`, `suspicious`, `critical`), and heuristic telemetry breakdown (phishing signatures, dangerous URI schemes, URL shorteners, IP obfuscation).
    - Cryptographic TrustQR authenticity section displaying Ed25519 institutional verification badge with issuer name, key ID, and timestamp.
    - Quarantine Protection Active guard: blocks execution of high-risk payloads by default with user-acknowledgment checkbox override.
    - Save-to-Vault and Dismiss actions with immediate reactive UI state update.
  - **Multi-QR Candidate Picker (`apps/user_app/lib/src/widgets/multi_qr_picker_dialog.dart`)**:
    - Candidate selection modal when multiple QR codes are detected within a single image or composite document.
    - Index telemetry markers (`#1`, `#2`, ...), payload type badges, safety score indicators, and one-tap candidate selection.
  - **Context-Aware Payload Action Card (`apps/user_app/lib/src/widgets/payload_action_card.dart`)**:
    - Dedicated rendering and action button dispatchers across all 15 supported payload types:
      - `UrlPayload`: "Open Safe Link" (with quarantine guard) and "Copy URL".
      - `WifiPayload`: "Connect Network" (with quarantine guard) and "Copy Password".
      - `VCardPayload` & `MeCardPayload`: "Save Contact" and "Copy Details".
      - `OtpAuthPayload`: "Copy Code" (TOTP/HOTP secret).
      - `UpiPaymentPayload`: "Pay via UPI" (with quarantine guard) and "Copy VPA".
      - `EpcPaymentPayload`: "Copy IBAN".
      - `CryptoPaymentPayload`: "Copy Address".
      - `GeoPayload`: "Open in Maps" and "Copy Coordinates".
      - `EmailPayload`: "Compose Email" and "Copy Email".
      - `SmsPayload`: "Send SMS" and "Copy Number".
      - `TelPayload`: "Call" and "Copy Number".
      - `EventPayload`: "Add Event" and "Copy Details".
      - `Gs1DigitalLinkPayload`: "Lookup GS1" and "Copy GTIN".
      - `PlainTextPayload`: "Copy Content".
  - **State Controller (`apps/user_app/lib/src/state/scanner_controller.dart`)**:
    - Central `ChangeNotifier` coordinating `ScanToVaultPipeline`, viewfinder HUD state, active threat inspection results, multi-QR candidate list, torch/flashlight toggle, and incognito mode.
    - Methods: `scanRawString`, `scanImageBuffer`, `scanFileBytes`, `scanMultiQrBuffer`, `selectMultiQrCandidate`, `dismissActiveResult`, `toggleTorch`, `toggleIncognito`, and `saveCurrentToVault`.
- **Quality Gates & Coverage**:
  - Achieved **99.32% line coverage** (734 / 739 lines hit) across `apps/user_app`.
  - 100% test pass rate across 40 unit, widget, and integration tests (`apps/user_app/test/*`).
  - 0 static analysis errors, warnings, or infos across entire monorepo (`flutter analyze --fatal-infos --fatal-warnings .`).
  - 100% compile-time binary isolation confirmed (`dart run scripts/verify_binary_isolation.dart`).
  - Automated verification script: `scripts/verify_subphase_4_2_1.ps1`.

---

## [0.1.0-subphase.4.1.2] - 2026-11-22

### Added
- **Multi-Language Localization Engine (`packages/qr_design_system/lib/src/l10n/cyber_localizations.dart`)**:
  - **Comprehensive Multi-Language Dictionaries**:
    - Full localization across 6 global languages: English (`en`), Spanish (`es`), French (`fr`), German (`de`), Hindi (`hi`), and Japanese (`ja`).
    - Localized translations for:
      - Application and brand titles (`appName`, `adminAppTitle`, `userAppTitle`).
      - Scanner reticle HUD states (`reticleIdle`, `reticleScanning`, `reticleSafe`, `reticleWarning`, `reticleThreat`, `scanPrompt`, `laserSweepActive`).
      - Threat safety scores and rating categories (`threatScore`, `threatSecure`, `threatCaution`, `threatCritical`, `threatScoreReading`).
      - Cryptographic TrustQR authenticity labels (`trustQrVerified`, `trustQrInvalid`, `trustQrIssuer`, `trustQrKeyId`, `trustQrIssuedAt`).
      - Navigation items (`navScanner`, `navGenerator`, `navVault`, `navAnalytics`, `navSettings`, `navBatch`, `navHistory`, `navFavorites`).
      - Primary action buttons (`buttonScan`, `buttonGenerate`, `buttonExport`, `buttonSave`, `buttonCancel`, `buttonCopy`, `buttonOpenUrl`, `buttonShare`, `buttonRetry`, `buttonClose`, `buttonQuarantine`).
      - Vault storage and search placeholders (`vaultSearchPlaceholder`, `vaultFilterAll`, `vaultExportJson`, `vaultImportJson`, `vaultClearHistory`, `vaultItemDeleted`).
      - WCAG screen reader accessibility hints (`a11yScannerReticle`, `a11yScannerReticleHint`, `a11yThreatGauge`, `a11yThreatGaugeHint`, `a11yTrustBadge`, `a11yTrustBadgeHint`, `a11yLoading`, `a11yHighContrastActive`, `a11yReducedMotionActive`).
  - **Flutter Localization Integration**:
    - `CyberLocalizations.delegate` (`LocalizationsDelegate<CyberLocalizations>`) with synchronous future loading.
    - `CyberLocalizations.supportedLocales` list of 6 supported locales.
    - Graceful English fallback mechanism for unsupported locale codes or missing keys.
- **Centralized Accessibility & WCAG Utilities (`packages/qr_design_system/lib/src/accessibility/cyber_accessibility.dart`)**:
  - `CyberAccessibility.isReducedMotion(context)`: Automatically respects system animation settings (`MediaQuery.disableAnimations` and `accessibleNavigation`).
  - `CyberAccessibility.isHighContrast(context)`: Detects OS-level high contrast requests (`MediaQuery.highContrast`).
  - `CyberAccessibility.resolveDuration(context, normalDuration)`: Collapses transition durations to `Duration.zero` when reduced motion is requested.
  - `CyberAccessibility.announce(context, message)`: Desktop/multi-window compatible screen reader announcement service via `SemanticsService.sendAnnouncement` and `View.of(context)`.
  - `CyberAccessibility.wrapButton(...)` and `wrapLiveRegion(...)`: Accessibility semantic helpers for buttons and dynamic live regions.
- **High-Contrast Theme System (`packages/qr_design_system/lib/src/tokens/cyber_theme.dart`)**:
  - `CyberTheme.highContrastDark()`: Pure black background (`#000000`), pure white high-contrast text (`#FFFFFF`, contrast ratio 21:1 exceeding WCAG AAA), bold 2.5px borders (`CyberTokens.borderWidthBold`), and saturated neon accents.
  - `CyberTheme.highContrastLight()`: Pure white background (`#FFFFFF`), pure black text (`#000000`, contrast ratio 21:1), and bold 2.5px black borders.
  - `CyberTheme.resolve(context)`: Dynamic theme selector respecting context accessibility settings.
- **Accessible Widget Enhancements**:
  - `HudScannerReticle`: Wrapped in `Semantics(liveRegion: true, label: ..., value: ..., hint: ...)` with dynamic status announcement across all 5 states; pauses continuous laser sweep animations and draws static center guide when reduced motion is active.
  - `ThreatScoreGauge`: Wrapped in `Semantics` exposing exact numerical score and verbal safety rating; skips cubic animation curve for instant display when reduced motion is active.
  - `TrustQrBadge`: Full accessibility description of cryptographic signature status and institutional authority in compact and expanded card modes.
  - `CyberButton`: Interactive button semantics with tooltip integration, disabled state indicators, and explicit loading announcement (`$label, loading`).
  - `CyberGlassCard`: Screen reader button semantics and custom accessibility labels when interactive (`onTap`).
- **Quality Gates & Coverage**:
  - Achieved **99.19% line coverage** (737 / 743 lines hit) across `packages/qr_design_system`.
  - 100% test pass rate across 64 unit and widget tests (`packages/qr_design_system/test/*`).
  - 0 static analysis errors, warnings, or infos across entire monorepo (`flutter analyze --fatal-infos --fatal-warnings .`).
  - 100% compile-time binary isolation confirmed (`dart run scripts/verify_binary_isolation.dart`).
  - Automated verification script: `scripts/verify_subphase_4_1_2.ps1`.

---

## [0.1.0-subphase.4.1.1] - 2026-11-22

### Added
- **Cyber-Precision Design Tokens & Themes (`packages/qr_design_system`)**:
  - **Color Palette & Accents** (`lib/src/tokens/cyber_colors.dart`):
    - Obsidian dark canvas (`#070A0F`), deep slate surface cards (`#0F172A`, `#1E293B`), and slate border sheens (`#334155`).
    - Alabaster light theme surfaces (`#F8FAFC`, `#FFFFFF`, `#CBD5E1`).
    - Neon semantic accent shaders: neon cyan (`#00F5FF`), emerald safe (`#00FF88`), amber caution (`#FFB800`), crimson critical threat (`#FF3366`), neon purple (`#B026FF`), and electric blue (`#0066FF`).
    - Multi-tiered text typography colors and glassmorphic translucent sheens.
  - **High-Tech Typography System** (`lib/src/tokens/cyber_typography.dart`):
    - Complete `TextTheme` for display, title, body, and label hierarchies across dark and light modes.
    - Specialized `monospace` typography for telemetry coordinates, cryptographic hashes, and token display.
  - **Tokens & Themes** (`lib/src/tokens/cyber_tokens.dart`, `lib/src/tokens/cyber_theme.dart`):
    - Corner radii (`radiusXs` to `radiusPill`), glassmorphic blur sigmas (`glassBlurSm` to `glassBlurLg`), border widths, spacing scales, and neon glow box shadows.
    - Complete Material 3 `CyberTheme.dark()` and `CyberTheme.light()` ThemeData with CardThemeData, NavigationBarThemeData, NavigationRailThemeData, and AppBarThemeData.
- **Glassmorphic Components (`packages/qr_design_system`)**:
  - **Frosted Glass Container Card** (`lib/src/glass/cyber_glass_card.dart`):
    - Translucent container with real `BackdropFilter` Gaussian blur (`ImageFilter.blur`), subtle border sheens, optional outer neon glow, and interactive ripple feedback (`onTap`).
  - **Glassmorphic Sheet & Modal Container** (`lib/src/glass/cyber_glass_sheet.dart`):
    - Frosted container with top drag handle, header title, trailing action slot, and backdrop blur for threat alerts and modal workflows.
- **Interactive HUD Scanner Reticle (`packages/qr_design_system`)**:
  - **Target Tracking Reticle** (`lib/src/reticle/hud_scanner_reticle.dart`):
    - Animated viewport with 4 glowing corner tracking brackets drawn with `CustomPainter`.
    - Continuous laser sweep scanline animation with gradient beam glow driven by an internal `AnimationController`.
    - Subtle crosshair target ticks at center.
    - Dynamic state transitions across 5 HUD states: `idle` (cyan steady), `scanning` (cyan laser sweep), `safe` (emerald green glow), `warning` (amber warning), and `threat` (crimson quarantine alarm).
    - Status telemetry indicator tag with glowing pulse indicator dot.
- **Specialized Cyber Components (`packages/qr_design_system`)**:
  - **Futuristic Action Button** (`lib/src/widgets/cyber_button.dart`):
    - 4 style variants (`primary`, `secondary`, `danger`, `outline`) with hover/active neon glow, accessibility semantics, and integrated loading spinner.
  - **Semantic Status Badge** (`lib/src/widgets/cyber_badge.dart`):
    - Pill or square badge with semantic color tiers (`neutral`, `safe`, `warning`, `threat`, `info`, `accent`) and optional pulsing dot indicator.
  - **Animated Safety Score Gauge** (`lib/src/widgets/threat_score_gauge.dart`):
    - Circular arc progress gauge animating from 0 to 100 with 3 color tiers: `SECURE` ($\ge 80$), `CAUTION` ($50–79$), and `CRITICAL` ($< 50$).
  - **TrustQR Cryptographic Authenticity Badge** (`lib/src/widgets/trust_qr_badge.dart`):
    - Authenticity badge supporting full card mode (displaying institution name, key ID, and verified status) and compact pill mode.
- **Adaptive Responsive Layouts & Workspace Shell (`packages/qr_design_system`)**:
  - **Form-Factor Breakpoints** (`lib/src/layout/responsive_layout.dart`):
    - Compact mobile (`< 600px`), medium tablet (`600px – 1024px`), and expanded desktop (`> 1024px`) with `ResponsiveBuilder` and `ResponsiveLayout.value(...)`.
  - **Adaptive Workspace Shell** (`lib/src/layout/adaptive_workspace_shell.dart`):
    - Automatically switches layout:
      - Mobile: Bottom `NavigationBar` with destination badges and action buttons.
      - Tablet: Left `NavigationRail` and split-view layout (`secondaryPane`).
      - Desktop: Full 240px navigation sidebar with headers and status badges, central workspace, and optional 360px inspector pane.
    - Keyboard shortcut bindings for desktop productivity: `Ctrl/Cmd+O` (Open), `Ctrl/Cmd+S` (Scan/Save), `Ctrl/Cmd+F` (Search), `Ctrl/Cmd+G` (Generate), and `Ctrl+1..9` (tab switching).
- **Quality Gates & Automated Verification**:
  - Authored comprehensive test suite in `packages/qr_design_system/test/`: `cyber_theme_test.dart`, `glassmorphic_widgets_test.dart`, `hud_reticle_test.dart`, `cyber_components_test.dart`, and `adaptive_workspace_test.dart` (37 tests).
  - Achieved **98.99% line coverage** (587 / 593 lines hit) across `packages/qr_design_system`.
  - Created automated gate script `scripts/verify_subphase_4_1_1.ps1` verifying 0 static analysis errors/warnings/infos, 37/37 tests passing, and 100% binary isolation.

---

## [0.1.0-subphase.3.2.2] - 2026-11-22

### Added
- **Real-Time Scannability & Contrast Simulator (`packages/qr_generator_engine`)**:
  - **Comprehensive Diagnostics & Contrast Analysis** (`lib/src/simulator/scannability_simulator.dart`):
    - Exact Michelson contrast ratio calculation $(L_{max} - L_{min}) / (L_{max} + L_{min})$ alongside WCAG 2.1 contrast ratio.
    - Environmental lighting and stress condition simulation: standard studio, high surface glare wash-out (35% contrast reduction), low-light sensor noise floor, 30° perspective tilt, and distance optical blur.
    - Diagnostic warning flags: `CRITICAL_LOW_CONTRAST`, `SUBOPTIMAL_CONTRAST`, `EXCESSIVE_LOGO_OCCLUSION`, `HIGH_LOGO_OCCLUSION`, and `INSUFFICIENT_QUIET_ZONE`.
    - Actionable engineering recommendations guiding contrast, logo dimensions, and quiet zone adjustments.
    - Full JSON serialization and deserialization for `ScannabilityReport` and `SimulatedEnvironmentScore`.
- **Pure-Dart High-DPI PNG Exporter (`packages/qr_generator_engine`)**:
  - **ISO/IEC 15948 Compliant PNG Writer** (`lib/src/export/png_exporter.dart`, `lib/src/export/crc32.dart`):
    - Standards-compliant 8-byte signature, `IHDR` (32-bit RGBA color type 6), `pHYs` chunk with customizable DPI conversion (e.g. 300 DPI = 11,811 pixels/meter), and `IDAT` scanline chunk with filter type 0 and zlib deflation.
    - Pure-Dart standard CRC-32 (IEEE 802.3 / ISO 3309) calculation engine with precomputed 256-word lookup table.
    - End-to-end round-trip scannability verified via `ImageFileDecoder` and `UniversalQrScannerEngine`.
- **Resolution-Independent Vector SVG Exporter (`packages/qr_generator_engine`)**:
  - **Scalable Vector Graphics Writer** (`lib/src/export/svg_exporter.dart`):
    - Produces clean XML `<svg>` with `<defs>` supporting multi-stop linear and radial gradients.
    - Vector primitives for all 6 module shapes: `square` (rect), `rounded` (rect with rx/ry fillets), `dots` (circle), `diamond` (polygon), `liquid` (connected rects), and `cyberGrid` (faceted octagon polygon).
    - Vector finder patterns with custom outer frames (`square`, `rounded`, `circle`, `squircle`, `hexagonal`) and pupils (`square`, `rounded`, `circle`, `diamond`).
    - Embedded logo cutout rendering with optional background box and vector `<path>` integration.
- **Print-Ready Vector PDF Document Exporter (`packages/qr_generator_engine`)**:
  - **ISO 32000-1 (%PDF-1.4) Vector Generator** (`lib/src/export/pdf_exporter.dart`):
    - Zero-dependency pure-Dart vector PDF generator supporting standard Helvetica and Helvetica-Bold typefaces.
    - 3 print-ready layouts:
      - `singleLabel`: 4x4 inch (288x288 pt) centered QR label with title and URL subtitle.
      - `stickerSheet`: Letter (612x792 pt) 3x4 grid with 12 border-delimited stickers and titles.
      - `badgeCard`: CR80 credit-card / attendee badge (3.375 x 2.125 inches = 243x153 pt) with top event header bar and attendee credentials.
    - Complete cross-reference table (`xref`), trailer dictionary, and `%%EOF` structuring.
- **High-Performance Batch Exporter & PKZIP 2.0 Container (`packages/qr_generator_engine`)**:
  - **Multi-Format Batch Processor & Archiver** (`lib/src/export/batch_exporter.dart`):
    - Asynchronous batch dispatch across PNG, SVG, PDF, and BMP formats with progress callbacks and item-level error isolation.
    - Automatic `manifest.json` generation within the bundle documenting timestamps, formats, item requests, and status counts.
    - Pure-Dart PKZIP 2.0 writer (`toZipArchive`) producing standard ZIP archives with Local File Headers, Central Directory Headers, and End of Central Directory records.
    - CSV parser (`exportFromCsv`) supporting headers (`id,content,title,templateId`) or single-column URLs.
    - JSON parser (`exportFromJson`) supporting list or object formats.
- **Scanner Engine PNG Decoding Support (`packages/qr_scanner_engine`)**:
  - Extended `ImageFileDecoder.decodeFileBytes` to recognize PNG signature `0x89 0x50 0x4E 0x47`, parse `IHDR` and `IDAT` chunks, decompress scanlines via `zlib.decode`, and return standard `ImageBuffer`.
- **Quality Gates & Automated Verification**:
  - Authored comprehensive test suite in `packages/qr_generator_engine/test/export_and_simulator_test.dart` (30 new tests).
  - Achieved **98.37% line coverage** (1,571 / 1,597 lines hit) across `packages/qr_generator_engine`.
  - Created automated gate script `scripts/verify_subphase_3_2_2.ps1` verifying 0 static analysis errors/warnings/infos, 67/67 tests passing in generator, 94/94 in scanner, and 100% binary isolation.

---

## [0.1.0-subphase.3.2.1] - 2026-11-22

### Added
- **Admin-Only Artistic QR Matrix Encoder (`packages/qr_generator_engine`)**:
  - **ISO/IEC 18004 QR Matrix Encoder** (`lib/src/encoder/qr_encoder.dart`):
    - Multi-mode bitstream encoding supporting Numeric (10-bit/3-digit), Alphanumeric (11-bit/2-char), and Byte (8-bit UTF-8) modes.
    - Automatic version selection (versions 1 through 10, extensible to 40) based on payload size and selected error correction level.
    - Reed-Solomon Error Correction encoding for all 4 standard levels: Low (7%), Medium (15%), Quartile (25%), High (30%).
    - Function pattern generation: 7x7 finder patterns, 1-module separators, horizontal and vertical timing patterns, alignment patterns for versions $\ge 2$, dark module, format info (BCH 15, 5 masked with `0x5412`), and 18-bit version info blocks for versions $\ge 7$.
    - Dynamic mask pattern evaluation implementing all 8 standard masks with ISO/IEC 18004 penalty formulas ($N_1$ adjacent runs, $N_2$ 2x2 blocks, $N_3$ 1:1:3:1:1 finder-like patterns, $N_4$ balance penalty) to automatically select optimal mask.
  - **Reed-Solomon Codeword Engine & Galois Field Arithmetic** (`lib/src/encoder/qr_polynomial.dart`, `lib/src/encoder/qr_version.dart`):
    - Pure-Dart Galois Field $GF(2^8)$ arithmetic with primitive polynomial `0x11D` (285), exponential/logarithm lookup tables, inversion, multiplication, and division.
    - Polynomial operations: multiplication, degree extraction, evaluation, and generator polynomial synthesis $g(x) = \prod_{i=0}^{n-1} (x - \alpha^i)$.
    - Codeword interleaving across group 1 and group 2 blocks per ISO/IEC 18004 specifications.
  - **Artistic Module Styling & Shaders** (`lib/src/rasterizer/qr_matrix_rasterizer.dart`, `lib/src/rasterizer/qr_generated_image.dart`):
    - 6 artistic module shapes: `square`, `rounded` (subtle corner fillet), `dots` (circular modules), `diamond`, `liquid` (organic connected modules that intelligently bridge adjacent dark modules and fillet exterior corners), and `cyberGrid` (high-tech chamfered facets).
    - Custom finder eye frame shapes: `square`, `rounded`, `circle`, `squircle` (superellipse), `hexagonal`.
    - Custom finder eye pupil shapes: `square`, `rounded`, `circle`, `diamond`.
    - Independent frame and pupil coloring with automatic contrast fallbacks.
  - **Color & Gradient Engine** (`lib/src/style/qr_color_config.dart`):
    - Multi-stop linear gradients with customizable angle projection (0° to 360°).
    - Multi-stop radial gradients from matrix center outward.
    - Smooth 32-bit ARGB interpolation and WCAG 2.1 relative luminance and contrast ratio computation.
  - **Center Logo Cutout Engine** (`lib/src/style/qr_logo_config.dart`):
    - Safe logo occlusion ratio calculator and strict validation against error correction budgets (L: 5%, M: 12%, Q: 20%, H: 26%).
    - Quiet zone module padding and collision guard ensuring logos never encroach on finder patterns.
    - `carveLogoArea` matrix module classification with `QrModuleType.logoArea`.
  - **Branded Preset Templates** (`lib/src/style/qr_template.dart`):
    - `cyberpunkNeon`: cyberGrid modules with glowing cyan/neon magenta gradient on dark slate canvas.
    - `corporateNavy`: executive rounded modules in deep navy blue on crisp white.
    - `emeraldTrust`: cryptographic TrustQR styling with emerald and rich teal gradient.
    - `highContrastMono`: industrial high-contrast black-on-white square matrix.
    - `sunsetVibrant`: fluid liquid modules with warm sunset coral to rose gradient.
    - Comprehensive JSON serialization and deserialization for custom template persistence.
  - **Pure-Dart Uncompressed 24-bit BMP Exporter** (`lib/src/rasterizer/qr_generated_image.dart`):
    - Full binary generation of uncompressed 24-bit BMP images with standard BITMAPFILEHEADER and BITMAPINFOHEADER.
  - **Real-Time Scannability Evaluator** (`lib/src/engine/artistic_qr_generator_engine.dart`):
    - WCAG contrast assessment across solid and gradient stops.
    - Occlusion vs ECC budget risk scoring.
    - Shape focus penalty adjustments.
    - Actionable recommendations with composite score (0–100) and `isScannable` boolean verdict.
- **Round-Trip Decoding Verification & Test Suite**:
  - Authored comprehensive test suites in `packages/qr_generator_engine/test/artistic_generator_test.dart` and `qr_encoder_test.dart`.
  - **100% Round-Trip Scannability Verification**: Rendered styled QR matrices to `ImageBuffer` and decoded them with `UniversalQrScannerEngine` from `packages/qr_scanner_engine` across Numeric, Alphanumeric, Byte modes, liquid/rounded shapes, branded templates, logo cutouts (with Reed-Solomon data recovery), and BMP byte streams!
  - Enhanced `AdaptiveBinarizer` in `qr_scanner_engine` with dynamic range minimum threshold floor preventing solid dark clusters from falsely inverting.
  - **Quality Gates**: Achieved **98.70% line coverage** (908 / 920 lines hit) across `packages/qr_generator_engine`.
  - 100% of automated tests pass (37 / 37 in generator engine, 94 / 94 in scanner engine).
  - 0 static analysis errors, warnings, or infos across the entire monorepo (`flutter analyze --fatal-infos --fatal-warnings .`).
  - Strict compile-time binary isolation verified (`scripts/verify_binary_isolation.dart`).
  - Added automated verification script `scripts/verify_subphase_3_2_1.ps1`.

---

## [0.1.0-subphase.3.1.2] - 2026-11-22

### Added
- **Integrated Scan-to-Firewall-to-Vault Pipeline (`ScanToVaultPipeline`)**:
  - **Pipeline Orchestrator** (`packages/qr_scanner_engine/lib/src/pipeline/scan_to_vault_pipeline.dart`):
    - End-to-end integration coordinating raw string, image buffer, BMP file, and multi-QR decoding with `QrPayloadParser`, `QrThreatFirewall`, and offline `QrVault`.
    - Automatic TrustQR envelope detection and unwrapping of inner signed payload.
    - Zero-Trust security inspection scoring (0–100), risk classification, actionable findings, and `isAllowed` action guard.
    - Offline encrypted vault recording with HMAC-SHA256 cryptographic integrity hash verified on stored items.
    - Smart auto-categorization generating contextual tags (`#url`, `#https`, `#http`, `#wifi`, `#contact`, `#event`, `#location`, `#email`, `#sms`, `#phone`, `#crypto`, `#2fa`, `#payment`, `#trustqr`, `#verified`, `#tampered`, `#threat-*`) and derived human-readable titles.
    - Configurable duplicate suppression (`autoDeduplicate`) within `deduplicationWindow`, returning existing vault items without writing duplicate entries.
    - Quarantine guard (`blockVaultOnCriticalThreat`) preventing critical malicious payloads from being stored into vault history.
    - Streaming batch execution (`processBatchImagesStream`, `processBatchFilesStream`) and concurrent future execution (`processBatchImages`, `processBatchFiles`).
    - Configurable privacy retention enforcement (`purgeOnScan: true`).
  - **Pipeline Models & Options** (`lib/src/pipeline/pipeline_options.dart`, `lib/src/pipeline/pipeline_scan_result.dart`):
    - `PipelineOptions` with granular toggles, `copyWith`, and JSON serialization.
    - `PipelineScanResult` containing raw content, structured `QrPayload`, `ThreatAssessment`, persisted `QrVaultItem?`, deduplication flag, and precise latency metrics.
- **Decoding & Pipeline Performance Benchmarks** (`test/benchmark/pipeline_performance_benchmark_test.dart`):
  - **Frame Latency Benchmark**: Average frame decode + firewall + vault latency of **5.06 ms** (197 frames/sec), easily beating the `< 25.0 ms` quality gate target.
  - **Throughput Benchmark**: High-throughput pipeline processing exceeding **46,980 payloads/sec** (0.0213 ms / 21.3 µs per inspection), crushing the `> 5,000` target.
  - **Multi-QR Benchmark**: Multi-QR extraction and pipeline processing averaging **5.25 ms** per composite image.
- **Automated Test Suite & Quality Gates**:
  - Added `test/pipeline/scan_to_vault_pipeline_test.dart` (15 new integration tests).
  - Achieved **99.31% line coverage** (1433 / 1443 lines hit) across `packages/qr_scanner_engine`.
  - Created automated verification script `scripts/verify_subphase_3_1_2.ps1`.
  - Total 94 tests passing, 0 static analyzer issues across all 8 monorepo targets, and 100% binary isolation maintained.

---

## [0.1.0-subphase.3.1.1] - 2026-11-22

### Added
- **Universal QR Decoding Pipeline (`packages/qr_scanner_engine`)**:
  - **Raw Image Processing & Local Binarization** (`lib/src/image/image_buffer.dart`):
    - `ImageBuffer` supporting RGBA, BGRA, RGB, and Grayscale formats with luminance computation, 90-degree rotations, cropping, and memory pooling.
    - `AdaptiveBinarizer` implementing local 8x8 block thresholding (Otsu-adapted) that handles uneven lighting, shadows, and glares.
    - `BinarizedBitMatrix` with bit-packed storage and bit-inversion (`inverted()`) for dark-mode QR support.
  - **Galois Field & Reed-Solomon Error Correction** (`lib/src/decoder/galois_field.dart`):
    - Pure-Dart $GF(2^8)$ arithmetic using ISO/IEC 18004 primitive polynomial $x^8 + x^4 + x^3 + x^2 + 1$ (0x11D).
    - `ReedSolomonDecoder` with Berlekamp-Massey error locator polynomial solving, Chien root search, and Forney error evaluation with exact $b=0$ QR characteristic-2 correction.
  - **Format Information & Error Detection** (`lib/src/decoder/qr_format_info.dart`):
    - QR format information decoder with BCH(15, 5) error correction correcting up to 3 bit errors, masking with `0x5412`, and `decodeBestOfTwo` redundant sampling.
  - **ISO/IEC 18004 QR Matrix Decoding** (`lib/src/decoder/qr_matrix_decoder.dart`):
    - Unmasking all 8 standard QR patterns (0 through 7).
    - Zig-zag codeword reading excluding finder eyes, separators, timing patterns, and alignment patterns.
    - Reed-Solomon block de-interleaving and error correction across all standard block structures.
    - Payload mode decoding for Numeric, Alphanumeric, and Byte modes with UTF-8 decoding and Latin-1 fallback.
  - **Finder Pattern Vision Detection** (`lib/src/detector/finder_pattern.dart`, `lib/src/detector/qr_detector.dart`):
    - Sub-pixel center estimation with 1:1:3:1:1 module ratio verification.
    - Geometric triplet ordering (Top-Left, Top-Right, Bottom-Left) with cross-product orientation alignment.
    - `PerspectiveTransform` with unit square to quadrilateral projective mapping and sub-pixel grid sampling.
  - **Multi-QR Batch Matrix Vision** (`lib/src/detector/multi_qr_detector.dart`):
    - Simultaneous detection and decoding of multiple QR codes in a single high-resolution image.
    - Automatic dark-mode / inverted QR code detection fallback.
  - **Uncompressed BMP File Decoder & Test Pattern Generator** (`lib/src/image/image_file_decoder.dart`):
    - Pure-Dart standard BMP file decoder (24-bit, 32-bit, 8-bit palette) and encoder.
    - Synthetic standards-compliant QR Version 1 (21x21) bit matrix and composite multi-QR image generator.
  - **Background Isolate Offloading** (`lib/src/isolate/isolate_qr_decoder.dart`):
    - Offloads CPU-intensive image binarization, perspective grid sampling, and decoding to background Dart isolates (`Isolate.run`), preventing UI thread jank.
    - Graceful synchronous in-thread fallback for platforms or testing environments without isolate support.
  - **Universal Facade Engine** (`lib/src/engine/universal_qr_scanner_engine.dart`):
    - Single, unified API for decoding from raw strings, image buffers, file bytes, and batch collections.
    - Seamless Zero-Trust firewall inspection integrated into every scan decode result.
- **Automated Test Suite & Quality Gates**:
  - Added `packages/qr_scanner_engine/test/decoding_pipeline_test.dart` (44 new unit and pipeline tests).
  - Achieved **99.36% line coverage** (1237 / 1245 lines hit) across `packages/qr_scanner_engine`.
  - Created automated verification script `scripts/verify_subphase_3_1_1.ps1`.
  - Total 76 tests passing, 0 static analyzer issues across all 8 workspace targets, and 100% binary isolation maintained.

---

## [0.1.0-subphase.2.2.2] - 2026-11-22

### Added
- **Server-Side RBAC & Entitlement Authority** (`services/rbac_api`):
  - **Ed25519 Institutional Key Authority (`RbacConfig`)**:
    - Generates and manages the institutional Ed25519 keypair for issuing and verifying compact entitlement tokens and signing `TrustQR` envelopes.
    - Pre-configured user and admin credentials with role-scoped authority.
  - **In-Memory Thread-Safe State & Audit Store (`RbacStore`)**:
    - In-memory revoked token registry (`jti` tracking).
    - Append-only administrative audit log recording every authentication attempt, privilege check, QR generation, batch dispatch, template creation, and token revocation event.
    - Fleet analytics aggregation: scans recorded, threats blocked, generations executed, TrustQR envelopes issued, and service uptime.
    - Template repository pre-populated with default designs (*Cyberpunk Neon Matrix*, *Corporate Sleek Minimal*, *Institutional TrustQR Secure*).
  - **Authentication & RBAC Middleware (`RbacMiddleware`, `AuthenticatedContext`)**:
    - Validates incoming `Authorization: Bearer <token>` headers against server's public key.
    - Rejects malformed tokens, expired tokens, revoked tokens, rogue keys, and tampered signatures with HTTP 401.
    - Enforces `role: admin` and required scopes for all administrative and generation endpoints with HTTP 403.
  - **Controller Routing & API Endpoints (`RbacRouter`, `RbacServer`)**:
    - `GET /api/v1/health`: Public server health and uptime status.
    - `GET /api/v1/trustqr/keys`: Public institutional Ed25519 public key endpoint in JWK format.
    - `POST /api/v1/auth/token`: Exchanges valid credentials for an asymmetric `EntitlementToken`.
    - `POST /api/v1/auth/verify`: Verifies arbitrary entitlement tokens against server's public key and revocation list.
    - `POST /api/v1/auth/revoke`: Allows users to revoke their own token and admins to revoke any token.
    - `POST /api/v1/telemetry/scan`: Authenticated telemetry ingestion endpoint accessible to both `user` and `admin`.
    - `POST /api/v1/admin/qr/generate`: Admin-only single QR specification generation.
    - `POST /api/v1/admin/qr/batch`: Admin-only batch QR specification generation.
    - `POST /api/v1/admin/qr/sign`: Admin-only cryptographic TrustQR envelope signing with server's institutional key.
    - `GET /api/v1/admin/templates` & `POST /api/v1/admin/templates`: Admin-only branded template management.
    - `GET /api/v1/admin/analytics`: Admin-only fleet-wide scan, generation, and security analytics.
    - `GET /api/v1/admin/audit`: Admin-only append-only audit trail retrieval with self-auditing read events.
- **Automated Penetration & Security Test Suite** (`services/rbac_api/test/rbac_penetration_test.dart`):
  - 11 adversarial penetration attack vectors tested across all protected endpoints:
    1. Anonymous access rejection (HTTP 401 `AUTH_REQUIRED`).
    2. Invalid authorization scheme rejection (HTTP 401 `AUTH_INVALID_SCHEME`).
    3. Malformed and truncated token rejection (HTTP 401 `TOKEN_MALFORMED`).
    4. Signature tampering rejection (HTTP 401 `TOKEN_INVALID`).
    5. Privilege escalation via claim modification rejection (HTTP 401 `TOKEN_INVALID`).
    6. Expired token rejection (HTTP 401 `TOKEN_EXPIRED`).
    7. Revoked token rejection (HTTP 401 `TOKEN_REVOKED`).
    8. Rogue untrusted key rejection (HTTP 401 `KEY_MISMATCH`).
    9. Valid user role boundary enforcement (HTTP 403 `INSUFFICIENT_PERMISSIONS` on every admin route).
    10. Authorized admin capability execution (HTTP 200/201 on all endpoints).
    11. Input validation & bad request boundary testing (HTTP 400 `BAD_REQUEST`).
- **Quality Gates & Coverage**:
  - Achieved **98.06% line coverage** (455 / 464 lines hit) across `services/rbac_api`.
  - 100% of automated tests pass (60 / 60 tests).
  - 0 static analysis errors, warnings, or infos across all 8 monorepo targets.
  - Added `scripts/verify_subphase_2_2_2.ps1` for automated gate enforcement.

---

## [0.1.0-subphase.2.2.1] - 2026-11-22

### Added
- **Offline-First Vault Engine** (`packages/qr_core/lib/src/vault/qr_vault.dart`):
  - **CRUD Operations**: Record items, update notes/titles, assign/unassign collections, tag items, toggle favorites, and paginate with offset/limit.
  - **Cryptographic HMAC Integrity Guard**: Every stored record is signed with HMAC-SHA256 over its canonical data representation. The vault continuously audits stored records and flags external database or file tampering.
  - **Multi-Criteria Filter Engine (`QrVaultFilter`)**: Query by item origin (`scanned` vs `generated`), favorite flag, collection ID, multiple payload types, security threat levels, tags, and date ranges.
  - **Full-Text Search (FTS)**: Multi-word token matching across titles, raw payloads, notes, TrustQR issuers, and tag labels with case-insensitive matching.
  - **Collections Management (`QrCollection`)**: Dynamic collection folders with computed item counts and options to unlink vs cascading delete contained items.
  - **Tag Aggregation**: Multi-tag management, global tag listing, and tag frequency count aggregation.
  - **Privacy Auto-Purge Retention (`VaultPrivacyPolicy`)**: Automatic deletion of historical scanned items older than N days (configurable 30/60/90 days), with automatic exemption for favorited items.
  - **Incognito Mode**: Temporary scan evaluation that bypasses durable disk storage completely.
  - **JSON Export & Import Pipeline**: Formatted JSON export with schema metadata and robust import validation handling duplicates and verifying integrity signatures.
  - **Storage Persistence Adapters**:
    - `InMemoryVaultStorageAdapter`: Ultra-fast memory cache for ephemeral test suites and incognito sessions.
    - `FileJsonVaultStorageAdapter`: Cross-platform durable file persistence with atomic temp-file write-and-rename semantics preventing data corruption.
- **Automated Test Suite & Verification**:
  - Authored comprehensive test suite in `packages/qr_core/test/vault_test.dart` (64 total tests in `qr_core` passing 100%).
  - Achieved **97.83% line coverage** (1530 / 1564 lines hit) across `packages/qr_core`.
  - Added `scripts/verify_subphase_2_2_1.ps1` verifying binary isolation, 0 analyzer issues, test suite, and coverage.

---

## [0.1.0-subphase.2.1.2] - 2026-11-22

### Added
- **150-Vector Adversarial Benchmark Corpus** (`packages/qr_scanner_engine/test/adversarial/adversarial_corpus.dart`):
  - **Category 1 (Dangerous Schemes, 17 vectors)**: `javascript:`, `vbscript:`, `data:`, `file:`, `blob:`, `about:`, `chrome:`, `powershell:`, `ms-appx:`, `ms-settings:`, casing variations, and encoded script vectors.
  - **Category 2 (Credential Masquerades, 10 vectors)**: User:pass in authority masking destination hosts (`https://admin:pass@host/`).
  - **Category 3 (IDN Homographs & Punycode, 20 vectors)**: Cyrillic `а`, `е`, `о`, `р`, `с`, `х`, `у`, `і`, `ј`, Greek `ο`, `α`, `ρ`, `ν`, `xn--` punycode brand mimics, and percent-encoded Cyrillic.
  - **Category 4 (Raw IPs & SSRF Targets, 16 vectors)**: IPv4 loopback (`127.0.0.1`, `127.0.0.2`), localhost, IPv6 loopback (`::1`, `[::1]`), RFC 1918 Class A/B/C private subnets, AWS metadata (`169.254.169.254`), hex IP (`0x7f000001`), dword IP (`2130706433`), and public raw IPs.
  - **Category 5 (URL Shorteners, 12 vectors)**: 12 major URL shorteners masking redirect targets.
  - **Category 6 (Insecure HTTP Sensitive Channels, 10 vectors)**: Sensitive keyword paths (`login`, `auth`, `password`, `checkout`, `payment`, `wallet`, `admin`) over plaintext HTTP.
  - **Category 7 (Excessive Subdomains & DGA Phishing, 10 vectors)**: 5+ level subdomain chains and high-entropy algorithmic domain names (Shannon entropy > 3.4).
  - **Category 8 (Open-Redirect & Reflected Query Injections, 12 vectors)**: `redirect=`, `url=`, `dest=`, `next=`, `target=`, `goto=` open redirect parameters and reflected script injections (`q=javascript:alert(1)`, `<script>`, `onerror=`).
  - **Category 9 (Wi-Fi Vulnerabilities, 8 vectors)**: Open public hotspots, empty SSID traps, deprecated WEP encryption, and secure WPA2/WPA3 configurations.
  - **Category 10 (Contact, SMS & Tel Sanitization, 10 vectors)**: Insecure HTTP URLs in vCard/MeCard, CRLF header injection in SMS/Tel, and embedded script/command strings in plain text.
  - **Category 11 (TrustQR Cryptographic Integrity, 10 vectors)**: Authentic Ed25519 signatures, single-byte payload tampering, signature corruption, issuer tampering, timestamp tampering, unregistered institutional keys, and malformed envelopes.
  - **Category 12 (Benign Multi-Format Payloads, 15 vectors)**: Clean payloads across all 15 formats producing 100/100 safety score with zero false positives.
- **Threat Firewall Adversarial Verification Suite** (`packages/qr_scanner_engine/test/adversarial/adversarial_firewall_test.dart`):
  - Zero false-negative validation across all critical exploit vectors.
  - Zero false-positive validation on all benign vectors.
  - Sub-millisecond performance benchmark: **0.0133 ms (13.3 µs)** average heuristic latency (75,321 payloads/sec) and **17.1 ms** Ed25519 signature verification latency.
- **Quality Gates & Coverage**:
  - Achieved **100.00% line coverage** (220/220 lines hit) in `packages/qr_scanner_engine`.
  - Added `scripts/verify_subphase_2_1_2.ps1` enforcing binary isolation, 0 analyzer issues, test suite, and coverage.

---

## [0.1.0-subphase.2.1.1] - 2026-11-22

### Added
- **Zero-Trust QR Threat Firewall Engine** (`packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart`):
  - **Dangerous Scheme Blocker**: Halts execution of `javascript:`, `vbscript:`, `data:`, `file:`, `blob:`, `powershell:`, and local command schemes with immediate 0/100 safety score.
  - **IDN Homograph & Punycode Detector**: Identifies mixed Cyrillic/Greek lookalikes (e.g. `pаypal.com`) and `xn--` punycode masquerading.
  - **Raw IP & Obfuscation Inspection**: Flags dotted-quad IPs, hex-encoded IPs (`0x7f000001`), dword IPs, and internal RFC 1918 / localhost / SSRF targets (`192.168.1.1`, `10.0.0.1`, `127.0.0.1`, `localhost`).
  - **Credential Embedding Detector**: Traps phishing URLs with embedded basic authentication credentials (`user:pass@host`).
  - **URL Shortener Warning System**: Detects redirection intermediaries (`bit.ly`, `tinyurl.com`, `t.co`, etc.).
  - **Transport Security Heuristics**: Differentiates general plaintext HTTP from high-risk HTTP handling authentication, checkout, or account operations.
  - **High-Entropy DGA & Subdomain Depth Analysis**: Flags domain label entropy exceeding 3.4 Shannon bits and excessive nested subdomains (> 4).
  - **Wi-Fi Trap Inspection**: Flags open/unencrypted Wi-Fi hotspots and cryptographically broken WEP encryption.
  - **Integrated TrustQR Signature Verification**: Automatically validates Ed25519 institutional public keys, detects tampered payloads, and catches expired QR codes.
- **Threat Assessment Model (`ThreatAssessment`, `ThreatFinding`)**:
  - Deterministic 0–100 Safety Score, severity categorization (`SAFE`, `CAUTION`, `SUSPICIOUS`, `CRITICAL`), structured findings with remediation advice, and `isActionAllowed` guard.
- **Coverage & Test Harness**:
  - Achieved **96.13% line coverage** (149 / 155 lines hit) in `packages/qr_scanner_engine`.
  - Added `scripts/verify_scanner_engine_coverage.ps1` for automated coverage validation.

---

## [0.1.0-subphase.1.2.2] - 2026-11-22

### Added
- **Pure-Dart Ed25519 (RFC 8032) Cryptographic Engine** (`packages/qr_core/lib/src/crypto/ed25519_engine.dart`):
  - Curve25519 Edwards point arithmetic modulo $2^{255}-19$, scalar multiplication, point compression/decompression, and SHA-512 based signing and verification.
  - Zero external native C/C++ dependencies; 100% portable across Android, iOS, Windows, Linux, and macOS.
- **HMAC-SHA256 Cryptographic Engine** (`packages/qr_core/lib/src/crypto/hmac_engine.dart`):
  - Constant-time signature verification for symmetric cryptographic tokens.
- **TrustQR Institutional Envelope Protocol** (`packages/qr_core/lib/src/crypto/trust_qr_envelope.dart`):
  - Canonical envelope signing and verification preventing physical QR sticker overlay tampering.
  - URI format: `trustqr://v1?issuer=...&payload=...&created=...&keyId=...&alg=...&sig=...`.
  - Expiration enforcement, key ID mismatch detection, and tamper detection down to single-byte modifications.
- **Asymmetric Entitlement Token Engine** (`packages/qr_core/lib/src/crypto/entitlement_token.dart`):
  - Compact 3-part token issuance (`<header>.<claims>.<signature>`) and verification.
  - Server-side cryptographic role enforcement (`admin` vs `user`), scope hierarchy, expiration enforcement, and local tampering rejection.
- **Automated Cryptographic Test Suite**:
  - Added `packages/qr_core/test/crypto_test.dart` covering key generation, 1-bit tamper detection, length guards, expiration checks, and adversarial token manipulation.
  - Line coverage: **98.37%** (1029 / 1046 lines hit), exceeding the mandatory `>= 95%` quality gate.

---

## [0.1.0-subphase.1.2.1] - 2026-11-22

### Added
- **Multi-Format QR Payload Engine (15 Distinct Formats)** in `packages/qr_core`:
  - `UrlPayload`: RFC 3986 URL parsing, normalization, scheme validation, query parameter decomposition.
  - `WifiPayload`: WPA, WPA2, WPA3, WEP, and unencrypted network parsing with delimiter escaping (`\;`, `\:`, `\\`) and hidden network support.
  - `VCardPayload`: vCard 3.0/4.0 contact parsing, name components, multi-phone, multi-email, URL, address, and notes.
  - `MeCardPayload`: Compact MeCard format parsing and escaped delimiter normalization.
  - `GeoPayload`: WGS84 geographic coordinate parsing with altitude, bounds validation (-90..90, -180..180), and query tags.
  - `EventPayload`: iCalendar VEVENT format with UTC datetime serialization and start/end temporal ordering checks.
  - `EmailPayload`: `mailto:` and `MATMSG:` email formats with subject, body, and CC support.
  - `SmsPayload`: `sms:` and `smsto:` message formats with phone number validation.
  - `TelPayload`: Telephone URI parser and serializer.
  - `OtpAuthPayload`: RFC 6238 TOTP and RFC 4226 HOTP 2FA authenticator formats with Base32 secret validation, configurable digits (6/8), period, and counter.
  - `UpiPaymentPayload`: NPCI UPI payment format with virtual payment address (VPA) validation, payee name, amount, currency, and transaction references.
  - `EpcPaymentPayload`: European Payments Council (SEPA) QR code parser with BIC, recipient name, IBAN validation, and remittance info.
  - `CryptoPaymentPayload`: Cryptocurrency URIs for Bitcoin, Ethereum, Solana, and Litecoin with amount, address, and label parameters.
  - `Gs1DigitalLinkPayload`: GS1 Digital Link URIs and parenthesized Application Identifier (AI) element strings (GTIN-8/12/13/14, serial number, batch/lot, expiry date).
  - `PlainTextPayload`: Text and structured JSON payload parser with automatic JSON decoding.
- **Schema Validation Suite (`SchemaValidator`)**:
  - Deterministic validators for URLs, email addresses, geographic coordinates, UPI VPAs, IBAN account numbers, and Base32 secrets.
- **Automated Test Suite & Line Coverage**:
  - Achieved **99.27% line coverage** (684 / 689 lines hit) with 26 comprehensive unit tests passing and 0 analyzer issues.
  - Added `scripts/verify_qr_core_coverage.ps1` for automated coverage verification.

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
