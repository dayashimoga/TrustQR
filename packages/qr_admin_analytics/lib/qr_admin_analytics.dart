/// Admin-only analytics, fleet telemetry, threat intelligence, and report exporter.
library qr_admin_analytics;

// Time series & anomaly detection
export 'src/time_series/time_series_interval.dart';
export 'src/time_series/time_series_point.dart';
export 'src/time_series/time_series_metrics.dart';
export 'src/time_series/time_series_aggregator.dart';

// Payload distribution breakdown
export 'src/breakdown/payload_distribution.dart';
export 'src/breakdown/payload_distribution_calculator.dart';

// Threat analytics & risk histograms
export 'src/security/threat_analytics_summary.dart';
export 'src/security/threat_analytics_engine.dart';

// Fleet hardware & TrustQR token lifecycle registry
export 'src/fleet/fleet_device.dart';
export 'src/fleet/trust_qr_token_record.dart';
export 'src/fleet/fleet_registry.dart';

// Tamper-evident cryptographic audit log trail
export 'src/audit/audit_log_entry.dart';
export 'src/audit/audit_log_filter.dart';
export 'src/audit/audit_log_engine.dart';

// Consolidated reports & multi-format exporters
export 'src/reports/analytics_report.dart';
export 'src/reports/analytics_report_exporter.dart';

// Unified facade
export 'src/admin_analytics_facade.dart';

// Service helper
export 'src/admin_analytics_service.dart';
