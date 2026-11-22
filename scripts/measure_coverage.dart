import 'dart:io';

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final file = File(lcovPath);
  if (!file.existsSync()) {
    print('Coverage file not found: $lcovPath');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  var totalLines = 0;
  var hitLines = 0;
  String currentFile = '';
  final missedByFile = <String, List<int>>{};
  final hitByFile = <String, int>{};
  final totalByFile = <String, int>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).trim();
      missedByFile.putIfAbsent(currentFile, () => []);
      hitByFile.putIfAbsent(currentFile, () => 0);
      totalByFile.putIfAbsent(currentFile, () => 0);
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNum = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      totalLines++;
      totalByFile[currentFile] = (totalByFile[currentFile] ?? 0) + 1;
      if (hits > 0) {
        hitLines++;
        hitByFile[currentFile] = (hitByFile[currentFile] ?? 0) + 1;
      } else {
        missedByFile[currentFile]!.add(lineNum);
      }
    }
  }

  print('============================================================');
  print('                  COVERAGE REPORT                           ');
  print('============================================================');
  for (final entry in totalByFile.entries) {
    final filePath = entry.key;
    final total = entry.value;
    final hit = hitByFile[filePath] ?? 0;
    final pct = total > 0 ? (hit / total * 100).toStringAsFixed(1) : '100.0';
    final fileName = filePath.split(Platform.isWindows ? '\\' : '/').last;
    final misses = missedByFile[filePath] ?? [];
    print('${fileName.padRight(30)} : $hit / $total ($pct%) | Missed: $misses');
  }

  final totalPct = totalLines > 0 ? (hitLines / totalLines * 100) : 100.0;
  print('------------------------------------------------------------');
  print('OVERALL LINE COVERAGE: $hitLines / $totalLines (${totalPct.toStringAsFixed(2)}%)');
  print('============================================================');

  if (totalPct < 95.0) {
    print('FAILURE: Line coverage ${totalPct.toStringAsFixed(2)}% is below 95.0% threshold.');
    exit(2);
  } else {
    print('SUCCESS: Line coverage meets mandatory >= 95.0% threshold.');
  }
}
