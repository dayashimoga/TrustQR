import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('DefaultQrScannerEngine Tests', () {
    final engine = const DefaultQrScannerEngine();

    test('Decodes URL correctly and marks https as safe', () async {
      final res = await engine.decodeFromRawString('https://github.com');
      expect(res.payloadType, equals(QrPayloadType.url));
      expect(res.threatLevel, equals(SecurityThreatLevel.safe));
      expect(res.confidence, equals(1.0));
    });

    test('Detects malicious javascript: scheme as critical threat', () async {
      final res = await engine.decodeFromRawString('javascript:alert(1)');
      expect(res.threatLevel, equals(SecurityThreatLevel.critical));
    });

    test('Detects unencrypted http:// as caution', () async {
      final res = await engine.decodeFromRawString('http://insecure-site.org');
      expect(res.payloadType, equals(QrPayloadType.url));
      expect(res.threatLevel, equals(SecurityThreatLevel.caution));
    });

    test('Detects wifi credentials format', () async {
      final res = await engine.decodeFromRawString('WIFI:S:MyNetwork;T:WPA;P:secret123;;');
      expect(res.payloadType, equals(QrPayloadType.wifi));
    });
  });
}
