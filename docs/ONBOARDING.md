# Developer Onboarding & Contribution Guide

## Universal QR Code Scanner & Generator Platform

Welcome to the **Universal QR Code Scanner & Generator Platform** codebase. This guide walks you through setting up your local environment, understanding the architecture, running test suites, and contributing safely.

---

## 1. Prerequisites & Toolchain Setup

### Required SDKs & Tools
- **Flutter SDK**: 3.24.0 or later (Channel stable).
- **Dart SDK**: 3.5.0 or later (Bundled with Flutter).
- **Git**: 2.40.0 or later.
- **Platform Toolchains** (depending on your development OS):
  - **Windows**: Visual Studio 2022 with "Desktop development with C++" workload.
  - **Linux**: GTK3 development libraries (`libgtk-3-dev`, `pkg-config`, `cmake`, `ninja-build`).
  - **macOS / iOS**: Xcode 15 or later with Command Line Tools and CocoaPods.
  - **Android**: Android Studio with Android SDK Platform 34 and Android NDK.

### Verifying Environment
```bash
flutter doctor -v
dart --version
git --version
```

---

## 2. Monorepo Architecture & Dependency Boundaries

The codebase is organized as a clean-architecture monorepo:

```
qrscanner/
├── packages/
│   ├── qr_core/                 # Payload formats (15), Ed25519 crypto, vault models
│   ├── qr_scanner_engine/       # Decoder pipeline, Reed-Solomon, Threat Firewall
│   ├── qr_generator_engine/     # ISO/IEC 18004 encoder, customizer, SVG/PDF exporters
│   ├── qr_design_system/        # Cyber-precision glassmorphism, reticle HUD, i18n
│   └── qr_admin_analytics/      # Fleet telemetry, time series, audit trail
├── services/
│   └── rbac_api/                # HTTP server, Ed25519 entitlement tokens, RBAC guard
├── apps/
│   ├── user_app/                # Restricted scanner app (NO generator dependencies)
│   └── admin_app/               # Premium multi-pane admin workspace & studio
├── docs/                        # Specifications, architecture, guides, tracker
└── scripts/                     # Automated auditors, packaging, coverage scripts
```

### Core Invariant: Compile-Time Binary Isolation
- `apps/user_app/pubspec.yaml` **must never** depend on `qr_generator_engine` or `qr_admin_analytics`.
- Always verify your branch with:
  ```bash
  dart run scripts/verify_binary_isolation.dart
  ```

---

## 3. Getting Started

### 3.1 Bootstrap Dependencies
Run `flutter pub get` across all packages, services, and applications:
```bash
flutter pub get
cd packages/qr_core && flutter pub get && cd ../..
cd packages/qr_scanner_engine && flutter pub get && cd ../..
cd packages/qr_generator_engine && flutter pub get && cd ../..
cd packages/qr_design_system && flutter pub get && cd ../..
cd packages/qr_admin_analytics && flutter pub get && cd ../..
cd services/rbac_api && dart pub get && cd ../..
cd apps/user_app && flutter pub get && cd ../..
cd apps/admin_app && flutter pub get && cd ../..
```

### 3.2 Running the Applications

#### Running the Restricted User App (Scanner)
```bash
cd apps/user_app
flutter run -d windows    # On Windows
flutter run -d macos      # On macOS
flutter run -d linux      # On Linux
flutter run -d chrome     # In Browser / Web
flutter run -d <DEVICE>   # On connected Android or iOS device
```

#### Running the Premium Admin App (Studio)
```bash
cd apps/admin_app
flutter run -d windows    # On Windows
flutter run -d macos      # On macOS
flutter run -d linux      # On Linux
```

#### Running the Server-Side RBAC API
```bash
cd services/rbac_api
dart run bin/server.dart --port 8080
```

---

## 4. Development Workflow & Quality Gates

Every code change must satisfy all four quality gates:

### Gate 1: Binary Isolation Audit
```bash
dart run scripts/verify_binary_isolation.dart
```

### Gate 2: Static Analysis (0 Warnings / 0 Errors / 0 Infos)
```bash
flutter analyze --fatal-infos --fatal-warnings .
```

### Gate 3: Test Execution & Coverage Audit (`>= 95.0%`)
```bash
dart run scripts/verify_ecosystem_coverage.dart
```

### Gate 4: End-to-End Test Suite
```bash
cd apps/user_app && flutter test test/e2e/user_e2e_journey_test.dart && cd ../..
cd apps/admin_app && flutter test test/e2e/admin_e2e_journey_test.dart && cd ../..
```

---

## 5. Coding Standards & Conventions

1. **Zero Placeholder Code**:
   - Never commit dummy buttons, mock actions, or placeholder snackbars. Every UI control must invoke real domain logic.
2. **Immutable Append-Only Ledgers**:
   - `CHANGELOG.md` and `TODO.md` are append-only. Never delete historical records.
3. **Pure-Dart Business Logic**:
   - Core cryptography, Reed-Solomon math, matrix generation, and export engines are written in pure Dart with zero native dependencies, ensuring 100% portable execution across mobile, desktop, and web.
4. **Accessible Semantics**:
   - All interactive controls must include WCAG-compliant `Semantics` labels and meet minimum 48x48 dp touch target dimensions.
