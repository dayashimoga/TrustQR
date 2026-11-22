# Changelog — Universal QR Code Scanner & Generator Platform

> **Policy**: This file is an **append-only** historical ledger. Never delete or overwrite prior entries.

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
