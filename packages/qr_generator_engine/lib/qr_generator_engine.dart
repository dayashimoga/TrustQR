/// Admin-only QR matrix generator, styling, and scannability simulator engine.
library qr_generator_engine;

import 'src/engine/artistic_qr_generator_engine.dart';

export 'src/matrix/qr_matrix.dart';
export 'src/encoder/qr_polynomial.dart';
export 'src/encoder/qr_version.dart';
export 'src/encoder/qr_encoder.dart';
export 'src/style/qr_eye_style.dart';
export 'src/style/qr_color_config.dart';
export 'src/style/qr_logo_config.dart';
export 'src/style/qr_template.dart';
export 'src/rasterizer/qr_generated_image.dart';
export 'src/rasterizer/qr_matrix_rasterizer.dart';
export 'src/engine/artistic_qr_generator_engine.dart';

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

/// Default implementation of [QrGeneratorEngine] backed by [ArtisticQrGeneratorEngine].
class DefaultQrGeneratorEngine extends ArtisticQrGeneratorEngine {
  const DefaultQrGeneratorEngine({
    super.encoder,
    super.rasterizer,
  });
}
