import 'dart:typed_data';
import '../../qr_generator_engine.dart';

/// Full-featured admin-only artistic QR generator engine.
class ArtisticQrGeneratorEngine implements QrGeneratorEngine {
  final QrEncoder _encoder;
  final QrMatrixRasterizer _rasterizer;
  final ScannabilitySimulator _simulator;
  final PngExporter _pngExporter;
  final SvgExporter _svgExporter;
  final PdfExporter _pdfExporter;
  final BatchExporter _batchExporter;

  const ArtisticQrGeneratorEngine({
    QrEncoder encoder = const QrEncoder(),
    QrMatrixRasterizer rasterizer = const QrMatrixRasterizer(),
    ScannabilitySimulator simulator = const ScannabilitySimulator(),
    PngExporter pngExporter = const PngExporter(),
    SvgExporter svgExporter = const SvgExporter(),
    PdfExporter pdfExporter = const PdfExporter(),
    BatchExporter batchExporter = const BatchExporter(),
  })  : _encoder = encoder,
        _rasterizer = rasterizer,
        _simulator = simulator,
        _pngExporter = pngExporter,
        _svgExporter = svgExporter,
        _pdfExporter = pdfExporter,
        _batchExporter = batchExporter;

  /// Encodes [payload] into a standards-compliant [QrMatrix].
  QrMatrix generateMatrix(
    String payload, {
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    QrLogoConfig? logoConfig,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    final matrix = _encoder.encode(
      payload,
      eccLevel: errorCorrection,
      fixedVersion: fixedVersion,
      fixedMaskPattern: fixedMaskPattern,
    );

    if (logoConfig != null) {
      logoConfig.carveLogoArea(matrix);
    }

    return matrix;
  }

  /// Generates a styled raster image of [payload] using templates or custom parameters.
  QrGeneratedImage generateStyledImage(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    // Resolve options with template fallbacks
    final shape = moduleShape ?? template?.moduleShape ?? QrModuleShape.square;
    final colors = colorConfig ?? template?.colorConfig ?? const QrColorConfig();
    final eyes = eyeStyle ?? template?.eyeStyle ?? const QrEyeStyle();
    final logo = logoConfig ?? template?.logoConfig;

    final matrix = generateMatrix(
      payload,
      errorCorrection: errorCorrection,
      logoConfig: logo,
      fixedVersion: fixedVersion,
      fixedMaskPattern: fixedMaskPattern,
    );

    return _rasterizer.rasterize(
      matrix: matrix,
      moduleShape: shape,
      colorConfig: colors,
      eyeStyle: eyes,
      logoConfig: logo,
      moduleSize: moduleSize,
      quietZone: quietZone,
    );
  }

  /// Generates an uncompressed 24-bit BMP binary byte stream.
  Uint8List generateBmp(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    final img = generateStyledImage(
      payload,
      template: template,
      moduleShape: moduleShape,
      colorConfig: colorConfig,
      eyeStyle: eyeStyle,
      logoConfig: logoConfig,
      errorCorrection: errorCorrection,
      moduleSize: moduleSize,
      quietZone: quietZone,
      fixedVersion: fixedVersion,
      fixedMaskPattern: fixedMaskPattern,
    );
    return img.toBmp();
  }

  /// Simulates scannability under real-world environmental stress conditions.
  ScannabilityReport simulateScannability(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int quietZone = 4,
    double roundTripConfidence = 1.0,
  }) {
    final shape = moduleShape ?? template?.moduleShape ?? QrModuleShape.square;
    final colors = colorConfig ?? template?.colorConfig ?? const QrColorConfig();
    final eyes = eyeStyle ?? template?.eyeStyle ?? const QrEyeStyle();
    final logo = logoConfig ?? template?.logoConfig;

    final matrix = generateMatrix(
      payload,
      errorCorrection: errorCorrection,
      logoConfig: logo,
    );

    return _simulator.simulate(
      matrix: matrix,
      colorConfig: colors,
      eyeStyle: eyes,
      moduleShape: shape,
      logoConfig: logo,
      errorCorrection: errorCorrection,
      quietZone: quietZone,
      roundTripConfidence: roundTripConfidence,
    );
  }

  /// Exports [payload] as a high-DPI PNG binary.
  Uint8List exportPng(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    int dpi = 300,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    final img = generateStyledImage(
      payload,
      template: template,
      moduleShape: moduleShape,
      colorConfig: colorConfig,
      eyeStyle: eyeStyle,
      logoConfig: logoConfig,
      errorCorrection: errorCorrection,
      moduleSize: moduleSize,
      quietZone: quietZone,
      fixedVersion: fixedVersion,
      fixedMaskPattern: fixedMaskPattern,
    );
    return _pngExporter.export(img, dpi: dpi);
  }

