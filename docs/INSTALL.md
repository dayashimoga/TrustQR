# Cross-Platform Installation & Binary Distribution Guide

## Universal QR Code Scanner & Generator Platform

This document provides complete instructions for downloading, installing, verifying, and running the **Universal QR Scanner** (`apps/user_app`) and **Universal QR Admin Studio** (`apps/admin_app`) across all five supported operating systems: **Android, iOS, Windows, Linux, and macOS**.

---

## 1. Supported Platform Matrix

| Platform | Form Factors | Minimum OS Version | Architecture | Distributed Artifact |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | Phone, Tablet | Android 8.0 (API Level 26)+ | `arm64-v8a`, `armeabi-v7a`, `x86_64` | `qrscanner-<app>-android-apk.zip` |
| **iOS** | iPhone, iPad | iOS 14.0+ | `arm64` | `qrscanner-<app>-ios-app.zip` |
| **Windows** | Laptop, Desktop | Windows 10 (Build 19041)+, Windows 11 | `x64` | `qrscanner-<app>-windows-x64.zip` |
| **Linux** | Laptop, Desktop | Ubuntu 20.04+, Debian 11+, Fedora 36+ | `x64` | `qrscanner-<app>-linux-x64.tar.gz` |
| **macOS** | MacBook, iMac, Mac mini | macOS 12.0 (Monterey)+ | Universal (`x64` + `arm64` Apple Silicon) | `qrscanner-<app>-macos-universal.tar.gz` |

---

## 2. Verifying Release Integrity (SHA-256 Checksums)

Every release bundle is accompanied by a detached `.sha256` checksum file. Always verify the checksum before installation.

### Windows (PowerShell)
```powershell
# Verify SHA-256 hash
Get-FileHash -Algorithm SHA256 .\qrscanner-user-windows-x64.zip
# Compare with the content of qrscanner-user-windows-x64.zip.sha256
Get-Content .\qrscanner-user-windows-x64.zip.sha256
```

### Linux & macOS (Terminal)
```bash
# Verify checksum using sha256sum
sha256sum -c qrscanner-user-linux-x64.tar.gz.sha256

# On macOS:
shasum -a 256 -c qrscanner-user-macos-universal.tar.gz.sha256
```

---

## 3. Platform Installation Instructions

### 3.1 Windows Installation (`.zip`)

1. **Download & Extract**:
   - Download `qrscanner-user-windows-x64.zip` (User App) or `qrscanner-admin-windows-x64.zip` (Admin Studio).
   - Extract the ZIP archive into `C:\Program Files\UniversalQR` or your preferred local folder:
     ```powershell
     Expand-Archive -Path .\qrscanner-user-windows-x64.zip -DestinationPath C:\UniversalQR\Scanner
     ```
2. **Launch Application**:
   - Open the extracted folder and double-click `qrscanner_user_app.exe` (or `qrscanner_admin_app.exe`).
   - *Optional*: Right-click the `.exe` and select **Pin to Start** or **Pin to taskbar**.

---

### 3.2 Linux Installation (`.tar.gz`)

1. **Extract Archive**:
   ```bash
   mkdir -p ~/UniversalQR/Scanner
   tar -xzf qrscanner-user-linux-x64.tar.gz -C ~/UniversalQR/Scanner
   ```
2. **Install Desktop Entry (Optional)**:
   ```bash
   cat <<EOF > ~/.local/share/applications/universal-qr-scanner.desktop
   [Desktop Entry]
   Name=Universal QR Scanner
   Comment=Security-Hardened Zero-Trust QR Code Scanner
   Exec=$HOME/UniversalQR/Scanner/qrscanner_user_app
   Icon=$HOME/UniversalQR/Scanner/data/flutter_assets/assets/icon.png
   Terminal=false
   Type=Application
   Categories=Utility;Security;
   EOF
   chmod +x ~/.local/share/applications/universal-qr-scanner.desktop
   ```
3. **Run from Terminal**:
   ```bash
   ~/UniversalQR/Scanner/qrscanner_user_app
   ```

---

### 3.3 macOS Installation (`.tar.gz` / `.app`)

1. **Extract Archive**:
   ```bash
   tar -xzf qrscanner-user-macos-universal.tar.gz -C /Applications/
   ```
2. **First Launch (Gatekeeper Permissions)**:
   - Double-click `Universal QR Scanner.app` in `/Applications`.
   - If prompted by macOS Gatekeeper, navigate to **System Settings > Privacy & Security** and click **Open Anyway**.
3. **Camera Permissions**:
   - When launched for the first time, click **Allow** when macOS requests access to the built-in FaceTime / USB camera.

---

### 3.4 Android Installation (`.apk`)

1. **Enable Unknown Sources**:
   - Navigate to **Settings > Security & Privacy > Install unknown apps** and enable permission for your browser or file manager.
2. **Install APK**:
   - Transfer `app-release.apk` (extracted from `qrscanner-user-android-apk.zip`) to your device and tap to install.
   - Alternatively, install via ADB:
     ```bash
     adb install -r app-release.apk
     ```
3. **Grant Permissions**:
   - Upon first launch, grant **Camera** permission for live QR scanning.

---

### 3.5 iOS Installation (`.ipa`)

1. **Enterprise / Ad-Hoc Distribution**:
   - Install using Apple Configurator, Xcode Devices, or an internal MDM platform.
2. **Simulator Testing**:
   - Unzip `qrscanner-user-ios-app.zip` and drag `Runner.app` onto the iOS Simulator window.
3. **Permissions**:
   - Accept the camera permission prompt (`NSCameraUsageDescription`) when the camera viewfinder opens.

---

## 4. Standalone Artifact Structure

Every distributed archive contains a flat, non-nested file structure:
```
archive-root/
├── <executable-or-app-bundle>
├── INSTALL.md                # Platform-specific quick install instructions
├── BUILD_METADATA.json       # Git commit, build timestamp, target OS, architecture
└── data/ or Frameworks/      # Required runtime assets and dynamic libraries
```
Accompanying detached manifest: `<archive-name>.sha256`
