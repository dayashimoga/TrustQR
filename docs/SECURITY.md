# Security & Threat Defense Architecture

## Universal QR Code Scanner & Generator Platform

This document details the multi-layered security architecture, cryptographic foundations, threat modeling, and defense-in-depth mechanisms implemented throughout the Universal QR platform.

---

## 1. Threat Model & Security Posture

QR codes serve as physical-to-digital bridges that encode arbitrary raw byte streams. Because QR codes are visually opaque to humans, they are widely exploited as vectors for **QR phishing (quishing)**, malicious URL redirects, credential harvesting, unauthorized Wi-Fi network joining, malware payload delivery, and protocol handler exploitation.

### Threat Matrix & Platform Mitigations

| Threat Vector | Attack Scenario | Platform Mitigation | Enforcement Point |
| :--- | :--- | :--- | :--- |
| **IDN Homograph Attacks** | Attacker uses Cyrillic/Greek characters visually identical to Latin (e.g. `gооgle.com` using Cyrillic `о`) to trick users into credential theft. | Heuristic Unicode script mixing detection, Punycode `xn--` conversion, and homoglyph normalization. Score penalty + ThreatLevel.high. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **Executable & Native URI Schemes** | Payload triggers native shell or application execution via schemes like `file://`, `javascript:`, `data:`, `smb:`, `intent:`. | Strict URI scheme whitelist and blocklist. Immediate quarantine blocking, ThreatLevel.critical, safety score = 0. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **Obfuscated / Literal IP Addresses** | Hostname is encoded as decimal (`http://2130706433`), hex (`http://0x7f.1`), octal, or raw IPv4/IPv6 to evade standard domain reputation filters. | Heuristic regex parser identifying raw IP hostnames in URLs. Score penalty + ThreatLevel.high quarantine. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **Suspicious Top-Level Domains (TLDs)** | Free or high-abuse TLDs commonly used for throwaway phishing infrastructure (`.zip`, `.mov`, `.top`, `.xyz`, `.click`, `.buzz`, `.country`). | Domain parser checks against high-risk TLD catalog. ThreatLevel.medium/high warning. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **URL Shorteners & Redirect Chains** | Obfuscation of destination endpoint via shorteners (`bit.ly`, `tinyurl.com`, `t.co`, `is.gd`, `ow.ly`). | Heuristic shortener domain detection with warning prompts preventing unverified auto-navigation. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **Malicious Wi-Fi Configurations** | Open or unencrypted Wi-Fi configuration with hidden SSID designed for evil-twin attacks or credential sniffing. | Wi-Fi payload security parser flags open/unencrypted networks (`T:nopass`) and recommends secure alternatives. | `packages/qr_scanner_engine/lib/src/security/qr_threat_firewall.dart` |
| **Tampered / Forged Institutional QR Codes** | Fake event tickets, product authenticity seals, or government IDs created by unauthorized parties. | Cryptographic `TrustQR` Ed25519 digital signatures with institutional key registry validation. Unsigned or forged codes show warning badges. | `packages/qr_core/lib/src/crypto/trust_qr_engine.dart` |
| **Client-Side Privilege Escalation** | End user attempts to access premium batch generation, fleet analytics, or custom template capabilities in restricted User App. | Strict **Compile-Time Binary Isolation** (forbidden packages completely omitted from build graph) + Server-side Ed25519 asymmetric token validation. | `apps/user_app/pubspec.yaml`, `scripts/verify_binary_isolation.dart`, `services/rbac_api` |
| **Local Vault Data Tampering** | Local sqlite/json storage modified offline by user or local malware to alter scan history or threat records. | Cryptographic HMAC-SHA256 signature verification over every persisted vault record. Any tampered field invalidates record. | `packages/qr_core/lib/src/vault/qr_vault_models.dart` |

---

## 2. Zero-Trust QR Threat Firewall

The **Zero-Trust Threat Firewall** (`QrThreatFirewall`) operates as an inline heuristic inspection engine that intercepts every decoded QR code before it reaches the UI, external applications, or persistent storage.

