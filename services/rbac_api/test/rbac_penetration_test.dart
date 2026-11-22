import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:qr_core/qr_core.dart';
import 'package:rbac_api/rbac_api.dart';
import 'package:test/test.dart';

void main() {
  group('RBAC Adversarial Penetration & Threat Security Suite', () {
    late RbacServer server;
    late int port;
    late HttpClient client;
    late String userToken;
    late String adminToken;
    late CryptoKeyPair attackerKeyPair;

    setUp(() async {
      server = await RbacServer.bind(port: 0);
      port = server.port;
      client = HttpClient();

      // Issue legitimate user token
      final userTokenObj = EntitlementToken.issue(
        tokenId: 'jti-legit-user-001',
        subject: 'standard-user@universalqr.org',
        role: UserRole.user,
        scopes: const ['qr:scan', 'qr:verify', 'qr:history:own'],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );
      userToken = userTokenObj.toCompactToken();

      // Issue legitimate admin token
      final adminTokenObj = EntitlementToken.issue(
        tokenId: 'jti-legit-admin-001',
        subject: 'fleet-admin@universalqr.org',
        role: UserRole.admin,
        scopes: const [
          'qr:scan',
          'qr:verify',
          'qr:history:own',
          'qr:generate',
          'qr:customize',
          'qr:batch',
          'qr:sign',
          'qr:templates',
          'qr:analytics',
          'qr:admin',
        ],
        privateKey: server.config.privateKey,
        issuer: server.config.issuer,
      );
      adminToken = adminTokenObj.toCompactToken();

      // Generate attacker rogue keypair
      final rogueSeed = sha256.convert(utf8.encode('rogue-attacker-seed-999')).bytes;
      attackerKeyPair = Ed25519Engine.generateKeyPairFromSeed(
        Uint8List.fromList(rogueSeed),
        keyId: 'rogue-key-999',
      );
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    // List of all protected admin endpoints
    final adminEndpoints = <({String method, String path, Map<String, dynamic>? body})>[
      (method: 'POST', path: '/api/v1/admin/qr/generate', body: {'content': 'https://test.com'}),
      (method: 'POST', path: '/api/v1/admin/qr/batch', body: {'items': [{'id': '1', 'content': 'test'}]}),
      (method: 'POST', path: '/api/v1/admin/qr/sign', body: {'payload': 'secure-doc'}),
      (method: 'GET', path: '/api/v1/admin/templates', body: null),
      (method: 'POST', path: '/api/v1/admin/templates', body: {'name': 'New Dark Matrix', 'styleConfig': {}}),
      (method: 'GET', path: '/api/v1/admin/analytics', body: null),
      (method: 'GET', path: '/api/v1/admin/audit', body: null),
    ];

    Future<HttpClientResponse> sendRequest({
      required String method,
      required String path,
      String? authHeader,
      Map<String, dynamic>? body,
      String? rawBody,
    }) async {
      final uri = Uri.parse('http://127.0.0.1:$port$path');
      final req = await client.openUrl(method, uri);
      if (authHeader != null) {
        req.headers.set(HttpHeaders.authorizationHeader, authHeader);
      }
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      } else if (rawBody != null) {
        req.headers.contentType = ContentType.json;
        req.write(rawBody);
      }
      return await req.close();
    }

    // -------------------------------------------------------------------------
    // VECTOR 1: Anonymous Access (Zero Auth Header)
    // -------------------------------------------------------------------------
    group('Vector 1: Anonymous Access Rejection', () {
      for (final endpoint in adminEndpoints) {
        test('Anonymous call to ${endpoint.method} ${endpoint.path} returns 401 Unauthorized', () async {
          final resp = await sendRequest(
            method: endpoint.method,
            path: endpoint.path,
            authHeader: null,
            body: endpoint.body,
          );
          expect(resp.statusCode, equals(HttpStatus.unauthorized));

          final respBody = await utf8.decoder.bind(resp).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          expect(json['error'], equals('Unauthorized'));
          expect(json['code'], equals('AUTH_REQUIRED'));
        });
      }
    });

    // -------------------------------------------------------------------------
    // VECTOR 2: Invalid Authorization Scheme
    // -------------------------------------------------------------------------
    group('Vector 2: Invalid Authorization Scheme Rejection', () {
      test('Basic auth header returns 401 Unauthorized', () async {
        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Basic YWRtaW46cGFzc3dvcmQ=',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('AUTH_INVALID_SCHEME'));
      });

      test('Token auth header without Bearer returns 401 Unauthorized', () async {
        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Token some-token-string',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('AUTH_INVALID_SCHEME'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 3: Malformed & Truncated Tokens
    // -------------------------------------------------------------------------
    group('Vector 3: Malformed Token Rejection', () {
      final malformedVariants = [
        'not-a-token',
        'singlePartOnly',
        'partOne.partTwo',
        'partOne.partTwo.partThree.partFour',
        'header.invalidBase64!#*.sig',
        'header.${base64UrlEncode(utf8.encode('{"corrupted": true}'))}.signature',
      ];

      for (var i = 0; i < malformedVariants.length; i++) {
        test('Malformed token variant #$i returns 401 Unauthorized', () async {
          final resp = await sendRequest(
            method: 'GET',
            path: '/api/v1/admin/analytics',
            authHeader: 'Bearer ${malformedVariants[i]}',
          );
          expect(resp.statusCode, equals(HttpStatus.unauthorized));

          final respBody = await utf8.decoder.bind(resp).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          expect(json['code'], equals('TOKEN_MALFORMED'));
        });
      }
    });

    // -------------------------------------------------------------------------
    // VECTOR 4: Cryptographic Signature Tampering
    // -------------------------------------------------------------------------
    group('Vector 4: Signature Tampering Rejection', () {
      test('Altered signature byte fails cryptographic verification', () async {
        final parts = adminToken.split('.');
        final originalSig = parts[2];
        // Flip the last character in the base64 signature
        final tamperedSig = originalSig.endsWith('A')
            ? '${originalSig.substring(0, originalSig.length - 1)}B'
            : '${originalSig.substring(0, originalSig.length - 1)}A';
        final tamperedToken = '${parts[0]}.${parts[1]}.$tamperedSig';

        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer $tamperedToken',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('TOKEN_INVALID'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 5: Adversarial Privilege Escalation (Payload Modification)
    // -------------------------------------------------------------------------
    group('Vector 5: Adversarial Privilege Escalation Rejection', () {
      test('User attempting to escalate role to admin in claims without valid private key is rejected', () async {
        final parts = userToken.split('.');
        final claimsJson = jsonDecode(utf8.decode(base64Url.decode(parts[1]))) as Map<String, dynamic>;

        // Maliciously modify claims to elevate role to admin and add admin scopes
        claimsJson['role'] = 'admin';
        claimsJson['scopes'] = ['qr:all', 'qr:admin', 'qr:generate'];

        final tamperedClaimsPart = base64UrlEncode(utf8.encode(jsonEncode(claimsJson)));
        // Retain original signature (which was over the user claims)
        final forgedToken = '${parts[0]}.$tamperedClaimsPart.${parts[2]}';

        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/generate',
          authHeader: 'Bearer $forgedToken',
          body: {'content': 'https://attacker.org'},
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('TOKEN_INVALID'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 6: Expired Tokens
    // -------------------------------------------------------------------------
    group('Vector 6: Expired Token Rejection', () {
      test('Token with past expiration timestamp is rejected with 401 TOKEN_EXPIRED', () async {
        final past = DateTime.now().subtract(const Duration(hours: 48));
        final expiredToken = EntitlementToken.issue(
          tokenId: 'jti-expired-001',
          subject: 'expired-admin@universalqr.org',
          role: UserRole.admin,
          scopes: ['qr:admin'],
          privateKey: server.config.privateKey,
          issuer: server.config.issuer,
          issuedAt: past,
          validity: const Duration(hours: 1), // expired 47 hours ago
        );

        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer ${expiredToken.toCompactToken()}',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('TOKEN_EXPIRED'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 7: Revoked Tokens
    // -------------------------------------------------------------------------
    group('Vector 7: Revoked Token Rejection', () {
      test('Revoked admin token receives 401 TOKEN_REVOKED', () async {
        final activeToken = EntitlementToken.issue(
          tokenId: 'jti-to-be-revoked',
          subject: 'compromised-admin@universalqr.org',
          role: UserRole.admin,
          scopes: ['qr:admin'],
          privateKey: server.config.privateKey,
          issuer: server.config.issuer,
        );

        // Before revocation, token works
        var resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer ${activeToken.toCompactToken()}',
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        // Revoke the token
        server.store.revokeToken('jti-to-be-revoked');

        // After revocation, token is rejected immediately
        resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer ${activeToken.toCompactToken()}',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('TOKEN_REVOKED'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 8: Rogue Key (Untrusted Keypair)
    // -------------------------------------------------------------------------
    group('Vector 8: Rogue Key Rejection', () {
      test('Token signed by untrusted attacker Ed25519 key fails key verification', () async {
        final rogueToken = EntitlementToken.issue(
          tokenId: 'jti-rogue-admin',
          subject: 'attacker@evil.org',
          role: UserRole.admin,
          scopes: ['qr:admin'],
          privateKey: attackerKeyPair.privateKey,
          issuer: server.config.issuer,
        );

        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer ${rogueToken.toCompactToken()}',
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('KEY_MISMATCH'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 9: Legitimate User Access Control (Role Barrier - 403 Forbidden)
    // -------------------------------------------------------------------------
    group('Vector 9: Valid User Role Barrier (403 Forbidden on Admin Routes)', () {
      for (final endpoint in adminEndpoints) {
        test('Valid user token receives 403 Forbidden on ${endpoint.method} ${endpoint.path}', () async {
          final resp = await sendRequest(
            method: endpoint.method,
            path: endpoint.path,
            authHeader: 'Bearer $userToken',
            body: endpoint.body,
          );
          expect(resp.statusCode, equals(HttpStatus.forbidden));

          final respBody = await utf8.decoder.bind(resp).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          expect(json['error'], equals('Forbidden'));
          expect(json['code'], equals('INSUFFICIENT_PERMISSIONS'));
          expect(json['message'], contains('Role admin is required'));
        });
      }

      test('User token attempting to revoke another users token receives 403 Forbidden', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/auth/revoke',
          authHeader: 'Bearer $userToken',
          body: {'tokenId': 'jti-other-user-token'},
        );
        expect(resp.statusCode, equals(HttpStatus.forbidden));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('INSUFFICIENT_PERMISSIONS'));
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 10: Authorized Admin Execution (200 OK on All Admin Routes)
    // -------------------------------------------------------------------------
    group('Vector 10: Authorized Admin Full Capability Execution', () {
      test('POST /api/v1/admin/qr/generate generates QR specification', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/generate',
          authHeader: 'Bearer $adminToken',
          body: {
            'content': 'https://universalqr.org/enterprise',
            'eccLevel': 'H',
            'shape': 'rounded',
            'foregroundColor': '#00F0FF',
            'backgroundColor': '#0A0E17',
          },
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['status'], equals('generated'));
        expect(json['content'], equals('https://universalqr.org/enterprise'));
        expect(json['eccLevel'], equals('H'));
        expect(json['matrixDimension'], equals(21));
      });

      test('POST /api/v1/admin/qr/batch generates batch specification', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/batch',
          authHeader: 'Bearer $adminToken',
          body: {
            'items': [
              {'id': 'qr-batch-1', 'content': 'https://item1.org', 'eccLevel': 'M'},
              {'id': 'qr-batch-2', 'content': 'https://item2.org', 'eccLevel': 'Q'},
              {'id': 'qr-batch-3', 'content': 'https://item3.org', 'eccLevel': 'H'},
            ],
          },
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['count'], equals(3));
        expect((json['items'] as List).length, equals(3));
      });

      test('POST /api/v1/admin/qr/sign creates verifiable TrustQR envelope', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/sign',
          authHeader: 'Bearer $adminToken',
          body: {
            'payload': 'https://universalqr.org/verified-contract-101',
            'expiresInSeconds': 86400,
          },
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['trustQrUri'], startsWith('trustqr://v1?'));
        expect(json['issuer'], equals(server.config.issuer));
        expect(json['keyId'], equals(server.config.publicKey.keyId));
        expect(json['signature'], isNotEmpty);

        // Verify the generated TrustQR envelope URI roundtrip
        final parsedEnvelope = TrustQrEnvelope.tryParse(json['trustQrUri'] as String);
        expect(parsedEnvelope, isNotNull);
        final verification = parsedEnvelope!.verify(publicKey: server.config.publicKey);
        expect(verification.isValid, isTrue);
        expect(verification.payload, equals('https://universalqr.org/verified-contract-101'));
      });

      test('GET and POST /api/v1/admin/templates manage branded templates', () async {
        // GET templates
        var resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/templates',
          authHeader: 'Bearer $adminToken',
        );
        expect(resp.statusCode, equals(HttpStatus.ok));
        var respBody = await utf8.decoder.bind(resp).join();
        var json = jsonDecode(respBody) as Map<String, dynamic>;
        final initialCount = (json['templates'] as List).length;
        expect(initialCount, greaterThanOrEqualTo(3));

        // POST template
        resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/templates',
          authHeader: 'Bearer $adminToken',
          body: {
            'name': 'Quantum Obsidian Matrix',
            'description': 'Glassmorphic obsidian with golden neon accents',
            'styleConfig': {
              'moduleShape': 'liquid',
              'foregroundColor': '#FFD700',
              'backgroundColor': '#0D1117',
            },
          },
        );
        expect(resp.statusCode, equals(HttpStatus.created));

        // Verify template was added
        resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/templates',
          authHeader: 'Bearer $adminToken',
        );
        respBody = await utf8.decoder.bind(resp).join();
        json = jsonDecode(respBody) as Map<String, dynamic>;
        expect((json['templates'] as List).length, equals(initialCount + 1));
      });

      test('GET /api/v1/admin/analytics returns system metrics', () async {
        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/analytics',
          authHeader: 'Bearer $adminToken',
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['totalGenerations'], greaterThanOrEqualTo(0));
        expect(json['uptimeSeconds'], isA<int>());
      });

      test('GET /api/v1/admin/audit returns administrative audit trail', () async {
        final resp = await sendRequest(
          method: 'GET',
          path: '/api/v1/admin/audit',
          authHeader: 'Bearer $adminToken',
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['auditLogs'], isA<List>());
        expect((json['auditLogs'] as List), isNotEmpty);
      });

      test('Admin can revoke any arbitrary token ID', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/auth/revoke',
          authHeader: 'Bearer $adminToken',
          body: {'tokenId': 'jti-compromised-user-token'},
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['revoked'], isTrue);
        expect(json['tokenId'], equals('jti-compromised-user-token'));
        expect(server.store.isTokenRevoked('jti-compromised-user-token'), isTrue);
      });

      test('User can revoke their own token when no tokenId specified in body', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/auth/revoke',
          authHeader: 'Bearer $userToken',
          body: {},
        );
        expect(resp.statusCode, equals(HttpStatus.ok));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['revoked'], isTrue);
        expect(json['tokenId'], equals('jti-legit-user-001'));
        expect(server.store.isTokenRevoked('jti-legit-user-001'), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // VECTOR 11: Input Validation & Edge Case Robustness
    // -------------------------------------------------------------------------
    group('Vector 11: Input Validation & Bad Request Handling', () {
      test('Empty content in generate returns 400 Bad Request', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/generate',
          authHeader: 'Bearer $adminToken',
          body: {'content': '   '},
        );
        expect(resp.statusCode, equals(HttpStatus.badRequest));

        final respBody = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        expect(json['code'], equals('BAD_REQUEST'));
      });

      test('Empty items list in batch returns 400 Bad Request', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/batch',
          authHeader: 'Bearer $adminToken',
          body: {'items': []},
        );
        expect(resp.statusCode, equals(HttpStatus.badRequest));
      });

      test('Empty payload in sign returns 400 Bad Request', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/sign',
          authHeader: 'Bearer $adminToken',
          body: {'payload': ''},
        );
        expect(resp.statusCode, equals(HttpStatus.badRequest));
      });

      test('Empty name in template creation returns 400 Bad Request', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/templates',
          authHeader: 'Bearer $adminToken',
          body: {'name': ' '},
        );
        expect(resp.statusCode, equals(HttpStatus.badRequest));
      });

      test('Invalid JSON in body returns 400 Bad Request', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/admin/qr/generate',
          authHeader: 'Bearer $adminToken',
          rawBody: '{ malformed json: true, ',
        );
        expect(resp.statusCode, equals(HttpStatus.badRequest));
      });

      test('Telemetry without auth returns 401 Unauthorized', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/telemetry/scan',
          authHeader: null,
          body: {'format': 'qr'},
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));
      });

      test('Revoke without auth returns 401 Unauthorized', () async {
        final resp = await sendRequest(
          method: 'POST',
          path: '/api/v1/auth/revoke',
          authHeader: null,
          body: {'tokenId': 'jti-test'},
        );
        expect(resp.statusCode, equals(HttpStatus.unauthorized));
      });
    });
  });
}
