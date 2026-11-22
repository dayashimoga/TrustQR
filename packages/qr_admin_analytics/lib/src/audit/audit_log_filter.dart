import 'audit_log_entry.dart';

/// Multi-criteria filter for administrative audit log queries.
class AuditLogFilter {
  final String? action;
  final String? actorRole;
  final String? actorId;
  final String? targetId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? searchQuery;

  const AuditLogFilter({
    this.action,
    this.actorRole,
    this.actorId,
    this.targetId,
    this.fromDate,
    this.toDate,
    this.searchQuery,
  });

  /// Evaluates whether a given [AuditLogEntry] matches this filter.
  bool matches(AuditLogEntry entry) {
    if (action != null && entry.action != action) {
      return false;
    }
    if (actorRole != null &&
        entry.actorRole.toLowerCase() != actorRole!.toLowerCase()) {
      return false;
    }
    if (actorId != null && entry.actorId != actorId) {
      return false;
    }
    if (targetId != null && entry.targetId != targetId) {
      return false;
    }
    if (fromDate != null && entry.timestamp.isBefore(fromDate!)) {
      return false;
    }
    if (toDate != null && entry.timestamp.isAfter(toDate!)) {
      return false;
    }
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.trim().toLowerCase();
      final matchesAction = entry.action.toLowerCase().contains(q);
      final matchesActor = entry.actorId.toLowerCase().contains(q);
      final matchesTarget = entry.targetId.toLowerCase().contains(q);
      final matchesDetails = entry.details.toString().toLowerCase().contains(q);
      final matchesIp = entry.ipAddress.toLowerCase().contains(q);
      if (!matchesAction &&
          !matchesActor &&
          !matchesTarget &&
          !matchesDetails &&
          !matchesIp) {
        return false;
      }
    }
    return true;
  }

  AuditLogFilter copyWith({
    String? action,
    String? actorRole,
    String? actorId,
    String? targetId,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    bool clearAction = false,
    bool clearActorRole = false,
    bool clearActorId = false,
    bool clearTargetId = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearSearchQuery = false,
  }) {
    return AuditLogFilter(
      action: clearAction ? null : (action ?? this.action),
      actorRole: clearActorRole ? null : (actorRole ?? this.actorRole),
      actorId: clearActorId ? null : (actorId ?? this.actorId),
      targetId: clearTargetId ? null : (targetId ?? this.targetId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  Map<String, dynamic> toJson() => {
        if (action != null) 'action': action,
        if (actorRole != null) 'actorRole': actorRole,
        if (actorId != null) 'actorId': actorId,
        if (targetId != null) 'targetId': targetId,
        if (fromDate != null) 'fromDate': fromDate!.toUtc().toIso8601String(),
        if (toDate != null) 'toDate': toDate!.toUtc().toIso8601String(),
        if (searchQuery != null) 'searchQuery': searchQuery,
      };

  factory AuditLogFilter.fromJson(Map<String, dynamic> json) => AuditLogFilter(
        action: json['action'] as String?,
        actorRole: json['actorRole'] as String?,
        actorId: json['actorId'] as String?,
        targetId: json['targetId'] as String?,
        fromDate: json['fromDate'] != null
            ? DateTime.parse(json['fromDate'] as String).toUtc()
            : null,
        toDate: json['toDate'] != null
            ? DateTime.parse(json['toDate'] as String).toUtc()
            : null,
        searchQuery: json['searchQuery'] as String?,
      );
}
