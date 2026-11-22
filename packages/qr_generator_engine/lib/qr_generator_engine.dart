/// Admin-only QR matrix generator, styling, and scannability simulator engine.
library qr_generator_engine;

/// Supported artistic module shapes.
enum QrModuleShape {
  square,
  rounded,
  dots,
  diamond,
  liquid,
  cyberGrid,
}

/// Error-correction level for Reed-Solomon encoding.
enum QrErrorCorrectionLevel {
  low,      // 7% recovery
  medium,   // 15% recovery
  quartile, // 25% recovery
  high,     // 30% recovery
}

/// Customization options for artistic QR generation.
class QrCustomizationOptions {
  final QrModuleShape moduleShape;
  final QrErrorCorrectionLevel errorCorrection;
  final int foregroundColorHex;
  final int backgroundColorHex;
  final bool hasEmbeddedLogo;
  final double logoOcclusionPercentage;

  const QrCustomizationOptions({
    this.moduleShape = QrModuleShape.square,
    this.errorCorrection = QrErrorCorrectionLevel.medium,
    this.foregroundColorHex = 0xFF000000,
    this.backgroundColorHex = 0xFFFFFFFF,
    this.hasEmbeddedLogo = false,
    this.logoOcclusionPercentage = 0.0,
  });
}

/// Real-time scannability assessment.
class ScannabilityAssessment {
  final double contrastRatio;
  final double scannabilityScore; // 0 - 100
  final bool isScannable;
  final String recommendation;

  const ScannabilityAssessment({
    required this.contrastRatio,
    required this.scannabilityScore,
    required this.isScannable,
    required this.recommendation,
  });
}

/// Abstract contract for QR matrix generation.
abstract class QrGeneratorEngine {
  ScannabilityAssessment evaluateScannability(QrCustomizationOptions options);
  String generateMatrixRepresentation(String payload, QrCustomizationOptions options);
}

/// Default implementation of [QrGeneratorEngine].
class DefaultQrGeneratorEngine implements QrGeneratorEngine {
  const DefaultQrGeneratorEngine();

  @override
  ScannabilityAssessment evaluateScannability(QrCustomizationOptions options) {
    // Basic Michelson / luminance ratio calculation
    final fgLuminance = _luminance(options.foregroundColorHex);
    final bgLuminance = _luminance(options.backgroundColorHex);
    final ratio = (bgLuminance > fgLuminance)
        ? (bgLuminance + 0.05) / (fgLuminance + 0.05)
        : (fgLuminance + 0.05) / (bgLuminance + 0.05);

    double score = 100.0;
    if (ratio < 4.5) {
      score -= (4.5 - ratio) * 20.0;
    }
    if (options.hasEmbeddedLogo) {
      score -= options.logoOcclusionPercentage * 1.5;
    }
    score = score.clamp(0.0, 100.0);

    final isScannable = score >= 50.0 && ratio >= 3.0;
    final recommendation = isScannable
        ? 'Optimal contrast and scannability.'
        : 'Warning: Low contrast or excessive logo occlusion may prevent reliable scanning.';

    return ScannabilityAssessment(
      contrastRatio: ratio,
      scannabilityScore: score,
      isScannable: isScannable,
      recommendation: recommendation,
    );
  }

  @override
  String generateMatrixRepresentation(String payload, QrCustomizationOptions options) {
    return 'QR_MATRIX[len=${payload.length},shape=${options.moduleShape.name},ec=${options.errorCorrection.name}]';
  }

  double _luminance(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}
