import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';

void main() {
  group('AdminAnalyticsService Tests', () {
    const service = AdminAnalyticsService();

    test('Aggregates metrics correctly from items', () {
      final now = DateTime.now();
      final items = [
        QrItem(
          id: '1',
          rawContent: 'https://test.com',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
          createdAt: now,
        ),
        QrItem(
          id: '2',
          rawContent: 'javascript:alert(1)',
          payloadType: QrPayloadType.plainText,
          threatLevel: SecurityThreatLevel.critical,
          createdAt: now,
        ),
      ];

      final summary = service.aggregateMetrics(items: items, generationCount: 5);
      expect(summary.totalScans, equals(2));
      expect(summary.totalGenerations, equals(5));
      expect(summary.threatsDetected, equals(1));
      expect(summary.scansByPayloadType[QrPayloadType.url], equals(1));
    });
  });
}
