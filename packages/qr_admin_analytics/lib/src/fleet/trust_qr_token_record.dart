import 'package:qr_core/qr_core.dart';

/// Registered TrustQR or entitlement token record for administrative auditing and revocation.
class TrustQrTokenRecord {
  final String tokenId;
  final String subject;
  final UserRole role;
  final String issuer;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isRevoked;
  final DateTime? revokedAt;
  final String? revocationReason;
  final Map<String, dynamic> entitlements;

  const TrustQrTokenRecord({
    required this.tokenId,
    required this.subject,
    required this.role,
    required this.issuer,
    required this.issuedAt,
    required this.expiresAt,
    this.isRevoked = false,
    this.revokedAt,
    this.revocationReason,
    this.entitlements = const {},
  });

  /// Evaluates whether this token has expired based on current UTC time.
  bool isExpired([DateTime? now]) {
    final current = now ?? DateTime.now().toUtc();
    return current.isAfter(expiresAt);
  }

  /// Whether this token is active, unrevoked, and unexpired.
  bool isValid([DateTime? now]) => !isRevoked && !isExpired(now);

  /// Alias for [isValid].
  bool isActive([DateTime? now]) => isValid(now);

  /// Status string representation ('active', 'expired', 'revoked').
  String status([DateTime? now]) =>
      isRevoked ? 'revoked' : (isExpired(now) ? 'expired' : 'active');

  TrustQrTokenRecord copyWith({
    String? tokenId,
    String? subject,
    UserRole? role,
    String? issuer,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isRevoked,
    DateTime? revokedAt,
    String? revocationReason,
    Map<String, dynamic>? entitlements,
  }) {
    return TrustQrTokenRecord(
      tokenId: tokenId ?? this.tokenId,
      subject: subject ?? this.subject,
      role: role ?? this.role,
      issuer: issuer ?? this.issuer,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRevoked: isRevoked ?? this.isRevoked,
      revokedAt: revokedAt ?? this.revokedAt,
      revocationReason: revocationReason ?? this.revocationReason,
      entitlements: entitlements ?? this.entitlements,
    );
  }

  Map<String, dynamic> toJson() => {
    'tokenId': tokenId,
    'subject': subject,
    'role': role.name,
    'issuer': issuer,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'isRevoked': isRevoked,
    'revokedAt': revokedAt?.toUtc().toIso8601String(),
    'revocationReason': revocationReason,
    'entitlements': entitlements,
  };

  factory TrustQrTokenRecord.fromJson(Map<String, dynamic> json) {
    return TrustQrTokenRecord(
      tokenId: json['tokenId'] as String,
      subject: json['subject'] as String,
      role: UserRole.values.byName(json['role'] as String? ?? 'user'),
      issuer: json['issuer'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String).toUtc(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
      isRevoked: (json['isRevoked'] as bool?) ?? false,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String).toUtc()
          : null,
      revocationReason: json['revocationReason'] as String?,
      entitlements: (json['entitlements'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
