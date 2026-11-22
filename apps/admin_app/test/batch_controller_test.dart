import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/batch_controller.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

void main() {
  group('BatchController Unit Tests', () {
    late BatchController controller;

    setUp(() {
      controller = BatchController();
    });

    test('initializes with default asset tags preset', () {
      expect(controller.itemCount, equals(5));
      expect(controller.items.first.id, equals('ASSET-CORP-001'));
      expect(controller.getScannability('ASSET-CORP-001'), isNotNull);
      expect(controller.selectedFormat, equals(ExportFormat.png));
      expect(controller.isProcessing, isFalse);
    });

    test('loads employee badges preset', () {
      controller.loadEmployeeBadgesPreset();
      expect(controller.itemCount, equals(4));
      expect(controller.items.first.id, equals('EMP-9001'));
      expect(controller.items.first.content, contains('BEGIN:VCARD'));
      expect(controller.getScannability('EMP-9001'), isNotNull);
    });

    test('loads wifi hotspots preset', () {
      controller.loadWifiHotspotsPreset();
      expect(controller.itemCount, equals(3));
      expect(controller.items.first.id, equals('WIFI-HQ-GUEST'));
      expect(controller.items.first.content, contains('WIFI:S:CORP-GUEST'));
      expect(controller.getScannability('WIFI-HQ-GUEST'), isNotNull);
    });

    test('adds and removes single items', () {
      controller.clearItems();
      expect(controller.itemCount, equals(0));

      const item = BatchItemRequest(
        id: 'CUSTOM-01',
        content: 'https://example.com/custom-01',
        title: 'Custom Item 1',
      );
      controller.addItem(item);
      expect(controller.itemCount, equals(1));
      expect(controller.getScannability('CUSTOM-01'), isNotNull);

      controller.removeItem('CUSTOM-01');
      expect(controller.itemCount, equals(0));
      expect(controller.getScannability('CUSTOM-01'), isNull);
    });

    test('parses CSV input with and without headers', () {
      controller.clearItems();

      // With header and hex colors
      const csvWithHeader = '''
id,content,title,subtitle,templateId,foregroundColorHex,backgroundColorHex
ITEM-01,https://test.com/1,Title 1,Subtitle 1,corporateNavy,#00F5FF,#0F172A
ITEM-02,https://test.com/2,Title 2,Subtitle 2,emeraldTrust,0xFF00FF88,0xFF0A0E17
''';
      final count1 = controller.parseCsv(csvWithHeader);
      expect(count1, equals(2));
      expect(controller.itemCount, equals(2));
      expect(controller.items[0].id, equals('ITEM-01'));
      expect(controller.items[0].foregroundColorHex, equals(0xFF00F5FF));
      expect(controller.items[1].foregroundColorHex, equals(0xFF00FF88));

      // Without header
      const csvNoHeader = 'ITEM-03,https://test.com/3,Title 3,Sub 3,cyberpunkNeon';
      final count2 = controller.parseCsv(csvNoHeader);
      expect(count2, equals(1));
      expect(controller.itemCount, equals(3));

      // Empty CSV
      expect(controller.parseCsv('   '), equals(0));
    });

    test('parses JSON array of batch item requests', () {
      controller.clearItems();

      const jsonStr = '''
[
  {
    "id": "JSON-01",
    "content": "https://api.domain.com/token/1",
    "title": "Machine Alpha",
    "subtitle": "Sensor 1",
    "templateId": "highContrastMono"
  },
  {
    "id": "JSON-02",
    "content": "https://api.domain.com/token/2",
    "title": "Machine Beta"
  }
]
''';
      final added = controller.parseJson(jsonStr);
      expect(added, equals(2));
      expect(controller.itemCount, equals(2));
      expect(controller.items[0].id, equals('JSON-01'));
      expect(controller.items[1].title, equals('Machine Beta'));

      // Empty or non-list JSON
      expect(controller.parseJson(''), equals(0));
      expect(controller.parseJson('{}'), equals(0));
    });

    test('setSelectedFormat switches format and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setSelectedFormat(ExportFormat.svg);
      expect(controller.selectedFormat, equals(ExportFormat.svg));
      expect(notified, isTrue);
    });

    test('generateBatch compiles pure-Dart PKZIP archive with SHA-256 hash', () async {
      final bundle = await controller.generateBatch(format: ExportFormat.png);
      expect(bundle, isNotNull);
      expect(controller.processedCount, equals(controller.itemCount));
      expect(controller.successCount, equals(controller.itemCount));
      expect(controller.failureCount, equals(0));
      expect(controller.lastZipBytes, isNotNull);
      expect(controller.lastZipBytes!.length, greaterThan(100));
      expect(controller.lastZipName, contains('.zip'));
      expect(controller.lastZipSize, greaterThan(100));
      expect(controller.lastZipSha256, isNotNull);
      expect(controller.lastZipSha256!.length, equals(64)); // 32-byte hex
      expect(controller.progress, equals(1.0));
      expect(controller.isProcessing, isFalse);
    });

    test('generateBatch returns null when items list is empty', () async {
      controller.clearItems();
      final bundle = await controller.generateBatch();
      expect(bundle, isNull);
    });
  });
}
