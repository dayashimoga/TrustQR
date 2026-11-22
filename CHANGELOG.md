# Changelog — Universal QR Code Scanner & Generator Platform

> **Policy**: This file is an **append-only** historical ledger. Never delete or overwrite prior entries.

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
