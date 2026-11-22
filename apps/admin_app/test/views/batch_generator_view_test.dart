import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/batch_controller.dart';
import 'package:admin_app/src/views/batch_generator_view.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

void main() {
  group('BatchGeneratorView Widget Tests', () {
    late BatchController batchController;

    setUp(() {
      batchController = BatchController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: Scaffold(
          body: BatchGeneratorView(batchController: batchController),
        ),
      );
    }

    testWidgets('renders header, initial asset tags, and queue count', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('BATCH GENERATOR // ZIP EXPORTER'), findsOneWidget);
      expect(find.byKey(const Key('batch_count_badge')), findsOneWidget);
      expect(find.text('5 ITEMS LOADED'), findsOneWidget);
      expect(find.text('ASSET-CORP-001'), findsOneWidget);
    });

    testWidgets('taps preset buttons and clear button', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear all
      await tester.tap(find.byKey(const Key('batch_clear_btn')));
      await tester.pumpAndSettle();
      expect(batchController.itemCount, equals(0));
      expect(find.text('0 ITEMS LOADED'), findsOneWidget);

      // Load employee badges
      await tester.tap(find.byKey(const Key('preset_employee_btn')));
      await tester.pumpAndSettle();
      expect(batchController.itemCount, equals(4));
      expect(find.text('EMP-9001'), findsOneWidget);

      // Load Wi-Fi stations
      await tester.tap(find.byKey(const Key('preset_wifi_btn')));
      await tester.pumpAndSettle();
      expect(batchController.itemCount, equals(3));
      expect(find.text('WIFI-HQ-GUEST'), findsOneWidget);

      // Load Asset tags
      await tester.tap(find.byKey(const Key('preset_asset_tags_btn')));
      await tester.pumpAndSettle();
      expect(batchController.itemCount, equals(5));
    });

    testWidgets('parses CSV and JSON from text field', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      batchController.clearItems();
      await tester.pumpAndSettle();

      // Enter CSV
      await tester.enterText(
        find.byKey(const Key('batch_raw_input_field')),
        'TAG-101,https://corp.local/tag-101,Machine A,Rack 1,corporateNavy',
      );
      await tester.tap(find.byKey(const Key('batch_parse_csv_btn')));
      await tester.pumpAndSettle();

      expect(batchController.itemCount, equals(1));
      expect(find.text('TAG-101'), findsOneWidget);

      // Enter JSON
      await tester.enterText(
        find.byKey(const Key('batch_raw_input_field')),
        '[{"id": "TAG-102", "content": "https://corp.local/tag-102", "title": "Sensor B"}]',
      );
      await tester.tap(find.byKey(const Key('batch_parse_json_btn')));
      await tester.pumpAndSettle();

      expect(batchController.itemCount, equals(2));
      expect(find.text('TAG-102'), findsOneWidget);
    });

    testWidgets('selects export format chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('format_chip_svg')));
      await tester.pumpAndSettle();
      expect(batchController.selectedFormat, equals(ExportFormat.svg));

      await tester.tap(find.byKey(const Key('format_chip_pdf')));
      await tester.pumpAndSettle();
      expect(batchController.selectedFormat, equals(ExportFormat.pdf));

      await tester.tap(find.byKey(const Key('format_chip_png')));
      await tester.pumpAndSettle();
      expect(batchController.selectedFormat, equals(ExportFormat.png));
    });

    testWidgets('executes batch generation and shows zip summary card with hash', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_generate_zip_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('batch_generate_zip_btn')));
      await tester.pumpAndSettle();

      expect(find.text('BATCH ZIP ARCHIVE COMPILED SUCCESSFULLY'), findsOneWidget);
      expect(find.byKey(const Key('batch_zip_hash_text')), findsOneWidget);
    });

    testWidgets('removes single item from queue', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ASSET-CORP-001'), findsOneWidget);
      await tester.tap(find.byKey(const Key('batch_remove_ASSET-CORP-001')));
      await tester.pumpAndSettle();

      expect(batchController.itemCount, equals(4));
      expect(find.text('ASSET-CORP-001'), findsNothing);
    });
  });
}
