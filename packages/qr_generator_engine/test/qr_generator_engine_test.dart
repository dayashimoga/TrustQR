import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

void main() {
  group('QrGeneratorEngine Tests', () {
    const engine = DefaultQrGeneratorEngine();

    test('Standard black on white options yield high scannability score', () {
      const options = QrCustomizationOptions(
        foregroundColorHex: 0xFF000000,
        backgroundColorHex: 0xFFFFFFFF,
      );
      final assessment = engine.evaluateScannability(options);
      expect(assessment.isScannable, isTrue);
      expect(assessment.contrastRatio, greaterThan(15.0));
      expect(assessment.scannabilityScore, equals(100.0));
    });

    test('Low contrast colors trigger warning and reduced scannability', () {
      const lowContrastOptions = QrCustomizationOptions(
        foregroundColorHex: 0xFF888888,
        backgroundColorHex: 0xFF999999,
      );
      final assessment = engine.evaluateScannability(lowContrastOptions);
      expect(assessment.contrastRatio, lessThan(3.0));
      expect(assessment.isScannable, isFalse);
    });

    test('Generates matrix representation string', () {
      final matrix = engine.generateMatrixRepresentation(
        'https://universal-qr.org',
        const QrCustomizationOptions(moduleShape: QrModuleShape.cyberGrid),
      );
      expect(matrix, contains('cyberGrid'));
      expect(matrix, contains('len=24'));
    });
  });
}
