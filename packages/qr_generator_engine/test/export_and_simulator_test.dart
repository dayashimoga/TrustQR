import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('CRC-32 Checksum Tests', () {
    test('Computes standard CRC-32 against reference vectors', () {
      // Empty input
      expect(Crc32.compute([]), equals(0));

      // Standard test vector "123456789" ASCII => 0xCBF43926 (3421780262)
      final asciiBytes = utf8.encode('123456789');
      expect(Crc32.compute(asciiBytes), equals(0xCBF43926));

      // Sub-range offset and length
      final padded = [0, 0, ...asciiBytes, 0, 0];
      expect(Crc32.compute(padded, 2, asciiBytes.length), equals(0xCBF43926));
    });
  });

  group('Scannability & Contrast Simulator Tests', () {
    const simulator = ScannabilitySimulator();
    const encoder = QrEncoder();

    test('Optimal contrast and default quiet zone yields high score and scannable verdict', () {
      final matrix = encoder.encode('https://example.com/optimal');
      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(
          foregroundColorHex: 0xFF000000,
          backgroundColorHex: 0xFFFFFFFF,
        ),
        quietZone: 4,
      );

      expect(report.isScannable, isTrue);
      expect(report.overallScore, greaterThanOrEqualTo(85.0));
      expect(report.contrastRatio, greaterThanOrEqualTo(20.0));
      expect(report.michelsonContrast, greaterThan(0.9));
      expect(report.quietZoneSufficient, isTrue);
      expect(report.warningFlags, isEmpty);
      expect(report.recommendations.first, contains('Optimal configuration'));
      expect(report.simulationScores.standardLightScore, greaterThanOrEqualTo(90.0));
      expect(report.simulationScores.glareLightingScore, greaterThan(70.0));
    });

    test('Critical low contrast triggers warnings and marks unscannable', () {
      final matrix = encoder.encode('https://example.com/low-contrast');
      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(
          foregroundColorHex: 0xFF888888,
          backgroundColorHex: 0xFF999999, // ~1.2:1 contrast
        ),
      );

      expect(report.isScannable, isFalse);
      expect(report.overallScore, lessThan(55.0));
      expect(report.warningFlags, contains('CRITICAL_LOW_CONTRAST'));
      expect(report.recommendations.any((r) => r.contains('below ISO 3:1')), isTrue);
      expect(report.simulationScores.glareLightingScore, lessThan(50.0));
    });

    test('Suboptimal contrast (3.0:1 to 4.5:1) warns without critical failure', () {
      final matrix = encoder.encode('https://example.com/suboptimal');
      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(
          foregroundColorHex: 0xFF4A4A4A,
          backgroundColorHex: 0xFF9E9E9E, // ~3.5:1 contrast
        ),
      );

      expect(report.warningFlags, contains('SUBOPTIMAL_CONTRAST'));
      expect(report.recommendations.any((r) => r.contains('dim lighting')), isTrue);
    });

    test('Excessive logo occlusion beyond RS ECC budget triggers warning', () {
      final matrix = encoder.encode('https://example.com/logo-test', eccLevel: QrErrorCorrectionLevel.low);
      const largeLogo = QrLogoConfig(sizeRatio: 0.35); // Exceeds Low ECC 5% budget

      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(),
        logoConfig: largeLogo,
        errorCorrection: QrErrorCorrectionLevel.low,
      );

      expect(report.warningFlags, contains('EXCESSIVE_LOGO_OCCLUSION'));
      expect(report.isScannable, isFalse);
      expect(report.recommendations.any((r) => r.contains('exceeding the')), isTrue);
    });

    test('Safe logo occlusion within High ECC budget yields scannable verdict', () {
      final matrix = encoder.encode('https://example.com/logo-safe', eccLevel: QrErrorCorrectionLevel.high);
      const safeLogo = QrLogoConfig(sizeRatio: 0.18);

      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(),
        logoConfig: safeLogo,
        errorCorrection: QrErrorCorrectionLevel.high,
      );

      expect(report.isScannable, isTrue);
      expect(report.warningFlags.contains('EXCESSIVE_LOGO_OCCLUSION'), isFalse);
    });

    test('Insufficient quiet zone (< 4 modules) triggers warning flag', () {
      final matrix = encoder.encode('https://example.com/tight');
      final report = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(),
        quietZone: 2,
      );

      expect(report.quietZoneSufficient, isFalse);
      expect(report.warningFlags, contains('INSUFFICIENT_QUIET_ZONE'));
      expect(report.recommendations.any((r) => r.contains('Quiet zone is 2 modules')), isTrue);
    });

    test('Evaluates gradient contrast stops properly', () {
      final matrix = encoder.encode('https://example.com/gradient');
      final gradConfig = QrColorConfig.linear([
        const QrColorStop(offset: 0.0, colorHex: 0xFF001133), // Deep dark
        const QrColorStop(offset: 1.0, colorHex: 0xFF004488), // Medium blue
      ], backgroundHex: 0xFFFFFFFF);

      final report = simulator.simulate(matrix: matrix, colorConfig: gradConfig);
      expect(report.isScannable, isTrue);
      expect(report.contrastRatio, greaterThan(4.5));
    });

    test('Module shape penalties and round trip confidence impacts composite score', () {
      final matrix = encoder.encode('https://example.com/shapes');

      final squareReport = simulator.simulate(matrix: matrix, colorConfig: const QrColorConfig(), moduleShape: QrModuleShape.square);
      final dotsReport = simulator.simulate(matrix: matrix, colorConfig: const QrColorConfig(), moduleShape: QrModuleShape.dots);
      final liquidReport = simulator.simulate(matrix: matrix, colorConfig: const QrColorConfig(), moduleShape: QrModuleShape.liquid);

      expect(dotsReport.overallScore, lessThan(squareReport.overallScore));
      expect(liquidReport.overallScore, lessThanOrEqualTo(squareReport.overallScore));

      // Reduced roundTripConfidence
      final lowConfidenceReport = simulator.simulate(
        matrix: matrix,
        colorConfig: const QrColorConfig(),
        roundTripConfidence: 0.5,
      );
      expect(lowConfidenceReport.overallScore, lessThan(squareReport.overallScore));
    });

    test('ScannabilityReport and SimulatedEnvironmentScore JSON serialization round-trip', () {
      final matrix = encoder.encode('https://example.com/json-test');
      final report = simulator.simulate(matrix: matrix, colorConfig: const QrColorConfig());

      final jsonMap = report.toJson();
      final reconstituted = ScannabilityReport.fromJson(jsonMap);

      expect(reconstituted.overallScore, equals(report.overallScore));
      expect(reconstituted.isScannable, equals(report.isScannable));
      expect(reconstituted.contrastRatio, equals(report.contrastRatio));
      expect(reconstituted.michelsonContrast, equals(report.michelsonContrast));
      expect(reconstituted.quietZoneModules, equals(report.quietZoneModules));
      expect(reconstituted.simulationScores.standardLightScore, equals(report.simulationScores.standardLightScore));
      expect(reconstituted.simulationScores.glareLightingScore, equals(report.simulationScores.glareLightingScore));
      expect(reconstituted.simulationScores.lowLightingScore, equals(report.simulationScores.lowLightingScore));
      expect(reconstituted.simulationScores.angleTiltScore, equals(report.simulationScores.angleTiltScore));
      expect(reconstituted.simulationScores.distanceBlurScore, equals(report.simulationScores.distanceBlurScore));
    });
  });

  group('PNG Exporter & Scanner Engine Round-Trip Tests', () {
    const pngExporter = PngExporter();
    const rasterizer = QrMatrixRasterizer();
    const encoder = QrEncoder();
    final scanner = UniversalQrScannerEngine();

    test('Generates valid PNG binary with correct headers and chunks', () {
      final matrix = encoder.encode('https://example.com/png-test');
      final img = rasterizer.rasterize(matrix: matrix, moduleSize: 8, quietZone: 4);
      final pngBytes = pngExporter.export(img, dpi: 300);

      // 1. Signature
      expect(pngBytes.length, greaterThan(64));
      expect(pngBytes.sublist(0, 8), equals(PngExporter.pngSignature));

      // 2. IHDR Chunk (bytes 8..33)
      final ihdrLen = ByteData.sublistView(pngBytes, 8, 12).getUint32(0, Endian.big);
      expect(ihdrLen, equals(13));
      final ihdrType = String.fromCharCodes(pngBytes.sublist(12, 16));
      expect(ihdrType, equals('IHDR'));

      final width = ByteData.sublistView(pngBytes, 16, 20).getUint32(0, Endian.big);
      final height = ByteData.sublistView(pngBytes, 20, 24).getUint32(0, Endian.big);
      expect(width, equals(img.width));
      expect(height, equals(img.height));

      final bitDepth = pngBytes[24];
      final colorType = pngBytes[25];
      expect(bitDepth, equals(8));
      expect(colorType, equals(6)); // RGBA

      // 3. IEND Chunk is at the end
      final endOffset = pngBytes.length - 12;
      final iendType = String.fromCharCodes(pngBytes.sublist(endOffset + 4, endOffset + 8));
      expect(iendType, equals('IEND'));
    });

    test('Decodes exported PNG back through UniversalQrScannerEngine round-trip', () async {
      const payload = 'https://universal-qr.app/verify/alpha123';
      final matrix = encoder.encode(payload, eccLevel: QrErrorCorrectionLevel.medium);
      final img = rasterizer.rasterize(
        matrix: matrix,
        moduleSize: 10,
        quietZone: 4,
        moduleShape: QrModuleShape.square,
        colorConfig: const QrColorConfig(
          foregroundColorHex: 0xFF000000,
          backgroundColorHex: 0xFFFFFFFF,
        ),
      );

      final pngBytes = pngExporter.export(img, dpi: 300);
      expect(pngBytes, isNotEmpty);

      // Test decoding file bytes with ImageFileDecoder
      final buffer = ImageFileDecoder.decodeFileBytes(pngBytes);
      expect(buffer, isNotNull);
      expect(buffer!.width, equals(img.width));
      expect(buffer.height, equals(img.height));

      // Test scanning directly via UniversalQrScannerEngine
      final result = await scanner.decodeFromFileBytes(pngBytes);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Decodes exported PNG with rounded modules and template styling', () async {
      const payload = 'WIFI:S:OfficeNetwork;T:WPA;P:StrongPassword123;;';
      final matrix = encoder.encode(payload, eccLevel: QrErrorCorrectionLevel.high);
      final img = rasterizer.rasterize(
        matrix: matrix,
        moduleSize: 10,
        quietZone: 4,
        moduleShape: QrModuleShape.rounded,
        colorConfig: const QrColorConfig(
          foregroundColorHex: 0xFF0A2540,
          backgroundColorHex: 0xFFFFFFFF,
        ),
      );

      final pngBytes = pngExporter.export(img, dpi: 150);
      final result = await scanner.decodeFromFileBytes(pngBytes);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });
  });

  group('Vector SVG Exporter Tests', () {
    const svgExporter = SvgExporter();
    const encoder = QrEncoder();

    test('Generates standard SVG document with background and viewbox', () {
      final matrix = encoder.encode('https://example.com/svg-standard');
      final svg = svgExporter.export(
        matrix: matrix,
        moduleShape: QrModuleShape.square,
        moduleSize: 10,
        quietZone: 4,
      );

      expect(svg, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('viewBox="0 0 '));
      expect(svg, contains('<rect width='));
      expect(svg, contains('<!-- Finder Eye Patterns -->'));
      expect(svg, contains('<!-- Data Modules -->'));
      expect(svg.trim(), endsWith('</svg>'));
    });

    test('Supports linear and radial gradient definitions in SVG <defs>', () {
      final matrix = encoder.encode('https://example.com/svg-gradient');

      // Linear gradient
      final linearSvg = svgExporter.export(
        matrix: matrix,
        colorConfig: QrColorConfig.linear([
          const QrColorStop(offset: 0.0, colorHex: 0xFF00FFCC),
          const QrColorStop(offset: 1.0, colorHex: 0xFFFF007F),
        ], angleDegrees: 45.0),
      );
      expect(linearSvg, contains('<defs>'));
      expect(linearSvg, contains('<linearGradient id="qr_grad_'));
      expect(linearSvg, contains('<stop offset="0.0%" stop-color="#00FFCC" />'));
      expect(linearSvg, contains('<stop offset="100.0%" stop-color="#FF007F" />'));
      expect(linearSvg, contains('fill="url(#qr_grad_'));

      // Radial gradient
      final radialSvg = svgExporter.export(
        matrix: matrix,
        colorConfig: QrColorConfig.radial([
          const QrColorStop(offset: 0.0, colorHex: 0xFF0055FF),
          const QrColorStop(offset: 1.0, colorHex: 0xFF000022),
        ]),
      );
      expect(radialSvg, contains('<radialGradient id="qr_grad_'));
    });

    test('Renders all 6 module shapes in SVG vector primitives', () {
      final matrix = encoder.encode('https://example.com/shapes');

      for (final shape in QrModuleShape.values) {
        final svg = svgExporter.export(matrix: matrix, moduleShape: shape);
        expect(svg, isNotEmpty);
        switch (shape) {
          case QrModuleShape.square:
          case QrModuleShape.liquid:
            expect(svg, contains('<rect x='));
            break;
          case QrModuleShape.rounded:
            expect(svg, contains('rx='));
            break;
          case QrModuleShape.dots:
            expect(svg, contains('<circle cx='));
            break;
          case QrModuleShape.diamond:
          case QrModuleShape.cyberGrid:
            expect(svg, contains('<polygon points='));
            break;
        }
      }
    });

    test('Renders all finder eye frame and pupil shapes in SVG', () {
      final matrix = encoder.encode('https://example.com/eyes');

      for (final frameShape in QrEyeFrameShape.values) {
        for (final pupilShape in QrEyePupilShape.values) {
          final svg = svgExporter.export(
            matrix: matrix,
            eyeStyle: QrEyeStyle(frameShape: frameShape, pupilShape: pupilShape),
          );
          expect(svg, isNotEmpty);
          expect(svg, contains('<!-- Finder Eye Patterns -->'));
        }
      }
    });

    test('Renders embedded logo cutout and custom SVG vector path', () {
      final matrix = encoder.encode('https://example.com/logo', eccLevel: QrErrorCorrectionLevel.high);
      final svg = svgExporter.export(
        matrix: matrix,
        logoConfig: const QrLogoConfig(
          sizeRatio: 0.20,
          backgroundColorHex: 0xFFFFFFFF,
          svgPathData: 'M 10 10 L 90 90',
          svgFillHex: 0xFF000000,
        ),
      );

      expect(svg, contains('<!-- Embedded Logo -->'));
      expect(svg, contains('<path d="M 10 10 L 90 90"'));
    });

    test('Accepts custom display dimensions', () {
      final matrix = encoder.encode('https://example.com/dim');
      final svg = svgExporter.export(matrix: matrix, displayWidth: 500, displayHeight: 500);
      expect(svg, contains('width="500.0"'));
      expect(svg, contains('height="500.0"'));
    });
  });

  group('Print-Ready Vector PDF Exporter Tests', () {
    const pdfExporter = PdfExporter();
    const encoder = QrEncoder();

    test('Generates valid PDF-1.4 binary document for singleLabel layout', () {
      final matrix = encoder.encode('https://example.com/pdf-single');
      final pdfBytes = pdfExporter.export(
        matrix: matrix,
        layout: PdfPageLayout.singleLabel,
        title: 'Single Label Title',
        subtitle: 'https://example.com/pdf-single',
      );

      final pdfStr = utf8.decode(pdfBytes, allowMalformed: true);
      expect(pdfStr, startsWith('%PDF-1.4'));
      expect(pdfStr, contains('/Type /Catalog'));
      expect(pdfStr, contains('/Type /Pages'));
      expect(pdfStr, contains('/Type /Page'));
      expect(pdfStr, contains('/BaseFont /Helvetica'));
      expect(pdfStr, contains('/BaseFont /Helvetica-Bold'));
      expect(pdfStr, contains('Single Label Title'));
      expect(pdfStr, contains('xref'));
      expect(pdfStr, contains('trailer'));
      expect(pdfStr, contains('startxref'));
      expect(pdfStr.trim(), endsWith('%%EOF'));
    });

    test('Generates valid stickerSheet layout with 3x4 grid', () {
      final matrix = encoder.encode('https://example.com/stickers');
      final pdfBytes = pdfExporter.export(
        matrix: matrix,
        layout: PdfPageLayout.stickerSheet,
        title: 'Batch Sticker',
      );

      final pdfStr = utf8.decode(pdfBytes, allowMalformed: true);
      expect(pdfStr, startsWith('%PDF-1.4'));
      expect(pdfStr, contains('612')); // Letter width
      expect(pdfStr, contains('792')); // Letter height
      expect(pdfStr, contains('Batch Sticker'));
      expect(pdfStr.trim(), endsWith('%%EOF'));
    });

    test('Generates valid badgeCard layout (CR80 credit-card dimensions)', () {
      final matrix = encoder.encode('https://example.com/badge');
      final pdfBytes = pdfExporter.export(
        matrix: matrix,
        layout: PdfPageLayout.badgeCard,
        title: 'Alex Mercer',
        subtitle: 'Lead Security Auditor',
      );

      final pdfStr = utf8.decode(pdfBytes, allowMalformed: true);
      expect(pdfStr, startsWith('%PDF-1.4'));
      expect(pdfStr, contains('EVENT ACCESS PASS'));
      expect(pdfStr, contains('Alex Mercer'));
      expect(pdfStr, contains('Lead Security Auditor'));
      expect(pdfStr.trim(), endsWith('%%EOF'));
    });
  });

  group('Batch Exporter & ZIP Archive Tests', () {
    const batchExporter = BatchExporter();

    test('Exports batch of items to PNG and builds valid PKZIP 2.0 archive', () async {
      final requests = [
        const BatchItemRequest(id: 'qr_001', content: 'https://example.com/item1', title: 'Item 1'),
        const BatchItemRequest(id: 'qr_002', content: 'https://example.com/item2', title: 'Item 2', templateId: 'corporate-navy'),
        const BatchItemRequest(id: 'qr_003', content: 'https://example.com/item3', title: 'Item 3', foregroundColorHex: 0xFF112233),
      ];

      var progressCalls = 0;
      final bundle = await batchExporter.exportBatch(
        requests: requests,
        format: ExportFormat.png,
        onProgress: (current, total) {
          progressCalls++;
          expect(total, equals(3));
          expect(current, inInclusiveRange(1, 3));
        },
      );

      expect(progressCalls, equals(3));
      expect(bundle.successCount, equals(3));
      expect(bundle.failureCount, equals(0));
      expect(bundle.errors, isEmpty);
      // 3 items + 1 manifest.json
      expect(bundle.files.length, equals(4));

      final fileNames = bundle.files.map((f) => f.fileName).toList();
      expect(fileNames, contains('qr_001.png'));
      expect(fileNames, contains('qr_002.png'));
      expect(fileNames, contains('qr_003.png'));
      expect(fileNames, contains('manifest.json'));

      // Validate ZIP archive generation
      final zipBytes = bundle.toZipArchive();
      expect(zipBytes.length, greaterThan(256));

      // PKZIP Local Header signature: 0x50 0x4B 0x03 0x04
      expect(zipBytes[0], equals(0x50));
      expect(zipBytes[1], equals(0x4B));
      expect(zipBytes[2], equals(0x03));
      expect(zipBytes[3], equals(0x04));

      // PKZIP End of Central Directory signature: 0x50 0x4B 0x05 0x06
      final eocdOffset = zipBytes.length - 22;
      expect(zipBytes[eocdOffset], equals(0x50));
      expect(zipBytes[eocdOffset + 1], equals(0x4B));
      expect(zipBytes[eocdOffset + 2], equals(0x05));
      expect(zipBytes[eocdOffset + 3], equals(0x06));

      // Verify total entries count in EOCD
      final entryCount = ByteData.sublistView(zipBytes, eocdOffset + 8, eocdOffset + 10).getUint16(0, Endian.little);
      expect(entryCount, equals(4));
    });

    test('Exports batch to SVG, PDF, and BMP formats', () async {
      final requests = [
        const BatchItemRequest(id: 'qr_test', content: 'https://example.com/multi'),
      ];

      final svgBundle = await batchExporter.exportBatch(requests: requests, format: ExportFormat.svg);
      expect(svgBundle.files.first.fileName, equals('qr_test.svg'));
      expect(svgBundle.files.first.mimeType, equals('image/svg+xml'));

      final pdfBundle = await batchExporter.exportBatch(requests: requests, format: ExportFormat.pdf);
      expect(pdfBundle.files.first.fileName, equals('qr_test.pdf'));
      expect(pdfBundle.files.first.mimeType, equals('application/pdf'));

      final bmpBundle = await batchExporter.exportBatch(requests: requests, format: ExportFormat.bmp);
      expect(bmpBundle.files.first.fileName, equals('qr_test.bmp'));
      expect(bmpBundle.files.first.mimeType, equals('image/bmp'));
    });

    test('Parses CSV content and executes batch export', () async {
      const csvData = '''
id,content,title,templateId
qr_csv_1,https://example.com/csv1,CSV Item 1,corporate-navy
qr_csv_2,https://example.com/csv2,CSV Item 2,emerald-trust
''';

      final bundle = await batchExporter.exportFromCsv(csvData, format: ExportFormat.svg);
      expect(bundle.successCount, equals(2));
      expect(bundle.files.map((f) => f.fileName), contains('qr_csv_1.svg'));
      expect(bundle.files.map((f) => f.fileName), contains('qr_csv_2.svg'));

      // Empty CSV returns empty bundle with error
      final emptyBundle = await batchExporter.exportFromCsv('', format: ExportFormat.png);
      expect(emptyBundle.errors, isNotEmpty);
      expect(emptyBundle.files, isEmpty);

      // Single column CSV without header
      const simpleCsv = '''
https://example.com/raw1
https://example.com/raw2
''';
      final simpleBundle = await batchExporter.exportFromCsv(simpleCsv);
      expect(simpleBundle.successCount, equals(2));
    });

    test('Parses JSON content and executes batch export', () async {
      const jsonList = '''
[
  {"id": "json_1", "content": "https://example.com/json1", "title": "JSON 1"},
  {"id": "json_2", "content": "https://example.com/json2", "title": "JSON 2"}
]
''';

      final bundle = await batchExporter.exportFromJson(jsonList, format: ExportFormat.pdf);
      expect(bundle.successCount, equals(2));
      expect(bundle.files.map((f) => f.fileName), contains('json_1.pdf'));
      expect(bundle.files.map((f) => f.fileName), contains('json_2.pdf'));

      // JSON object with "items" wrapper
      const jsonObject = '''
{
  "items": [
    {"id": "wrapped_1", "content": "https://example.com/wrapped1"}
  ]
}
''';
      final wrappedBundle = await batchExporter.exportFromJson(jsonObject);
      expect(wrappedBundle.successCount, equals(1));

      // Malformed JSON throws FormatException
      expect(
        () => batchExporter.exportFromJson('{"invalid": true}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('BatchItemRequest serialization and deserialization', () {
      const req = BatchItemRequest(
        id: 'req_123',
        content: 'https://example.com/test',
        title: 'Title',
        subtitle: 'Subtitle',
        templateId: 'corporate-navy',
        foregroundColorHex: 0xFF112233,
        backgroundColorHex: 0xFFFFFFFF,
        metadata: {'tag': 'production'},
      );

      final json = req.toJson();
      final reconstituted = BatchItemRequest.fromJson(json);

      expect(reconstituted.id, equals(req.id));
      expect(reconstituted.content, equals(req.content));
      expect(reconstituted.title, equals(req.title));
      expect(reconstituted.subtitle, equals(req.subtitle));
      expect(reconstituted.templateId, equals(req.templateId));
      expect(reconstituted.foregroundColorHex, equals(req.foregroundColorHex));
      expect(reconstituted.backgroundColorHex, equals(req.backgroundColorHex));
      expect(reconstituted.metadata?['tag'], equals('production'));
    });
  });

  group('ArtisticQrGeneratorEngine Facade Full Integration Tests', () {
    const engine = DefaultQrGeneratorEngine();

    test('simulateScannability returns comprehensive report', () {
      final report = engine.simulateScannability(
        'https://example.com/engine-sim',
        template: QrTemplate.corporateNavy,
        quietZone: 4,
      );

      expect(report.isScannable, isTrue);
      expect(report.overallScore, greaterThan(75.0));
    });

    test('exportPng, exportSvg, and exportPdf facade helpers work seamlessly', () {
      const payload = 'https://example.com/facade-exports';

      final pngBytes = engine.exportPng(payload, template: QrTemplate.corporateNavy);
      expect(pngBytes.sublist(0, 8), equals(PngExporter.pngSignature));

      final svgStr = engine.exportSvg(payload, template: QrTemplate.cyberpunkNeon);
      expect(svgStr, contains('<svg xmlns="http://www.w3.org/2000/svg"'));

      final pdfBytes = engine.exportPdf(payload, layout: PdfPageLayout.singleLabel);
      expect(utf8.decode(pdfBytes, allowMalformed: true), contains('%PDF-1.4'));
    });

    test('exportBatch, exportFromCsv, and exportFromJson facade helpers work seamlessly', () async {
      final batch = await engine.exportBatch(
        requests: [const BatchItemRequest(id: 'item_1', content: 'https://example.com/b1')],
      );
      expect(batch.successCount, equals(1));

      final csvBatch = await engine.exportFromCsv('qr_1,https://example.com/csv');
      expect(csvBatch.successCount, equals(1));

      final jsonBatch = await engine.exportFromJson('[{"id": "j1", "content": "https://example.com/json"}]');
      expect(jsonBatch.successCount, equals(1));
    });
  });
}
