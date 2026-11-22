import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:user_app/src/state/vault_controller.dart';
import 'package:user_app/src/widgets/vault_item_detail_modal.dart';

void main() {
  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late VaultController controller;
  late QrVaultItem testItem;
  late QrCollection testCollection;

  setUp(() async {
    integrityKey = CryptoKeyPair.generateHmacKey().privateKey;
    vault = QrVault.inMemory(integrityKey: integrityKey);
    await vault.init();
    controller = VaultController(vault: vault);
    await controller.init();

    testCollection = await controller.createCollection(
      name: 'Test Category',
      colorHex: '#00F0FF',
    );

    testItem = await vault.recordItem(
      rawContent: 'https://security.example.org/verify?token=xyz',
      payloadType: QrPayloadType.url,
      threatLevel: SecurityThreatLevel.safe,
      safetyScore: 94,
      title: 'Security Verification Portal',
      notes: 'Initial test notes',
      tags: ['security', 'portal'],
      isTrustQr: true,
      trustQrIssuer: 'Institutional Authority',
      collectionId: testCollection.id,
    );
    await controller.refresh();
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({required QrVaultItem item, VoidCallback? onDismiss}) {
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
        body: VaultItemDetailModal(
          item: item,
          controller: controller,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  group('VaultItemDetailModal - Verification & Details Display', () {
    testWidgets('renders cryptographic HMAC intact banner, score gauge, format and details', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('integrity_banner')), findsOneWidget);
      expect(find.text('HMAC-SHA256 INTEGRITY INTACT // UNTAMPERED'), findsOneWidget);
      expect(find.text('FORMAT: URL'), findsOneWidget);
      expect(find.text('https://security.example.org/verify?token=xyz'), findsOneWidget);
      expect(find.text('Institutional Authority'), findsOneWidget);
      expect(find.text('security'), findsOneWidget);
      expect(find.text('portal'), findsOneWidget);
      expect(find.text('Initial test notes'), findsOneWidget);
    });

    testWidgets('renders tampered security alert banner when signature is invalidated', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create tampered item with fake signature
      final tamperedItem = QrVaultItem(
        id: testItem.id,
        rawContent: 'https://tampered-malicious.org',
        payloadType: testItem.payloadType,
        threatLevel: SecurityThreatLevel.critical,
        safetyScore: 10,
        origin: testItem.origin,
        createdAt: testItem.createdAt,
        integrityHash: 'invalid_tampered_base64_signature==',
      );

      await tester.pumpWidget(buildTestWidget(item: tamperedItem));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('integrity_banner')), findsOneWidget);
      expect(find.text('SECURITY ALERT: TAMPERED RECORD // INVALID SIGNATURE'), findsOneWidget);
    });

    testWidgets('copies raw payload to clipboard and updates label', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('copy_payload_btn'));
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();

      expect(find.text('COPIED'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('toggles favorite status', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      final favBtn = find.byKey(const Key('favorite_toggle_btn'));
      await tester.tap(favBtn);
      await tester.pumpAndSettle();

      expect(controller.items.first.isFavorite, isTrue);

      await tester.tap(favBtn);
      await tester.pumpAndSettle();
      expect(controller.items.first.isFavorite, isFalse);
    });

    testWidgets('adds and removes tags', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      final tagInput = find.byKey(const Key('add_tag_input'));
      await tester.ensureVisible(tagInput);
      await tester.enterText(tagInput, 'verified');

      final addTagBtn = find.byKey(const Key('add_tag_btn'));
      await tester.tap(addTagBtn);
      await tester.pumpAndSettle();

      expect(find.text('verified'), findsOneWidget);
      expect(controller.items.first.tags, contains('verified'));

      // Remove a tag
      final closeIcon = find.descendant(
        of: find.widgetWithText(Chip, 'security'),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(controller.items.first.tags, isNot(contains('security')));
    });

    testWidgets('edits and saves notes', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      final notesInput = find.byKey(const Key('notes_input'));
      await tester.ensureVisible(notesInput);
      await tester.enterText(notesInput, 'Updated secret notes from inspector');

      final saveNotesBtn = find.byKey(const Key('save_notes_btn'));
      await tester.tap(saveNotesBtn);
      await tester.pumpAndSettle();

      expect(controller.items.first.notes, 'Updated secret notes from inspector');
    });

    testWidgets('reassigns collection via dropdown', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(item: testItem));
      await tester.pumpAndSettle();

      final dropdown = find.byKey(const Key('collection_dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select 'None (Unassigned)'
      final noneOption = find.text('None (Unassigned)').last;
      await tester.tap(noneOption);
      await tester.pumpAndSettle();

      expect(controller.items.first.collectionId, isNull);
    });

    testWidgets('deletes record and triggers dismiss callback', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool dismissed = false;
      await tester.pumpWidget(buildTestWidget(
        item: testItem,
        onDismiss: () => dismissed = true,
      ));
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('delete_record_btn'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(controller.items, isEmpty);
    });

    testWidgets('close buttons trigger onDismiss', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int dismissCount = 0;
      await tester.pumpWidget(buildTestWidget(
        item: testItem,
        onDismiss: () => dismissCount++,
      ));
      await tester.pumpAndSettle();

      final topCloseBtn = find.byKey(const Key('sheet_close_btn'));
      await tester.tap(topCloseBtn);
      await tester.pumpAndSettle();
      expect(dismissCount, 1);

      final bottomCloseBtn = find.byKey(const Key('close_detail_btn'));
      await tester.ensureVisible(bottomCloseBtn);
      await tester.tap(bottomCloseBtn);
      await tester.pumpAndSettle();
      expect(dismissCount, 2);
    });
  });
}
