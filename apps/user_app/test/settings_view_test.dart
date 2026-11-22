import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:user_app/src/state/scanner_controller.dart';
import 'package:user_app/src/state/vault_controller.dart';
import 'package:user_app/src/views/settings_view.dart';

void main() {
  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late ScannerController scannerController;
  late VaultController vaultController;
  bool isHighContrast = false;

  setUp(() async {
    integrityKey = CryptoKeyPair.generateHmacKey().privateKey;
    vault = QrVault.inMemory(integrityKey: integrityKey);
    await vault.init();

    scannerController = ScannerController();
    vaultController = VaultController(vault: vault);
    await vaultController.init();
    isHighContrast = false;
  });

  tearDown(() {
    scannerController.dispose();
    vaultController.dispose();
  });

  Widget buildTestWidget({ValueChanged<bool>? onToggleHighContrast}) {
    return MaterialApp(
      theme: CyberTheme.dark(),
      supportedLocales: CyberLocalizations.supportedLocales,
      localizationsDelegates: const [
        CyberLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SettingsView(
          scannerController: scannerController,
          vaultController: vaultController,
          isHighContrast: isHighContrast,
          onToggleHighContrast: onToggleHighContrast ?? (val) => isHighContrast = val,
        ),
      ),
    );
  }

  group('SettingsView - Controls & Cryptographic Operations', () {
    testWidgets('renders all 4 setting cards and entitlement status', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SECURITY, PRIVACY & SYSTEM SETTINGS'), findsOneWidget);
      expect(find.text('ACCESSIBILITY & APPEARANCE'), findsOneWidget);
      expect(find.text('PRIVACY & VAULT RETENTION'), findsOneWidget);
      expect(find.text('CRYPTOGRAPHIC BACKUP & PORTABILITY'), findsOneWidget);
      expect(find.text('SECURITY POSTURE & RBAC ENTITLEMENT'), findsOneWidget);
      expect(find.text('RESTRICTED USER'), findsOneWidget);
      expect(find.text('VERIFIED // ZERO GENERATOR'), findsOneWidget);
    });

    testWidgets('toggles high contrast mode switch', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool toggled = false;
      await tester.pumpWidget(buildTestWidget(
        onToggleHighContrast: (val) => toggled = val,
      ));
      await tester.pumpAndSettle();

      final switchWidget = find.byKey(const Key('high_contrast_switch'));
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('toggles privacy incognito mode', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(scannerController.isIncognito, isFalse);
      final incognitoSwitch = find.byKey(const Key('incognito_mode_switch'));
      await tester.tap(incognitoSwitch);
      await tester.pumpAndSettle();

      expect(scannerController.isIncognito, isTrue);
    });

    testWidgets('updates auto-purge retention and keep favorites policy', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final dropdown = find.byKey(const Key('auto_purge_dropdown'));
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 Days').last);
      await tester.pumpAndSettle();

      expect(vaultController.privacyPolicy.autoPurgeHistoryDays, 30);

      // Toggle preserve favorites
      final keepFavSwitch = find.byKey(const Key('keep_favorites_switch'));
      await tester.tap(keepFavSwitch);
      await tester.pumpAndSettle();

      expect(vaultController.privacyPolicy.keepFavoritesOnPurge, isFalse);
    });

    testWidgets('triggers purge expired scans now', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final purgeBtn = find.byKey(const Key('purge_now_btn'));
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Purge completed:'), findsOneWidget);
    });

    testWidgets('clears all scan history with confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await vault.recordItem(
        rawContent: 'test scan to clear',
        payloadType: QrPayloadType.plainText,
      );
      await vaultController.refresh();
      expect(vaultController.items.length, 1);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final clearHistoryBtn = find.byKey(const Key('clear_history_btn'));
      await tester.tap(clearHistoryBtn);
      await tester.pumpAndSettle();

      expect(find.text('CLEAR ALL SCAN HISTORY'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('confirm_clear_all_btn'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(vaultController.items, isEmpty);
      expect(find.textContaining('Cleared 1 scan record(s)'), findsOneWidget);
    });

    testWidgets('exports vault and copies backup JSON', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await vault.recordItem(
        rawContent: 'backup-payload',
        payloadType: QrPayloadType.plainText,
      );
      await vaultController.refresh();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final exportBtn = find.byKey(const Key('export_vault_btn'));
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.text('VAULT BACKUP EXPORT // JSON'), findsOneWidget);

      final copyBtn = find.byKey(const Key('copy_settings_export_btn'));
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Backup JSON copied to clipboard.'), findsOneWidget);
    });

    testWidgets('restores vault from valid JSON payload with HMAC verification', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final exportedJson = await vaultController.exportSelectedOrAllToJson();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final importBtn = find.byKey(const Key('import_vault_btn'));
      await tester.tap(importBtn);
      await tester.pumpAndSettle();

      expect(find.text('RESTORE VAULT // JSON IMPORT'), findsOneWidget);

      final input = find.byKey(const Key('import_json_input'));
      await tester.enterText(input, exportedJson);

      final overwriteCheckbox = find.byKey(const Key('import_overwrite_checkbox'));
      await tester.tap(overwriteCheckbox);

      final confirmBtn = find.byKey(const Key('confirm_import_btn'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Import complete:'), findsOneWidget);
    });
  });
}
