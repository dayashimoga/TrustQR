/// Server-side RBAC and entitlement enforcement server.
library rbac_api;

import 'dart:convert';
import 'dart:io';
import 'package:qr_core/qr_core.dart';

/// Server-side RBAC claims token.
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

/// Lightweight RBAC HTTP Service.
class RbacServer {
  final HttpServer _server;

  RbacServer._(this._server);

  static Future<RbacServer> bind({InternetAddress? address, int port = 8089}) async {
    final server = await HttpServer.bind(address ?? InternetAddress.loopbackIPv4, port);
    final instance = RbacServer._(server);
    server.listen(instance._handleRequest);
    return instance;
  }

  int get port => _server.port;

  Future<void> close({bool force = false}) => _server.close(force: force);

  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // Public / health check
    if (path == '/api/v1/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'healthy', 'service': 'rbac_api'}))
        ..close();
      return;
    }

    // Role check middleware for admin endpoints
    if (path.startsWith('/api/v1/admin/')) {
      final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
      final roleHeader = request.headers.value('X-User-Role');

      if (authHeader == null || roleHeader != 'admin') {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'error': 'Forbidden',
            'message': 'Role admin is required to access administrative and generation endpoints.',
          }))
          ..close();
        return;
      }

      // Valid admin
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'authorized', 'role': 'admin'}))
        ..close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }
}
