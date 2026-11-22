import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:admin_app/src/state/studio_controller.dart';

class _FaultyEngine extends DefaultQrGeneratorEngine {
  const _FaultyEngine();

  @override
  QrMatrix generateMatrix(
    String payload, {
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    QrLogoConfig? logoConfig,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    throw Exception('Simulated engine explosion');
  }
}

void main() {
  group('StudioController Unit Tests', () {
    late StudioController controller;

    setUp(() {
      controller = StudioController();
    });

    test('initializes with default URL payload and valid state', () {
      expect(controller.payloadType, QrPayloadType.url);
      expect(controller.useManualRawPayload, isFalse);
      expect(controller.moduleShape, QrModuleShape.cyberGrid);
      expect(controller.errorCorrection, QrErrorCorrectionLevel.high);
      expect(controller.foregroundColorHex, 0xFF00F5FF);
      expect(controller.backgroundColorHex, 0xFF090D14);
      expect(controller.isTrustQrEnabled, isFalse);
      expect(controller.currentMatrix, isNotNull);
      expect(controller.currentImage, isNotNull);
      expect(controller.scannabilityReport, isNotNull);
      expect(controller.matrixRepresentation, contains('QR_MATRIX'));
    });

    test('switches through all 15 payload formats and generates valid structured payloads', () {
      for (final type in QrPayloadType.values) {
        controller.setPayloadType(type);
        expect(controller.payloadType, type);
        final payload = controller.buildStructuredPayload();
        expect(payload.type, type);
        final raw = payload.toRawPayload();
        expect(raw.isNotEmpty, isTrue);
        expect(controller.effectivePayload, raw);
        expect(controller.currentMatrix, isNotNull);
      }
    });

    test('builds fully populated vCard and MeCard payloads', () {
      controller.setPayloadType(QrPayloadType.vcard);
      controller.vcardFirstName = 'Alex';
      controller.vcardLastName = 'Vance';
      controller.vcardUrl = 'https://universal-qr.org/alex';
      controller.vcardAddress = '100 Security Ave';
      final vcard = controller.buildStructuredPayload();
      expect(vcard.toRawPayload(), contains('N:Vance;Alex;;;'));
      expect(vcard.toRawPayload(), contains('URL:https://universal-qr.org/alex'));
      expect(vcard.toRawPayload(), contains('ADR:;;100 Security Ave;;;;'));

      controller.setPayloadType(QrPayloadType.mecard);
      controller.mecardUrl = 'https://universal-qr.org/mecard';
      final mecard = controller.buildStructuredPayload();
      expect(mecard.toRawPayload(), contains('URL:https://universal-qr.org/mecard;'));
    });

    test('manual raw payload override works', () {
      controller.setUseManualRawPayload(true);
      controller.setManualRawPayload('CUSTOM_RAW_OVERRIDE_PAYLOAD');
      expect(controller.useManualRawPayload, isTrue);
      expect(controller.effectivePayload, 'CUSTOM_RAW_OVERRIDE_PAYLOAD');
      expect(controller.matrixRepresentation, contains('QR_MATRIX'));

      controller.setUseManualRawPayload(false);
      expect(controller.useManualRawPayload, isFalse);
      expect(controller.effectivePayload, controller.urlAddress);
    });

    test('customizes module shapes and error correction levels', () {
      for (final shape in QrModuleShape.values) {
        controller.setModuleShape(shape);
        expect(controller.moduleShape, shape);
      }

      for (final ec in QrErrorCorrectionLevel.values) {
        controller.setErrorCorrection(ec);
        expect(controller.errorCorrection, ec);
      }
    });

    test('customizes colors, gradients, and angles', () {
      controller.setColors(
        foreground: 0xFF00FF00,
        background: 0xFF111111,
        gradient: QrGradientType.radial,
        gradientColor2: 0xFFFF0055,
        linearAngle: 90.0,
      );
      expect(controller.foregroundColorHex, 0xFF00FF00);
      expect(controller.backgroundColorHex, 0xFF111111);
      expect(controller.gradientType, QrGradientType.radial);
      expect(controller.gradientColor2Hex, 0xFFFF0055);
      expect(controller.linearAngleDegrees, 90.0);

      // Solid color branch
      controller.setColors(gradient: QrGradientType.none);
      expect(controller.gradientType, QrGradientType.none);
      expect(controller.currentMatrix, isNotNull);
    });

    test('customizes eye shapes and colors', () {
      controller.setEyeStyle(
        frameShape: QrEyeFrameShape.square,
        pupilShape: QrEyePupilShape.square,
        frameColor: 0xFF00F0FF,
        pupilColor: 0xFFFF007F,
      );
      expect(controller.eyeFrameShape, QrEyeFrameShape.square);
      expect(controller.eyePupilShape, QrEyePupilShape.square);
      expect(controller.eyeFrameColorHex, 0xFF00F0FF);
      expect(controller.eyePupilColorHex, 0xFFFF007F);
    });

    test('applies branded templates correctly', () {
      final templates = [
        QrTemplate.cyberpunkNeon,
        QrTemplate.corporateNavy,
        QrTemplate.emeraldTrust,
        QrTemplate.highContrastMono,
      ];

      for (final tmpl in templates) {
        controller.applyTemplate(tmpl);
        expect(controller.activeTemplate?.id, tmpl.id);
        expect(controller.moduleShape, tmpl.moduleShape);
        expect(controller.eyeFrameShape, tmpl.eyeStyle.frameShape);
        expect(controller.eyePupilShape, tmpl.eyeStyle.pupilShape);
        expect(controller.foregroundColorHex, tmpl.colorConfig.foregroundColorHex);
        expect(controller.backgroundColorHex, tmpl.colorConfig.backgroundColorHex);
      }
    });

    test('center logo toggle and occlusion ratio clamping', () {
      controller.setLogoConfig(hasLogo: true, sizeRatio: 0.25);
      expect(controller.hasLogo, isTrue);
      expect(controller.logoSizeRatio, 0.25);

      // Clamping bounds
      controller.setLogoConfig(hasLogo: true, sizeRatio: 0.01);
      expect(controller.logoSizeRatio, 0.05);

      controller.setLogoConfig(hasLogo: true, sizeRatio: 0.90);
      expect(controller.logoSizeRatio, 0.30);

      controller.setLogoConfig(hasLogo: false);
      expect(controller.hasLogo, isFalse);
    });

    test('Ed25519 TrustQR institutional signing toggle and verification', () {
      controller.setTrustQrEnabled(true);
      expect(controller.isTrustQrEnabled, isTrue);
      expect(controller.effectivePayload, startsWith('trustqr://v1?'));
      expect(controller.signedEnvelope, isNotNull);
      expect(controller.envelopeVerification, isNotNull);
      expect(controller.envelopeVerification!.isValid, isTrue);
      expect(controller.signedEnvelope!.algorithm, CryptoAlgorithm.ed25519);

      // Change authority details with keyId only
      controller.setAuthorityDetails(keyId: 'custom-key-99');
      expect(controller.keyId, 'custom-key-99');
      expect(controller.envelopeVerification!.isValid, isTrue);

      // Change authority details with issuer only
      controller.setAuthorityDetails(issuer: 'Custom Enterprise Authority');
      expect(controller.authorityIssuer, 'Custom Enterprise Authority');

      // Disable TrustQR
      controller.setTrustQrEnabled(false);
      expect(controller.isTrustQrEnabled, isFalse);
      expect(controller.signedEnvelope, isNull);
      expect(controller.effectivePayload, isNot(startsWith('trustqr://')));
    });

    test('handles generator exceptions gracefully in recalculate()', () {
      final faultyCtrl = StudioController(generator: const _FaultyEngine());
      expect(faultyCtrl.matrixRepresentation, contains('[ERROR:'));
    });

    test('exports PNG with valid 8-byte PNG signature', () {
      final pngBytes = controller.exportPng(dpi: 300, moduleSize: 8);
      expect(pngBytes, isNotEmpty);
      expect(controller.lastExportFormat, 'PNG');
      expect(controller.lastExportBytes, pngBytes.length);
      expect(controller.lastExportMessage, contains('300DPI PNG'));

      // PNG magic bytes: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);
    });

    test('exports vector SVG XML string', () {
      final svg = controller.exportSvg(moduleSize: 8);
      expect(svg, isNotEmpty);
      expect(svg, startsWith('<svg'));
      expect(svg, endsWith('</svg>\n'));
      expect(controller.lastExportFormat, 'SVG');
      expect(controller.lastExportMessage, contains('Vector SVG'));
    });

    test('exports print-ready PDF binary with PDF-1.4 header', () {
      final pdfBytes = controller.exportPdf();
      expect(pdfBytes, isNotEmpty);
      expect(controller.lastExportFormat, 'PDF');
      expect(controller.lastExportMessage, contains('Print-Ready PDF'));

      // PDF magic ASCII: %PDF-
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('exports 24-bit BMP binary with BM signature', () {
      final bmpBytes = controller.exportBmp(moduleSize: 8);
      expect(bmpBytes, isNotEmpty);
      expect(controller.lastExportFormat, 'BMP');
      expect(controller.lastExportMessage, contains('24-bit BMP'));

      // BMP signature: 'B', 'M'
      expect(bmpBytes[0], 0x42);
      expect(bmpBytes[1], 0x4D);
    });
  });
}
