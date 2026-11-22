import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

/// State coordinator for fleet telemetry, threat intelligence, audit logging,
/// and canonical administrative reporting.
class AnalyticsController extends ChangeNotifier {
  late final AdminAnalyticsFacade _facade;
  TimeSeriesBucketInterval _interval = TimeSeriesBucketInterval.daily;

  String? _lastExportResult;
  String? _lastExportType;
  bool _isAuditVerified = true;
  int _auditVerifiedCount = 0;

  AnalyticsController({AdminAnalyticsFacade? facade}) {
    if (facade != null) {
      _facade = facade;
    } else {
      // Deterministic keypair for audit trail HMAC-SHA256 signing
      final auditKey = Uint8List.fromList(List.generate(32, (i) => (i * 7 + 13) % 256));
      final priv = CryptoPrivateKey(
        bytes: auditKey,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: 'audit-ledger-hmac-key-2026',
      );
      final pub = CryptoPublicKey(
        bytes: auditKey,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: 'audit-ledger-hmac-key-2026',
      );
      _facade = AdminAnalyticsFacade(
        auditPrivateKey: priv,
        auditPublicKey: pub,
      );
      _populateInitialFleetTelemetry();
    }
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  AdminAnalyticsFacade get facade => _facade;
  TimeSeriesBucketInterval get interval => _interval;
  String? get lastExportResult => _lastExportResult;
  String? get lastExportType => _lastExportType;
  bool get isAuditVerified => _isAuditVerified;
  int get auditVerifiedCount => _auditVerifiedCount;

  TimeSeriesMetrics get timeSeriesMetrics {
    final report = _facade.generateConsolidatedReport(interval: _interval);
    return report.timeSeriesMetrics;
  }

  PayloadDistribution get payloadDistribution {
    final report = _facade.generateConsolidatedReport(interval: _interval);
    return report.payloadDistribution;
  }

  ThreatAnalyticsSummary get threatSummary => _facade.threatEngine.summarize();

  List<FleetDevice> get fleetDevices => _facade.fleet.devices;
  List<TrustQrTokenRecord> get fleetTokens => _facade.fleet.tokens;
  List<AuditLogEntry> get auditLogs => _facade.audit.query();

  int get totalScans => timeSeriesMetrics.totalScans;
  int get totalGenerations => timeSeriesMetrics.totalGenerations;
  int get totalThreats => timeSeriesMetrics.totalThreats;
  int get activeDevices => _facade.fleet.summarize().activeDevices;

  double get threatRate {
    final total = totalScans;
    if (total == 0) return 0.0;
    return (totalThreats / total) * 100.0;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void setInterval(TimeSeriesBucketInterval interval) {
    if (_interval != interval) {
      _interval = interval;
      notifyListeners();
    }
  }

  void revokeDevice(String deviceId) {
    _facade.fleet.revokeDevice(deviceId);
    _facade.recordAdminAction(
      action: 'REVOKE_DEVICE',
      actorId: 'admin@enterprise.corp',
      actorRole: 'admin',
      targetId: deviceId,
      details: {'reason': 'Administrative security action'},
    );
    notifyListeners();
  }

  void restoreDevice(String deviceId) {
    _facade.fleet.unrevokeDevice(deviceId);
    _facade.recordAdminAction(
      action: 'RESTORE_DEVICE',
      actorId: 'admin@enterprise.corp',
      actorRole: 'admin',
      targetId: deviceId,
      details: {'reason': 'Administrative reinstatement'},
    );
    notifyListeners();
  }

  void revokeToken(String tokenId) {
    _facade.fleet.revokeToken(tokenId);
    _facade.recordAdminAction(
      action: 'REVOKE_TOKEN',
      actorId: 'admin@enterprise.corp',
      actorRole: 'admin',
      targetId: tokenId,
      details: {'reason': 'Manual token invalidation'},
    );
    notifyListeners();
  }

  bool verifyAuditLedger() {
    final result = _facade.audit.verifyAll();
    _isAuditVerified = result.isValid;
    _auditVerifiedCount = result.totalChecked;
    notifyListeners();
    return _isAuditVerified;
  }

  String exportCanonicalJson({bool pretty = true}) {
    final report = _facade.generateConsolidatedReport(interval: _interval);
    final json = _facade.exportReportJson(report, pretty: pretty);
    _lastExportResult = json;
    _lastExportType = 'JSON Report';
    notifyListeners();
    return json;
  }

  String exportTimeSeriesCsv() {
    final csv = _facade.exportTimeSeriesCsv(interval: _interval);
    _lastExportResult = csv;
    _lastExportType = 'Time Series CSV';
    notifyListeners();
    return csv;
  }

  String exportPayloadBreakdownCsv() {
    final csv = _facade.exportPayloadDistributionCsv();
    _lastExportResult = csv;
    _lastExportType = 'Payload Breakdown CSV';
    notifyListeners();
    return csv;
  }

  String exportThreatsCsv() {
    final csv = _facade.exportThreatAuditCsv();
    _lastExportResult = csv;
    _lastExportType = 'Threat Firewall CSV';
    notifyListeners();
    return csv;
  }

  String exportFleetInventoryCsv() {
    final csv = _facade.exportFleetInventoryCsv();
    _lastExportResult = csv;
    _lastExportType = 'Fleet Inventory CSV';
    notifyListeners();
    return csv;
  }

  // ---------------------------------------------------------------------------
  // Initial Mock Data Population (Real Domain Objects)
  // ---------------------------------------------------------------------------

  void _populateInitialFleetTelemetry() {
    final now = DateTime.now().toUtc();

    // 1. Telemetry scans across formats and days
    final formats = QrPayloadType.values;
    final random = math.Random(42);

    for (var d = 6; d >= 0; d--) {
      final dayTs = now.subtract(Duration(days: d));

      // Normal scans
      final scanCount = 15 + random.nextInt(15);
      for (var s = 0; s < scanCount; s++) {
        final fmt = formats[random.nextInt(formats.length)];
        final isThreat = random.nextInt(10) < 2; // ~20% threats
        final score = isThreat ? random.nextInt(40) : (75 + random.nextInt(26));
        final level = isThreat
            ? (score < 20 ? SecurityThreatLevel.critical : SecurityThreatLevel.suspicious)
            : SecurityThreatLevel.safe;

        _facade.recordScanTelemetry(
          payloadType: fmt,
          safetyScore: score,
          threatLevel: level,
          threatFlags: isThreat ? ['suspicious_pattern', 'low_entropy'] : const [],
          domain: isThreat ? 'malicious-domain-${random.nextInt(5)}.xyz' : 'trusted.corp',
          timestamp: dayTs.add(Duration(hours: s % 12, minutes: random.nextInt(60))),
        );
      }

      // QR generations
      final genCount = 5 + random.nextInt(8);
      for (var g = 0; g < genCount; g++) {
        final fmt = formats[random.nextInt(formats.length)];
        _facade.recordGenerationTelemetry(
          payloadType: fmt,
          timestamp: dayTs.add(Duration(hours: g % 10, minutes: random.nextInt(60))),
        );
      }
    }

    // 2. Fleet Devices across 5 platforms
    _facade.fleet.registerDevice(
      deviceId: 'dev_android_pixel8_01',
      deviceName: 'Pixel 8 Pro Scanner',
      os: 'Android 14',
      appVersion: '0.1.0',
      registeredAt: now.subtract(const Duration(days: 30)),
    );
    _facade.fleet.recordDeviceHeartbeat('dev_android_pixel8_01', scans: 142, threats: 4);

    _facade.fleet.registerDevice(
      deviceId: 'dev_ios_iphone15_01',
      deviceName: 'iPhone 15 Pro Max',
      os: 'iOS 17.4',
      appVersion: '0.1.0',
      registeredAt: now.subtract(const Duration(days: 20)),
    );
    _facade.fleet.recordDeviceHeartbeat('dev_ios_iphone15_01', scans: 98, threats: 1);

    _facade.fleet.registerDevice(
      deviceId: 'dev_win_thinkpad_01',
      deviceName: 'ThinkPad P1 Gen 6',
      os: 'Windows 11',
      appVersion: '0.1.0',
      registeredAt: now.subtract(const Duration(days: 45)),
    );
    _facade.fleet.recordDeviceHeartbeat('dev_win_thinkpad_01', scans: 312, threats: 8);

    _facade.fleet.registerDevice(
      deviceId: 'dev_mac_macbook_01',
      deviceName: 'MacBook Pro M3 Max',
      os: 'macOS 14.5 Sonoma',
      appVersion: '0.1.0',
      registeredAt: now.subtract(const Duration(days: 15)),
    );
    _facade.fleet.recordDeviceHeartbeat('dev_mac_macbook_01', scans: 220, threats: 5);

    _facade.fleet.registerDevice(
      deviceId: 'dev_linux_workstation_01',
      deviceName: 'Ubuntu Precision 5820',
      os: 'Linux Ubuntu 24.04',
      appVersion: '0.1.0',
      registeredAt: now.subtract(const Duration(days: 10)),
    );
    _facade.fleet.recordDeviceHeartbeat('dev_linux_workstation_01', scans: 85, threats: 2);

    _facade.fleet.registerDevice(
      deviceId: 'dev_rogue_scanner_99',
      deviceName: 'Unknown Android Scanner',
      os: 'Android 11',
      appVersion: '0.0.9',
      registeredAt: now.subtract(const Duration(days: 60)),
    );
    _facade.fleet.revokeDevice('dev_rogue_scanner_99', reason: 'Compromised firmware');

    // 3. TrustQR Tokens
    final tokens = [
      TrustQrTokenRecord(
        tokenId: 'tok_auth_001',
        issuer: 'universal-qr-authority',
        subject: 'admin@enterprise.corp',
        role: UserRole.admin,
        issuedAt: now.subtract(const Duration(days: 5)),
        expiresAt: now.add(const Duration(days: 25)),
      ),
      TrustQrTokenRecord(
        tokenId: 'tok_auth_002',
        issuer: 'universal-qr-authority',
        subject: 'secops@enterprise.corp',
        role: UserRole.admin,
        issuedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 28)),
      ),
      TrustQrTokenRecord(
        tokenId: 'tok_compromised_099',
        issuer: 'untrusted-issuer',
        subject: 'intruder@unknown.xyz',
        role: UserRole.user,
        issuedAt: now.subtract(const Duration(days: 10)),
        expiresAt: now.subtract(const Duration(days: 1)),
        isRevoked: true,
        revocationReason: 'Cryptographic key breach',
      ),
    ];
    for (final tok in tokens) {
      _facade.fleet.registerToken(tok);
    }

    // 4. Initial Audit Logs
    _facade.recordAdminAction(
      action: 'SYSTEM_BOOT',
      actorId: 'system',
      actorRole: 'system',
      targetId: 'cluster_node_01',
      details: {'version': '0.1.0', 'securityEngine': 'Zero-Trust v1'},
      ipAddress: '127.0.0.1',
      timestamp: now.subtract(const Duration(days: 7)),
    );
    _facade.recordAdminAction(
      action: 'ENROLL_AUTHORITY_KEY',
      actorId: 'cso@enterprise.corp',
      actorRole: 'admin',
      targetId: 'admin-ed25519-auth-key',
      details: {'algorithm': 'Ed25519', 'curve': 'Ed25519'},
      ipAddress: '10.0.4.15',
      timestamp: now.subtract(const Duration(days: 6)),
    );
    _facade.recordAdminAction(
      action: 'REVOKE_DEVICE',
      actorId: 'admin@enterprise.corp',
      actorRole: 'admin',
      targetId: 'dev_rogue_scanner_99',
      details: {'reason': 'Outdated firmware and excessive threats'},
      ipAddress: '10.0.4.22',
      timestamp: now.subtract(const Duration(days: 3)),
    );

    final auditCheck = _facade.audit.verifyAll();
    _isAuditVerified = auditCheck.isValid;
    _auditVerifiedCount = auditCheck.totalChecked;
  }
}
