import 'package:qr_core/qr_core.dart';
import 'audit/audit_log_engine.dart';
import 'audit/audit_log_entry.dart';
import 'breakdown/payload_distribution_calculator.dart';
import 'fleet/fleet_registry.dart';
import 'reports/analytics_report.dart';
import 'reports/analytics_report_exporter.dart';
import 'security/threat_analytics_engine.dart';
import 'time_series/time_series_aggregator.dart';
import 'time_series/time_series_interval.dart';

/// Unified administrative facade coordinating telemetry aggregation, threat intelligence,
/// fleet lifecycle management, cryptographic audit logs, and report exports.
class AdminAnalyticsFacade {
  final TimeSeriesAggregator _timeSeries;
  final PayloadDistributionCalculator _payloadCalculator;
  final ThreatAnalyticsEngine _threatEngine;
  final FleetRegistry _fleet;
  final AuditLogEngine _audit;
  final List<QrVaultItem> _recordedItems = [];
  final List<DateTime> _recordedGenerations = [];

  AdminAnalyticsFacade({
    required CryptoPrivateKey auditPrivateKey,
    required CryptoPublicKey auditPublicKey,
    TimeSeriesAggregator? timeSeriesAggregator,
    PayloadDistributionCalculator? payloadCalculator,
    ThreatAnalyticsEngine? threatEngine,
    FleetRegistry? fleetRegistry,
  })  : _timeSeries = timeSeriesAggregator ?? const TimeSeriesAggregator(),
        _payloadCalculator =
            payloadCalculator ?? PayloadDistributionCalculator(),
        _threatEngine = threatEngine ?? ThreatAnalyticsEngine(),
        _fleet = fleetRegistry ?? FleetRegistry(),
        _audit = AuditLogEngine(
          privateKey: auditPrivateKey,
          publicKey: auditPublicKey,
        );

  // ---------------------------------------------------------------------------
  // Subsystem Accessors
  // ---------------------------------------------------------------------------

  TimeSeriesAggregator get timeSeries => _timeSeries;
  PayloadDistributionCalculator get payloadCalculator => _payloadCalculator;
  ThreatAnalyticsEngine get threatEngine => _threatEngine;
  FleetRegistry get fleet => _fleet;
  AuditLogEngine get audit => _audit;

  // ---------------------------------------------------------------------------
  // Telemetry Ingestion
  // ---------------------------------------------------------------------------

  /// Ingests a completed scan inspection event across time series, payload format, and threat engines.
  void recordScanTelemetry({
    required QrPayloadType payloadType,
    required int safetyScore,
    required SecurityThreatLevel threatLevel,
    List<String> threatFlags = const [],
    String? domain,
    DateTime? timestamp,
  }) {
    final ts = (timestamp ?? DateTime.now()).toUtc();
    final item = QrVaultItem(
      id: 'scan_${ts.millisecondsSinceEpoch}_${_recordedItems.length}',
      rawContent: domain != null && domain.isNotEmpty ? 'https://$domain' : 'scan_payload',
      payloadType: payloadType,
      safetyScore: safetyScore,
      threatLevel: threatLevel,
      origin: QrItemOrigin.scanned,
      createdAt: ts,
      integrityHash: '',
    );
    _recordedItems.add(item);
    _payloadCalculator.recordPayload(payloadType);
    _threatEngine.recordInspection(
      safetyScore: safetyScore,
      threatLevel: threatLevel,
      threatFlags: threatFlags,
      domain: domain,
    );
  }

  /// Ingests a completed QR generation event across time series and payload format breakdown.
  void recordGenerationTelemetry({
    required QrPayloadType payloadType,
    DateTime? timestamp,
  }) {
    final ts = (timestamp ?? DateTime.now()).toUtc();
    _recordedGenerations.add(ts);
    _payloadCalculator.recordPayload(payloadType);
  }

