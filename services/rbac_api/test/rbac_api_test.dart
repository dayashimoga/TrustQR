import 'dart:io';
import 'package:test/test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:rbac_api/rbac_api.dart';

void main() {
  group('RBAC API Server Tests', () {
    late RbacServer server;
    late int port;

    setUp(() async {
      server = await RbacServer.bind(port: 0);
      port = server.port;
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('Health endpoint returns 200 OK', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/health'));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));
    });

    test('Admin endpoint rejects requests without admin credentials with 403 Forbidden', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/analytics'));
      req.headers.set('X-User-Role', 'user');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.forbidden));
    });

    test('Admin endpoint allows requests with valid admin credentials', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/admin/analytics'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer mock-valid-admin-token');
      req.headers.set('X-User-Role', 'admin');
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.ok));
    });

    test('RbacClaims serialization and role hierarchy', () {
      final claims = RbacClaims(
        subject: 'admin@universalqr.org',
        role: UserRole.admin,
        scopes: ['qr:all'],
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(claims.isAdmin, isTrue);
      expect(claims.hasScope('qr:generate'), isTrue);

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
  });
}
