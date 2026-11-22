import 'dart:convert';
import 'dart:io';
import 'package:qr_core/qr_core.dart';
import 'package:rbac_api/rbac_api.dart';
import 'package:test/test.dart';

void main() {
  group('RBAC API Server & Core Model Tests', () {
    late RbacServer server;
    late int port;
    late HttpClient client;

    setUp(() async {
      server = await RbacServer.bind(port: 0);
      port = server.port;
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('Health endpoint returns 200 OK with server metadata', () async {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/health'));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['status'], equals('healthy'));
      expect(json['service'], equals('rbac_api'));
      expect(json['version'], equals('0.1.0'));
      expect(json['issuer'], equals('universal-qr-authority'));
      expect(json['uptimeSeconds'], isA<int>());
    });

    test('Server properties and address verification', () {
      expect(server.port, equals(port));
      expect(server.address, equals(InternetAddress.loopbackIPv4));
    });

    test('CORS OPTIONS preflight returns 204 No Content with CORS headers', () async {
      final req = await client.openUrl('OPTIONS', Uri.parse('http://127.0.0.1:$port/api/v1/admin/analytics'));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.noContent));
      expect(resp.headers.value('Access-Control-Allow-Origin'), equals('*'));
      expect(resp.headers.value('Access-Control-Allow-Methods'), contains('POST'));
    });

    test('TrustQR public keys endpoint returns Ed25519 institutional key', () async {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/trustqr/keys'));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['keys'], isA<List>());
      final keys = json['keys'] as List;
      expect(keys.length, equals(1));

      final key = keys.first as Map<String, dynamic>;
      expect(key['kty'], equals('OKP'));
      expect(key['crv'], equals('Ed25519'));
      expect(key['kid'], equals('trustqr-root-2026'));
      expect(key['alg'], equals('Ed25519'));
      expect(key['x'], isNotEmpty);
    });

    test('Authentication exchange with valid credentials issues signed EntitlementToken', () async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/token'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'username': 'admin',
        'password': 'admin-password-secure',
      }));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['token'], isNotEmpty);
      expect(json['role'], equals('admin'));
      expect(json['scopes'], contains('qr:admin'));
      expect(json['scopes'], contains('qr:generate'));

      final token = EntitlementToken.tryParse(json['token'] as String);
      expect(token, isNotNull);
      expect(token!.role, equals(UserRole.admin));
    });

    test('Authentication exchange with invalid credentials returns 401 Unauthorized', () async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/token'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'username': 'admin',
        'password': 'wrong-password',
      }));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.unauthorized));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['code'], equals('INVALID_CREDENTIALS'));
    });

    test('Authentication exchange with empty/invalid body returns 400 Bad Request', () async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/token'));
      req.headers.contentType = ContentType.json;
      req.write('');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('Verify endpoint accurately verifies valid token', () async {
      final token = EntitlementToken.issue(
        tokenId: 'jti-test-verify',
        subject: 'user@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );

      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/verify'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'token': token.toCompactToken()}));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['isValid'], isTrue);
      expect(json['role'], equals('user'));
    });

    test('Verify endpoint with empty body returns 400 Bad Request', () async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/verify'));
      req.headers.contentType = ContentType.json;
      req.write('');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('Verify endpoint with malformed token returns isValid: false', () async {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/verify'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'token': 'not.a.valid.token'}));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['isValid'], isFalse);
      expect(json['reason'], contains('Malformed'));
    });

    test('Verify endpoint rejects revoked token', () async {
      final token = EntitlementToken.issue(
        tokenId: 'jti-revoked-token',
        subject: 'user@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );

      server.store.revokeToken('jti-revoked-token');

      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/auth/verify'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'token': token.toCompactToken()}));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['isValid'], isFalse);
      expect(json['reason'], contains('revoked'));
    });

    test('Telemetry ingestion endpoint records scanner events from authenticated user', () async {
      final token = EntitlementToken.issue(
        tokenId: 'jti-scanner-user',
        subject: 'scanner@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );

      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/telemetry/scan'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${token.toCompactToken()}');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'format': 'qr',
        'payloadType': 'url',
        'threatLevel': 'critical',
        'isVerified': false,
        'scanDurationMs': 14,
        'clientPlatform': 'android',
      }));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['recorded'], isTrue);

      final analytics = server.store.getAnalytics();
      expect(analytics.totalScans, equals(1));
      expect(analytics.threatsBlocked, equals(1));
    });

    test('Telemetry endpoint with empty body returns 400 Bad Request', () async {
      final token = EntitlementToken.issue(
        tokenId: 'jti-telemetry-empty',
        subject: 'scanner@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );

      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/telemetry/scan'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${token.toCompactToken()}');
      req.headers.contentType = ContentType.json;
      req.write('');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('Admin endpoints with empty body return 400 Bad Request', () async {
      final adminToken = EntitlementToken.issue(
        tokenId: 'jti-admin-empty-bodies',
        subject: 'admin@universalqr.org',
        role: UserRole.admin,
        scopes: ['qr:admin'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      ).toCompactToken();

      // Generate empty body
      var req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/qr/generate'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
      req.headers.contentType = ContentType.json;
      req.write('');
      var resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));

      // Batch empty body
      req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/qr/batch'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
      req.headers.contentType = ContentType.json;
      req.write('');
      resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));

      // Sign empty body
      req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/qr/sign'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
      req.headers.contentType = ContentType.json;
      req.write('');
      resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));

      // Templates empty body
      req = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/templates'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
      req.headers.contentType = ContentType.json;
      req.write('');
      resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.badRequest));
    });

    test('Unmatched endpoint returns 404 Not Found', () async {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/unknown/endpoint'));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.notFound));
    });

    test('RbacClaims model serialization and methods', () {
      final claims = RbacClaims(
        subject: 'admin@universalqr.org',
        role: UserRole.admin,
        scopes: ['qr:all'],
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(claims.isAdmin, isTrue);
      expect(claims.hasScope('qr:generate'), isTrue);

      final json = claims.toJson();
      final deserialized = RbacClaims.fromJson(json);
      expect(deserialized.subject, equals(claims.subject));
      expect(deserialized.role, equals(claims.role));

      final userClaims = RbacClaims(
        subject: 'user@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(userClaims.isAdmin, isFalse);
      expect(userClaims.hasScope('qr:scan'), isTrue);
      expect(userClaims.hasScope('qr:generate'), isFalse);
    });

    test('Auth and Admin models JSON serialization roundtrip', () {
      final genReq = QrGenerateRequest.fromJson({
        'content': 'https://universalqr.org',
        'eccLevel': 'Q',
        'shape': 'diamond',
        'foregroundColor': '#00F0FF',
        'backgroundColor': '#0A0E17',
      });
      expect(genReq.content, equals('https://universalqr.org'));
      expect(genReq.eccLevel, equals('Q'));
      expect(genReq.shape, equals('diamond'));
      expect(genReq.toJson()['foregroundColor'], equals('#00F0FF'));

      final genResp = QrGenerateResponse(
        status: 'generated',
        content: 'https://universalqr.org',
        eccLevel: 'Q',
        version: 1,
        matrixDimension: 21,
      );
      expect(genResp.toJson()['version'], equals(1));

      final batchReq = QrBatchRequest.fromJson({
        'items': [
          {'id': 'item-1', 'content': 'qr-1', 'eccLevel': 'M'},
          {'id': 'item-2', 'content': 'qr-2', 'eccLevel': 'H'},
        ]
      });
      expect(batchReq.items.length, equals(2));
      expect(batchReq.toJson()['items'], isA<List>());

      final batchResp = QrBatchResponse(
        batchId: 'batch-test-01',
        count: 1,
        items: [{'id': '1'}],
      );
      expect(batchResp.toJson()['batchId'], equals('batch-test-01'));

      final signReq = QrSignRequest.fromJson({
        'payload': 'secure-content',
        'expiresInSeconds': 3600,
      });
      expect(signReq.payload, equals('secure-content'));
      expect(signReq.expiresInSeconds, equals(3600));
      expect(signReq.toJson()['expiresInSeconds'], equals(3600));

      final signResp = QrSignResponse(
        trustQrUri: 'trustqr://v1?test',
        issuer: 'authority',
        keyId: 'key-1',
        signature: 'sig-1',
        payload: 'test-payload',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(signResp.toJson()['trustQrUri'], equals('trustqr://v1?test'));

      final template = QrTemplate.fromJson({
        'id': 'tmpl-test',
        'name': 'Test Template',
        'description': 'A test template',
        'styleConfig': {'shape': 'dots'},
      });
      expect(template.id, equals('tmpl-test'));
      expect(template.styleConfig['shape'], equals('dots'));
      expect(template.toJson()['name'], equals('Test Template'));

      final telemetry = ScanTelemetryRequest(
        format: 'qr',
        payloadType: 'url',
        threatLevel: 'low',
        isVerified: true,
        scanDurationMs: 15,
        clientPlatform: 'ios',
      );
      final teleJson = telemetry.toJson();
      expect(teleJson['format'], equals('qr'));
      expect(teleJson['clientPlatform'], equals('ios'));

      final auditEvent = AdminAuditEvent(
        id: 'audit-001',
        action: 'test.action',
        actor: 'test.actor',
        timestamp: DateTime.now(),
        status: 'success',
        ip: '127.0.0.1',
        details: {'key': 'value'},
      );
      final auditJson = auditEvent.toJson();
      expect(auditJson['id'], equals('audit-001'));
      expect(auditJson['ip'], equals('127.0.0.1'));
      expect(auditJson['details']['key'], equals('value'));

      final analytics = AdminAnalytics(
        totalScans: 10,
        totalGenerations: 5,
        threatsBlocked: 2,
        activeSessions: 1,
        trustQrSignaturesIssued: 3,
        uptimeSeconds: 120,
      );
      final analyticsJson = analytics.toJson();
      expect(analyticsJson['totalScans'], equals(10));
      expect(analyticsJson['uptimeSeconds'], equals(120));

      final failure = AuthFailure(
        statusCode: HttpStatus.forbidden,
        message: 'Denied',
        code: 'ACCESS_DENIED',
      );
      expect(failure.toJson()['error'], equals('Forbidden'));
    });
  });
}
