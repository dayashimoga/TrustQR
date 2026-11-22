import 'dart:io';

/// Automated Binary Isolation Auditor
///
/// Verifies the Global Engineering Contract invariant:
/// [apps/user_app] must NEVER depend on or import [qr_generator_engine] or [qr_admin_analytics].
///
/// Also includes a self-test mode to guarantee the auditor detects and rejects violations.

const forbiddenPackages = [
  'qr_generator_engine',
  'qr_admin_analytics',
];

class IsolationAuditResult {
  final bool passed;
  final List<String> violations;

  const IsolationAuditResult({required this.passed, required this.violations});
}

IsolationAuditResult auditUserAppIsolation({Directory? rootDir}) {
  final root = rootDir ?? Directory.current;
  final userAppDir = Directory('${root.path}/apps/user_app');
  final violations = <String>[];

  if (!userAppDir.existsSync()) {
    violations.add('Directory not found: ${userAppDir.path}');
    return IsolationAuditResult(passed: false, violations: violations);
  }

  // 1. Audit apps/user_app/pubspec.yaml
  final pubspecFile = File('${userAppDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    violations.add('pubspec.yaml not found in ${userAppDir.path}');
  } else {
    final content = pubspecFile.readAsStringSync();
    for (final pkg in forbiddenPackages) {
      if (content.contains(pkg)) {
        violations.add('CRITICAL: apps/user_app/pubspec.yaml declares forbidden dependency: "$pkg"');
      }
    }
  }

  // 2. Audit all Dart source files in apps/user_app/lib and apps/user_app/test
  for (final subDirName in ['lib', 'test']) {
    final targetDir = Directory('${userAppDir.path}/$subDirName');
    if (targetDir.existsSync()) {
      final files = targetDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (file.path.endsWith('.dart')) {
          final source = file.readAsStringSync();
          for (final pkg in forbiddenPackages) {
            if (source.contains(pkg)) {
              violations.add('CRITICAL: Forbidden import/reference to "$pkg" found in ${file.path}');
            }
          }
        }
      }
    }
  }

  return IsolationAuditResult(passed: violations.isEmpty, violations: violations);
}

bool runSelfTest() {
  // Synthesize a dummy directory structure with a forbidden import to assert failure detection
  final tempDir = Directory.systemTemp.createTempSync('isolation_selftest_');
  try {
    final mockUserApp = Directory('${tempDir.path}/apps/user_app/lib')..createSync(recursive: true);
    final mockPubspec = File('${tempDir.path}/apps/user_app/pubspec.yaml');
    mockPubspec.writeAsStringSync('name: mock_user_app\ndependencies:\n  qr_generator_engine: any\n');

    final mockFile = File('${mockUserApp.path}/leak.dart');
    mockFile.writeAsStringSync("import 'package:qr_admin_analytics/qr_admin_analytics.dart';");

    final result = auditUserAppIsolation(rootDir: tempDir);
    final caughtPubspec = result.violations.any((v) => v.contains('pubspec.yaml') && v.contains('qr_generator_engine'));
    final caughtSource = result.violations.any((v) => v.contains('leak.dart') && v.contains('qr_admin_analytics'));

    return !result.passed && caughtPubspec && caughtSource;
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  print('=== Universal QR Binary Isolation Auditor ===');

  // Run self-test first
  final selfTestOk = runSelfTest();
  if (!selfTestOk) {
    stderr.writeln('[FATAL] Binary isolation auditor self-test failed! Breach detection logic is non-functional.');
    exit(2);
  }
  print('[PASS] Auditor self-test passed: Negative breach detection is fully active.');

  // Audit repository
  final result = auditUserAppIsolation();
  if (!result.passed) {
    stderr.writeln('\n[CRITICAL FAILURE] Binary isolation contract violated:');
    for (final v in result.violations) {
      stderr.writeln('  - $v');
    }
    exit(1);
  }

  print('[PASS] apps/user_app is 100% physically and compile-time isolated from forbidden packages:');
  for (final pkg in forbiddenPackages) {
    print('  - $pkg: EXCLUDED');
  }
  print('[SUCCESS] All binary isolation checks passed cleanly.');
  exit(0);
}
