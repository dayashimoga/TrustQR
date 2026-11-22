import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/views/studio_workspace_view.dart';

void main() {
  group('StudioWorkspaceView Widget Tests', () {
    late StudioController controller;

    setUp(() {
      controller = StudioController();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: child,
      );
    }

    testWidgets('renders wide desktop layout with all panels', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(StudioWorkspaceView(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Universal QR Studio & Fleet Analytics [Admin]'), findsOneWidget);
      expect(find.text('Artistic QR Generator Studio'), findsOneWidget);
      expect(find.text('URL'), findsWidgets);

      // Verify presence of all major subcomponents
      expect(find.text('Live QR Matrix Preview'), findsOneWidget);
      expect(find.text('QR Payload & Format'), findsOneWidget);
      expect(find.text('Artistic Customization Studio'), findsOneWidget);
      expect(find.text('Scannability Simulator'), findsOneWidget);
      expect(find.text('TrustQR Cryptographic Signer'), findsOneWidget);

      // Test fleet telemetry action button
      await tester.tap(find.byKey(const Key('fleet_telemetry_appbar_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Generations:'), findsOneWidget);
    });

    testWidgets('renders compact mobile layout and updates TrustQR badge', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.setTrustQrEnabled(true);

      await tester.pumpWidget(createTestApp(StudioWorkspaceView(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('ED25519 VERIFIED'), findsOneWidget);
      expect(find.text('Live QR Matrix Preview'), findsOneWidget);
    });
  });
}
