import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:user_app/src/state/vault_controller.dart';
import 'package:user_app/src/views/vault_view.dart';

void main() {
  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late VaultController controller;
  late QrVaultItem item1;
  late QrVaultItem item3;

  setUp(() async {
    integrityKey = CryptoKeyPair.generateHmacKey().privateKey;
    vault = QrVault.inMemory(integrityKey: integrityKey);
    await vault.init();
    controller = VaultController(vault: vault);
    await controller.init();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> populateVault() async {
    item1 = await vault.recordItem(
      rawContent: 'https://alpha.example.com',
      payloadType: QrPayloadType.url,
      threatLevel: SecurityThreatLevel.safe,
      safetyScore: 95,
      title: 'Alpha Portal',
      tags: ['corp'],
      isTrustQr: true,
      trustQrIssuer: 'GovTrust',
    );
    await vault.recordItem(
      rawContent: 'WIFI:S:Guest;T:WPA;P:secret;;',
      payloadType: QrPayloadType.wifi,
      threatLevel: SecurityThreatLevel.safe,
      safetyScore: 90,
      title: 'Guest Wi-Fi',
      isFavorite: true,
      tags: ['office'],
    );
    item3 = await vault.recordItem(
      rawContent: 'http://malicious-phish.biz',
      payloadType: QrPayloadType.url,
      threatLevel: SecurityThreatLevel.caution,
      safetyScore: 45,
      title: 'Phishing Alert',
      tags: ['threat'],
    );
    await controller.refresh();
  }

  Widget buildTestWidget({VoidCallback? onNavigateToScanner}) {
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
        body: VaultView(
          controller: controller,
          onNavigateToScanner: onNavigateToScanner,
        ),
      ),
    );
  }

  group('VaultView - Empty & Populated States', () {
    testWidgets('renders empty state when vault has no items', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool openedScanner = false;
      await tester.pumpWidget(buildTestWidget(
        onNavigateToScanner: () => openedScanner = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('VAULT IS EMPTY'), findsOneWidget);
      final openScannerBtn = find.byKey(const Key('empty_open_scanner_btn'));
      expect(openScannerBtn, findsOneWidget);
      await tester.tap(openScannerBtn);
      expect(openedScanner, isTrue);
    });

    testWidgets('renders populated items list and verifies item cards', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vault_items_list')), findsOneWidget);
      expect(find.text('Alpha Portal'), findsOneWidget);
      expect(find.text('Guest Wi-Fi'), findsOneWidget);
      expect(find.text('Phishing Alert'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('searches vault and clears search', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('vault_search_field'));
      await tester.enterText(searchField, 'Guest');
      await tester.pumpAndSettle();

      expect(find.text('Guest Wi-Fi'), findsOneWidget);
      expect(find.text('Alpha Portal'), findsNothing);

      // Clear search
      final clearBtn = find.byKey(const Key('clear_search_btn'));
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Portal'), findsOneWidget);
      expect(find.text('Guest Wi-Fi'), findsOneWidget);
    });

    testWidgets('empty state with active filter allows clearing filters', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('vault_search_field'));
      await tester.enterText(searchField, 'Nonexistent Query Token');
      await tester.pumpAndSettle();

      expect(find.text('NO MATCHING RECORDS'), findsOneWidget);
      final clearFiltersBtn = find.byKey(const Key('empty_clear_filters_btn'));
      await tester.tap(clearFiltersBtn);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Portal'), findsOneWidget);
    });
  });

  group('VaultView - Filters, Sort, Tags & Selection', () {
    testWidgets('filters by quick filter chips (Favorites, Safe, Caution)', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Favorites chip
      await tester.tap(find.text('Favorites (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Guest Wi-Fi'), findsOneWidget);
      expect(find.text('Alpha Portal'), findsNothing);

      // Tap Safe chip
      await tester.tap(find.text('Safe'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha Portal'), findsOneWidget);
      expect(find.text('Phishing Alert'), findsNothing);

      // Tap All chip
      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha Portal'), findsOneWidget);
      expect(find.text('Guest Wi-Fi'), findsOneWidget);
      expect(find.text('Phishing Alert'), findsOneWidget);
    });

    testWidgets('filters by tag chips', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find and tap 'office' tag chip
      final officeChip = find.widgetWithText(FilterChip, 'office');
      expect(officeChip, findsOneWidget);
      await tester.tap(officeChip);
      await tester.pumpAndSettle();

      expect(find.text('Guest Wi-Fi'), findsOneWidget);
      expect(find.text('Alpha Portal'), findsNothing);
    });

    testWidgets('changes sorting via dropdown', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sortDropdown = find.byKey(const Key('vault_sort_dropdown'));
      await tester.tap(sortDropdown);
      await tester.pumpAndSettle();

      // Select 'Safety Score (High)'
      await tester.tap(find.text('Safety Score (High)').last);
      await tester.pumpAndSettle();

      expect(controller.filter.sortBy, QrVaultSortBy.safetyScoreDesc);
    });

    testWidgets('multi-selection, batch select all, deselect, export and delete', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select item1 via checkbox
      final checkbox1 = find.byKey(Key('checkbox_${item1.id}'));
      await tester.tap(checkbox1);
      await tester.pumpAndSettle();

      expect(find.text('1 RECORD(S) SELECTED'), findsOneWidget);

      // Tap Select All
      final selectAllBtn = find.byKey(const Key('batch_select_all_btn'));
      await tester.tap(selectAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('3 RECORD(S) SELECTED'), findsOneWidget);

      // Tap Export Selected
      final exportBtn = find.byKey(const Key('batch_export_btn'));
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.text('VAULT EXPORT // JSON'), findsOneWidget);
      final copyExportBtn = find.byKey(const Key('copy_export_json_btn'));
      await tester.tap(copyExportBtn);
      await tester.pumpAndSettle();

      // Tap Deselect
      final deselectBtn = find.byKey(const Key('batch_clear_selection_btn'));
      await tester.tap(deselectBtn);
      await tester.pumpAndSettle();

      expect(find.text('3 RECORD(S) SELECTED'), findsNothing);

      // Select item3 and delete
      final checkbox3 = find.byKey(Key('checkbox_${item3.id}'));
      await tester.tap(checkbox3);
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('batch_delete_btn'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Phishing Alert'), findsNothing);
      expect(controller.items.length, 2);
    });

    testWidgets('tapping item opens detail sheet, tapping favorite toggles immediately', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Toggle favorite on item1
      final favBtn1 = find.byKey(Key('item_fav_${item1.id}'));
      await tester.tap(favBtn1);
      await tester.pumpAndSettle();

      expect(controller.items.firstWhere((i) => i.id == item1.id).isFavorite, isTrue);

      // Tap card to open detail
      final itemCard = find.byKey(Key('vault_item_${item1.id}'));
      await tester.tap(itemCard);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('integrity_banner')), findsOneWidget);
    });

    testWidgets('refresh button triggers vault refresh', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await populateVault();
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final refreshBtn = find.byKey(const Key('refresh_vault_btn'));
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(controller.items.length, 3);
    });
  });
}
