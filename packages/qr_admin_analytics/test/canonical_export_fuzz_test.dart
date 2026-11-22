import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('Canonical Export Fuzz & Schema Validation Tests', () {
    final now = DateTime.utc(2026, 11, 22, 12, 0, 0);

    test('CSV RFC 4180 escaping handles quotes, commas, newlines, and Unicode correctly', () {
      final fuzzedDevices = [
        FleetDevice(
          deviceId: 'dev_fuzz_1',
          deviceName: 'Terminal, "HQ" \n Floor 2',
          os: 'Windows 11 "Enterprise"',
          appVersion: '1.0.0-rc.1',
          registeredAt: now,
          lastActiveAt: now,
        ),
        FleetDevice(
          deviceId: 'dev_unicode_2',
          deviceName: '東京 端末 🚀 (Tokyo Device)',
          os: 'iOS / 日本語',
          appVersion: '2.3.4',
          registeredAt: now,
          lastActiveAt: now,
        ),
        FleetDevice(
          deviceId: 'dev_hindi_3',
          deviceName: 'सुरक्षित उपकरण // Secure Device',
          os: 'Android / हिंदी',
          appVersion: '3.0.0',
          registeredAt: now,
          lastActiveAt: now,
        ),
      ];

      final fuzzedTokens = [
        TrustQrTokenRecord(
          tokenId: 'tok_fuzz_1',
          subject: 'user, "admin" <user@domain.com>',
          role: UserRole.admin,
          issuer: 'CA: "Central, Authority"',
          issuedAt: now,
          expiresAt: now.add(const Duration(days: 30)),
        ),
      ];

      final csv = AnalyticsReportExporter.exportFleetInventoryCsv(fuzzedDevices, fuzzedTokens);

      // Verify quotes are doubled
      expect(csv, contains('"Terminal, ""HQ"" \n Floor 2"'));
      expect(csv, contains('"Windows 11 ""Enterprise"""'));
      expect(csv, contains('"user, ""admin"" <user@domain.com>"'));

      // Verify Unicode is preserved without corruption
      expect(csv, contains('東京 端末 🚀 (Tokyo Device)'));
      expect(csv, contains('सुरक्षित उपकरण // Secure Device'));
    });

    test('Exports empty datasets gracefully without crashing or invalid headers', () {
      // 1. Empty TimeSeriesMetrics
      const emptyMetrics = TimeSeriesMetrics(
        points: [],
        interval: TimeSeriesBucketInterval.daily,
        totalScans: 0,
        totalGenerations: 0,
        totalThreats: 0,
        averageVolumePerBucket: 0.0,
        volumeStandardDeviation: 0.0,
        peakVolume: 0,
      );
      final tsCsv = AnalyticsReportExporter.exportTimeSeriesCsv(emptyMetrics);
      expect(tsCsv, startsWith('bucket_timestamp,interval,scans'));

      // 2. Empty PayloadDistribution
      final emptyDist = PayloadDistribution.fromCounts({});
      final pCsv = AnalyticsReportExporter.exportPayloadDistributionCsv(emptyDist);
      expect(pCsv, startsWith('payload_type,count,percentage'));
      // All 15 formats should still be present with 0 counts
      expect(pCsv, contains('url,0,0.00%'));
      expect(pCsv, contains('wifi,0,0.00%'));

      // 3. Empty ThreatAnalyticsSummary
      const emptyThreat = ThreatAnalyticsSummary(
        totalAudited: 0,
        safeCount: 0,
        cautionCount: 0,
        suspiciousCount: 0,
        criticalCount: 0,
        averageSafetyScore: 100.0,
        attackCategoryCounts: {},
        topMaliciousDomains: {},
        scoreHistogram: {},
      );
      final tCsv = AnalyticsReportExporter.exportThreatAuditCsv(emptyThreat);
      expect(tCsv, contains('total_audited,0'));
      expect(tCsv, contains('total_threats,0'));

      // 4. Empty Fleet Inventory
      final fCsv = AnalyticsReportExporter.exportFleetInventoryCsv([], []);
      expect(fCsv, contains('# Fleet Registered Devices'));
      expect(fCsv, contains('# TrustQR Cryptographic Tokens'));
    });

    test('Evaluates 15-format distribution edge cases: 100% single format and even split', () {
      // Edge Case 1: 100% single format (e.g. 500 Wi-Fi QR codes)
      final wifiOnly = PayloadDistribution.fromCounts({QrPayloadType.wifi: 500});
      expect(wifiOnly.totalCount, equals(500));
      expect(wifiOnly.percentages[QrPayloadType.wifi], equals(100.0));
      expect(wifiOnly.topFormat, equals(QrPayloadType.wifi));
      expect(wifiOnly.topNonUrlFormat, equals(QrPayloadType.wifi));

      // Edge Case 2: 15-way even split (10 of each type = 150 total)
      final evenCounts = <QrPayloadType, int>{};
      for (final type in QrPayloadType.values) {
        evenCounts[type] = 10;
      }
      final evenDist = PayloadDistribution.fromCounts(evenCounts);
      expect(evenDist.totalCount, equals(150));
      for (final type in QrPayloadType.values) {
        // 10 / 150 * 100 = 6.67%
        expect(evenDist.percentages[type], equals(6.67));
      }
    });

    test('SHA-256 canonical fingerprint is deterministic and highly sensitive to single-byte mutations', () {
      const timeSeriesMetrics = TimeSeriesMetrics(
        points: [],
        interval: TimeSeriesBucketInterval.hourly,
        totalScans: 100,
        totalGenerations: 50,
        totalThreats: 5,
        averageVolumePerBucket: 15.0,
        volumeStandardDeviation: 2.0,
        peakVolume: 30,
      );

      final payloadDist = PayloadDistribution.fromCounts({QrPayloadType.url: 100});

      const threatSummary = ThreatAnalyticsSummary(
        totalAudited: 100,
        safeCount: 95,
        cautionCount: 3,
        suspiciousCount: 1,
        criticalCount: 1,
        averageSafetyScore: 92.0,
        attackCategoryCounts: {'phishing': 2},
        topMaliciousDomains: {'bad.org': 2},
        scoreHistogram: {'80-100': 95, '0-19': 1},
      );

      const fleetSummary = FleetSummary(
        totalDevices: 5,
        activeDevices: 5,
        revokedDevices: 0,
        totalTokens: 10,
        activeTokens: 10,
        revokedTokens: 0,
        expiredTokens: 0,
        devicesByOs: {'Android': 5},
      );

      final report = AnalyticsReport.create(
        reportId: 'rep_fingerprint_test',
        generatedAt: now,
        timeSeriesMetrics: timeSeriesMetrics,
        payloadDistribution: payloadDist,
        threatSummary: threatSummary,
        fleetSummary: fleetSummary,
        totalAuditLogs: 20,
      );

      // Reproducibility: 500 repeated fingerprint calculations yield the exact same string
      for (var i = 0; i < 500; i++) {
        expect(report.verifyFingerprint(), isTrue);
      }

      // Sensitivity: Single character mutation in reportId changes hash completely
      final mutatedReport = AnalyticsReport(
        reportId: 'rep_fingerprint_tesu', // 't' -> 'u'
        generatedAt: report.generatedAt,
        timeSeriesMetrics: report.timeSeriesMetrics,
        payloadDistribution: report.payloadDistribution,
        threatSummary: report.threatSummary,
        fleetSummary: report.fleetSummary,
        totalAuditLogs: report.totalAuditLogs,
        sha256Fingerprint: report.sha256Fingerprint,
      );

      expect(mutatedReport.verifyFingerprint(), isFalse);
    });
  });
}
