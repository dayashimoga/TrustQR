---
name: architecture-governance
description: >-
  Audits monorepo architecture, package dependency boundaries, compile-time binary isolation
  between Admin App and User App, and enforces continuous AI course correction against scope creep.
---

# Architecture Governance & Binary Isolation Skill

Use this skill when designing, modifying, or auditing package boundaries in the `qrscanner` monorepo.

## Allowed Dependency Graph

```text
apps/user_app (Restricted Scanner Only)
  ├── packages/qr_core
  ├── packages/qr_scanner_engine
  └── packages/qr_design_system
  [FORBIDDEN: packages/qr_generator_engine, packages/qr_admin_analytics]

apps/admin_app (Premium Full Ecosystem)
  ├── packages/qr_core
  ├── packages/qr_scanner_engine
  ├── packages/qr_generator_engine
  ├── packages/qr_admin_analytics
  └── packages/qr_design_system

services/rbac_api (Server-Side RBAC & Entitlement Service)
  └── packages/qr_core
```

## Verification Procedure

1. Inspect `apps/user_app/pubspec.yaml` and confirm zero references to `qr_generator_engine` or `qr_admin_analytics`.
2. Search `apps/user_app/lib/` for any import containing `qr_generator_engine` or `qr_admin_analytics`.
3. Verify no circular dependencies exist across `packages/*`.
4. Confirm every feature aligns with `docs/REQUIREMENTS.md` and `docs/ARCHITECTURE.md` without scope drift.
