import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:user_app/src/state/vault_controller.dart';
import 'package:user_app/src/views/collections_view.dart';

void main() {
  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late VaultController controller;

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

  Widget buildTestWidget({ValueChanged<String>? onSelectCollection}) {
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
        body: CollectionsView(
          controller: controller,
          onSelectCollection: onSelectCollection,
        ),
      ),
    );
  }

  group('CollectionsView - Workflow & Dialogs', () {
    testWidgets('renders empty state and creates collection via empty state button', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NO COLLECTIONS CREATED'), findsOneWidget);

      final createFirstBtn = find.byKey(const Key('empty_create_collection_btn'));
      await tester.tap(createFirstBtn);
      await tester.pumpAndSettle();

      expect(find.text('NEW COLLECTION'), findsOneWidget);

      final nameField = find.byKey(const Key('create_collection_name_field'));
      final descField = find.byKey(const Key('create_collection_desc_field'));
      await tester.enterText(nameField, 'Personal Vault');
      await tester.enterText(descField, 'Personal scans and crypto keys');

      // Tap emerald color choice
      final colorChoice = find.byKey(const Key('color_choice_#00FF9D'));
      await tester.tap(colorChoice);
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('confirm_create_collection_btn'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Personal Vault'), findsOneWidget);
      expect(find.text('Personal scans and crypto keys'), findsOneWidget);
      expect(find.text('0 RECORD(S)'), findsOneWidget);
      expect(controller.collections.length, 1);
    });

    testWidgets('creates collection via header button', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await controller.createCollection(name: 'Existing Folder');
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Existing Folder'), findsOneWidget);

      final headerBtn = find.byKey(const Key('new_collection_btn'));
      await tester.tap(headerBtn);
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('create_collection_name_field'));
      await tester.enterText(nameField, 'Work Projects');

      final confirmBtn = find.byKey(const Key('confirm_create_collection_btn'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Work Projects'), findsOneWidget);
      expect(controller.collections.length, 2);
    });

    testWidgets('view button sets filter and invokes onSelectCollection callback', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final col = await controller.createCollection(name: 'Finances');
      String? selectedId;

      await tester.pumpWidget(buildTestWidget(
        onSelectCollection: (id) => selectedId = id,
      ));
      await tester.pumpAndSettle();

      final viewBtn = find.byKey(Key('view_collection_${col.id}_btn'));
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(selectedId, col.id);
      expect(controller.filter.collectionId, col.id);
    });

    testWidgets('deletes collection with option to delete contained records', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final col = await controller.createCollection(name: 'To Delete');
      await vault.recordItem(
        rawContent: 'contained payload',
        payloadType: QrPayloadType.plainText,
        collectionId: col.id,
      );
      await controller.refresh();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(Key('delete_collection_${col.id}_btn'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('DELETE COLLECTION // TO DELETE'), findsOneWidget);

      // Toggle checkbox to delete contained items too
      final checkbox = find.byKey(const Key('delete_items_too_checkbox'));
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final confirmDeleteBtn = find.byKey(const Key('confirm_delete_collection_btn'));
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      expect(controller.collections, isEmpty);
      expect(controller.items, isEmpty);
    });
  });
}
