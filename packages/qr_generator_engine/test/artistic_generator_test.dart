import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('Artistic Styling & Configuration Tests', () {
    test('QrColorConfig linear and radial gradients', () {
      final solid = QrColorConfig.solid(0xFF112233, backgroundHex: 0xFFFFFFFF);
      expect(solid.getColorAt(0.5, 0.5), equals(0xFF112233));
      expect(solid.stops, isEmpty);

      final linear = QrColorConfig.linear([
        const QrColorStop(offset: 0.0, colorHex: 0xFF000000),
        const QrColorStop(offset: 1.0, colorHex: 0xFFFFFFFF),
      ], angleDegrees: 90.0);

      expect(linear.gradientType, equals(QrGradientType.linear));
      // Top (v = 0.0) should be close to black
      final topColor = linear.getColorAt(0.5, 0.0);
      expect((topColor >> 16) & 0xFF, lessThan(50));
      // Bottom (v = 1.0) should be close to white
      final bottomColor = linear.getColorAt(0.5, 1.0);
      expect((bottomColor >> 16) & 0xFF, greaterThan(200));

      final radial = QrColorConfig.radial([
        const QrColorStop(offset: 0.0, colorHex: 0xFFFF0000),
        const QrColorStop(offset: 1.0, colorHex: 0xFF0000FF),
      ]);
      expect(radial.gradientType, equals(QrGradientType.radial));
      final centerColor = radial.getColorAt(0.5, 0.5);
      expect((centerColor >> 16) & 0xFF, greaterThan(200)); // Red in center

      // Contrast ratio calculations
      final cr = QrColorConfig.contrastRatio(0xFF000000, 0xFFFFFFFF);
      expect(cr, greaterThan(20.0));

      // Serialization
      final json = linear.toJson();
      final revived = QrColorConfig.fromJson(json);
      expect(revived.gradientType, equals(QrGradientType.linear));
      expect(revived.stops.length, equals(2));
    });

    test('QrEyeStyle configuration and JSON', () {
      const eye = QrEyeStyle(
        frameShape: QrEyeFrameShape.circle,
        pupilShape: QrEyePupilShape.diamond,
        frameColorHex: 0xFF00F0FF,
        pupilColorHex: 0xFFFF007F,
      );

      expect(eye.frameShape, equals(QrEyeFrameShape.circle));
      expect(eye.pupilShape, equals(QrEyePupilShape.diamond));
      final json = eye.toJson();
      final revived = QrEyeStyle.fromJson(json);
      expect(revived.frameShape, equals(QrEyeFrameShape.circle));
      expect(revived.pupilShape, equals(QrEyePupilShape.diamond));
      expect(revived.frameColorHex, equals(0xFF00F0FF));
      expect(revived.pupilColorHex, equals(0xFFFF007F));
    });

    test('QrLogoConfig occlusion and bounds validation', () {
      const logo = QrLogoConfig(
        sizeRatio: 0.20,
        quietZoneModules: 1,
        borderRadius: 4,
      );

      final bounds = logo.calculateCutoutModuleBounds(25);
      expect(bounds.left, greaterThan(0));
      expect(bounds.right, lessThan(25));
      expect(bounds.width, equals(bounds.height));

      final occlusion = logo.calculateOcclusionRatio(25);
      expect(occlusion, greaterThan(0.0));
      expect(occlusion, lessThan(0.30));

      // Valid under high ECC
      expect(logo.validateOcclusion(25, QrErrorCorrectionLevel.high), isTrue);
      // Valid under quartile ECC
      expect(logo.validateOcclusion(25, QrErrorCorrectionLevel.quartile), isTrue);

      // Oversized logo should fail validation
      const hugeLogo = QrLogoConfig(sizeRatio: 0.60);
      expect(hugeLogo.validateOcclusion(25, QrErrorCorrectionLevel.low), isFalse);

      final matrix = QrMatrix(25);
      logo.carveLogoArea(matrix);
      expect(matrix.getType(12, 12), equals(QrModuleType.logoArea));
      expect(matrix.get(12, 12), isFalse);

      // Serialization
      final json = logo.toJson();
      final revived = QrLogoConfig.fromJson(json);
      expect(revived.sizeRatio, equals(0.20));
      expect(revived.quietZoneModules, equals(1));
    });

    test('QrTemplate presets and lookup', () {
      expect(QrTemplate.builtInTemplates.length, equals(5));

      final cyber = QrTemplate.findById('cyberpunk-neon');
      expect(cyber, isNotNull);
      expect(cyber!.moduleShape, equals(QrModuleShape.cyberGrid));

      final corporate = QrTemplate.findById('corporate-navy');
      expect(corporate, isNotNull);

      final nonExistent = QrTemplate.findById('does-not-exist');
      expect(nonExistent, isNull);

      final json = cyber.toJson();
      final revived = QrTemplate.fromJson(json);
      expect(revived.id, equals('cyberpunk-neon'));
      expect(revived.moduleShape, equals(QrModuleShape.cyberGrid));
    });
  });

  group('Rasterizer & BMP Generation Tests', () {
    test('QrGeneratedImage pixel access and fillRect', () {
      final img = QrGeneratedImage(width: 50, height: 50);
      expect(img.pixelCount, equals(2500));

      img.setPixel(10, 10, 0xFFFF0000);
      expect(img.getPixel(10, 10), equals(0xFFFF0000));
      expect(img.getPixel(0, 0), equals(0));

      img.fillRect(20, 20, 10, 10, 0xFF00FF00);
      expect(img.getPixel(25, 25), equals(0xFF00FF00));
    });

    test('toBmp produces valid uncompressed BMP bytes', () {
      final img = QrGeneratedImage(width: 30, height: 30);
      img.fillRect(0, 0, 30, 30, 0xFFFFFFFF);
      img.fillRect(5, 5, 20, 20, 0xFF000000);

      final bmpBytes = img.toBmp();
      expect(bmpBytes.length, greaterThan(54));
      // Verify BM magic signature
      expect(bmpBytes[0], equals(0x42));
      expect(bmpBytes[1], equals(0x4D));

      final data = ByteData.view(bmpBytes.buffer);
      final fileSize = data.getUint32(2, Endian.little);
      expect(fileSize, equals(bmpBytes.length));
      final dataOffset = data.getUint32(10, Endian.little);
      expect(dataOffset, equals(54));
      final width = data.getInt32(18, Endian.little);
      final height = data.getInt32(22, Endian.little);
      expect(width, equals(30));
      expect(height, equals(30));
    });

    test('Rasterizes with various module shapes', () {
      const rasterizer = QrMatrixRasterizer();
      final matrix = QrEncoder().encode('ShapeTest123');

      for (final shape in QrModuleShape.values) {
        final img = rasterizer.rasterize(
          matrix: matrix,
          moduleShape: shape,
          moduleSize: 8,
          quietZone: 2,
        );
        expect(img.width, equals((matrix.dimension + 4) * 8));
        expect(img.height, equals((matrix.dimension + 4) * 8));
      }
    });

    test('Rasterizes with various eye frame and pupil shapes', () {
      const rasterizer = QrMatrixRasterizer();
      final matrix = QrEncoder().encode('EyeTest123');

      for (final frameShape in QrEyeFrameShape.values) {
        for (final pupilShape in QrEyePupilShape.values) {
          final img = rasterizer.rasterize(
            matrix: matrix,
            eyeStyle: QrEyeStyle(
              frameShape: frameShape,
              pupilShape: pupilShape,
              frameColorHex: 0xFF123456,
              pupilColorHex: 0xFF654321,
            ),
            moduleSize: 8,
            quietZone: 2,
          );
          expect(img.pixelCount, greaterThan(0));
        }
      }
    });
  });

  group('ArtisticQrGeneratorEngine Facade & Scannability Assessment', () {
    final engine = ArtisticQrGeneratorEngine();

    test('generateMatrix and generateStyledImage', () {
      final matrix = engine.generateMatrix('https://universal-qr.org');
      expect(matrix.dimension, greaterThanOrEqualTo(21));

      final img = engine.generateStyledImage(
        'https://universal-qr.org',
        template: QrTemplate.corporateNavy,
        moduleSize: 10,
      );
      expect(img.width, greaterThan(0));

      final bmpBytes = engine.generateBmp('https://universal-qr.org');
      expect(bmpBytes[0], equals(0x42));
      expect(bmpBytes[1], equals(0x4D));
    });

    test('evaluateScannability with various parameters', () {
      // Optimal
      final good = engine.evaluateScannability(
        const QrCustomizationOptions(
          foregroundColorHex: 0xFF000000,
          backgroundColorHex: 0xFFFFFFFF,
        ),
      );
      expect(good.isScannable, isTrue);
      expect(good.scannabilityScore, greaterThan(90.0));

      // Low contrast
      final lowContrast = engine.evaluateScannability(
        const QrCustomizationOptions(
          foregroundColorHex: 0xFF777777,
          backgroundColorHex: 0xFF888888,
        ),
      );
      expect(lowContrast.isScannable, isFalse);
      expect(lowContrast.contrastRatio, lessThan(3.0));
      expect(lowContrast.recommendation, contains('Critical'));

      // Sub-optimal contrast
      final subOptimal = engine.evaluateScannability(
        const QrCustomizationOptions(
          foregroundColorHex: 0xFF333333,
          backgroundColorHex: 0xFF666666,
        ),
      );
      expect(subOptimal.contrastRatio, lessThan(4.5));

      // Logo occlusion within budget
      final logoBudget = engine.evaluateScannability(
        const QrCustomizationOptions(),
        logoConfig: const QrLogoConfig(sizeRatio: 0.15),
        errorCorrection: QrErrorCorrectionLevel.high,
      );
      expect(logoBudget.isScannable, isTrue);

      // Logo occlusion exceeding budget
      final logoOver = engine.evaluateScannability(
        const QrCustomizationOptions(),
        logoConfig: const QrLogoConfig(sizeRatio: 0.50),
        errorCorrection: QrErrorCorrectionLevel.low,
      );
      expect(logoOver.isScannable, isFalse);
      expect(logoOver.recommendation, contains('exceeds maximum safe budget'));

      // Shape penalties
      for (final shape in [
        QrModuleShape.rounded,
        QrModuleShape.liquid,
        QrModuleShape.dots,
        QrModuleShape.diamond,
        QrModuleShape.cyberGrid,
      ]) {
        final assessed = engine.evaluateScannability(
          QrCustomizationOptions(moduleShape: shape),
        );
        expect(assessed.scannabilityScore, lessThan(100.0));
      }

      // Gradient color configuration scannability
      final gradientAssess = engine.evaluateScannability(
        const QrCustomizationOptions(),
        colorConfig: QrColorConfig.linear([
          const QrColorStop(offset: 0.0, colorHex: 0xFF111111),
          const QrColorStop(offset: 1.0, colorHex: 0xFF444444),
        ], backgroundHex: 0xFFFFFFFF),
      );
      expect(gradientAssess.contrastRatio, greaterThan(7.0));

      // Exception string representation
      const ex = QrLogoOcclusionException(
        message: 'Occlusion limit breached',
        occlusionRatio: 0.35,
        maxAllowedRatio: 0.25,
      );
      expect(ex.toString(), contains('QrLogoOcclusionException'));

      // ModuleRect getters
      const rect = ModuleRect(left: 2, top: 3, right: 6, bottom: 8);
      expect(rect.width, equals(5));
      expect(rect.height, equals(6));
      expect(rect.moduleCount, equals(30));

      // QrColorConfig single stop edge case & fromJson defaults
      final singleStop = QrColorConfig.linear([
        const QrColorStop(offset: 0.0, colorHex: 0xFF00FF00),
      ]);
      expect(singleStop.getColorAt(0.5, 0.5), equals(0xFF00FF00));
      final defaultColor = QrColorConfig.fromJson({});
      expect(defaultColor.foregroundColorHex, equals(0xFF000000));

      // QrTemplate fromJson defaults
      final defaultTpl = QrTemplate.fromJson({'id': 'custom', 'name': 'Custom'});
      expect(defaultTpl.id, equals('custom'));
      expect(defaultTpl.description, isEmpty);
    });
  });

  group('Universal Scanner Engine Round-Trip Scannability Verification', () {
    final generator = ArtisticQrGeneratorEngine();
    final scanner = UniversalQrScannerEngine();

    ImageBuffer toImageBuffer(QrGeneratedImage img) {
      return ImageBuffer(
        bytes: img.rgbaBytes,
        width: img.width,
        height: img.height,
        format: ImageColorFormat.rgba8888,
      );
    }

    test('Round-trip decode: standard URL Byte payload', () async {
      const payload = 'https://universal-qr.org/verify/session-42';
      final img = generator.generateStyledImage(
        payload,
        moduleShape: QrModuleShape.square,
        colorConfig: QrColorConfig.solid(0xFF000000, backgroundHex: 0xFFFFFFFF),
        moduleSize: 10,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
      expect(result.payloadType, equals(QrPayloadType.url));
    });

    test('Round-trip decode: pure Numeric payload', () async {
      const payload = '987654321098765';
      final img = generator.generateStyledImage(
        payload,
        moduleShape: QrModuleShape.square,
        colorConfig: QrColorConfig.solid(0xFF000000, backgroundHex: 0xFFFFFFFF),
        moduleSize: 10,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: Alphanumeric payload', () async {
      const payload = 'INVOICE:2026-X77';
      final img = generator.generateStyledImage(
        payload,
        moduleShape: QrModuleShape.square,
        colorConfig: QrColorConfig.solid(0xFF000000, backgroundHex: 0xFFFFFFFF),
        moduleSize: 10,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: highContrastMono template', () async {
      const payload = 'WIFI:S:MyNetwork;T:WPA;P:Secret123;;';
      final img = generator.generateStyledImage(
        payload,
        template: QrTemplate.highContrastMono,
        moduleSize: 10,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
      expect(result.payloadType, equals(QrPayloadType.wifi));
    });

    test('Round-trip decode: corporateNavy template', () async {
      const payload = 'https://acme.corp/portal';
      final img = generator.generateStyledImage(
        payload,
        template: QrTemplate.corporateNavy,
        moduleSize: 12,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: emeraldTrust template', () async {
      const payload = 'https://trustqr.institution.gov/cert/8899';
      final img = generator.generateStyledImage(
        payload,
        template: QrTemplate.emeraldTrust,
        moduleSize: 12,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: liquid module shape', () async {
      const payload = 'LIQUID-SHAPE-VERIFIED';
      final img = generator.generateStyledImage(
        payload,
        moduleShape: QrModuleShape.liquid,
        colorConfig: QrColorConfig.solid(0xFF000000, backgroundHex: 0xFFFFFFFF),
        moduleSize: 12,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: rounded module shape', () async {
      const payload = 'ROUNDED-MODULES-TEST';
      final img = generator.generateStyledImage(
        payload,
        moduleShape: QrModuleShape.rounded,
        colorConfig: QrColorConfig.solid(0xFF000000, backgroundHex: 0xFFFFFFFF),
        moduleSize: 12,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: center logo cutout with High ECC error correction', () async {
      const payload = 'https://logo-protected.org/data';
      const logoConfig = QrLogoConfig(
        sizeRatio: 0.18,
        quietZoneModules: 1,
        borderRadius: 4,
      );

      final img = generator.generateStyledImage(
        payload,
        logoConfig: logoConfig,
        errorCorrection: QrErrorCorrectionLevel.high,
        moduleSize: 12,
        quietZone: 4,
      );

      final buffer = toImageBuffer(img);
      final result = await scanner.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });

    test('Round-trip decode: exported BMP byte stream decoded via ImageFileDecoder', () async {
      const payload = 'BMP-EXPORT-ROUND-TRIP';
      final bmpBytes = generator.generateBmp(
        payload,
        moduleSize: 10,
        quietZone: 4,
      );

      final decodedBuffer = ImageFileDecoder.decodeFileBytes(bmpBytes);
      expect(decodedBuffer, isNotNull);
      final result = await scanner.decodeFromImageBuffer(decodedBuffer!);
      expect(result, isNotNull);
      expect(result!.rawContent, equals(payload));
    });
  });
}
