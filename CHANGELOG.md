# Changelog — Universal QR Code Scanner & Generator Platform

> **Policy**: This file is an **append-only** historical ledger. Never delete or overwrite prior entries.

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
