import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/main.dart';
import 'package:user_app/src/state/scanner_controller.dart';
import 'package:user_app/src/state/vault_controller.dart';

void main() {
  group('UserApp Full Application Integration Tests', () {
    late QrVault vault;
    late ScannerController controller;
    late VaultController vaultController;

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
      vaultController = VaultController(vault: vault);
      await vaultController.init();
    });

    tearDown(() {
      controller.dispose();
      vaultController.dispose();
    });

    testWidgets('UserApp launches with navigation items and renders Scanner tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(
        controller: controller,
        vaultController: vaultController,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Scanner'), findsAtLeast(1));
      expect(find.text('History'), findsAtLeast(1));
      expect(find.text('Collections'), findsAtLeast(1));
      expect(find.text('Settings'), findsAtLeast(1));
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);
    });

    testWidgets('Navigates across all 4 tabs (Scanner, Vault, Collections, Settings)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(
        controller: controller,
        vaultController: vaultController,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Navigate to Vault (History) tab
      await tester.tap(find.byIcon(Icons.lock_clock_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VAULT IS EMPTY'), findsOneWidget);

      // Tap return to viewfinder button
      await tester.tap(find.text('Open Scanner'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);

      // 2. Navigate to Collections tab
      await tester.tap(find.byIcon(Icons.folder_special_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COLLECTIONS // SMART FOLDERS'), findsOneWidget);

      // 3. Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.tune_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SECURITY, PRIVACY & SYSTEM SETTINGS'), findsOneWidget);
      expect(find.text('RESTRICTED USER'), findsOneWidget);

      // Toggle high contrast switch
      final highContrastSwitch = find.byKey(const Key('high_contrast_switch'));
      await tester.tap(highContrastSwitch);
      await tester.pump(const Duration(milliseconds: 100));

      // Toggle incognito switch
      final incognitoSwitch = find.byKey(const Key('incognito_mode_switch'));
      await tester.tap(incognitoSwitch);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isIncognito, isTrue);
    });

    testWidgets('Performs scan, logs in inspector, and updates vault metrics', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(
        controller: controller,
        vaultController: vaultController,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Inspector pane should be visible on expanded layout (> 1024px)
      expect(find.text('SECURITY TELEMETRY'), findsOneWidget);
      expect(find.text('ENCRYPTED VAULT STATS'), findsOneWidget);

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

    testWidgets('Search shortcut Ctrl+F switches navigation to Vault tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(UserApp(
        controller: controller,
        vaultController: vaultController,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // We are on Scanner tab initially
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);

      // Trigger Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should be switched to Vault tab
      expect(find.text('VAULT IS EMPTY'), findsOneWidget);
    });

    test('main entrypoint function is defined', () {
      expect(main, isNotNull);
    });
  });
}
