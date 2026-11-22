import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('ThreatAnalyticsEngine & Summary Tests', () {
    test('Records inspections, classifies threat categories, and aggregates summary correctly', () {
      final engine = ThreatAnalyticsEngine();

      // Inspection 1: Safe URL
      engine.recordInspection(
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        threatFlags: const [],
        domain: 'example.com',
      );

      // Inspection 2: Safe Plaintext
      engine.recordInspection(
        safetyScore: 95,
        threatLevel: SecurityThreatLevel.safe,
        threatFlags: const [],
      );

      // Inspection 3: Caution Phishing
      engine.recordInspection(
        safetyScore: 55,
        threatLevel: SecurityThreatLevel.caution,
        threatFlags: const ['phishing_keyword_detected', 'shortener_bitly'],
        domain: 'evil-phish.biz',
      );

      // Inspection 4: Suspicious Homograph
      engine.recordInspection(
        safetyScore: 35,
        threatLevel: SecurityThreatLevel.suspicious,
        threatFlags: const ['idn_homograph_spoof'],
        domain: 'xn--googl-p1a.com',
      );

      // Inspection 5: Critical IP / SSRF
      engine.recordInspection(
        safetyScore: 10,
        threatLevel: SecurityThreatLevel.critical,
        threatFlags: const ['private_ip_ssrf', 'dangerous_scheme_file'],
        domain: '192.168.1.1',
      );

      // Inspection 6: Critical Phishing duplicate domain
      engine.recordInspection(
        safetyScore: 5,
        threatLevel: SecurityThreatLevel.critical,
        threatFlags: const ['phishing_credential_harvest'],
        domain: 'evil-phish.biz',
      );

      // Inspection 7: Caution Insecure Wi-Fi
      engine.recordInspection(
        safetyScore: 50,
        threatLevel: SecurityThreatLevel.caution,
        threatFlags: const ['insecure_wifi_nopass'],
      );

      // Inspection 8: Suspicious DGA
      engine.recordInspection(
        safetyScore: 25,
        threatLevel: SecurityThreatLevel.suspicious,
        threatFlags: const ['dga_high_entropy'],
        domain: 'xkjq984mz0a.net',
      );

      // Inspection 9: Generic Custom Flag
      engine.recordInspection(
        safetyScore: 40,
        threatLevel: SecurityThreatLevel.suspicious,
        threatFlags: const ['custom_unknown_threat'],
        domain: 'weird.net',
      );

      final summary = engine.summarize();

      // Check counts
      expect(summary.totalAudited, equals(9));
      expect(summary.safeCount, equals(2));
      expect(summary.cautionCount, equals(2));
      expect(summary.suspiciousCount, equals(3));
      expect(summary.criticalCount, equals(2));
      expect(summary.totalThreats, equals(7));
      expect(summary.threatRatePercentage, closeTo(77.78, 0.05));

      // Average safety score
      expect(summary.averageSafetyScore, closeTo(46.11, 0.1));

      // Category breakdown
      expect(summary.attackCategoryCounts['Phishing / Social Engineering'], equals(2));
      expect(summary.attackCategoryCounts['URL Shortener Cloaking'], equals(1));
      expect(summary.attackCategoryCounts['IDN Homograph / Spoofing'], equals(1));
      expect(summary.attackCategoryCounts['SSRF / Local Network Probe'], equals(1));
      expect(summary.attackCategoryCounts['Dangerous URI Scheme'], equals(1));
      expect(summary.attackCategoryCounts['Insecure Wi-Fi Network'], equals(1));
      expect(summary.attackCategoryCounts['Algorithmic DGA Domain'], equals(1));
      expect(summary.attackCategoryCounts['Custom Unknown Threat'], equals(1));

      // Score Histogram
      expect(summary.scoreHistogram['0-19'], equals(2));
      expect(summary.scoreHistogram['20-39'], equals(2));
      expect(summary.scoreHistogram['40-59'], equals(3));
      expect(summary.scoreHistogram['60-79'], equals(0));
      expect(summary.scoreHistogram['80-100'], equals(2));

      // Top malicious domains: evil-phish.biz should have count 2
      expect(summary.topMaliciousDomains['evil-phish.biz'], equals(2));

      // Serialization round-trip
      final json = summary.toJson();
      final restored = ThreatAnalyticsSummary.fromJson(json);

      expect(restored.totalAudited, equals(summary.totalAudited));
      expect(restored.safeCount, equals(summary.safeCount));
      expect(restored.criticalCount, equals(summary.criticalCount));
      expect(restored.totalThreats, equals(summary.totalThreats));
      expect(restored.averageSafetyScore, equals(summary.averageSafetyScore));
      expect(restored.topMaliciousDomains['evil-phish.biz'], equals(2));

      // Test analyze(List<QrVaultItem>)
      final items = [
        QrVaultItem(
          id: 'v1',
          rawContent: 'javascript:alert(1)',
          payloadType: QrPayloadType.plainText,
          safetyScore: 10,
          threatLevel: SecurityThreatLevel.critical,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v2',
          rawContent: 'https://tinyurl.com/abc',
          payloadType: QrPayloadType.url,
          safetyScore: 50,
          threatLevel: SecurityThreatLevel.caution,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v3',
          rawContent: 'WIFI:S:cafe;T:nopass;;',
          payloadType: QrPayloadType.wifi,
          safetyScore: 40,
          threatLevel: SecurityThreatLevel.caution,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v4',
          rawContent: 'https://xn--test-9na.com',
          payloadType: QrPayloadType.url,
          safetyScore: 25,
          threatLevel: SecurityThreatLevel.suspicious,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v5',
          rawContent: 'https://192.168.1.1/admin',
          payloadType: QrPayloadType.url,
          safetyScore: 5,
          threatLevel: SecurityThreatLevel.critical,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
        QrVaultItem(
          id: 'v6',
          rawContent: 'https://abcdefghijklmnopqrstuvwxy.biz',
          payloadType: QrPayloadType.url,
          safetyScore: 30,
          threatLevel: SecurityThreatLevel.suspicious,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now(),
          integrityHash: '',
        ),
      ];

      final vaultSummary = engine.analyze(items);
      expect(vaultSummary.totalAudited, equals(6));
      expect(vaultSummary.criticalCount, equals(2));
      expect(vaultSummary.attackCategoryCounts['dangerous_scheme'], equals(1));
      expect(vaultSummary.attackCategoryCounts['url_shortener'], equals(1));
      expect(vaultSummary.attackCategoryCounts['insecure_wifi'], equals(1));
      expect(vaultSummary.attackCategoryCounts['phishing_idn_homograph'], equals(1));
      expect(vaultSummary.attackCategoryCounts['malicious_ip'], equals(1));
      expect(vaultSummary.attackCategoryCounts['high_entropy_dga'], equals(1));

      // Test empty analyze
      final emptyVault = engine.analyze(const []);
      expect(emptyVault.totalAudited, equals(0));

      // Engine clear
      engine.clear();
      final emptySummary = engine.summarize();
      expect(emptySummary.totalAudited, equals(0));
      expect(emptySummary.averageSafetyScore, equals(100.0));
      expect(emptySummary.totalThreats, equals(0));
    });
  });
}
