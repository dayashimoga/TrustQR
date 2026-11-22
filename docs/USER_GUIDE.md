# Platform User & Administrator Guide

## Universal QR Code Scanner & Generator Platform

This guide provides end users and system administrators with comprehensive instructions for operating the **Universal QR Scanner** (`apps/user_app`) and **Universal QR Admin Studio** (`apps/admin_app`) across desktop, laptop, tablet, and mobile devices.

---

## Part 1: Universal QR Scanner (User App)

The **Universal QR Scanner** is an ultra-fast, security-hardened QR decoding application with an integrated Zero-Trust Threat Firewall and an offline-first encrypted vault.

### 1.1 Scanner Interface & Viewfinder
- **HUD Reticle**: The viewfinder displays an animated cyber-precision reticle with corner brackets and a real-time laser sweep.
- **Scanning Sources**:
  - **Live Camera**: Point your camera at any 1D or 2D QR code. The engine decodes frames sub-5ms.
  - **Image Gallery**: Click the **Gallery / Image** icon to select an image from your device storage.
  - **File Ingestion**: Drop or browse for uncompressed BMP or supported image files.
  - **Multi-QR Batch Matrix Vision**: Detects multiple QR codes appearing simultaneously within a single frame or image.
- **Torch / Flashlight Toggle**: Tap the flashlight icon for scanning in low-light environments.
- **Camera Flip**: Switch between front and rear cameras on mobile and tablet devices.

### 1.2 Zero-Trust Threat Firewall & Security HUD
Whenever a QR code is detected, the Threat Firewall evaluates the payload:
- **Green HUD (Safe, Score 80–100)**: The payload is verified, clean, and safe to open or copy.
- **Yellow HUD (Caution, Score 60–79)**: Flags non-critical anomalies such as open Wi-Fi networks or URL shorteners. Review details before proceeding.
- **Orange HUD (Suspicious, Score 40–59)**: High-risk TLDs or unusual URL structures detected. Automatic actions are blocked.
- **Red HUD (High / Critical Threat, Score 0–39)**: Quarantine alert triggered! Detected phishing attempt, dangerous URI scheme (`file:`, `javascript:`), or IDN homoglyph attack.
- **TrustQR Verified Badge**: If the QR code was cryptographically signed with institutional Ed25519 keys, a gold/cyan "VERIFIED INSTITUTIONAL QR" shield badge confirms authenticity.

### 1.3 Personal Offline Encrypted Vault
- **History View**: Chronological ledger of all scanned codes with date, safety score, payload type, and threat badges.
- **Search & Filter**: Full-text search (FTS) across payload strings, format categories, and tags.
- **Favorites & Collections**: Star important codes or organize them into custom collections (e.g., "Work Wi-Fi", "Event Tickets", "Crypto Addresses").
- **Privacy Mode & Retention**: Configure auto-purge policies (keep for 7, 30, 90 days, or never store history).
- **Export & Backup**: Export your vault records as canonical JSON or import prior backups. All records are protected by HMAC-SHA256 signatures.

---

## Part 2: Universal QR Admin Studio (Admin App)

The **Universal QR Admin Studio** is a full-featured creative, batch generation, and telemetry workspace designed for institutional and administrative workflows.

### 2.1 RBAC Authentication & Session Management
- **Entitlement Unlock**: When launching the Admin App, access is guarded by cryptographic Ed25519 entitlement tokens.
- **Session Status**: The bottom bar displays the active user identity, role (`admin`), and token validity duration.
- **Token Generation**: Use the built-in token dialog or link with `services/rbac_api` to authenticate your session.

### 2.2 Interactive QR Studio
- **15 Supported Payload Formats**:
  - **Web & Social**: URL / HTTPS links.
  - **Connectivity**: Wi-Fi networks (SSID, WPA/WPA2/WPA3, WEP, password, hidden network toggle).
  - **Identity & Contacts**: vCard (full name, phone, email, organization, title, URL) and MeCard formats.
  - **Location**: Geo Coordinates (latitude, longitude, altitude).
  - **Calendar**: iCalendar VEvent (title, start/end dates, location, description).
  - **Communication**: Email, SMS, Phone call / Tel numbers.
  - **Security & Auth**: Two-Factor Authentication (OTP / TOTP / HOTP URI).
  - **Payments & Finance**: UPI (Virtual Payment Address, payee name, amount, transaction note), EPC SEPA Credit Transfer (IBAN, BIC, amount), and Cryptocurrency (Bitcoin, Ethereum addresses, amounts).
  - **Retail & Logistics**: GS1 Digital Link compliant barcodes.
  - **Unstructured**: PlainText with UTF-8 support.
