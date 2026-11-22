import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/auth_controller.dart';
import 'package:admin_app/src/views/admin_settings_view.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('AdminSettingsView Widget Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: Scaffold(
          body: AdminSettingsView(authController: authController),
        ),
      );
    }

    testWidgets('renders operator profile, trust anchors, and security posture cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS & SECURITY GOVERNANCE'), findsOneWidget);
      expect(find.text('ACTIVE OPERATOR ENTITLEMENT'), findsOneWidget);
      expect(find.text('admin@enterprise.corp'), findsOneWidget);
      expect(find.text('INSTITUTIONAL TRUST ANCHORS'), findsOneWidget);
      expect(find.text('MONOREPO SECURITY & ISOLATION POSTURE'), findsOneWidget);
      expect(find.text('Compile-Time Binary Isolation'), findsOneWidget);
      expect(find.text('Zero-Trust QR Threat Firewall'), findsOneWidget);
      expect(find.text('Server-Side RBAC Guard'), findsOneWidget);
      expect(find.byKey(const Key('active_token_text')), findsOneWidget);
    });

    testWidgets('pen-test controls simulate user role, expired token, and sign out', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Simulate User Role
      await tester.tap(find.byKey(const Key('simulate_user_role_btn')));
      await tester.pumpAndSettle();
      expect(authController.role, equals(UserRole.user));
      expect(authController.isAdmin, isFalse);

      // 2. Simulate Expired Token
      await tester.tap(find.byKey(const Key('simulate_expired_token_btn')));
      await tester.pumpAndSettle();
      expect(authController.isAuthenticated, isFalse);
      expect(authController.denialReason, contains('expired'));

      // 3. Sign Out
      await tester.tap(find.byKey(const Key('sign_out_btn')));
      await tester.pumpAndSettle();
      expect(authController.isAuthenticated, isFalse);
      expect(authController.subject, equals('anonymous'));
    });
  });
}
