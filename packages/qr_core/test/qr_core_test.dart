import 'package:test/test.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('QrCore Domain Model Tests', () {
    test('QrPayloadType enums contain 15 distinct formats', () {
      expect(QrPayloadType.values.length, equals(15));
      expect(QrPayloadType.values, contains(QrPayloadType.url));
      expect(QrPayloadType.values, contains(QrPayloadType.wifi));
      expect(QrPayloadType.values, contains(QrPayloadType.vcard));
      expect(QrPayloadType.values, contains(QrPayloadType.upi));
      expect(QrPayloadType.values, contains(QrPayloadType.otpauth));
      expect(QrPayloadType.values, contains(QrPayloadType.plainText));
    });

    test('SecurityThreatLevel contains expected hierarchy', () {
      expect(SecurityThreatLevel.values.length, equals(4));
      expect(SecurityThreatLevel.safe.index, lessThan(SecurityThreatLevel.critical.index));
    });

    test('QrItem serialization produces valid JSON', () {
      final now = DateTime.now();
      final item = QrItem(
        id: 'test-123',
        rawContent: 'https://example.com',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.safe,
        createdAt: now,
        isFavorite: true,
        tags: ['work', 'verified'],
      );

      final json = item.toJson();
      expect(json['id'], equals('test-123'));
      expect(json['payloadType'], equals('url'));
      expect(json['threatLevel'], equals('safe'));
      expect(json['isFavorite'], isTrue);
      expect(json['tags'], equals(['work', 'verified']));
    });
  });
}
