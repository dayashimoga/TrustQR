import '../models/admin_models.dart';
import '../models/auth_models.dart';

/// In-memory state and append-only audit log store for RBAC authority service.
class RbacStore {
  final Set<String> _revokedTokenIds = {};
  final List<AdminAuditEvent> _auditLog = [];
  final List<ScanTelemetryRequest> _telemetryLogs = [];
  final List<QrTemplate> _templates = [];
  final DateTime _startTime = DateTime.now();

  int _totalScans = 0;
  int _totalGenerations = 0;
  int _threatsBlocked = 0;
  int _trustQrSignaturesIssued = 0;

  RbacStore() {
    _initializeDefaultTemplates();
  }

  void _initializeDefaultTemplates() {
    _templates.addAll([
      QrTemplate(
        id: 'tmpl-cyber-neon',
        name: 'Cyberpunk Neon Matrix',
        description: 'Futuristic high-contrast neon cyan and magenta gradient with diamond modules',
        styleConfig: const {
          'moduleShape': 'diamond',
          'eyeShape': 'cyber_grid',
          'foregroundColor': '#00F0FF',
          'gradientEndColor': '#FF003C',
          'backgroundColor': '#0A0E17',
        },
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      QrTemplate(
        id: 'tmpl-corporate-minimal',
        name: 'Corporate Sleek Minimal',
        description: 'Professional high-readability monochrome template with subtle rounded corners',
        styleConfig: const {
          'moduleShape': 'rounded',
          'eyeShape': 'rounded',
          'foregroundColor': '#111827',
          'backgroundColor': '#FFFFFF',
        },
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      QrTemplate(
        id: 'tmpl-trustqr-shield',
        name: 'Institutional TrustQR Secure',
        description: 'Signed TrustQR institutional badge with cryptographic verification anchor',
        styleConfig: const {
          'moduleShape': 'dots',
          'eyeShape': 'square',
          'foregroundColor': '#059669',
          'backgroundColor': '#F0FDF4',
          'badge': 'trustqr-verified',
        },
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  /// Revokes an entitlement token by its token ID (`jti`).
  void revokeToken(String tokenId) {
    _revokedTokenIds.add(tokenId);
  }

  /// Checks if a token ID has been revoked.
  bool isTokenRevoked(String tokenId) {
    return _revokedTokenIds.contains(tokenId);
  }

  /// Appends an administrative audit log event.
  void recordAudit({
    required String action,
    required String actor,
    String status = 'success',
    String? ip,
    Map<String, dynamic>? details,
  }) {
    final event = AdminAuditEvent(
      id: 'audit-${DateTime.now().millisecondsSinceEpoch}-${_auditLog.length}',
      action: action,
      actor: actor,
      timestamp: DateTime.now(),
      status: status,
      ip: ip,
      details: details,
    );
    _auditLog.add(event);
  }

  /// Ingests scanner telemetry event.
  void recordTelemetry(ScanTelemetryRequest telemetry) {
    _telemetryLogs.add(telemetry);
    _totalScans++;
    if (telemetry.threatLevel == 'high' || telemetry.threatLevel == 'critical') {
      _threatsBlocked++;
    }
  }

  /// Returns active templates.
  List<QrTemplate> getTemplates() => List.unmodifiable(_templates);

  /// Adds a new branded template.
  void addTemplate(QrTemplate template) {
    _templates.add(template);
  }

  /// Records QR generations.
  void recordGeneration({int count = 1}) {
    _totalGenerations += count;
  }

  /// Records institutional TrustQR envelope signing.
  void recordTrustQrSignature() {
    _trustQrSignaturesIssued++;
  }

  /// Returns audit log records (most recent first).
  List<AdminAuditEvent> getAuditLogs({int limit = 100}) {
    final reversed = _auditLog.reversed.take(limit).toList();
    return List.unmodifiable(reversed);
  }

  /// Computes fleet analytics summary.
  AdminAnalytics getAnalytics() {
    final uptimeSeconds = DateTime.now().difference(_startTime).inSeconds;
    return AdminAnalytics(
      totalScans: _totalScans,
      totalGenerations: _totalGenerations,
      threatsBlocked: _threatsBlocked,
      activeSessions: 1,
      trustQrSignaturesIssued: _trustQrSignaturesIssued,
      uptimeSeconds: uptimeSeconds,
    );
  }
}
