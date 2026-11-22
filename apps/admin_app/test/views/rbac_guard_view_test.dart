import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/auth_controller.dart';
import 'package:admin_app/src/views/rbac_guard_view.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('RbacGuardView Widget Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: RbacGuardView(
          authController: authController,
          child: const Scaffold(
            body: Center(
              child: Text('PROTECTED ADMIN WORKSPACE', key: Key('protected_content')),
            ),
          ),
        ),
      );
    }

    testWidgets('renders child workspace when authenticated as administrator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protected_content')), findsOneWidget);
      expect(find.text('SECURITY ACCESS RESTRICTED'), findsNothing);
    });

    testWidgets('renders AccessDeniedView when role is restricted user', (tester) async {
      authController.signInAsUser(subject: 'test_user@domain.com');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protected_content')), findsNothing);
      expect(find.text('SECURITY ACCESS RESTRICTED'), findsOneWidget);
      expect(find.byKey(const Key('rbac_denial_reason_text')), findsOneWidget);
      expect(find.textContaining("holds role 'user'"), findsOneWidget);
    });

    testWidgets('sign in as admin button authenticates and reveals child', (tester) async {
      authController.signInAsUser();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign_in_admin_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sign_in_admin_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protected_content')), findsOneWidget);
      expect(find.text('SECURITY ACCESS RESTRICTED'), findsNothing);
    });

    testWidgets('simulate restricted user button denies access', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protected_content')), findsOneWidget);

      authController.signOut();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign_in_user_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sign_in_user_btn')));
      await tester.pumpAndSettle();

      expect(find.text('SECURITY ACCESS RESTRICTED'), findsOneWidget);
      expect(find.byKey(const Key('protected_content')), findsNothing);
    });

    testWidgets('validates custom token via text input field', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final validAdminToken = authController.rawTokenString!;
      authController.signOut();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('rbac_token_input_field')),
        validAdminToken,
      );
      await tester.tap(find.byKey(const Key('validate_token_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protected_content')), findsOneWidget);
    });
  });
}
