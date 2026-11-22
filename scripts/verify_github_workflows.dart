// Universal QR Platform — GitHub Actions Workflow Validator
// Audits CI quality gate and build-release matrix workflow configurations,
// YAML structure, dispatch inputs, platform matrices, packaging invocations,
// and binary isolation requirements.

import 'dart:io';

void main() {
  print('=== Universal QR GitHub Actions Workflow Auditor ===');

  final rootDir = Directory.current;
  final ciWorkflowFile = File('${rootDir.path}/.github/workflows/ci-quality-gate.yml');
  final buildWorkflowFile = File('${rootDir.path}/.github/workflows/build-release-matrix.yml');

  int passCount = 0;
  int failCount = 0;

  void assertRule(String checkName, bool condition, String failureDetails) {
    if (condition) {
      print('  [PASS] $checkName');
      passCount++;
    } else {
      stderr.writeln('  [FAIL] $checkName: $failureDetails');
      failCount++;
    }
  }

  print('\n[1] Verifying Workflow File Existence:');
  assertRule(
    '.github/workflows/ci-quality-gate.yml exists',
    ciWorkflowFile.existsSync(),
    'File missing: ${ciWorkflowFile.path}',
  );
  assertRule(
    '.github/workflows/build-release-matrix.yml exists',
    buildWorkflowFile.existsSync(),
    'File missing: ${buildWorkflowFile.path}',
  );

  if (!ciWorkflowFile.existsSync() || !buildWorkflowFile.existsSync()) {
    stderr.writeln('ERROR: One or more workflow files do not exist.');
    exit(1);
  }

  final ciYaml = ciWorkflowFile.readAsStringSync();
  final buildYaml = buildWorkflowFile.readAsStringSync();

  print('\n[2] Verifying CI Quality Gate Workflow (.github/workflows/ci-quality-gate.yml):');

  assertRule(
    'CI triggers on push to main',
    ciYaml.contains('branches: [ main ]') || ciYaml.contains('branches:\n    - main'),
    'Expected push trigger on main branch',
  );
  assertRule(
    'CI triggers on pull_request to main',
    ciYaml.contains('pull_request:'),
    'Expected pull_request trigger',
  );
  assertRule(
    'CI triggers on workflow_dispatch',
    ciYaml.contains('workflow_dispatch:'),
    'Expected workflow_dispatch trigger',
  );
  assertRule(
    'CI executes Gate 1: Compile-Time Binary Isolation Audit',
    ciYaml.contains('dart run scripts/verify_binary_isolation.dart'),
    'Missing dart run scripts/verify_binary_isolation.dart in CI steps',
  );
  assertRule(
    'CI executes Gate 2: Native Runner Configuration Auditor',
    ciYaml.contains('dart run scripts/verify_native_runner_configs.dart'),
    'Missing dart run scripts/verify_native_runner_configs.dart in CI steps',
  );
  assertRule(
    'CI executes Gate 3: Monorepo Static Analysis (--fatal-infos --fatal-warnings)',
    ciYaml.contains('flutter analyze --fatal-infos --fatal-warnings .'),
    'Missing flutter analyze in CI steps',
  );
  assertRule(
    'CI executes Gate 4: Adversarial Threat Firewall Corpus (150 vectors)',
    ciYaml.contains('packages/qr_scanner_engine') && ciYaml.contains('test/adversarial/'),
    'Missing adversarial threat corpus run in CI steps',
  );
  assertRule(
    'CI executes Gate 4: Server-Side RBAC Penetration Suite',
    ciYaml.contains('services/rbac_api') && ciYaml.contains('test/penetration_test.dart'),
    'Missing RBAC penetration suite in CI steps',
  );
  assertRule(
    'CI executes Gate 5: Coverage Gate (>=95% target)',
    ciYaml.contains('check_coverage') && ciYaml.contains('95'),
    'Missing coverage gate enforcement (>=95%)',
  );
  assertRule(
    'CI executes Gate 6: Standalone Packaging Pipeline Test',
    ciYaml.contains('scripts/package_artifact.sh'),
    'Missing package_artifact.sh execution in CI steps',
  );

  print('\n[3] Verifying Build & Release Matrix (.github/workflows/build-release-matrix.yml):');

  assertRule(
    'Build matrix triggers on push tags (v*)',
    buildYaml.contains("tags:\n      - 'v*'") || buildYaml.contains("tags: [ 'v*' ]") || buildYaml.contains("tags:\n      - \"v*\""),
    'Missing tag trigger for v*',
  );
  assertRule(
    'Build matrix triggers on workflow_dispatch',
    buildYaml.contains('workflow_dispatch:'),
    'Missing workflow_dispatch trigger',
  );

  // Dispatch inputs
  assertRule(
    'workflow_dispatch input: target_app (all, admin_app, user_app)',
    buildYaml.contains('target_app:') &&
        buildYaml.contains('- all') &&
        buildYaml.contains('- admin_app') &&
        buildYaml.contains('- user_app'),
    'Missing or invalid target_app input definition',
  );
  assertRule(
    'workflow_dispatch input: target_platform (all, android, ios, windows, linux, macos)',
    buildYaml.contains('target_platform:') &&
        buildYaml.contains('- all') &&
        buildYaml.contains('- android') &&
        buildYaml.contains('- ios') &&
        buildYaml.contains('- windows') &&
        buildYaml.contains('- linux') &&
        buildYaml.contains('- macos'),
    'Missing or invalid target_platform input definition',
  );
  assertRule(
    'workflow_dispatch input: build_mode (release, debug, profile)',
    buildYaml.contains('build_mode:') &&
        buildYaml.contains('- release') &&
        buildYaml.contains('- debug') &&
        buildYaml.contains('- profile'),
    'Missing or invalid build_mode input definition',
  );
  assertRule(
    'workflow_dispatch input: publish_release (boolean)',
    buildYaml.contains('publish_release:') && buildYaml.contains('type: boolean'),
    'Missing or invalid publish_release input definition',
  );

  // Preflight Quality Audit Job
  assertRule(
    'Pre-build governance quality gate (preflight-audit)',
    buildYaml.contains('preflight-audit:') &&
        buildYaml.contains('scripts/verify_binary_isolation.dart') &&
        buildYaml.contains('scripts/verify_native_runner_configs.dart') &&
        buildYaml.contains('flutter analyze'),
    'Missing preflight-audit job with binary isolation and static analysis',
  );

  // Platform Runner Environments
  assertRule(
    'Platform builder: windows-latest runner',
    buildYaml.contains('build-windows:') && buildYaml.contains('runs-on: windows-latest'),
    'Missing windows-latest builder job',
  );
  assertRule(
    'Platform builder: ubuntu-latest runner (Linux & Android)',
    buildYaml.contains('build-linux:') &&
        buildYaml.contains('runs-on: ubuntu-latest') &&
        buildYaml.contains('build-android:'),
    'Missing ubuntu-latest builder jobs for Linux and Android',
  );
  assertRule(
    'Platform builder: macos-latest runner (macOS & iOS)',
    buildYaml.contains('build-apple:') && buildYaml.contains('runs-on: macos-latest'),
    'Missing macos-latest builder job for Apple platforms',
  );

  // Standalone Packaging Invocations
  assertRule(
    'Invokes scripts/package_artifact.ps1 on Windows',
    buildYaml.contains('scripts/package_artifact.ps1'),
    'Missing package_artifact.ps1 call in windows build',
  );
  assertRule(
    'Invokes scripts/package_artifact.sh on Linux, Android, and macOS/iOS',
    buildYaml.contains('scripts/package_artifact.sh'),
    'Missing package_artifact.sh call in POSIX builds',
  );

  // Standalone Artifact Uploads
  assertRule(
    'Uploads standalone non-nested artifacts via actions/upload-artifact@v4',
    buildYaml.contains('actions/upload-artifact@v4') &&
        buildYaml.contains('qrscanner-') &&
        buildYaml.contains('dist/artifacts/qrscanner-'),
    'Missing actions/upload-artifact@v4 for standalone artifacts',
  );

  // Release Publishing Job
  assertRule(
    'Publishes GitHub Release with standalone assets and SHA-256 manifests',
    buildYaml.contains('publish-release:') &&
        buildYaml.contains('softprops/action-gh-release@v2') &&
        buildYaml.contains('*.sha256'),
    'Missing publish-release job with action-gh-release',
  );

  print('\n-----------------------------------------------------------');
  print('Workflow Auditor Summary: $passCount passed, $failCount failed.');

  if (failCount > 0) {
    stderr.writeln('[FAILED] GitHub Actions workflow files have validation errors.');
    exit(1);
  }

  print('[SUCCESS] All GitHub Actions CI/CD workflows strictly verified.');
  exit(0);
}
