import 'package:qr_core/qr_core.dart';
import 'audit_log_entry.dart';
import 'audit_log_filter.dart';

/// Result of a comprehensive cryptographic audit trail verification.
class AuditLogAuditResult {
  final bool isValid;
  final int totalChecked;
  final List<AuditLogEntry> tamperedEntries;
  final bool isChronological;

  const AuditLogAuditResult({
    required this.isValid,
    required this.totalChecked,
    required this.tamperedEntries,
    required this.isChronological,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'totalChecked': totalChecked,
        'tamperedCount': tamperedEntries.length,
        'isChronological': isChronological,
        'tamperedIds': tamperedEntries.map((e) => e.id).toList(),
      };
}

/// Cryptographically signed administrative audit log engine.
class AuditLogEngine {
  final CryptoPrivateKey privateKey;
  final CryptoPublicKey publicKey;
  final List<AuditLogEntry> _entries = [];
  int _sequenceCounter = 0;

  AuditLogEngine({
    required this.privateKey,
    required this.publicKey,
  });

  /// Appends and signs a new administrative action in the audit trail.
  AuditLogEntry logAction({
    required String action,
    required String actorId,
    required String actorRole,
    required String targetId,
    Map<String, dynamic> details = const {},
    String ipAddress = '127.0.0.1',
    DateTime? timestamp,
  }) {
    _sequenceCounter++;
    final id = 'audit_${DateTime.now().millisecondsSinceEpoch}_$_sequenceCounter';

    final entry = AuditLogEntry.create(
      id: id,
      timestamp: timestamp,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      targetId: targetId,
      details: details,
      ipAddress: ipAddress,
      privateKey: privateKey,
    );

    _entries.add(entry);
    return entry;
  }

  /// Queries audit logs matching the given filter with optional pagination.
  List<AuditLogEntry> query({
    AuditLogFilter? filter,
    int? limit,
    int? offset,
  }) {
    var result = _entries.toList();

    if (filter != null) {
      result = result.where((e) => filter.matches(e)).toList();
    }

    final start = offset ?? 0;
    if (start >= result.length) {
      return const [];
    }

    final end = limit != null ? (start + limit).clamp(0, result.length) : result.length;
    return result.sublist(start, end);
  }

  /// Verifies the cryptographic HMAC integrity and chronology of every recorded log entry.
  AuditLogAuditResult verifyAll() {
    final tampered = <AuditLogEntry>[];
    var chronological = true;
    DateTime? previousTimestamp;

    for (final entry in _entries) {
      final valid = entry.verifyIntegrity(publicKey);
      if (!valid) {
        tampered.add(entry);
      }

      if (previousTimestamp != null && entry.timestamp.isBefore(previousTimestamp)) {
        chronological = false;
      }
      previousTimestamp = entry.timestamp;
    }

    final isValid = tampered.isEmpty && chronological;

    return AuditLogAuditResult(
      isValid: isValid,
      totalChecked: _entries.length,
      tamperedEntries: tampered,
      isChronological: chronological,
    );
  }

  /// Total recorded audit log entries.
  int get count => _entries.length;

  /// Unmodifiable view of recorded audit log entries.
  List<AuditLogEntry> get entries => List.unmodifiable(_entries);

  /// Loads an external list of audit log entries (e.g. from persistent storage or backup).
  void loadEntries(List<AuditLogEntry> entries) {
    _entries.clear();
    _entries.addAll(entries);
  }

  /// Clears in-memory audit logs.
  void clear() {
    _entries.clear();
    _sequenceCounter = 0;
  }
}
