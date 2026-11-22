# Automated Testing & Verification Guide

## Universal QR Code Scanner & Generator Platform

This document describes the testing architecture, quality gates, coverage requirements, test suites, and execution instructions for the Universal QR platform across all packages, services, and applications.

---

## 1. Quality Gate Standards

The platform enforces four non-negotiable automated quality gates before any code is committed, merged, or released:

1. **Mandatory `>= 95.0%` Line Coverage**:
   - Every individual package, backend service, and Flutter application must achieve at least 95.0% line coverage.
   - Verified via `scripts/verify_ecosystem_coverage.dart` and `lcov` coverage reports.
2. **Zero Static Analysis Defects**:
   - `flutter analyze --fatal-infos --fatal-warnings .` must pass with **0 errors, 0 warnings, and 0 infos**.
3. **Strict Compile-Time Binary Isolation**:
   - `scripts/verify_binary_isolation.dart` audits the dependency graph to ensure `apps/user_app` has zero compile-time dependencies on `packages/qr_generator_engine` or `packages/qr_admin_analytics`.
4. **100% Test Pass Rate**:
   - All unit, widget, integration, adversarial benchmark, and E2E journey tests must pass with 0 failures or skips.

---

## 2. Monorepo Coverage Matrix

Audited on **2026-11-22** via `scripts/verify_ecosystem_coverage.dart`:

| Component | Path | Test Files | Total Lines | Covered Lines | Line Coverage | Quality Gate |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **QR Core Engine** | `packages/qr_core` | 3 suites (64 tests) | 1,564 | 1,530 | **97.83%** | **PASSED** (>=95%) |
| **QR Scanner Engine** | `packages/qr_scanner_engine` | 6 suites (94 tests) | 1,443 | 1,433 | **99.31%** | **PASSED** (>=95%) |
| **QR Generator Engine** | `packages/qr_generator_engine` | 4 suites (67 tests) | 1,597 | 1,571 | **98.37%** | **PASSED** (>=95%) |
| **Design System** | `packages/qr_design_system` | 4 suites (64 tests) | 743 | 737 | **99.19%** | **PASSED** (>=95%) |
| **Admin Analytics** | `packages/qr_admin_analytics` | 4 suites (46 tests) | 922 | 912 | **98.92%** | **PASSED** (>=95%) |
| **RBAC API Service** | `services/rbac_api` | 2 suites (60 tests) | 464 | 455 | **98.06%** | **PASSED** (>=95%) |
| **User Application** | `apps/user_app` | 5 suites (92 tests) | 1,738 | 1,696 | **97.58%** | **PASSED** (>=95%) |
| **Admin Application** | `apps/admin_app` | 5 suites (83 tests) | 2,385 | 2,308 | **96.77%** | **PASSED** (>=95%) |
| **ECOSYSTEM TOTAL** | **Monorepo Aggregation** | **33 suites (570 tests)** | **10,856** | **10,642** | **98.03%** | **ALL PASSED** |

---

## 3. Test Suites & Verification Scope

### 3.1 Unit & Domain Logic Tests
- **`packages/qr_core`**:
  - `test/qr_payload_test.dart`: 15 structured payload formats (URL, Wi-Fi, vCard, MeCard, Geo, Event, Email, SMS, Tel, OTP, UPI, EPC, Crypto, GS1, PlainText), schema validation, and bidirectional parsing.
  - `test/crypto_test.dart`: Pure-Dart Ed25519 digital signature signing and verification (RFC 8032), keypair generation, and HMAC-SHA256 asymmetric entitlement tokens.
  - `test/vault_test.dart`: Offline-first vault persistence, FTS search, collection tags, auto-purge retention policies, HMAC record integrity, and JSON export/import.

### 3.2 Security, Firewall & Adversarial Tests
- **`packages/qr_scanner_engine`**:
  - `test/adversarial/threat_firewall_adversarial_test.dart`: 150-vector adversarial corpus across 12 categories:
    1. IDN Homograph attacks (Punycode `xn--`, Cyrillic character substitutions).
    2. Executable / dangerous URI schemes (`file:`, `javascript:`, `data:`, `smb:`, `intent:`).
    3. Obfuscated literal IP addresses (decimal, hex, octal, raw IPv4/IPv6).
    4. Malicious / high-risk TLDs (`.zip`, `.mov`, `.top`, `.xyz`, `.click`).
    5. URL shorteners & redirection cloaking (`bit.ly`, `tinyurl.com`, `t.co`).
    6. Open & unencrypted Wi-Fi network payloads.
    7. High-entropy phishing paths and credential harvesting parameters.
    8. Valid institutional `TrustQR` signatures (verified badge).
    9. Forged / tampered `TrustQR` signatures (detected and flagged).
    10. Malformed payload schemas.
    11. Standard clean payloads (zero false positives).
    12. Extreme payload boundaries and edge cases.
- **`services/rbac_api`**:
  - `test/rbac_api_penetration_test.dart`: Comprehensive penetration test verifying 11 security vectors:
    - Route access with no token (`401 Unauthorized`).
    - Malformed token strings (`401 Unauthorized`).
    - Cryptographically tampered signatures (`401 Unauthorized`).
    - Expired tokens (`401 Unauthorized`).
    - Revoked token IDs (`401 Unauthorized`).
    - Non-existent token revocation (`404 Not Found`).
    - `role: user` accessing admin generation routes (`403 Forbidden`).
    - `role: user` accessing admin batch generation routes (`403 Forbidden`).
    - `role: user` accessing admin analytics and audit routes (`403 Forbidden`).
    - Valid `role: user` access to telemetry ingestion (`200 OK`).
    - Valid `role: admin` access to all admin operations (`200 OK`).

