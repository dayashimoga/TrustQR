import 'dart:convert';
import 'dart:io';
import 'package:qr_core/qr_core.dart';
import '../config/rbac_config.dart';
import '../middleware/rbac_middleware.dart';
import '../models/admin_models.dart';
import '../models/auth_models.dart';
import '../store/rbac_store.dart';

/// Request router and HTTP dispatcher for RBAC Authority service.
class RbacRouter {
  final RbacConfig config;
  final RbacStore store;

  RbacRouter({
    required this.config,
    required this.store,
  });

  /// Dispatches incoming HTTP requests to corresponding controller routes.
  Future<void> handleRequest(HttpRequest request) async {
    _applyCorsHeaders(request.response);

    // Handle OPTIONS preflight requests
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();
      return;
    }

    final path = request.uri.path;
    final method = request.method;

    try {
      // 1. Health check (Public)
      if (path == '/api/v1/health' && method == 'GET') {
        _sendJson(request.response, {
          'status': 'healthy',
          'service': 'rbac_api',
          'version': '0.1.0',
          'issuer': config.issuer,
          'uptimeSeconds': store.getAnalytics().uptimeSeconds,
        });
        return;
      }

      // 2. Public institutional keys for TrustQR verification (Public)
      if (path == '/api/v1/trustqr/keys' && method == 'GET') {
        _sendJson(request.response, {
          'keys': [
            {
              'kty': 'OKP',
              'crv': 'Ed25519',
              'kid': config.publicKey.keyId,
              'alg': 'Ed25519',
              'x': config.publicKey.toBase64Url(),
              'use': 'sig',
              'issuer': config.issuer,
            }
          ]
        });
        return;
      }

      // 3. Issue Entitlement Token (Public)
      if (path == '/api/v1/auth/token' && method == 'POST') {
        final body = await _readJsonBody(request);
        if (body == null) {
          _sendError(request.response, HttpStatus.badRequest, 'Invalid JSON body', 'BAD_REQUEST');
          return;
        }

        final loginReq = LoginRequest.fromJson(body);
        final cred = config.credentials[loginReq.username];

        if (cred == null || cred.password != loginReq.password) {
          store.recordAudit(
            action: 'auth.login.failed',
            actor: loginReq.username.isNotEmpty ? loginReq.username : 'anonymous',
            status: 'failed',
            ip: _getClientIp(request),
            details: {'reason': 'Invalid credentials'},
          );
          _sendError(request.response, HttpStatus.unauthorized, 'Invalid username or password', 'INVALID_CREDENTIALS');
          return;
        }

        final now = DateTime.now().toUtc();
        final tokenId = 'jti-${now.millisecondsSinceEpoch}-${loginReq.username}';
        final token = EntitlementToken.issue(
          tokenId: tokenId,
          subject: '${loginReq.username}@universalqr.org',
          role: cred.role,
          scopes: cred.scopes,
          privateKey: config.privateKey,
          issuer: config.issuer,
          validity: config.tokenValidity,
          issuedAt: now,
        );

        store.recordAudit(
          action: 'auth.login.success',
          actor: loginReq.username,
          status: 'success',
          ip: _getClientIp(request),
          details: {'role': cred.role.name, 'tokenId': tokenId},
        );

        final loginResp = LoginResponse(
          token: token.toCompactToken(),
          subject: token.subject,
          role: token.role,
          scopes: token.scopes,
          issuedAt: token.issuedAt,
          expiresAt: token.expiresAt,
        );

        _sendJson(request.response, loginResp.toJson());
        return;
      }

      // 4. Verify Entitlement Token (Public)
      if (path == '/api/v1/auth/verify' && method == 'POST') {
        final body = await _readJsonBody(request);
        if (body == null) {
          _sendError(request.response, HttpStatus.badRequest, 'Invalid JSON body', 'BAD_REQUEST');
          return;
        }

        final verifyReq = VerifyTokenRequest.fromJson(body);
        final token = EntitlementToken.tryParse(verifyReq.token);

        if (token == null) {
          _sendJson(request.response, {
            'isValid': false,
            'reason': 'Malformed entitlement token format',
          });
          return;
        }

        if (store.isTokenRevoked(token.tokenId)) {
          _sendJson(request.response, {
            'isValid': false,
            'tokenId': token.tokenId,
            'reason': 'Token has been revoked',
          });
          return;
        }

        final verification = token.verify(publicKey: config.publicKey);
        _sendJson(request.response, verification.toJson());
        return;
      }

      // Authenticate caller for protected routes
      final authResult = RbacMiddleware.authenticate(request, config, store);
      if (authResult.failure != null) {
        _sendError(
          request.response,
          authResult.failure!.statusCode,
          authResult.failure!.message,
          authResult.failure!.code,
        );
        return;
      }

      final context = authResult.context!;

      // 5. Revoke Token (Requires Authentication: user can revoke own, admin can revoke any)
      if (path == '/api/v1/auth/revoke' && method == 'POST') {
        if (!context.isAuthenticated) {
          _sendError(request.response, HttpStatus.unauthorized, 'Authentication required to revoke token', 'AUTH_REQUIRED');
          return;
        }

        final body = await _readJsonBody(request);
        final revokeReq = body != null ? RevokeTokenRequest.fromJson(body) : const RevokeTokenRequest();
        final targetTokenId = revokeReq.tokenId ?? context.token?.tokenId;

        if (targetTokenId == null) {
          _sendError(request.response, HttpStatus.badRequest, 'Missing tokenId to revoke', 'BAD_REQUEST');
          return;
        }

        if (targetTokenId != context.token?.tokenId && !context.isAdmin) {
          _sendError(request.response, HttpStatus.forbidden, 'Only administrators can revoke arbitrary tokens', 'INSUFFICIENT_PERMISSIONS');
          return;
        }

        store.revokeToken(targetTokenId);
        store.recordAudit(
          action: 'auth.revoke',
          actor: context.subject ?? 'unknown',
          status: 'success',
          ip: context.clientIp,
          details: {'revokedTokenId': targetTokenId},
        );

        _sendJson(request.response, {
          'revoked': true,
          'tokenId': targetTokenId,
        });
        return;
      }

      // 6. Scanner Telemetry Ingestion (Accessible to both user and admin)
      if (path == '/api/v1/telemetry/scan' && method == 'POST') {
        if (!context.isAuthenticated) {
          _sendError(request.response, HttpStatus.unauthorized, 'Authentication required to submit telemetry', 'AUTH_REQUIRED');
          return;
        }

        final body = await _readJsonBody(request);
        if (body == null) {
          _sendError(request.response, HttpStatus.badRequest, 'Invalid telemetry JSON payload', 'BAD_REQUEST');
          return;
        }

        final telemetry = ScanTelemetryRequest.fromJson(body);
        store.recordTelemetry(telemetry);

        _sendJson(request.response, {
          'recorded': true,
          'status': 'acknowledged',
          'threatLevel': telemetry.threatLevel,
        });
        return;
      }

      // 7. Admin-Only Endpoints (Strictly requires role: admin)
      if (path.startsWith('/api/v1/admin/')) {
        final adminFailure = RbacMiddleware.requireAdmin(context);
        if (adminFailure != null) {
          store.recordAudit(
            action: 'admin.access.denied',
            actor: context.subject ?? 'anonymous',
            status: 'denied',
            ip: context.clientIp,
            details: {'path': path, 'code': adminFailure.code},
          );
          _sendError(request.response, adminFailure.statusCode, adminFailure.message, adminFailure.code);
          return;
        }

        // POST /api/v1/admin/qr/generate
        if (path == '/api/v1/admin/qr/generate' && method == 'POST') {
          final body = await _readJsonBody(request);
          if (body == null) {
            _sendError(request.response, HttpStatus.badRequest, 'Invalid generation payload', 'BAD_REQUEST');
            return;
          }

          final genReq = QrGenerateRequest.fromJson(body);
          if (genReq.content.trim().isEmpty) {
            _sendError(request.response, HttpStatus.badRequest, 'Content cannot be empty', 'BAD_REQUEST');
            return;
          }

          store.recordGeneration();
          store.recordAudit(
            action: 'admin.qr.generate',
            actor: context.subject!,
            status: 'success',
            ip: context.clientIp,
            details: {'eccLevel': genReq.eccLevel, 'shape': genReq.shape},
          );

          final genResp = QrGenerateResponse(
            status: 'generated',
            content: genReq.content,
            eccLevel: genReq.eccLevel,
            version: 1,
            matrixDimension: 21,
          );

          _sendJson(request.response, genResp.toJson());
          return;
        }

        // POST /api/v1/admin/qr/batch
        if (path == '/api/v1/admin/qr/batch' && method == 'POST') {
          final body = await _readJsonBody(request);
          if (body == null) {
            _sendError(request.response, HttpStatus.badRequest, 'Invalid batch payload', 'BAD_REQUEST');
            return;
          }

          final batchReq = QrBatchRequest.fromJson(body);
          if (batchReq.items.isEmpty) {
            _sendError(request.response, HttpStatus.badRequest, 'Batch items list cannot be empty', 'BAD_REQUEST');
            return;
          }

          final batchId = 'batch-${DateTime.now().millisecondsSinceEpoch}';
          store.recordGeneration(count: batchReq.items.length);
          store.recordAudit(
            action: 'admin.qr.batch',
            actor: context.subject!,
            status: 'success',
            ip: context.clientIp,
            details: {'batchId': batchId, 'count': batchReq.items.length},
          );

          final results = batchReq.items.map((item) => {
            'id': item.id,
            'content': item.content,
            'eccLevel': item.eccLevel,
            'status': 'generated',
          }).toList();

          final batchResp = QrBatchResponse(
            batchId: batchId,
            count: batchReq.items.length,
            items: results,
          );

          _sendJson(request.response, batchResp.toJson());
          return;
        }

        // POST /api/v1/admin/qr/sign (Institutional TrustQR Cryptographic Signing)
        if (path == '/api/v1/admin/qr/sign' && method == 'POST') {
          final body = await _readJsonBody(request);
          if (body == null) {
            _sendError(request.response, HttpStatus.badRequest, 'Invalid signing payload', 'BAD_REQUEST');
            return;
          }

          final signReq = QrSignRequest.fromJson(body);
          if (signReq.payload.trim().isEmpty) {
            _sendError(request.response, HttpStatus.badRequest, 'Payload cannot be empty', 'BAD_REQUEST');
            return;
          }

          final now = DateTime.now().toUtc();
          final expiresAt = signReq.expiresInSeconds != null
              ? now.add(Duration(seconds: signReq.expiresInSeconds!))
              : null;

          final envelope = TrustQrEnvelope.sign(
            issuer: config.issuer,
            payload: signReq.payload,
            privateKey: config.privateKey,
            createdAt: now,
            expiresAt: expiresAt,
          );

          store.recordTrustQrSignature();
          store.recordAudit(
            action: 'admin.qr.sign',
            actor: context.subject!,
            status: 'success',
            ip: context.clientIp,
            details: {'issuer': envelope.issuer, 'keyId': envelope.keyId},
          );

          final signResp = QrSignResponse(
            trustQrUri: envelope.toUriString(),
            issuer: envelope.issuer,
            keyId: envelope.keyId,
            signature: envelope.signature,
            payload: envelope.payload,
            createdAt: envelope.createdAt,
            expiresAt: envelope.expiresAt,
          );

          _sendJson(request.response, signResp.toJson());
          return;
        }

        // GET /api/v1/admin/templates
        if (path == '/api/v1/admin/templates' && method == 'GET') {
          final templates = store.getTemplates().map((t) => t.toJson()).toList();
          _sendJson(request.response, {'templates': templates});
          return;
        }

        // POST /api/v1/admin/templates
        if (path == '/api/v1/admin/templates' && method == 'POST') {
          final body = await _readJsonBody(request);
          if (body == null) {
            _sendError(request.response, HttpStatus.badRequest, 'Invalid template payload', 'BAD_REQUEST');
            return;
          }

          final name = body['name'] as String? ?? '';
          if (name.trim().isEmpty) {
            _sendError(request.response, HttpStatus.badRequest, 'Template name is required', 'BAD_REQUEST');
            return;
          }

          final newTemplate = QrTemplate(
            id: 'tmpl-${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            description: body['description'] as String? ?? '',
            styleConfig: Map<String, dynamic>.from(body['styleConfig'] as Map? ?? {}),
            createdAt: DateTime.now(),
          );

          store.addTemplate(newTemplate);
          store.recordAudit(
            action: 'admin.templates.create',
            actor: context.subject!,
            status: 'success',
            ip: context.clientIp,
            details: {'templateId': newTemplate.id, 'name': newTemplate.name},
          );

          _sendJson(request.response, newTemplate.toJson(), statusCode: HttpStatus.created);
          return;
        }

        // GET /api/v1/admin/analytics
        if (path == '/api/v1/admin/analytics' && method == 'GET') {
          final analytics = store.getAnalytics();
          _sendJson(request.response, analytics.toJson());
          return;
        }

        // GET /api/v1/admin/audit
        if (path == '/api/v1/admin/audit' && method == 'GET') {
          store.recordAudit(
            action: 'admin.audit.view',
            actor: context.subject!,
            status: 'success',
            ip: context.clientIp,
          );
          final logs = store.getAuditLogs().map((log) => log.toJson()).toList();
          _sendJson(request.response, {'auditLogs': logs});
          return;
        }
      }

      // Unmatched route -> 404 Not Found
      _sendError(request.response, HttpStatus.notFound, 'Endpoint not found', 'NOT_FOUND');
    } catch (e, stack) {
      _sendError(
        request.response,
        HttpStatus.internalServerError,
        'Internal server error: $e',
        'INTERNAL_ERROR',
        details: {'stackTrace': stack.toString()},
      );
    }
  }

  void _applyCorsHeaders(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, DELETE, PUT')
      ..set('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-User-Role')
      ..contentType = ContentType.json;
  }

  Future<Map<String, dynamic>?> _readJsonBody(HttpRequest request) async {
    try {
      final raw = await utf8.decoder.bind(request).join();
      if (raw.trim().isEmpty) return null;
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
      return null;
    } catch (_) {
      return null;
    }
  }

  void _sendJson(HttpResponse response, Map<String, dynamic> data, {int statusCode = HttpStatus.ok}) {
    response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(data))
      ..close();
  }

  void _sendError(
    HttpResponse response,
    int statusCode,
    String message,
    String code, {
    Map<String, dynamic>? details,
  }) {
    final failure = AuthFailure(statusCode: statusCode, message: message, code: code);
    final payload = failure.toJson();
    if (details != null) {
      payload['details'] = details;
    }

    _sendJson(response, payload, statusCode: statusCode);
  }

  String _getClientIp(HttpRequest request) {
    return request.headers.value('x-forwarded-for') ??
        request.connectionInfo?.remoteAddress.address ??
        'unknown';
  }
}
