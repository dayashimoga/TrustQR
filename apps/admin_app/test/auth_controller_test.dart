import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/auth_controller.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('AuthController Unit Tests', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('initializes with valid signed admin session', () {
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isTrue);
      expect(controller.role, equals(UserRole.admin));
      expect(controller.subject, equals('admin@enterprise.corp'));
      expect(controller.activeToken, isNotNull);
      expect(controller.rawTokenString, isNotNull);
      expect(controller.denialReason, isNull);
      expect(controller.scopes, contains('generate'));
      expect(controller.scopes, contains('batch'));
      expect(controller.keyId, equals(AuthController.defaultAdminKeyId));
    });

    test('signInAsAdmin issues authentic admin token and updates state', () {
      controller.signOut();
      expect(controller.isAuthenticated, isFalse);

      controller.signInAsAdmin(subject: 'cso@enterprise.corp');
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isTrue);
      expect(controller.subject, equals('cso@enterprise.corp'));
      expect(controller.role, equals(UserRole.admin));
      expect(controller.denialReason, isNull);
    });

    test('signInAsUser signs in with user role and denies admin access', () {
      controller.signInAsUser(subject: 'contractor@external.org');
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isAdmin, isFalse);
      expect(controller.role, equals(UserRole.user));
      expect(controller.subject, equals('contractor@external.org'));
      expect(controller.denialReason, contains("Access Denied: Subject 'contractor@external.org' holds role 'user'"));
    });

    test('authenticateWithToken validates valid compact token', () {
      final validToken = controller.rawTokenString!;
      controller.signOut();

      final success = controller.authenticateWithToken(validToken);
      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isTrue);
      expect(controller.denialReason, isNull);
    });

    test('authenticateWithToken rejects empty, malformed, or tampered token', () {
      expect(controller.authenticateWithToken('   '), isFalse);
      expect(controller.denialReason, contains('Token cannot be empty'));

      expect(controller.authenticateWithToken('not.a.valid.jwt.string'), isFalse);
      expect(controller.denialReason, contains('Invalid token format'));

      // Tampered token payload
      final parts = controller.rawTokenString!.split('.');
      final tampered = '${parts[0]}.${parts[1]}xyz.${parts[2]}';
      expect(controller.authenticateWithToken(tampered), isFalse);
      expect(controller.denialReason, isNotNull);
    });

    test('authenticateWithToken rejects valid user token for admin access', () {
      controller.signInAsUser(subject: 'regular_user@company.com');
      final userToken = controller.rawTokenString!;
      controller.signOut();

      final result = controller.authenticateWithToken(userToken);
      expect(result, isFalse);
      expect(controller.denialReason, contains("Access Denied: Role 'user' lacks administrator privileges"));
    });

    test('simulateExpiredToken simulates expiration and denies access', () {
      controller.simulateExpiredToken();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isAdmin, isFalse);
      expect(controller.denialReason, contains('Entitlement token has expired'));
    });

    test('signOut clears credentials and sets unauthenticated guest state', () {
      controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isAdmin, isFalse);
      expect(controller.activeToken, isNull);
      expect(controller.rawTokenString, isNull);
      expect(controller.subject, equals('anonymous'));
      expect(controller.scopes, isEmpty);
      expect(controller.denialReason, contains('Signed out'));
    });
  });
}
