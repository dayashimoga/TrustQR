import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('qr_admin_analytics Library Re-export Tests', () {
    test('Verifies all subsystem exports are accessible and function cohesively', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final privKey = CryptoPrivateKey(
        bytes: key,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: 'k1',
      );
      final pubKey = CryptoPublicKey(
        bytes: key,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: 'k1',
      );

      final facade = AdminAnalyticsFacade(
        auditPrivateKey: privKey,
        auditPublicKey: pubKey,
      );

      expect(facade.timeSeries, isA<TimeSeriesAggregator>());
      expect(facade.payloadCalculator, isA<PayloadDistributionCalculator>());
      expect(facade.threatEngine, isA<ThreatAnalyticsEngine>());
      expect(facade.fleet, isA<FleetRegistry>());
      expect(facade.audit, isA<AuditLogEngine>());

      final report = facade.generateConsolidatedReport();
      expect(report.sha256Fingerprint.length, equals(64));
      expect(report.verifyFingerprint(), isTrue);

      // Verify AdminAnalyticsService legacy adapter
      const service = AdminAnalyticsService();
      final items = [
        QrVaultItem(
          id: 'v1',
          rawContent: 'https://test.com',
          payloadType: QrPayloadType.url,
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v2',
          rawContent: 'javascript:alert(1)',
          payloadType: QrPayloadType.plainText,
          safetyScore: 10,
          threatLevel: SecurityThreatLevel.critical,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
      ];
      final summary = service.aggregateMetrics(items: items, generationCount: 3);
      expect(summary.totalScans, equals(2));
      expect(summary.totalGenerations, equals(3));
      expect(summary.threatsDetected, equals(1));
      expect(summary.toJson()['totalScans'], equals(2));
    });
  });
}