### 3.3 Engine & Performance Benchmarks
- **`packages/qr_scanner_engine`**:
  - `test/pipeline/decoding_pipeline_test.dart`: Pure-Dart image processing, adaptive binarization (8x8 local thresholding), GF(256) Galois Field math, Reed-Solomon BCH error correction, and ISO/IEC 18004 matrix decoding across Numeric, Alphanumeric, and Byte modes.
  - `test/benchmark/scan_to_vault_benchmark_test.dart`: Integrated scan-to-firewall-to-vault latency benchmarking. Measured average single frame latency of **5.06 ms** (< 25 ms gate pass) and throughput exceeding **46,900 payloads/sec**.
- **`packages/qr_generator_engine`**:
  - `test/qr_generator_test.dart`: ISO/IEC 18004 full matrix encoding, mask penalty evaluation (N1–N4), 6 module shapes, custom finder eye styles, multi-stop gradients, and safe center logo cutouts.
  - `test/export_and_simulator_test.dart`: Real-time scannability & contrast simulator (Michelson/WCAG 2.1 compliance), 32-bit PNG, vector SVG XML, and print-ready PDF-1.4 export pipelines with 100% round-trip decode verification.

### 3.4 UI Design System & Accessibility Widget Tests
- **`packages/qr_design_system`**:
  - `test/glassmorphism_and_reticle_test.dart`: Cyber-precision glassmorphic cards, glowing borders, and HUD scanner reticles with laser sweep animation.
  - `test/adaptive_and_accessibility_test.dart`: WCAG 2.1 AA accessibility semantics, screen reader labels, minimum 48x48 dp touch target compliance, high-contrast modes, and multi-language localization (English, Spanish, French, German, Japanese, Chinese).

### 3.5 End-to-End (E2E) Integration Journeys
- **`apps/user_app/test/e2e/user_e2e_journey_test.dart`**:
  - **Journey 1**: Deceptive phishing QR detection (`http://paypa1-update.com/login`), Threat Firewall heuristic interception, quarantine warning display, and encrypted vault storage.
  - **Journey 2**: Institutional `TrustQR` Ed25519 signature decoding, on-device public key verification, verified badge display, and FTS vault retrieval.
  - **Journey 3**: High-throughput multi-QR batch scanning (10 distinct formats), auto-categorization, tag filtering, and instant collection grouping.
- **`apps/admin_app/test/e2e/admin_e2e_journey_test.dart`**:
  - **Journey 1**: Interactive Studio payload creation (Wi-Fi, vCard, Crypto, OTP), artistic customization (Obsidian Stealth, dot modules, leaf eyes, gradient styling), real-time Scannability Simulator execution (18.2:1 contrast ratio, 100% score), and multi-format export (PNG, SVG, PDF).
  - **Journey 2**: Institutional `TrustQR` keypair generation, structured vCard signing, cryptographic signature packaging, and verification badge confirmation.
  - **Journey 3**: High-throughput batch generator executing 5-item batch generation, individual scannability evaluation, pure-Dart PKZIP archive packaging, and detached SHA-256 fingerprint generation.
  - **Journey 4**: Multi-pane RBAC entitlement validation (`admin` vs `user` vs `unauthenticated`), fleet telemetry dashboard aggregation, and HMAC-SHA256 verified audit trail.

---

## 4. How to Run Tests

### Run All Tests Across Monorepo
```bash
# Execute static analysis
flutter analyze --fatal-infos --fatal-warnings .

# Run master ecosystem coverage audit and report
dart run scripts/verify_ecosystem_coverage.dart
```

### Run Tests for Individual Packages
```bash
# QR Core
cd packages/qr_core
flutter test --coverage

# QR Scanner Engine
cd packages/qr_scanner_engine
flutter test --coverage

# QR Generator Engine
cd packages/qr_generator_engine
flutter test --coverage

# Design System
cd packages/qr_design_system
flutter test --coverage

# Admin Analytics Engine
cd packages/qr_admin_analytics
flutter test --coverage

# Server-Side RBAC API
cd services/rbac_api
dart test --coverage=coverage

# User App
cd apps/user_app
flutter test --coverage

# Admin App
cd apps/admin_app
flutter test --coverage
```

### Run Subphase Master Verification Gates
```powershell
# PowerShell verification scripts
powershell -ExecutionPolicy Bypass -File scripts/verify_subphase_6_2_1.ps1
powershell -ExecutionPolicy Bypass -File scripts/verify_subphase_6_2_2.ps1
```

---

## 5. Continuous Integration (CI/CD)

The GitHub Actions CI pipeline (`.github/workflows/ci-quality-gate.yml`) runs automatically on all pull requests and pushes to `main`:
1. **Gate 1**: Compile-time binary isolation audit (`scripts/verify_binary_isolation.dart`).
2. **Gate 2**: Native runner configuration auditor (`scripts/verify_native_runner_configs.dart`).
3. **Gate 3**: Monorepo static analysis (`flutter analyze --fatal-infos --fatal-warnings .`).
4. **Gate 4**: Adversarial Threat Firewall corpus (150 vectors) and RBAC penetration suite.
5. **Gate 5**: Test execution with `lcov` coverage enforcement (`>= 95.0%`).
6. **Gate 6**: Standalone packaging pipeline verification across all 10 OS-application targets.
