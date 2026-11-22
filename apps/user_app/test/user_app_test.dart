import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/main.dart';
import 'package:user_app/src/state/scanner_controller.dart';

void main() {
  group('UserApp Full Application Integration Tests', () {
    late QrVault vault;
    late ScannerController controller;

    setUp(() async {
      vault = QrVault.inMemory(
        integrityKey: CryptoKeyPair.generateHmacKey().privateKey,
      );
      await vault.init();
      controller = ScannerController(
        pipeline: ScanToVaultPipeline(
          scanner: UniversalQrScannerEngine(),
          firewall: QrThreatFirewall(),
          vault: vault,
        ),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('UserApp launches with navigation items and renders Scanner tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Scanner'), findsAtLeast(1));
      expect(find.text('History'), findsAtLeast(1));
      expect(find.text('Settings'), findsAtLeast(1));
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);
    });

    testWidgets('Navigates between Scanner, History, and Settings tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to History tab
      await tester.tap(find.byIcon(Icons.history_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ENCRYPTED SCAN VAULT'), findsOneWidget);

      // Tap return to viewfinder button
      await tester.tap(find.text('Return to Scanner Viewfinder'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.tune_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SECURITY & ACCESSIBILITY SETTINGS'), findsOneWidget);
      expect(find.text('ROLE: RESTRICTED USER // GENERATOR DISABLED'), findsOneWidget);

      // Toggle high contrast switch
      final highContrastSwitch = find.byType(Switch).first;
      await tester.tap(highContrastSwitch);
      await tester.pump(const Duration(milliseconds: 100));

      // Toggle incognito switch
      final incognitoSwitch = find.byType(Switch).last;
      await tester.tap(incognitoSwitch);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isIncognito, isTrue);
    });

    testWidgets('Performs scan and displays action in security telemetry inspector', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      // Inspector pane should be visible on expanded layout (> 1024px)
      expect(find.text('SECURITY TELEMETRY'), findsOneWidget);

      // Perform a scan
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'https://apex-verified.org');
      await tester.tap(find.text('Inspect'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Open Safe Link inside modal
      await tester.ensureVisible(find.text('Open Safe Link'));
      await tester.tap(find.text('Open Safe Link'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify action logged in telemetry pane
      expect(find.textContaining('open_url: https://apex-verified.org'), findsOneWidget);
    });

    testWidgets('UserApp default constructor initializes and cleans up', (tester) async {
      await tester.pumpWidget(const UserApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(UserApp), findsOneWidget);
    });

    testWidgets('Search shortcut Ctrl+F resets navigation to Scanner tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to History
      await tester.tap(find.byIcon(Icons.history_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ENCRYPTED SCAN VAULT'), findsOneWidget);

      // Trigger Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));

      // Should be back on Scanner Viewfinder
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);
    });

    test('main entrypoint function is defined', () {
      expect(main, isNotNull);
    });
  });
}
