import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../breakdown/payload_distribution.dart';
import '../fleet/fleet_registry.dart';
import '../security/threat_analytics_summary.dart';
import '../time_series/time_series_metrics.dart';

/// Consolidated administrative analytics report with cryptographic SHA-256 integrity fingerprint.
class AnalyticsReport {
  final String reportId;
  final DateTime generatedAt;
  final TimeSeriesMetrics timeSeriesMetrics;
  final PayloadDistribution payloadDistribution;
  final ThreatAnalyticsSummary threatSummary;
  final FleetSummary fleetSummary;
  final int totalAuditLogs;
  final String sha256Fingerprint;

  const AnalyticsReport({
    required this.reportId,
    required this.generatedAt,
    required this.timeSeriesMetrics,
    required this.payloadDistribution,
    required this.threatSummary,
    required this.fleetSummary,
    required this.totalAuditLogs,
    required this.sha256Fingerprint,
  });

  /// Computes a canonical SHA-256 fingerprint for a report's data payloads.
  static String computeFingerprint({
    required String reportId,
    required DateTime generatedAt,
    required TimeSeriesMetrics timeSeriesMetrics,
    required PayloadDistribution payloadDistribution,
    required ThreatAnalyticsSummary threatSummary,
    required FleetSummary fleetSummary,
    required int totalAuditLogs,
  }) {
    final canonicalMap = {
      'reportId': reportId,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'timeSeries': timeSeriesMetrics.toJson(),
      'payloadDistribution': payloadDistribution.toJson(),
      'threatSummary': threatSummary.toJson(),
      'fleetSummary': fleetSummary.toJson(),
      'totalAuditLogs': totalAuditLogs,
    };
    final jsonStr = jsonEncode(canonicalMap);
    return sha256.convert(utf8.encode(jsonStr)).toString();
  }

  /// Factory creating an [AnalyticsReport] and generating its cryptographic fingerprint automatically.
  factory AnalyticsReport.create({
    required String reportId,
    DateTime? generatedAt,
    required TimeSeriesMetrics timeSeriesMetrics,
    required PayloadDistribution payloadDistribution,
    required ThreatAnalyticsSummary threatSummary,
    required FleetSummary fleetSummary,
    required int totalAuditLogs,
  }) {
    final genAt = (generatedAt ?? DateTime.now()).toUtc();
    final fingerprint = computeFingerprint(
      reportId: reportId,
      generatedAt: genAt,
      timeSeriesMetrics: timeSeriesMetrics,
      payloadDistribution: payloadDistribution,
      threatSummary: threatSummary,
      fleetSummary: fleetSummary,
      totalAuditLogs: totalAuditLogs,
    );

    return AnalyticsReport(
      reportId: reportId,
      generatedAt: genAt,
      timeSeriesMetrics: timeSeriesMetrics,
      payloadDistribution: payloadDistribution,
      threatSummary: threatSummary,
      fleetSummary: fleetSummary,
      totalAuditLogs: totalAuditLogs,
      sha256Fingerprint: fingerprint,
    );
  }

  /// Verifies that the report's payload matches its embedded SHA-256 fingerprint.
  bool verifyFingerprint() {
    final expected = computeFingerprint(
      reportId: reportId,
      generatedAt: generatedAt,
      timeSeriesMetrics: timeSeriesMetrics,
      payloadDistribution: payloadDistribution,
      threatSummary: threatSummary,
      fleetSummary: fleetSummary,
      totalAuditLogs: totalAuditLogs,
    );
    return expected == sha256Fingerprint;
  }

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'sha256Fingerprint': sha256Fingerprint,
        'totalAuditLogs': totalAuditLogs,
        'timeSeries': timeSeriesMetrics.toJson(),
        'payloadDistribution': payloadDistribution.toJson(),
        'threatSummary': threatSummary.toJson(),
        'fleetSummary': fleetSummary.toJson(),
      };

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) =>
      AnalyticsReport(
        reportId: json['reportId'] as String,
        generatedAt: DateTime.parse(json['generatedAt'] as String).toUtc(),
        sha256Fingerprint: json['sha256Fingerprint'] as String,
        totalAuditLogs: (json['totalAuditLogs'] as num?)?.toInt() ?? 0,
        timeSeriesMetrics: TimeSeriesMetrics.fromJson(
            json['timeSeries'] as Map<String, dynamic>),
        payloadDistribution: PayloadDistribution.fromJson(
            json['payloadDistribution'] as Map<String, dynamic>),
        threatSummary: ThreatAnalyticsSummary.fromJson(
            json['threatSummary'] as Map<String, dynamic>),
        fleetSummary:
            FleetSummary.fromJson(json['fleetSummary'] as Map<String, dynamic>),
      );
}