- **Artistic Customization**:
  - **Preset Templates**: Cyber Glass, Obsidian Stealth, Neon Emerald, Solar Gold, Corporate Cobalt.
  - **Module Shapes**: Square, Rounded Rectangle, Circle / Dot, Diamond, Smooth Curvature, Hexagon.
  - **Finder Eye Styles**: Standard Square, Rounded Eye, Circular Eye, Leaf Shape, Shield Contour.
  - **Color & Gradients**: Solid colors or multi-stop linear/radial gradients with angle rotation.
  - **Center Logo Cutout**: Upload custom brand logos (PNG/SVG) with automatic quiet-zone padding to maintain scannability.
- **Live Scannability & Contrast Simulator**:
  - **Michelson & WCAG 2.1 Contrast Gauge**: Real-time evaluation of foreground-to-background contrast ratio (recommends >= 4.5:1).
  - **Environmental Stress Bars**: Simulates scannability under Studio Lighting, Glare, Dim Conditions, Perspective Tilt (30°), and Optical Blur.
  - **Occlusion Check**: Measures logo area coverage relative to Reed-Solomon error correction capacity (L: 7%, M: 15%, Q: 25%, H: 30%).
- **Multi-Format Export Pipeline**:
  - **PNG Image**: 32-bit high-resolution raster export (up to 300 DPI for print).
  - **Vector SVG**: Scalable vector XML code for web rendering and design tools.
  - **Print PDF**: Standards-compliant PDF-1.4 with precise page dimensioning and vector matrix.
  - **Raw BMP**: Lossless uncompressed bitmap export.

### 2.3 Institutional TrustQR Cryptographic Signer
- **Ed25519 Keypair Generator**: Generate institutional public/private key pairs directly within the Studio using `Random.secure()`.
- **Payload Envelope Packaging**: Signs the structured payload using RFC 8032 EdDSA, outputting verifiable `trustqr://` URIs.
- **Key Authority Sync**: Publish public keys to `services/rbac_api` for instant ecosystem-wide verification.

### 2.4 High-Throughput Batch Generator
- **Data Ingestion**: Import CSV or JSON datasets with multiple payload records.
- **Preset Integration**: Apply consistent branding templates and styles across thousands of QR codes.
- **Batch Scannability Audit**: Automatically evaluates scannability scores across all generated codes.
- **Pure-Dart PKZIP Exporter**: Assembles generated QR codes into a single non-nested `.zip` archive accompanied by detached `.sha256` checksum manifests.

### 2.5 Fleet Telemetry & Anomaly Analytics
- **Live Metrics Dashboard**: Real-time telemetry ingestion from distributed scanner devices.
- **Time-Series Charts**: Scan volume trends, active generation rates, and threat event occurrences over 24h, 7d, 30d, and 365d windows.
- **15-Format Distribution**: Pie/doughnut breakdown of scanned and generated payload types.
- **Threat Severity Histogram**: Distribution of safe, caution, suspicious, and quarantined threats.
- **Top Malicious Domains**: Ranked table of blocked phishing domains, malicious TLDs, and IP literals.
- **Device & Token Governance**: Inventory of registered client devices with one-click token revocation.
- **Canonical Report Exporters**: Export full analytics summaries to canonical JSON or 4 RFC 4180 CSV formats.

### 2.6 HMAC-SHA256 Verified Audit Trail
- **Immutable Log Browser**: Displays all administrative actions (keys generated, tokens revoked, batches exported).
- **Tamper-Detection Badge**: Real-time HMAC-SHA256 verification indicator confirms that no audit records have been altered or deleted.
- **Multi-Criteria Filter**: Filter by actor ID, role, action type, IP address, or timestamp range.
