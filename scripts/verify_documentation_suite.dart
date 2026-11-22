// Automated Documentation Suite Auditor
// Verifies presence, file size, markdown link integrity, and completeness
// across the entire Universal QR Platform documentation repository.

import 'dart:io';

class DocAuditResult {
  final String path;
  final bool exists;
  final int byteLength;
  final List<String> issues;

  DocAuditResult({
    required this.path,
    required this.exists,
    required this.byteLength,
    required this.issues,
  });

  bool get isPassed => exists && issues.isEmpty;
}

void main() {
  print('===========================================================');
  print('  UNIVERSAL QR CODE PLATFORM — DOCUMENTATION AUDITOR       ');
  print('===========================================================');

  final rootDir = Directory.current;

  final mandatoryDocs = <String, int>{
    'README.md': 1000,
    'AGENTS.md': 2000,
    'CHANGELOG.md': 5000,
    'TODO.md': 5000,
    'docs/ARCHITECTURE.md': 5000,
    'docs/REQUIREMENTS.md': 5000,
    'docs/ROADMAP.md': 10000,
    'docs/PROGRESS_TRACKER.md': 5000,
    'docs/SECURITY.md': 4000,
    'docs/TESTING.md': 4000,
    'docs/USER_GUIDE.md': 4000,
    'docs/ONBOARDING.md': 3000,
    'docs/INSTALL.md': 3000,
  };

  int totalPassed = 0;
  int totalFailed = 0;

  print('\n[1] Auditing Mandatory Documentation Files & Size Thresholds:');

  for (final entry in mandatoryDocs.entries) {
    final relPath = entry.key;
    final minSize = entry.value;
    final file = File('${rootDir.path}/$relPath');

    if (!file.existsSync()) {
      print('  [FAIL] Missing mandatory doc: $relPath');
      totalFailed++;
      continue;
    }

    final length = file.lengthSync();
    if (length < minSize) {
      print('  [FAIL] $relPath length ($length bytes) is below minimum threshold ($minSize bytes)');
      totalFailed++;
      continue;
    }

    print('  [PASS] $relPath ($length bytes, minimum: $minSize bytes)');
    totalPassed++;
  }

  print('\n[2] Auditing Relative Markdown Link Targets:');
  final markdownLinkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

  for (final relPath in mandatoryDocs.keys) {
    final file = File('${rootDir.path}/$relPath');
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();
    final parentDir = file.parent.path;
    final matches = markdownLinkRegex.allMatches(content);

    int fileLinkIssues = 0;

    for (final match in matches) {
      final target = match.group(2) ?? '';
      
      // Ignore external web links, mailto, anchor fragments, and schemas
      if (target.startsWith('http://') ||
          target.startsWith('https://') ||
          target.startsWith('mailto:') ||
          target.startsWith('#') ||
          target.startsWith('file://')) {
        continue;
      }

      // Strip query parameters or anchor hashes from relative file paths
      final cleanTarget = target.split('#').first.split('?').first;
      if (cleanTarget.isEmpty) continue;

      // Resolve relative path
      String targetPath;
      if (cleanTarget.startsWith('/')) {
        targetPath = '${rootDir.path}$cleanTarget';
      } else {
        targetPath = '$parentDir/$cleanTarget';
      }

      final normalizedPath = File(targetPath).resolveSymbolicLinksSyncOrSelf();
      final targetFile = File(normalizedPath);
      final targetDir = Directory(normalizedPath);

      if (!targetFile.existsSync() && !targetDir.existsSync()) {
        print('  [FAIL] Broken link in $relPath: "$target" -> "$targetPath" does not exist.');
        fileLinkIssues++;
        totalFailed++;
      }
    }

    if (fileLinkIssues == 0) {
      print('  [PASS] All relative links in $relPath resolve cleanly.');
      totalPassed++;
    }
  }

  print('\n[3] Auditing Final Progress Tracker Status:');
  final trackerFile = File('${rootDir.path}/docs/PROGRESS_TRACKER.md');
  if (trackerFile.existsSync()) {
    final trackerContent = trackerFile.readAsStringSync();
    if (trackerContent.contains('- **Blocked Subphases**: 0')) {
      print('  [PASS] Zero blocked subphases recorded.');
      totalPassed++;
    } else {
      print('  [FAIL] Blocked subphases detected in PROGRESS_TRACKER.md');
      totalFailed++;
    }
  }

  print('\n-----------------------------------------------------------');
  print('Documentation Auditor Summary: $totalPassed passed, $totalFailed failed.');

  if (totalFailed > 0) {
    print('[ERROR] Documentation auditor identified defects.');
    exit(1);
  }

  print('[SUCCESS] All documentation files and cross-links verified cleanly!');
  print('===========================================================');
}

extension FileUtils on File {
  String resolveSymbolicLinksSyncOrSelf() {
    try {
      return resolveSymbolicLinksSync();
    } catch (_) {
      return path;
    }
  }
}
