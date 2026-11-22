import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('AnalyticsReport Tests', () {
    final now = DateTime.utc(2026, 11, 22, 12, 0);

    final timeSeriesMetrics = TimeSeriesMetrics(
      points: [
        TimeSeriesPoint(
          timestamp: now,
          scanCount: 25,
          generationCount: 5,
          threatCount: 2,
        ),
      ],
      interval: TimeSeriesBucketInterval.daily,
      totalScans: 25,
      totalGenerations: 5,
      totalThreats: 2,
      averageVolumePerBucket: 30.0,
      volumeStandardDeviation: 0.0,
      peakVolume: 30,
      peakTimestamp: now,
    );

    final payloadDistribution = PayloadDistribution.fromCounts({
      QrPayloadType.url: 20,
      QrPayloadType.wifi: 10,
    });

    final threatSummary = ThreatAnalyticsSummary(
      totalAudited: 25,
      safeCount: 23,
      cautionCount: 1,
      suspiciousCount: 1,
      criticalCount: 0,
      averageSafetyScore: 92.5,
      attackCategoryCounts: {'Phishing / Social Engineering': 2},
      topMaliciousDomains: {'bad.com': 2},
      scoreHistogram: {'80-100': 23, '40-59': 2},
    );

    const fleetSummary = FleetSummary(
      totalDevices: 10,
      activeDevices: 8,
      revokedDevices: 2,
      totalTokens: 5,
      activeTokens: 4,
      revokedTokens: 1,
      expiredTokens: 0,
      devicesByOs: {'Android': 6, 'iOS': 4},
    );

    test('Creates report, verifies cryptographic fingerprint, and serializes correctly', () {
      final report = AnalyticsReport.create(
        reportId: 'rep_20261122_01',
        generatedAt: now,
        timeSeriesMetrics: timeSeriesMetrics,
        payloadDistribution: payloadDistribution,
        threatSummary: threatSummary,
        fleetSummary: fleetSummary,
        totalAuditLogs: 15,
      );

      // Verify fingerprint matches
      expect(report.verifyFingerprint(), isTrue);
      expect(report.sha256Fingerprint.length, equals(64));

      // Tampered report fails fingerprint verification
      final tampered = AnalyticsReport(
        reportId: report.reportId,
        generatedAt: report.generatedAt,
        timeSeriesMetrics: report.timeSeriesMetrics,
        payloadDistribution: report.payloadDistribution,
        threatSummary: report.threatSummary,
        fleetSummary: const FleetSummary(
          totalDevices: 999, // Tampered
          activeDevices: 8,
          revokedDevices: 2,
          totalTokens: 5,
          activeTokens: 4,
          revokedTokens: 1,
          expiredTokens: 0,
          devicesByOs: {},
        ),
        totalAuditLogs: report.totalAuditLogs,
        sha256Fingerprint: report.sha256Fingerprint,
      );
      expect(tampered.verifyFingerprint(), isFalse);

      // JSON serialization round-trip
      final json = report.toJson();
      final restored = AnalyticsReport.fromJson(json);

      expect(restored.reportId, equals(report.reportId));
      expect(restored.totalAuditLogs, equals(15));
      expect(restored.sha256Fingerprint, equals(report.sha256Fingerprint));
      expect(restored.verifyFingerprint(), isTrue);
    });

    test('AnalyticsReportExporter exports JSON and all CSV variations correctly', () {
      final report = AnalyticsReport.create(
        reportId: 'rep_export_test',
        generatedAt: now,
        timeSeriesMetrics: timeSeriesMetrics,
        payloadDistribution: payloadDistribution,
        threatSummary: threatSummary,
        fleetSummary: fleetSummary,
        totalAuditLogs: 5,
      );

      // JSON Export (standard & pretty)
      final jsonStr = AnalyticsReportExporter.exportToJson(report);
      expect(jsonStr, contains('"reportId":"rep_export_test"'));

      final prettyJson = AnalyticsReportExporter.exportToJson(report, pretty: true);
      expect(prettyJson, contains('  "reportId": "rep_export_test"'));

      // Canonical Fingerprint
      final fp1 = AnalyticsReportExporter.computeCanonicalFingerprint(jsonStr);
      final fp2 = AnalyticsReportExporter.computeCanonicalFingerprint(jsonStr);
      expect(fp1, equals(fp2));

      // CSV 1: Time Series
      final tsCsv = AnalyticsReportExporter.exportTimeSeriesCsv(timeSeriesMetrics);
      expect(tsCsv, contains('bucket_timestamp,interval,scans'));
      expect(tsCsv, contains('daily,25,5,2,30'));

      // CSV 2: Payload Distribution
      final pCsv = AnalyticsReportExporter.exportPayloadDistributionCsv(payloadDistribution);
      expect(pCsv, contains('payload_type,count,percentage'));
      expect(pCsv, contains('url,20'));
      expect(pCsv, contains('wifi,10'));

      // CSV 3: Threat Audit
      final tCsv = AnalyticsReportExporter.exportThreatAuditCsv(threatSummary);
      expect(tCsv, contains('# Threat Firewall Audit Summary'));
      expect(tCsv, contains('total_audited,25'));
      expect(tCsv, contains('safe_count,23'));
      expect(tCsv, contains('# Attack Category Breakdown'));
      expect(tCsv, contains('Phishing / Social Engineering,2'));
      expect(tCsv, contains('# Top Malicious Domains'));
      expect(tCsv, contains('bad.com,2'));

      // CSV 4: Fleet Inventory
      final devices = <FleetDevice>[
        FleetDevice(
          deviceId: 'dev_1',
          deviceName: 'Phone "Alpha", Model X',
          os: 'Android',
          appVersion: '1.0.0',
          registeredAt: now,
          lastActiveAt: now,
        ),
      ];
      final tokens = <TrustQrTokenRecord>[
        TrustQrTokenRecord(
          tokenId: 'tok_1',
          subject: 'admin@corp.io',
          role: UserRole.admin,
          issuer: 'corp_auth',
          issuedAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      ];

      final fCsv = AnalyticsReportExporter.exportFleetInventoryCsv(devices, tokens);
      expect(fCsv, contains('# Fleet Registered Devices'));
      // Check escaping of quotes/commas in deviceName
      expect(fCsv, contains('"Phone ""Alpha"", Model X"'));
      expect(fCsv, contains('# TrustQR Cryptographic Tokens'));
      expect(fCsv, contains('tok_1,admin@corp.io,admin'));
    });
  });
}