### 2.1 Inspection Pipeline
```
[ Decoded Raw String ]
         │
         ▼
[ URI Scheme Validator ] ──▶ (Blacklisted Scheme?) ──▶ Critical Threat (Score 0)
         │ No
         ▼
[ IDN Homoglyph Detector ] ──▶ (Punycode / Mixed Scripts?) ──▶ High Threat (Score -35)
         │
         ▼
[ IP Obfuscation Scanner ] ──▶ (Raw / Hex / Decimal IP?) ──▶ High Threat (Score -40)
         │
         ▼
[ TLD & Shortener Heuristics ] ──▶ (Abuse TLD / Shortener?) ──▶ Medium Threat (Score -25)
         │
         ▼
[ Wi-Fi / Schema Vulnerabilities ] ──▶ (Open Wi-Fi / Malformed?) ──▶ Caution Flag
         │
         ▼
[ TrustQR Cryptographic Verifier ] ──▶ (Valid Institutional Ed25519 Signature?)
         │ Yes                                    │ No / Unsigned
         ▼                                        ▼
Verified Institutional Badge               Standard Safety Score (0–100)
```

### 2.2 Threat Levels & Scoring

The Threat Firewall outputs a normalized safety score ranging from `0` (Maximum Hazard) to `100` (Fully Benign):

- **`ThreatLevel.safe` (Score 80–100)**: Clean, well-formed payload on trusted standard schemes (`https://`, `mailto:`, `vcard`, etc.) with no obfuscation.
- **`ThreatLevel.caution` (Score 60–79)**: Minor heuristic flags (e.g., URL shortener, open Wi-Fi network, long query string). User is prompted with warning details before action.
- **`ThreatLevel.suspicious` (Score 40–59)**: Multiple heuristic anomalies, suspicious TLD, or unverified high-entropy parameters. Auto-navigation strictly disabled.
- **`ThreatLevel.high` (Score 20–39)**: Confirmed phishing indicators, IDN homoglyphs, or literal IP hostnames. Quarantine alert displayed; action blocked by default.
- **`ThreatLevel.critical` (Score 0–19)**: Dangerous protocol schemes (`file:`, `javascript:`, `data:`, `smb:`, `intent:`) or known malicious signatures. Immediate quarantine; execution prohibited.

### 2.3 Adversarial Corpus Validation

The Threat Firewall is validated against a 150-vector adversarial corpus spanning 12 distinct attack and benign categories (`packages/qr_scanner_engine/test/adversarial/`):
- **False Negative Rate**: **0.00%** (zero malicious vectors bypassed detection).
- **Average Inspection Latency**: **0.0133 ms** per payload (~75,000 evaluations per second).

---

## 3. TrustQR Cryptographic Signing Engine

**TrustQR** is an institutional digital signature standard built on **Ed25519 (RFC 8032)** for verifiable, tamper-proof QR code payloads.

### 3.1 TrustQR Envelope Format

A TrustQR payload encodes a canonical URI with cryptographic attributes:
```
trustqr://v1?issuer=<ISSUER_ID>&key_id=<KEY_ID>&ts=<TIMESTAMP>&sig=<BASE64URL_SIGNATURE>&payload=<BASE64URL_PAYLOAD>
```

- **Algorithm**: Pure-Dart Ed25519 (EdDSA over Curve25519 with SHA-512).
- **Public Key**: 32-byte Ed25519 public key identified by `key_id` and registered in the institutional key authority.
- **Signature**: 64-byte EdDSA signature computed over the UTF-8 bytes of canonical payload string: `"<ISSUER_ID>:<KEY_ID>:<TIMESTAMP>:<PAYLOAD>"`.
- **Replay Protection**: Included microsecond-precision UTC timestamp (`ts`) with configurable validity window.

### 3.2 Key Management

- **Institutional Key Authority**: Managed by `services/rbac_api` at `/api/v1/trustqr/keys`.
- **Admin App Key Generation**: Administrators can generate fresh Ed25519 keypairs locally in the Admin App with cryptographically secure random number generation (`Random.secure()`).
- **Signature Verification**: Performed entirely on-device by both User App and Admin App with zero network latency.

---

## 4. Compile-Time Binary Isolation Invariant

To guarantee that restricted client installations cannot be patched or manipulated into revealing admin capabilities:

1. **Physical Monorepo Separation**:
   - `packages/qr_generator_engine` (Artistic QR generation, SVG/PDF exporters, scannability simulator).
   - `packages/qr_admin_analytics` (Fleet telemetry, anomaly detection, audit trail).
   - `apps/user_app` (End-user scanner application).
   - `apps/admin_app` (Full administrative studio application).

