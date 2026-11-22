import 'package:qr_core/qr_core.dart';

/// Legacy/convenience RBAC claims model.
class RbacClaims {
  final String subject;
  final UserRole role;
  final List<String> scopes;
  final DateTime expiresAt;

  const RbacClaims({
    required this.subject,
    required this.role,
    required this.scopes,
    required this.expiresAt,
  });

  bool get isAdmin => role == UserRole.admin;

  bool hasScope(String requiredScope) => scopes.contains(requiredScope) || isAdmin;

  Map<String, dynamic> toJson() => {
    'sub': subject,
    'role': role.name,
    'scopes': scopes,
    'exp': expiresAt.toIso8601String(),
  };

  static RbacClaims fromJson(Map<String, dynamic> map) {
    return RbacClaims(
      subject: map['sub'] as String,
      role: UserRole.values.byName(map['role'] as String),
      scopes: List<String>.from(map['scopes'] as List),
      expiresAt: DateTime.parse(map['exp'] as String),
    );
  }
}

/// Request to authenticate and acquire an entitlement token.
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  static LoginRequest fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}

/// Response returned on successful authentication.
class LoginResponse {
  final String token;
  final String tokenType;
  final String subject;
  final UserRole role;
  final List<String> scopes;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LoginResponse({
    required this.token,
    this.tokenType = 'Bearer',
    required this.subject,
    required this.role,
    required this.scopes,
    required this.issuedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'tokenType': tokenType,
    'subject': subject,
    'role': role.name,
    'scopes': scopes,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}

/// Request to verify an entitlement token.
class VerifyTokenRequest {
  final String token;

  const VerifyTokenRequest({required this.token});

  static VerifyTokenRequest fromJson(Map<String, dynamic> json) {
    return VerifyTokenRequest(
      token: json['token'] as String? ?? '',
    );
  }
}

/// Request to revoke an entitlement token.
class RevokeTokenRequest {
  final String? tokenId;

  const RevokeTokenRequest({this.tokenId});

  static RevokeTokenRequest fromJson(Map<String, dynamic> json) {
    return RevokeTokenRequest(
      tokenId: json['tokenId'] as String?,
    );
  }
}

/// Telemetry scan event payload ingested from mobile/desktop client scanner.
class ScanTelemetryRequest {
  final String format;
  final String payloadType;
  final String threatLevel;
  final bool isVerified;
  final int scanDurationMs;
  final String? clientPlatform;

  const ScanTelemetryRequest({
    required this.format,
    required this.payloadType,
    required this.threatLevel,
    required this.isVerified,
    required this.scanDurationMs,
    this.clientPlatform,
  });

  static ScanTelemetryRequest fromJson(Map<String, dynamic> json) {
    return ScanTelemetryRequest(
      format: json['format'] as String? ?? 'qr',
      payloadType: json['payloadType'] as String? ?? 'plainText',
      threatLevel: json['threatLevel'] as String? ?? 'low',
      isVerified: json['isVerified'] as bool? ?? false,
      scanDurationMs: (json['scanDurationMs'] as num?)?.toInt() ?? 0,
      clientPlatform: json['clientPlatform'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'format': format,
    'payloadType': payloadType,
    'threatLevel': threatLevel,
    'isVerified': isVerified,
    'scanDurationMs': scanDurationMs,
    if (clientPlatform != null) 'clientPlatform': clientPlatform,
  };
}