  /// Exports [payload] as a resolution-independent vector SVG XML string.
  String exportSvg(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    double? displayWidth,
    double? displayHeight,
  }) {
    final shape = moduleShape ?? template?.moduleShape ?? QrModuleShape.square;
    final colors = colorConfig ?? template?.colorConfig ?? const QrColorConfig();
    final eyes = eyeStyle ?? template?.eyeStyle ?? const QrEyeStyle();
    final logo = logoConfig ?? template?.logoConfig;

    final matrix = generateMatrix(
      payload,
      errorCorrection: errorCorrection,
      logoConfig: logo,
    );

    return _svgExporter.export(
      matrix: matrix,
      moduleShape: shape,
      colorConfig: colors,
      eyeStyle: eyes,
      logoConfig: logo,
      moduleSize: moduleSize,
      quietZone: quietZone,
      displayWidth: displayWidth,
      displayHeight: displayHeight,
    );
  }

  /// Exports [payload] as a print-ready vector PDF binary.
  Uint8List exportPdf(
    String payload, {
    QrTemplate? template,
    QrColorConfig? colorConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    PdfPageLayout layout = PdfPageLayout.singleLabel,
    String? title,
    String? subtitle,
    int quietZone = 4,
  }) {
    final colors = colorConfig ?? template?.colorConfig ?? const QrColorConfig();

    final matrix = generateMatrix(
      payload,
      errorCorrection: errorCorrection,
    );

    return _pdfExporter.export(
      matrix: matrix,
      layout: layout,
      title: title,
      subtitle: subtitle,
      colorConfig: colors,
      quietZone: quietZone,
    );
  }

  /// Executes batch export across multiple items with progress notification.
  Future<QrBatchExportBundle> exportBatch({
    required List<BatchItemRequest> requests,
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    int dpi = 300,
    void Function(int current, int total)? onProgress,
  }) {
    return _batchExporter.exportBatch(
      requests: requests,
      format: format,
      defaultTemplate: defaultTemplate,
      errorCorrection: errorCorrection,
      moduleSize: moduleSize,
      quietZone: quietZone,
      dpi: dpi,
      onProgress: onProgress,
    );
  }

  /// Runs batch export parsed from CSV content.
  Future<QrBatchExportBundle> exportFromCsv(
    String csvContent, {
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    void Function(int current, int total)? onProgress,
  }) {
    return _batchExporter.exportFromCsv(
      csvContent,
      format: format,
      defaultTemplate: defaultTemplate,
      onProgress: onProgress,
    );
  }

  /// Runs batch export parsed from JSON content.
  Future<QrBatchExportBundle> exportFromJson(
    String jsonContent, {
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    void Function(int current, int total)? onProgress,
  }) {
    return _batchExporter.exportFromJson(
      jsonContent,
      format: format,
      defaultTemplate: defaultTemplate,
      onProgress: onProgress,
    );
  }

  @override
  String generateMatrixRepresentation(String payload, QrCustomizationOptions options) {
    final matrix = generateMatrix(
      payload,
      errorCorrection: options.errorCorrection,
    );
    return 'QR_MATRIX[dim=${matrix.dimension},len=${payload.length},shape=${options.moduleShape.name},ec=${options.errorCorrection.name}]';
  }

  @override
  ScannabilityAssessment evaluateScannability(
    QrCustomizationOptions options, {
    QrColorConfig? colorConfig,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel? errorCorrection,
  }) {
    final colors = colorConfig ??
        QrColorConfig(
          foregroundColorHex: options.foregroundColorHex,
          backgroundColorHex: options.backgroundColorHex,
        );

    final ecc = errorCorrection ?? options.errorCorrection;

    // 1. Calculate contrast ratio
    var minContrast = QrColorConfig.contrastRatio(colors.foregroundColorHex, colors.backgroundColorHex);
    if (colors.stops.isNotEmpty) {
      for (final stop in colors.stops) {
        final cr = QrColorConfig.contrastRatio(stop.colorHex, colors.backgroundColorHex);
        if (cr < minContrast) {
          minContrast = cr;
        }
      }
    }

    // 2. Base score from contrast ratio (WCAG 7:1 gives 100, 4.5:1 gives 85, 3:1 gives 60)
    var score = 100.0;
    if (minContrast < 7.0) {
      score -= (7.0 - minContrast) * 8.0;
    }
    if (minContrast < 4.5) {
      score -= (4.5 - minContrast) * 15.0;
    }

    // 3. Occlusion penalty
    final occlusion = logoConfig != null
        ? logoConfig.calculateOcclusionRatio(25)
        : (options.hasEmbeddedLogo ? options.logoOcclusionPercentage / 100.0 : 0.0);

    final maxOcclusion = QrLogoConfig.getMaxAllowedOcclusion(ecc);
    if (occlusion > 0) {
      if (occlusion > maxOcclusion) {
        // Excessive occlusion penalty
        score -= (occlusion - maxOcclusion) * 200.0;
      } else {
        // Minor penalty within safe budget
        score -= (occlusion / maxOcclusion) * 15.0;
      }
    }

    // 4. Shape penalty (soft or rounded edges slightly reduce scanner focus under glare)
    switch (options.moduleShape) {
      case QrModuleShape.square:
        break; // Zero penalty for classic sharp squares
      case QrModuleShape.rounded:
      case QrModuleShape.liquid:
        score -= 2.0;
        break;
      case QrModuleShape.dots:
      case QrModuleShape.diamond:
      case QrModuleShape.cyberGrid:
        score -= 5.0;
        break;
    }

    score = score.clamp(0.0, 100.0);

    // 5. Determine scannability verdict and actionable recommendations
    final isScannable = score >= 55.0 && minContrast >= 3.0 && occlusion <= maxOcclusion;
    final List<String> issues = [];

    if (minContrast < 3.0) {
      issues.add('Critical: Low contrast ratio (${minContrast.toStringAsFixed(1)}:1) will cause scan failures.');
    } else if (minContrast < 4.5) {
      issues.add('Sub-optimal contrast (${minContrast.toStringAsFixed(1)}:1). Darker foreground recommended.');
    }

    if (occlusion > maxOcclusion) {
      issues.add('Logo occlusion (${(occlusion * 100).toStringAsFixed(1)}%) exceeds maximum safe budget for ${ecc.name.toUpperCase()} ECC (${(maxOcclusion * 100).toStringAsFixed(1)}%).');
    }

    final recommendation = issues.isEmpty
        ? 'Optimal contrast (${minContrast.toStringAsFixed(1)}:1) and scannability.'
        : issues.join(' ');

    return ScannabilityAssessment(
      contrastRatio: minContrast,
      scannabilityScore: score,
      isScannable: isScannable,
      recommendation: recommendation,
    );
  }
}