2. **Compile-Time Invariant**:
   - `apps/user_app/pubspec.yaml` **must never** depend directly or transitively on `qr_generator_engine` or `qr_admin_analytics`.
   - The compiled User App binary on all platforms (APK, IPA, Windows EXE, Linux binary, macOS App) physically lacks the symbol tables, bytecodes, and assets required for QR code generation, batch processing, or fleet telemetry management.

3. **Automated Auditor Gate**:
   - `scripts/verify_binary_isolation.dart` executes on every pre-commit hook and in CI (`.github/workflows/ci-quality-gate.yml`).
   - Includes negative breach self-testing: artificially injecting a forbidden package causes the auditor to immediately fail with exit code 1.

---

## 5. Server-Side Role-Based Access Control (RBAC)

The backend service (`services/rbac_api`) enforces asymmetric, cryptographically signed entitlement tokens for all API interactions.

### 5.1 Entitlement Token Architecture

- **Token Format**: Asymmetric Ed25519 signed JWT-like entitlement token.
- **Claims**:
  ```json
  {
    "sub": "user_or_admin_id",
    "role": "admin" | "user",
    "iat": 1700000000,
    "exp": 1700086400,
    "jti": "unique-token-uuid",
    "permissions": ["qr:scan", "qr:generate", "qr:batch", "admin:analytics"]
  }
  ```
- **Cryptographic Verification**: Server signs tokens with its private Ed25519 authority key. Every incoming request must provide an `Authorization: Bearer <TOKEN>` header.

### 5.2 Endpoint Access Matrix

| Route | Method | Required Role | Description |
| :--- | :--- | :--- | :--- |
| `/api/v1/auth/token` | POST | Public | Issue signed entitlement token with credentials. |
| `/api/v1/auth/verify` | POST | Authenticated | Validate token signature, expiration, and revocation. |
| `/api/v1/auth/revoke` | POST | Admin | Revoke an active entitlement token ID. |
| `/api/v1/telemetry/scan` | POST | Authenticated | Ingest client scan telemetry. |
| `/api/v1/trustqr/keys` | GET | Public | Retrieve active institutional TrustQR public keys. |
| `/api/v1/admin/qr/generate` | POST | **Admin Only** | Server-side artistic QR code generation. |
| `/api/v1/admin/qr/batch` | POST | **Admin Only** | High-throughput batch generation. |
| `/api/v1/admin/qr/sign` | POST | **Admin Only** | Institutional TrustQR payload signing. |
| `/api/v1/admin/templates` | GET/POST | **Admin Only** | Template management endpoints. |
| `/api/v1/admin/analytics` | GET | **Admin Only** | Fleet telemetry and anomaly reports. |
| `/api/v1/admin/audit` | GET | **Admin Only** | HMAC-SHA256 verified administrative audit trail. |

Any request to admin routes with `role: user`, an invalid signature, an expired timestamp, or a revoked token is rejected with `HTTP 403 Forbidden` or `HTTP 401 Unauthorized`.

---

## 6. Offline-First Vault Security & Data Privacy

### 6.1 HMAC-SHA256 Integrity Verification
Every record stored in the encrypted local vault (`QrVaultItem`) includes an HMAC-SHA256 integrity signature computed over:
`"<ID>:<RAW_STRING>:<PAYLOAD_TYPE>:<THREAT_LEVEL>:<SAFETY_SCORE>:<SCANNED_AT>:<METADATA>"`

If any field is tampered with on disk, the signature check fails and the item is flagged as compromised.

### 6.2 Privacy & Retention Policies
- **Zero Cloud Telemetry Mode**: User App defaults to offline local storage. No scan records or payload contents are transmitted to external servers without explicit consent.
- **Configurable Auto-Purge**: Vault supports retention policies (e.g., auto-delete records older than 7, 30, or 90 days).
- **Secure Export**: Vault exports use canonical JSON with deterministic field ordering and SHA-256 fingerprint validation.

---

## 7. Administrative Audit Trail Security

All sensitive administrative actions (key generation, batch runs, template updates, token revocations, export generation) generate immutable audit records (`AuditLogItem`):

- **Integrity**: Each audit record is signed with HMAC-SHA256.
- **Non-Repudiation**: Records capture `actorId`, `role`, `action`, `target`, `timestamp`, `ipAddress`, and `payloadSnapshot`.
- **Penetration Testing**: Evaluated against 12 tampering scenarios (timestamp rollback, role forgery, bit-flip corruption, signature replay) with 100% tamper detection.