  /// Clears recorded telemetry events.
  void clearTelemetry() {
    _recordedItems.clear();
    _recordedGenerations.clear();
    _payloadCalculator.reset();
    _threatEngine.clear();
  }

  /// Records and cryptographically signs an administrative action in the audit trail.
  AuditLogEntry recordAdminAction({
    required String action,
    required String actorId,
    required String actorRole,
    required String targetId,
    Map<String, dynamic> details = const {},
    String ipAddress = '127.0.0.1',
    DateTime? timestamp,
  }) {
    return _audit.logAction(
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      targetId: targetId,
      details: details,
      ipAddress: ipAddress,
      timestamp: timestamp,
    );
  }

  // ---------------------------------------------------------------------------
  // Reporting & Exporting
  // ---------------------------------------------------------------------------

  /// Generates a consolidated administrative analytics report with a cryptographic SHA-256 fingerprint.
  AnalyticsReport generateConsolidatedReport({
    String? reportId,
    DateTime? generatedAt,
    TimeSeriesBucketInterval interval = TimeSeriesBucketInterval.daily,
    List<QrVaultItem>? scannedItems,
    List<DateTime>? generationTimestamps,
  }) {
    final id = reportId ?? 'report_${DateTime.now().millisecondsSinceEpoch}';
    final items = scannedItems ?? _recordedItems;
    final gens = generationTimestamps ?? _recordedGenerations;
    final metrics = _timeSeries.aggregate(
      scannedItems: items,
      generationTimestamps: gens,
      interval: interval,
    );
    final distribution = scannedItems != null
        ? _payloadCalculator.calculate(scannedItems)
        : _payloadCalculator.calculate();
    final threatSummary = _threatEngine.summarize(items.isNotEmpty ? items : null);
    final fleetSummary = _fleet.summarize();

    return AnalyticsReport.create(
      reportId: id,
      generatedAt: generatedAt,
      timeSeriesMetrics: metrics,
      payloadDistribution: distribution,
      threatSummary: threatSummary,
      fleetSummary: fleetSummary,
      totalAuditLogs: _audit.count,
    );
  }

  /// Exports a generated report as canonical JSON.
  String exportReportJson(AnalyticsReport report, {bool pretty = false}) =>
      AnalyticsReportExporter.exportToJson(report, pretty: pretty);

  /// Exports time-series aggregated points as CSV.
  String exportTimeSeriesCsv({
    TimeSeriesBucketInterval interval = TimeSeriesBucketInterval.daily,
    List<QrVaultItem>? scannedItems,
    List<DateTime>? generationTimestamps,
  }) {
    final metrics = _timeSeries.aggregate(
      scannedItems: scannedItems ?? _recordedItems,
      generationTimestamps: generationTimestamps ?? _recordedGenerations,
      interval: interval,
    );
    return AnalyticsReportExporter.exportTimeSeriesCsv(metrics);
  }

  /// Exports payload distribution breakdown as CSV.
  String exportPayloadDistributionCsv([List<QrVaultItem>? items]) {
    final distribution = items != null
        ? _payloadCalculator.calculate(items)
        : _payloadCalculator.calculate();
    return AnalyticsReportExporter.exportPayloadDistributionCsv(distribution);
  }

  /// Exports threat security firewall summary and audit breakdown as CSV.
  String exportThreatAuditCsv([List<QrVaultItem>? items]) {
    final summary = _threatEngine.summarize(items ?? (items == null && _recordedItems.isNotEmpty ? _recordedItems : null));
    return AnalyticsReportExporter.exportThreatAuditCsv(summary);
  }

  /// Exports fleet registered devices and TrustQR tokens as CSV.
  String exportFleetInventoryCsv() {
    return AnalyticsReportExporter.exportFleetInventoryCsv(
      _fleet.devices,
      _fleet.tokens,
    );
  }

  /// Performs full cryptographic HMAC and chronological integrity audit on the audit trail.
  AuditLogAuditResult verifyAuditIntegrity() => _audit.verifyAll();
}
