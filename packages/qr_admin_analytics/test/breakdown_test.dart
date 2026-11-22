import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('PayloadDistribution Tests', () {
    test('Calculates percentages, top format, and top non-url format correctly', () {
      final rawCounts = {
        QrPayloadType.url: 50,
        QrPayloadType.wifi: 30,
        QrPayloadType.vcard: 20,
      };

      final distribution = PayloadDistribution.fromCounts(rawCounts);

      expect(distribution.totalCount, equals(100));
      expect(distribution.counts[QrPayloadType.url], equals(50));
      expect(distribution.percentages[QrPayloadType.url], equals(50.0));
      expect(distribution.counts[QrPayloadType.wifi], equals(30));
      expect(distribution.percentages[QrPayloadType.wifi], equals(30.0));
      expect(distribution.counts[QrPayloadType.vcard], equals(20));
      expect(distribution.percentages[QrPayloadType.vcard], equals(20.0));

      // All 15 formats accounted for
      expect(distribution.counts.length, equals(QrPayloadType.values.length));
      expect(distribution.percentages.length, equals(QrPayloadType.values.length));
      expect(distribution.counts[QrPayloadType.email], equals(0));
      expect(distribution.percentages[QrPayloadType.email], equals(0.0));

      // Top format is URL
      expect(distribution.topFormat, equals(QrPayloadType.url));
      // Top non-URL format is Wi-Fi
      expect(distribution.topNonUrlFormat, equals(QrPayloadType.wifi));

      // Serialization round-trip
      final json = distribution.toJson();
      final restored = PayloadDistribution.fromJson(json);

      expect(restored.totalCount, equals(100));
      expect(restored.topFormat, equals(QrPayloadType.url));
      expect(restored.topNonUrlFormat, equals(QrPayloadType.wifi));
      expect(restored.counts[QrPayloadType.wifi], equals(30));
    });

    test('Handles empty counts without errors', () {
      final distribution = PayloadDistribution.fromCounts(const {});
      expect(distribution.totalCount, equals(0));
      expect(distribution.topFormat, isNull);
      expect(distribution.topNonUrlFormat, isNull);
      expect(distribution.percentages[QrPayloadType.url], equals(0.0));
    });
  });

  group('PayloadDistributionCalculator Tests', () {
    test('Records single and batch payloads and resets cleanly', () {
      final calculator = PayloadDistributionCalculator();

      calculator.recordPayload(QrPayloadType.sms);
      calculator.recordPayload(QrPayloadType.sms);
      calculator.recordPayloads([
        QrPayloadType.geo,
        QrPayloadType.geo,
        QrPayloadType.geo,
        QrPayloadType.event,
      ]);

      final dist = calculator.calculate();
      expect(dist.totalCount, equals(6));
      expect(dist.counts[QrPayloadType.sms], equals(2));
      expect(dist.counts[QrPayloadType.geo], equals(3));
      expect(dist.counts[QrPayloadType.event], equals(1));
      expect(dist.topFormat, equals(QrPayloadType.geo));

      // Test calculate from external QrVaultItem list
      final externalItems = [
        QrVaultItem(
          id: 'ext_1',
          rawContent: 'test',
          payloadType: QrPayloadType.wifi,
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
      ];
      final extDist = calculator.calculate(externalItems);
      expect(extDist.totalCount, equals(1));
      expect(extDist.counts[QrPayloadType.wifi], equals(1));

      calculator.reset();
      final emptyDist = calculator.calculate();
      expect(emptyDist.totalCount, equals(0));
    });
  });
}
