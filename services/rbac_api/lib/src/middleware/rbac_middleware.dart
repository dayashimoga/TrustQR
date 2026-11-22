import 'dart:io';
import 'package:qr_core/qr_core.dart';
import '../config/rbac_config.dart';
import '../store/rbac_store.dart';

/// Authentication failure details.
class AuthFailure {
  final int statusCode;
  final String message;
  final String code;

  const AuthFailure({
    required this.statusCode,
    required this.message,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'error': statusCode == HttpStatus.forbidden
        ? 'Forbidden'
        : statusCode == HttpStatus.unauthorized
            ? 'Unauthorized'
            : statusCode == HttpStatus.badRequest
                ? 'Bad Request'
                : statusCode == HttpStatus.notFound
                    ? 'Not Found'
                    : 'Error',
    'message': message,
    'code': code,
  };
}

/// Request context decorated with verified authentication and role claims.
class AuthenticatedContext {
  final HttpRequest request;
  final EntitlementToken? token;
  final UserRole? role;
  final String? subject;
  final List<String> scopes;
  final bool isAuthenticated;

  const AuthenticatedContext({
    required this.request,
    this.token,
    this.role,
    this.subject,
    this.scopes = const [],
    required this.isAuthenticated,
  });

  bool get isAdmin => role == UserRole.admin;

  bool hasScope(String requiredScope) => isAdmin || scopes.contains(requiredScope);

  String get clientIp =>
      request.headers.value('x-forwarded-for') ??
      request.connectionInfo?.remoteAddress.address ??
      'unknown';
}

/// Authentication and RBAC verification middleware.
class RbacMiddleware {
  /// Evaluates authentication headers on the incoming HTTP request.
  ///
  /// Returns [AuthenticatedContext] if valid, or throws/returns [AuthFailure] on invalid/unauthorized tokens.
  static ({AuthenticatedContext? context, AuthFailure? failure}) authenticate(
    HttpRequest request,
    RbacConfig config,
    RbacStore store,
  ) {
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);

    // If no Authorization header is present, context is unauthenticated.
    if (authHeader == null || authHeader.trim().isEmpty) {
      return (
        context: AuthenticatedContext(request: request, isAuthenticated: false),
        failure: null,
      );
    }

    final trimmed = authHeader.trim();
    if (!trimmed.toLowerCase().startsWith('bearer ')) {
      return (
        context: null,
        failure: const AuthFailure(
          statusCode: HttpStatus.unauthorized,
          message: 'Authorization header must use Bearer scheme',
          code: 'AUTH_INVALID_SCHEME',
        ),
      );
    }

    final tokenString = trimmed.substring(7).trim();
    final parsedToken = EntitlementToken.tryParse(tokenString);

    if (parsedToken == null) {
      return (
        context: null,
        failure: const AuthFailure(
          statusCode: HttpStatus.unauthorized,
          message: 'Malformed entitlement token format',
          code: 'TOKEN_MALFORMED',
        ),
      );
    }

    // Check revocation list
    if (store.isTokenRevoked(parsedToken.tokenId)) {
      return (
        context: null,
        failure: const AuthFailure(
          statusCode: HttpStatus.unauthorized,
          message: 'Entitlement token has been revoked',
          code: 'TOKEN_REVOKED',
        ),
      );
    }

    // Verify cryptographic signature and expiration
    final verification = parsedToken.verify(publicKey: config.publicKey);
    if (!verification.isValid) {
      final reason = verification.reason ?? 'Token validation failed';
      String code = 'TOKEN_INVALID';
      if (reason.toLowerCase().contains('expired')) {
        code = 'TOKEN_EXPIRED';
      } else if (reason.toLowerCase().contains('mismatch')) {
        code = 'KEY_MISMATCH';
      }

      return (
        context: null,
        failure: AuthFailure(
          statusCode: HttpStatus.unauthorized,
          message: reason,
          code: code,
        ),
      );
    }

    return (
      context: AuthenticatedContext(
        request: request,
        token: parsedToken,
        role: parsedToken.role,
        subject: parsedToken.subject,
        scopes: parsedToken.scopes,
        isAuthenticated: true,
      ),
      failure: null,
    );
  }

  /// Verifies that caller has `UserRole.admin` or required scopes for admin endpoints.
  static AuthFailure? requireAdmin(AuthenticatedContext context) {
    if (!context.isAuthenticated) {
      return const AuthFailure(
        statusCode: HttpStatus.unauthorized,
        message: 'Authentication required to access administrative resource',
        code: 'AUTH_REQUIRED',
      );
    }

    if (!context.isAdmin) {
      return const AuthFailure(
        statusCode: HttpStatus.forbidden,
        message: 'Role admin is required to access administrative and generation endpoints.',
        code: 'INSUFFICIENT_PERMISSIONS',
      );
    }

    return null;
  }
}
