import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../breakdown/payload_distribution.dart';
import '../fleet/fleet_device.dart';
import '../fleet/trust_qr_token_record.dart';
import '../security/threat_analytics_summary.dart';
import '../time_series/time_series_metrics.dart';
import 'analytics_report.dart';

/// Exporter for administrative analytics in canonical JSON and CSV formats.
class AnalyticsReportExporter {
  const AnalyticsReportExporter._();

  /// Computes a canonical SHA-256 fingerprint for arbitrary exported text.
  static String computeCanonicalFingerprint(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  /// Exports an [AnalyticsReport] as canonical JSON.
  static String exportToJson(AnalyticsReport report, {bool pretty = false}) {
    final map = report.toJson();
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    }
    return jsonEncode(map);
  }

  /// Exports time-series points as CSV.
  static String exportTimeSeriesCsv(TimeSeriesMetrics metrics) {
    final buffer = StringBuffer();
    buffer.writeln(
        'bucket_timestamp,interval,scans,generations,threats,total_volume,sma_volume,is_anomaly');

    for (final point in metrics.points) {
      final ts = point.timestamp.toUtc().toIso8601String();
      final interval = metrics.interval.name;
      final scans = point.scans;
      final gens = point.generations;
      final threats = point.threats;
      final total = point.totalVolume;
      final sma = point.movingAverage?.toStringAsFixed(2) ?? '';
      final anomaly = point.isAnomaly ? 'true' : 'false';

      buffer.writeln(
          '$ts,$interval,$scans,$gens,$threats,$total,$sma,$anomaly');
    }

    return buffer.toString();
  }

  /// Exports 15-format payload distribution breakdown as CSV.
  static String exportPayloadDistributionCsv(PayloadDistribution distribution) {
    final buffer = StringBuffer();
    buffer.writeln('payload_type,count,percentage');

    for (final entry in distribution.counts.entries) {
      final type = entry.key.name;
      final count = entry.value;
      final pct = distribution.percentages[entry.key]?.toStringAsFixed(2) ?? '0.00';
      buffer.writeln('$type,$count,$pct%');
    }

    return buffer.toString();
  }

  /// Exports comprehensive threat security metrics as CSV.
  static String exportThreatAuditCsv(ThreatAnalyticsSummary summary) {
    final buffer = StringBuffer();

    // Section 1: Summary Overview
    buffer.writeln('# Threat Firewall Audit Summary');
    buffer.writeln('metric,value');
    buffer.writeln('total_audited,${summary.totalAudited}');
    buffer.writeln('safe_count,${summary.safeCount}');
    buffer.writeln('caution_count,${summary.cautionCount}');
    buffer.writeln('suspicious_count,${summary.suspiciousCount}');
    buffer.writeln('critical_count,${summary.criticalCount}');
    buffer.writeln('total_threats,${summary.totalThreats}');
    buffer.writeln('threat_rate_percentage,${summary.threatRatePercentage}%');
    buffer.writeln('average_safety_score,${summary.averageSafetyScore.toStringAsFixed(2)}');
    buffer.writeln('');

    // Section 2: Attack Categories
    buffer.writeln('# Attack Category Breakdown');
    buffer.writeln('attack_category,count');
    for (final entry in summary.attackCategoryCounts.entries) {
      buffer.writeln('${_escapeCsv(entry.key)},${entry.value}');
    }
    buffer.writeln('');

    // Section 3: Risk Score Histogram
    buffer.writeln('# Risk Score Distribution');
    buffer.writeln('score_range,count');
    for (final entry in summary.scoreHistogram.entries) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    buffer.writeln('');

    // Section 4: Top Malicious Domains
    buffer.writeln('# Top Malicious Domains');
    buffer.writeln('domain,detected_count');
    for (final entry in summary.topMaliciousDomains.entries) {
      buffer.writeln('${_escapeCsv(entry.key)},${entry.value}');
    }

    return buffer.toString();
  }

  /// Exports active fleet devices and TrustQR tokens as CSV.
  static String exportFleetInventoryCsv(
    List<FleetDevice> devices,
    List<TrustQrTokenRecord> tokens,
  ) {
    final buffer = StringBuffer();

    // Section 1: Fleet Devices
    buffer.writeln('# Fleet Registered Devices');
    buffer.writeln('device_id,device_name,os,app_version,registered_at,last_seen_at,is_revoked');
    for (final d in devices) {
      buffer.writeln(
        '${_escapeCsv(d.deviceId)},${_escapeCsv(d.deviceName)},${_escapeCsv(d.os)},${_escapeCsv(d.appVersion)},${d.registeredAt.toUtc().toIso8601String()},${d.lastSeenAt.toUtc().toIso8601String()},${d.isRevoked}',
      );
    }
    buffer.writeln('');

    // Section 2: TrustQR Tokens
    buffer.writeln('# TrustQR Cryptographic Tokens');
    buffer.writeln('token_id,subject,role,issued_at,expires_at,is_revoked,status');
    for (final t in tokens) {
      buffer.writeln(
        '${_escapeCsv(t.tokenId)},${_escapeCsv(t.subject)},${_escapeCsv(t.role.name)},${t.issuedAt.toUtc().toIso8601String()},${t.expiresAt.toUtc().toIso8601String()},${t.isRevoked},${t.status()}',
      );
    }

    return buffer.toString();
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
