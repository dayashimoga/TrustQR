---
name: ci-cd-release-matrix
description: >-
  Configures and validates GitHub Actions workflows for selective and full cross-platform builds
  (Android, iOS, Windows, Linux, macOS) for Admin App and User App with standalone artifacts.
---

# CI/CD & Cross-Platform Release Matrix Skill

Use this skill when authoring or validating `.github/workflows/` and release packaging scripts.

## Mandatory CI/CD Requirements

1. **Selective & Full Matrix Inputs (`workflow_dispatch`)**:
   - `target_app`: `all` | `admin_app` | `user_app`
   - `target_platform`: `all` | `android` | `ios` | `windows` | `linux` | `macos`
   - `build_mode`: `release` | `debug` | `profile`
2. **Artifact Packaging Standards**:
   - Avoid unnecessary nested ZIP archives.
   - Upload standalone, clearly named downloadable artifacts (e.g., `qrscanner-admin-windows-x64`, `qrscanner-user-android-apk`) accompanied by `INSTALL.md` and `.sha256` checksum manifests.
3. **Quality Gate Prerequisite**:
   - Every build workflow must run the binary isolation check, static analyzer, and automated test suite before publishing artifacts.
