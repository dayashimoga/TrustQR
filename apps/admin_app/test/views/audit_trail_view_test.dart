import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/analytics_controller.dart';
import 'package:admin_app/src/views/audit_trail_view.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('AuditTrailView Widget Tests', () {
    late AnalyticsController controller;

    setUp(() {
      controller = AnalyticsController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: Scaffold(
          body: AuditTrailView(analyticsController: controller),
        ),
      );
    }

    testWidgets('renders header, verified status banner, and audit entries', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CRYPTOGRAPHIC AUDIT TRAIL'), findsOneWidget);
      expect(find.byKey(const Key('verify_audit_ledger_btn')), findsOneWidget);
      expect(find.byKey(const Key('audit_integrity_status_text')), findsOneWidget);
      expect(find.textContaining('ALL 3 AUDIT LOG ENTRIES VERIFIED'), findsOneWidget);
      expect(find.text('SYSTEM_BOOT'), findsOneWidget);
      expect(find.text('ENROLL_AUTHORITY_KEY'), findsOneWidget);
      expect(find.text('REVOKE_DEVICE'), findsOneWidget);
    });

    testWidgets('verify all signatures button triggers audit verification', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('verify_audit_ledger_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('CRYPTOGRAPHICALLY SOUND'), findsOneWidget);
    });

    testWidgets('filter input filters logs by action or actor', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Filter by 'REVOKE'
      await tester.enterText(
        find.byKey(const Key('audit_filter_input_field')),
        'REVOKE',
      );
      await tester.pumpAndSettle();

      expect(find.text('REVOKE_DEVICE'), findsOneWidget);
      expect(find.text('SYSTEM_BOOT'), findsNothing);

      // Filter with no match
      await tester.enterText(
        find.byKey(const Key('audit_filter_input_field')),
        'NON_EXISTENT_ACTION_99',
      );
      await tester.pumpAndSettle();

      expect(find.text('No audit logs match the current filter criteria.'), findsOneWidget);
    });
  });
}
