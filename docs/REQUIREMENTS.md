# Product & Technical Requirements Specification (SRS)
## Universal QR Code Scanner & Generator Platform

---

## 1. Executive Vision

Build a production-grade, cross-platform **QR Code Scanner and Generator Ecosystem** that runs natively across **Android, iOS, Windows, Linux, and macOS** (phones, tablets, foldables, laptops, and desktops) using 100% free and open-source technologies.

The platform delivers **two physically and cryptographically separated applications**:
1. **Admin App (`apps/admin_app` — Premium / Full Access)**: Complete access to QR scanning, single & batch QR generation, artistic customization, branded logos/templates, real-time scannability simulation, Ed25519 cryptographic QR signing (`TrustQR`), fleet management, and advanced analytics.
2. **User App (`apps/user_app` — Restricted / Scanner Only)**: Strictly restricted to QR scanning (camera, images, screenshots, files, batch scanning), threat/phishing inspection, `TrustQR` signature verification, and personal scan history/collections. QR generation and admin tools are physically excluded from the binary and blocked server-side via cryptographic RBAC.

---

## 2. Functional Requirements

### 2.1 Universal QR Scanning (Both `user_app` and `admin_app`)
- **FR-SCAN-01 (Multi-Source Input)**: Decode QR codes from live device cameras, uploaded image files (`.png`, `.jpg`, `.jpeg`, `.webp`, `.bmp`), screenshots, clipboard images, and drag-and-drop desktop files.
- **FR-SCAN-02 (Batch Matrix Vision)**: Detect and decode multiple QR codes simultaneously within a single image or frame, returning bounding coordinates and individual structured payloads.
- **FR-SCAN-03 (15+ Structured QR Formats)**: Parse, validate, and provide context-aware actions for:
  1. Web URLs (`https://`, `http://`)
  2. Wi-Fi Network Credentials (`WIFI:S:...;T:...;P:...;;`)
  3. vCard 3.0/4.0 Contacts (`BEGIN:VCARD...END:VCARD`)
  4. MeCard Contacts (`MECARD:N:...;TEL:...;;`)
  5. Geographic Coordinates (`geo:lat,lng`)
  6. iCalendar Events (`BEGIN:VEVENT...END:VEVENT`)
  7. Email / Mailto (`mailto:`, `MATMSG:`)
  8. SMS (`smsto:`, `sms:`)
  9. Telephone (`tel:`)
  10. TOTP / 2FA Authenticator (`otpauth://totp/...`)
  11. UPI Payment (`upi://pay?...`)
  12. EPC / SEPA European Payment QR (`BCD\n002...`)
  13. Cryptocurrency Payment URIs (`bitcoin:`, `ethereum:`)
  14. GS1 Digital Link / Enterprise Asset Tags
  15. Plain Text & Structured JSON/Key-Value Payloads

### 2.2 Zero-Trust Security & Anti-Phishing Firewall (Both `user_app` and `admin_app`)
- **FR-SEC-01 (Threat Score & Heuristic Inspection)**: Analyze every scanned payload offline before execution, producing a deterministic **Safety Score (0–100)**, threat classification (`SAFE`, `CAUTION`, `SUSPICIOUS`, `CRITICAL`), and human-readable security rationale.
- **FR-SEC-02 (IDN Homograph & Scheme Protection)**: Detect Punycode/IDN homograph spoofing (`xn--` and mixed-script lookalikes), block dangerous URI schemes (`javascript:`, `vbscript:`, `data:`, `file:`), flag obfuscated IP addresses, URL shorteners, and credential-embedding URLs.
- **FR-SEC-03 (TrustQR Ed25519 Cryptographic Verification)**: Verify cryptographically signed `TrustQR` payloads using public Ed25519 verification keys to prevent physical QR sticker tampering.

### 2.3 Offline-First History, Collections & Organization (Both `user_app` and `admin_app`)
- **FR-ORG-01 (Offline-First Persistence)**: Persist scan history (and generated QR records in Admin App) locally with full offline access.
- **FR-ORG-02 (Collections, Favorites & Tags)**: Organize items into custom collections/folders, mark favorites, attach multi-tags, and add user notes.
- **FR-ORG-03 (Instant Search & Multi-Faceted Filtering)**: Filter and search by full-text query, payload format, security classification, favorite status, collection, and date range.

### 2.4 Advanced QR Generation & Customization (`admin_app` ONLY)
- **FR-GEN-01 (Reed-Solomon Matrix Engine)**: Generate standards-compliant ISO/IEC 18004 QR matrices across versions 1–40 and error-correction levels `L` (7%), `M` (15%), `Q` (25%), and `H` (30%).
- **FR-GEN-02 (Artistic Styling & Branding)**: Customize module shapes (`square`, `rounded`, `dots`, `diamond`, `liquid`, `cyber_grid`), finder eye frames/centers, foreground/background colors, linear/radial multi-stop gradients, embedded center logos with automatic quiet-zone clearing, and branded call-to-action frames/templates.
- **FR-GEN-03 (Real-Time Scannability & Contrast Simulator)**: Compute real-time Michelson & WCAG luminance contrast ratios, logo occlusion percentage, and simulated decode verification to prevent un-scannable artistic designs.
- **FR-GEN-04 (Multi-Format Export & Batch Studio)**: Export high-DPI PNG, scalable vector SVG, print-ready PDF, and batch-generate QR archives from CSV/JSON datasets.
- **FR-GEN-05 (TrustQR Cryptographic Signing)**: Sign generated QR codes with Admin Ed25519 keys.

### 2.5 Admin Analytics, Fleet Management & RBAC (`admin_app` & `services/rbac_api`)
- **FR-ADM-01 (Analytics & Insights)**: Track generation volume, scan distribution by payload type, security threat statistics, error-correction usage, and active templates, with CSV/JSON analytics export.
- **FR-ADM-02 (Strict Two-Tier RBAC Enforcement)**:
  - `apps/user_app` has zero compile-time dependency on `qr_generator_engine` or `qr_admin_analytics`.
  - `services/rbac_api` cryptographically signs and validates Ed25519 role tokens and rejects any non-admin call to generation, template, batch, or analytics endpoints with `HTTP 403 Forbidden`.

---

## 3. Non-Functional Requirements

- **NFR-PERF-01**: Single QR decode from memory buffer `< 25 ms`; custom QR canvas render `< 16 ms` (60 FPS); batch generation `>= 50 QRs/sec` in background isolates.
- **NFR-QUAL-01**: `>= 95%` line test coverage across core packages and services; `100%` passing automated tests; `0` static analyzer issues.
- **NFR-UX-01**: Adaptive responsive layouts across Mobile (`<600px`), Tablet (`600–1024px`), and Desktop (`>1024px`), WCAG AAA contrast options, screen-reader semantics, and multi-language localization.
- **NFR-CICD-01**: GitHub Actions workflows supporting both full matrix builds and on-demand `workflow_dispatch` selection of application (`admin_app`, `user_app`, `all`) and platform (`android`, `ios`, `windows`, `linux`, `macos`, `all`), producing standalone downloadable artifacts without nested ZIP archives.
