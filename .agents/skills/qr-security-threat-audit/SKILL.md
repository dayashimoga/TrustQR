---
name: qr-security-threat-audit
description: >-
  Audits and tests QR payload threat detection, anti-phishing heuristics, IDN homograph checks,
  Ed25519 TrustQR signature verification, and adversarial RBAC privilege escalation resistance.
---

# QR Security & Threat Audit Skill

Use this skill when building or auditing the QR Threat Firewall, TrustQR signature envelopes, or RBAC security tests.

## Threat Inspection Checklist

1. **Dangerous Scheme Blocking**: Block `javascript:`, `vbscript:`, `data:`, `file:`, and unexpected custom command schemes.
2. **IDN Homograph & Punycode Detection**: Detect mixed-script domain labels (e.g., Cyrillic/Latin lookalikes) and `xn--` punycode domains masquerading as trusted brands.
3. **Network & Phishing Heuristics**: Flag raw IPv4/IPv6 URLs, hex/octal IP encodings, URL shorteners, credential-in-URL patterns (`user:pass@host`), insecure HTTP on sensitive paths, and excessive subdomain depth.
4. **Payload Sanitization**: Inspect Wi-Fi (`WIFI:`), vCard (`BEGIN:VCARD`), UPI/EMVCo payment URIs, and SMS/Tel payloads for hidden injection characters or deceptive parameters.
5. **Adversarial RBAC Audit**: Execute automated penetration tests confirming a `role: user` token cannot invoke any `/api/v1/admin/*` or `/api/v1/qr/generate*` endpoint.
