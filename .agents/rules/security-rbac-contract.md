# Security, RBAC & Physical Binary Separation Contract

## 1. Physical Compile-Time Isolation
- `apps/user_app` is the restricted scanner-only application.
- `apps/user_app/pubspec.yaml` and all Dart source files inside `apps/user_app/` are **strictly prohibited** from importing or referencing `qr_generator_engine` or `qr_admin_analytics`.
- Automated CI and local verification scripts must check `apps/user_app/pubspec.yaml` and `apps/user_app/lib/` on every subphase to guarantee zero dependency leakage.

## 2. Cryptographic & Server-Side RBAC Enforcement
- Role claims (`admin` vs `user`) and feature entitlements (`qr.scan`, `qr.generate`, `qr.customize`, `qr.batch_generate`, `qr.sign`, `qr.analytics`, `qr.manage`) are issued and verified by `services/rbac_api` using cryptographic signatures (Ed25519 / HMAC-SHA256).
- Client-side role checks in `apps/admin_app` are backed by cryptographic token verification and server-side RBAC middleware.
- Regular user credentials (`role: user`) must always receive `403 Forbidden` when attempting to invoke any admin or generator endpoint, even via direct HTTP manipulation.
- Local storage tampering (modifying local SQLite records or preferences) must fail cryptographic signature verification and immediately revoke elevated local session state.

## 3. Zero-Trust QR Threat Inspection
- Every scanned QR payload (in both `user_app` and `admin_app`) passes through the **Zero-Trust Threat Firewall** before any external action (such as opening a browser, joining Wi-Fi, or launching an intent) is triggered:
  - Detect and flag IDN homograph / punycode spoofing (`xn--`).
  - Block executable/dangerous URI schemes (`javascript:`, `vbscript:`, `data:text/html`, `file://`).
  - Flag raw IP, hex/octal IP obfuscation, insecure `http://` payment/login links, URL shorteners, and suspicious high-entropy phishing domains.
  - Validate Ed25519 `TrustQR` cryptographic envelopes to distinguish verified institutional QR codes from tampered/unsigned codes.
