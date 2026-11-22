import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/admin_nav_controller.dart';
import 'package:admin_app/src/state/analytics_controller.dart';
import 'package:admin_app/src/state/auth_controller.dart';
import 'package:admin_app/src/state/batch_controller.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/views/admin_shell_view.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('AdminShellView Widget Tests', () {
    late AuthController authController;
    late AdminNavController navController;
    late StudioController studioController;
    late BatchController batchController;
    late AnalyticsController analyticsController;

    setUp(() {
      authController = AuthController();
      navController = AdminNavController();
      studioController = StudioController();
      batchController = BatchController();
      analyticsController = AnalyticsController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: AdminShellView(
          authController: authController,
          navController: navController,
          studioController: studioController,
          batchController: batchController,
          analyticsController: analyticsController,
        ),
      );
    }

    testWidgets('displays header with role, subject, and sign out button', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell_role_badge')), findsOneWidget);
      expect(find.byKey(const Key('shell_subject_text')), findsOneWidget);
      expect(find.byKey(const Key('shell_sign_out_btn')), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('admin@enterprise.corp'), findsOneWidget);
    });

    testWidgets('switches between all 5 workspaces via navigation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Initial workspace is Studio
      expect(navController.currentPane, equals(AdminPane.studio));

      // 2. Switch to Batch Generator
      await tester.tap(find.text('Batch Generator'));
      await tester.pumpAndSettle();
      expect(navController.currentPane, equals(AdminPane.batch));
      expect(find.text('BATCH GENERATOR // ZIP EXPORTER'), findsOneWidget);

      // 3. Switch to Fleet Analytics
      await tester.tap(find.text('Fleet Analytics'));
      await tester.pumpAndSettle();
      expect(navController.currentPane, equals(AdminPane.analytics));
      expect(find.text('FLEET TELEMETRY & THREAT INTELLIGENCE'), findsOneWidget);

      // 4. Switch to Audit Trail
      await tester.tap(find.text('Audit Trail'));
      await tester.pumpAndSettle();
      expect(navController.currentPane, equals(AdminPane.audit));
      expect(find.text('CRYPTOGRAPHIC AUDIT TRAIL'), findsOneWidget);

      // 5. Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(navController.currentPane, equals(AdminPane.settings));
      expect(find.text('SETTINGS & SECURITY GOVERNANCE'), findsOneWidget);
    });

    testWidgets('sign out button signs out operator', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell_sign_out_btn')));
      await tester.pumpAndSettle();

      expect(authController.isAuthenticated, isFalse);
    });
  });
}
