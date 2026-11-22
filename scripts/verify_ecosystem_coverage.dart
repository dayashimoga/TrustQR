// Universal QR Code Platform — Full Ecosystem Master Coverage Auditor
// Aggregates and verifies line coverage across all 8 monorepo packages, services, and apps
// enforcing the mandatory >= 95.0% line coverage quality gate.

import 'dart:io';

class CoverageRecord {
  final String name;
  final String path;
  final int linesFound;
  final int linesHit;

  const CoverageRecord({
    required this.name,
    required this.path,
    required this.linesFound,
    required this.linesHit,
  });

  double get percentage => linesFound == 0 ? 100.0 : (linesHit / linesFound) * 100.0;
}

CoverageRecord parseLcov(String name, String componentPath) {
  final lcovFile = File('$componentPath/coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    throw Exception('Coverage file missing: ${lcovFile.path}. Run tests with --coverage first.');
  }

  int linesFound = 0;
  int linesHit = 0;

  final lines = lcovFile.readAsLinesSync();
  for (final line in lines) {
    if (line.startsWith('LF:')) {
      linesFound += int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      linesHit += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }

  return CoverageRecord(
    name: name,
    path: componentPath,
    linesFound: linesFound,
    linesHit: linesHit,
  );
}

void main() {
  print('========================================================================');
  print('  UNIVERSAL QR CODE PLATFORM — FULL ECOSYSTEM COVERAGE AUDITOR        ');
  print('  Mandatory Quality Gate: >= 95.0% Line Coverage on All Modules       ');
  print('========================================================================\n');

  final components = [
    {'name': 'packages/qr_core', 'path': 'packages/qr_core'},
    {'name': 'packages/qr_scanner_engine', 'path': 'packages/qr_scanner_engine'},
    {'name': 'packages/qr_generator_engine', 'path': 'packages/qr_generator_engine'},
    {'name': 'packages/qr_design_system', 'path': 'packages/qr_design_system'},
    {'name': 'packages/qr_admin_analytics', 'path': 'packages/qr_admin_analytics'},
    {'name': 'services/rbac_api', 'path': 'services/rbac_api'},
    {'name': 'apps/user_app', 'path': 'apps/user_app'},
    {'name': 'apps/admin_app', 'path': 'apps/admin_app'},
  ];

  final records = <CoverageRecord>[];
  bool allPassed = true;

  for (final comp in components) {
    try {
      final record = parseLcov(comp['name']!, comp['path']!);
      records.add(record);
    } catch (e) {
      stderr.writeln('  [ERROR] ${comp['name']}: $e');
      allPassed = false;
    }
  }

  if (records.isEmpty) {
    stderr.writeln('\n[FATAL] No coverage data could be loaded.');
    exit(1);
  }

  print('| Component                     | Lines Hit | Total Lines | Coverage % | Status |');
  print('| :---------------------------- | :-------- | :---------- | :--------- | :----- |');

  int totalHit = 0;
  int totalFound = 0;

  for (final r in records) {
    totalHit += r.linesHit;
    totalFound += r.linesFound;
    final pctStr = r.percentage.toStringAsFixed(2);
    final isPass = r.percentage >= 95.0;
    if (!isPass) allPassed = false;
    final statusStr = isPass ? 'PASS' : 'FAIL';

    print('| ${r.name.padRight(29)} | ${r.linesHit.toString().padLeft(9)} | ${r.linesFound.toString().padLeft(11)} | ${('$pctStr%').padLeft(10)} | ${statusStr.padRight(6)} |');
  }

  final totalPct = totalFound == 0 ? 100.0 : (totalHit / totalFound) * 100.0;
  final totalPctStr = totalPct.toStringAsFixed(2);
  final overallPass = allPassed && totalPct >= 95.0;

  print('|-------------------------------|-----------|-------------|------------|--------|');
  print('| AGGREGATE ECOSYSTEM TOTAL     | ${totalHit.toString().padLeft(9)} | ${totalFound.toString().padLeft(11)} | ${('$totalPctStr%').padLeft(10)} | ${(overallPass ? 'PASS' : 'FAIL').padRight(6)} |');
  print('========================================================================');

  print('\nEcosystem Coverage Summary:');
  print('  - Monorepo Modules Audited: ${records.length} / ${components.length}');
  print('  - Total Lines Covered:      $totalHit / $totalFound');
  print('  - Aggregate Line Coverage:  $totalPctStr%');
  print('  - Mandatory Quality Gate:   >= 95.0%');

  if (!overallPass) {
    stderr.writeln('\n[FAILED] One or more components failed the mandatory >= 95.0% coverage threshold.');
    exit(1);
  }

  print('\n[SUCCESS] Entire ecosystem satisfies mandatory >= 95.0% coverage quality gate.');
  exit(0);
}
