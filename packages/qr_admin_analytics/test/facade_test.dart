import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  final testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i + 5));
  final auditPrivateKey = CryptoPrivateKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'audit_key_01',
  );
  final auditPublicKey = CryptoPublicKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'audit_key_01',
  );

  group('AdminAnalyticsFacade Tests', () {
    test('Orchestrates end-to-end ingestion, reporting, exports, and audit verification', () {
      final facade = AdminAnalyticsFacade(
        auditPrivateKey: auditPrivateKey,
        auditPublicKey: auditPublicKey,
      );

      final now = DateTime.utc(2026, 11, 22, 10, 0);

      // Ingest scan events
      facade.recordScanTelemetry(
        payloadType: QrPayloadType.url,
        safetyScore: 98,
        threatLevel: SecurityThreatLevel.safe,
        domain: 'trusted.com',
        timestamp: now,
      );

      facade.recordScanTelemetry(
        payloadType: QrPayloadType.url,
        safetyScore: 20,
        threatLevel: SecurityThreatLevel.critical,
        threatFlags: ['phishing_detected'],
        domain: 'phish-evil.com',
        timestamp: now.add(const Duration(hours: 1)),
      );

      facade.recordScanTelemetry(
        payloadType: QrPayloadType.wifi,
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        timestamp: now.add(const Duration(hours: 2)),
      );

      // Ingest generation events
      facade.recordGenerationTelemetry(
        payloadType: QrPayloadType.vcard,
        timestamp: now.add(const Duration(hours: 3)),
      );
      facade.recordGenerationTelemetry(
        payloadType: QrPayloadType.url,
        timestamp: now.add(const Duration(hours: 4)),
      );

      // Register fleet hardware and tokens
      facade.fleet.registerDevice(
        deviceId: 'dev_hq_01',
        deviceName: 'HQ Terminal A',
        os: 'Windows 11',
        appVersion: '1.2.0',
        registeredAt: now,
      );

      facade.fleet.registerToken(
        TrustQrTokenRecord(
          tokenId: 'tok_fleet_01',
          subject: 'admin@hq.corp',
          role: UserRole.admin,
          issuer: 'hq_authority',
          issuedAt: now,
          expiresAt: now.add(const Duration(days: 30)),
        ),
      );

      // Record administrative audit actions
      final logEntry = facade.recordAdminAction(
        action: 'POLICY_UPDATE',
        actorId: 'super_admin',
        actorRole: 'admin',
        targetId: 'firewall_policy_v2',
        details: {'minSafetyScore': 75},
        timestamp: now.add(const Duration(hours: 5)),
      );

      expect(logEntry.action, equals('POLICY_UPDATE'));
      expect(facade.audit.count, equals(1));

      // Verify audit integrity
      final auditResult = facade.verifyAuditIntegrity();
      expect(auditResult.isValid, isTrue);
      expect(auditResult.totalChecked, equals(1));

      // Generate consolidated report
      final report = facade.generateConsolidatedReport(
        reportId: 'rep_facade_test_01',
        generatedAt: now.add(const Duration(hours: 6)),
        interval: TimeSeriesBucketInterval.hourly,
      );

      expect(report.reportId, equals('rep_facade_test_01'));
      expect(report.timeSeriesMetrics.totalScans, equals(3));
      expect(report.timeSeriesMetrics.totalGenerations, equals(2));
      expect(report.timeSeriesMetrics.totalThreats, equals(1));
      expect(report.payloadDistribution.totalCount, equals(5));
      expect(report.threatSummary.totalAudited, equals(3));
      expect(report.threatSummary.criticalCount, equals(1));
      expect(report.fleetSummary.totalDevices, equals(1));
      expect(report.fleetSummary.totalTokens, equals(1));
      expect(report.totalAuditLogs, equals(1));
      expect(report.verifyFingerprint(), isTrue);

      // Export methods
      final jsonOutput = facade.exportReportJson(report);
      expect(jsonOutput, contains('"rep_facade_test_01"'));

      final tsCsv = facade.exportTimeSeriesCsv(interval: TimeSeriesBucketInterval.hourly);
      expect(tsCsv, contains('bucket_timestamp,interval,scans'));

      final payloadCsv = facade.exportPayloadDistributionCsv();
      expect(payloadCsv, contains('url,3'));

      final threatCsv = facade.exportThreatAuditCsv();
      expect(threatCsv, contains('phish-evil.com,1'));

      final customItem = QrVaultItem(
        id: 'c1',
        rawContent: 'https://custom.org',
        payloadType: QrPayloadType.url,
        safetyScore: 99,
        threatLevel: SecurityThreatLevel.safe,
        origin: QrItemOrigin.scanned,
        createdAt: now,
        integrityHash: '',
      );
      final customPayloadCsv = facade.exportPayloadDistributionCsv([customItem]);
      expect(customPayloadCsv, contains('url,1'));
      final customThreatCsv = facade.exportThreatAuditCsv([customItem]);
      expect(customThreatCsv, contains('total_audited,1'));

      final fleetCsv = facade.exportFleetInventoryCsv();
      expect(fleetCsv, contains('dev_hq_01'));
      expect(fleetCsv, contains('tok_fleet_01'));

      // Clear telemetry
      facade.clearTelemetry();
      final clearedReport = facade.generateConsolidatedReport();
      expect(clearedReport.timeSeriesMetrics.totalScans, equals(0));
    });
  });
}
