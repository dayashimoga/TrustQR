---
name: rbac-backend-persistence
description: >-
  Implements and verifies server-side RBAC enforcement, cryptographic Ed25519/HMAC entitlement
  tokens, and offline-first local SQLite persistence.
---

# RBAC Backend & Offline-First Persistence Skill

Use this skill when working on `services/rbac_api` or local storage repositories in `packages/qr_core`.

## Server-Side RBAC Enforcement Rules

1. **Role Matrix**:
   - `user`: Allowed scopes: `["qr:scan", "qr:verify", "qr:history:own"]`.
   - `admin`: Allowed scopes: `["qr:scan", "qr:verify", "qr:history:own", "qr:generate", "qr:customize", "qr:batch", "qr:sign", "qr:templates", "qr:analytics", "qr:admin"]`.
2. **Cryptographic Verification**:
   - Tokens and offline entitlement manifests are signed with the server's Ed25519 private key.
   - Any modified payload, expired timestamp, or mismatched role claim must immediately fail signature verification and return `401 Unauthorized` or `403 Forbidden`.
3. **Offline-First Sync & Vault**:
   - Local scan history, collections, favorites, and audit events are persisted locally with deterministic schema migrations and full-text search filtering.
