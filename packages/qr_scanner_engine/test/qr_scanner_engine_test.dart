import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('DefaultQrScannerEngine Tests', () {
    final engine = DefaultQrScannerEngine();

    test('Decodes URL correctly and marks https as safe', () async {
      final res = await engine.decodeFromRawString('https://github.com');
      expect(res.payloadType, equals(QrPayloadType.url));
      expect(res.threatLevel, equals(SecurityThreatLevel.safe));
      expect(res.threatAssessment.isSafe, isTrue);
      expect(res.confidence, equals(1.0));
      expect(res.rawContent, equals('https://github.com'));
    });

    test('Detects malicious javascript: scheme as critical threat', () async {
      final res = await engine.decodeFromRawString('javascript:alert(1)');
      expect(res.threatLevel, equals(SecurityThreatLevel.critical));
      expect(res.threatAssessment.isCritical, isTrue);
      expect(res.threatAssessment.isActionAllowed, isFalse);
    });

    test('Detects unencrypted http:// as caution or suspicious', () async {
      final res = await engine.decodeFromRawString('http://insecure-site.org');
      expect(res.payloadType, equals(QrPayloadType.url));
      expect(res.threatLevel, equals(SecurityThreatLevel.caution));
    });

    test('Detects wifi credentials format and inspects open network', () async {
      final res = await engine.decodeFromRawString('WIFI:S:MyNetwork;T:WPA;P:secret123;;');
      expect(res.payloadType, equals(QrPayloadType.wifi));
      expect(res.threatLevel, equals(SecurityThreatLevel.safe));
    });

    test('Bypasses threat firewall when options disable it', () async {
      final res = await engine.decodeFromRawString(
        'javascript:alert(1)',
        options: const ScannerOptions(enableThreatFirewall: false),
      );
      expect(res.threatLevel, equals(SecurityThreatLevel.safe));
      expect(res.threatAssessment.summary, contains('bypassed'));
    });
  });
}
