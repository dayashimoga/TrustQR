import 'dart:math' as math;
import '../../qr_generator_engine.dart';

/// Environmental lighting and distance simulation scores (0.0 to 100.0).
class SimulatedEnvironmentScore {
  /// Optimal studio conditions (normal diffuse lighting, 20-30cm distance, 0° tilt).
  final double standardLightScore;

  /// High surface glare wash-out (loss of ~35% effective contrast from specular reflections).
  final double glareLightingScore;

  /// Dim ambient lighting (high sensor noise floor).
  final double lowLightingScore;

  /// Angular perspective distortion (~30° perspective tilt).
  final double angleTiltScore;

  /// Distant camera / optical defocusing (edge gradient blur).
  final double distanceBlurScore;

  const SimulatedEnvironmentScore({
    required this.standardLightScore,
    required this.glareLightingScore,
    required this.lowLightingScore,
    required this.angleTiltScore,
    required this.distanceBlurScore,
  });

  Map<String, dynamic> toJson() => {
    'standardLightScore': standardLightScore,
    'glareLightingScore': glareLightingScore,
    'lowLightingScore': lowLightingScore,
    'angleTiltScore': angleTiltScore,
    'distanceBlurScore': distanceBlurScore,
  };

  factory SimulatedEnvironmentScore.fromJson(Map<String, dynamic> json) {
    return SimulatedEnvironmentScore(
      standardLightScore: (json['standardLightScore'] as num).toDouble(),
      glareLightingScore: (json['glareLightingScore'] as num).toDouble(),
      lowLightingScore: (json['lowLightingScore'] as num).toDouble(),
      angleTiltScore: (json['angleTiltScore'] as num).toDouble(),
      distanceBlurScore: (json['distanceBlurScore'] as num).toDouble(),
    );
  }
}

/// Comprehensive scannability assessment report.
class ScannabilityReport {
  /// Composite scannability score from 0.0 (unscannable) to 100.0 (optimal).
  final double overallScore;

  /// True if the code exceeds minimum reliability thresholds across standard scanners.
  final bool isScannable;

  /// WCAG 2.1 contrast ratio between foreground and background (1.0 to 21.0).
  final double contrastRatio;

  /// Michelson contrast ratio: (Lmax - Lmin) / (Lmax + Lmin), ranging 0.0 to 1.0.
  final double michelsonContrast;

  /// Ratio of modules occluded by embedded logo relative to total modules.
  final double logoOcclusionPercentage;

  /// Maximum safe occlusion percentage under the active Reed-Solomon ECC level.
  final double maxSafeOcclusionPercentage;

  /// Quiet zone width in modules surrounding the matrix.
  final int quietZoneModules;

  /// True if quiet zone meets or exceeds standard 4-module ISO/IEC 18004 requirement.
  final bool quietZoneSufficient;

  /// Machine vision round-trip decode verification confidence (0.0 to 1.0).
  final double roundTripConfidence;

  /// Active diagnostic warning flags.
  final List<String> warningFlags;

  /// Actionable engineering recommendations for improving print and camera scannability.
  final List<String> recommendations;

  /// Scores under simulated real-world environmental stress conditions.
  final SimulatedEnvironmentScore simulationScores;

  const ScannabilityReport({
    required this.overallScore,
    required this.isScannable,
    required this.contrastRatio,
    required this.michelsonContrast,
    required this.logoOcclusionPercentage,
    required this.maxSafeOcclusionPercentage,
    required this.quietZoneModules,
    required this.quietZoneSufficient,
    required this.roundTripConfidence,
    required this.warningFlags,
    required this.recommendations,
    required this.simulationScores,
  });

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'isScannable': isScannable,
    'contrastRatio': contrastRatio,
    'michelsonContrast': michelsonContrast,
    'logoOcclusionPercentage': logoOcclusionPercentage,
    'maxSafeOcclusionPercentage': maxSafeOcclusionPercentage,
    'quietZoneModules': quietZoneModules,
    'quietZoneSufficient': quietZoneSufficient,
    'roundTripConfidence': roundTripConfidence,
    'warningFlags': warningFlags,
    'recommendations': recommendations,
    'simulationScores': simulationScores.toJson(),
  };

  factory ScannabilityReport.fromJson(Map<String, dynamic> json) {
    return ScannabilityReport(
      overallScore: (json['overallScore'] as num).toDouble(),
      isScannable: json['isScannable'] as bool,
      contrastRatio: (json['contrastRatio'] as num).toDouble(),
      michelsonContrast: (json['michelsonContrast'] as num).toDouble(),
      logoOcclusionPercentage: (json['logoOcclusionPercentage'] as num).toDouble(),
      maxSafeOcclusionPercentage: (json['maxSafeOcclusionPercentage'] as num).toDouble(),
      quietZoneModules: json['quietZoneModules'] as int,
      quietZoneSufficient: json['quietZoneSufficient'] as bool,
      roundTripConfidence: (json['roundTripConfidence'] as num).toDouble(),
      warningFlags: List<String>.from(json['warningFlags'] as List? ?? []),
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
      simulationScores: SimulatedEnvironmentScore.fromJson(
        json['simulationScores'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Real-time scannability and environmental contrast simulator.
class ScannabilitySimulator {
  const ScannabilitySimulator();

  /// Simulates scannability for a configured QR matrix under diverse environmental conditions.
  ScannabilityReport simulate({
    required QrMatrix matrix,
    required QrColorConfig colorConfig,
    QrEyeStyle eyeStyle = const QrEyeStyle(),
    QrModuleShape moduleShape = QrModuleShape.square,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int quietZone = 4,
    double roundTripConfidence = 1.0,
  }) {
    final dim = matrix.dimension;
    final List<String> warnings = [];
    final List<String> recommendations = [];

    // 1. Contrast calculations
    final bgLum = QrColorConfig.relativeLuminance(colorConfig.backgroundColorHex);
    var minContrast = QrColorConfig.contrastRatio(colorConfig.foregroundColorHex, colorConfig.backgroundColorHex);
    var minFgLum = QrColorConfig.relativeLuminance(colorConfig.foregroundColorHex);
    var maxFgLum = minFgLum;

    if (colorConfig.stops.isNotEmpty) {
      for (final stop in colorConfig.stops) {
        final cr = QrColorConfig.contrastRatio(stop.colorHex, colorConfig.backgroundColorHex);
        final lum = QrColorConfig.relativeLuminance(stop.colorHex);
        if (cr < minContrast) minContrast = cr;
        if (lum < minFgLum) minFgLum = lum;
        if (lum > maxFgLum) maxFgLum = lum;
      }
    }

    // Michelson contrast formula: (Lmax - Lmin) / (Lmax + Lmin)
    final lMax = math.max(bgLum, maxFgLum);
    final lMin = math.min(bgLum, minFgLum);
    final michelson = (lMax + lMin) > 0 ? (lMax - lMin) / (lMax + lMin) : 0.0;

    // Contrast warnings
    if (minContrast < 3.0) {
      warnings.add('CRITICAL_LOW_CONTRAST');
      recommendations.add('Contrast ratio (${minContrast.toStringAsFixed(1)}:1) is below ISO 3:1 threshold. Increase luminance contrast.');
    } else if (minContrast < 4.5) {
      warnings.add('SUBOPTIMAL_CONTRAST');
      recommendations.add('Contrast ratio (${minContrast.toStringAsFixed(1)}:1) meets minimum threshold but may struggle under dim lighting.');
    }

    // 2. Logo Occlusion & Reed-Solomon Budget
    final occlusionRatio = logoConfig != null ? logoConfig.calculateOcclusionRatio(dim) : 0.0;
    final occlusionPercent = occlusionRatio * 100.0;
    final maxSafeOcclusionRatio = QrLogoConfig.getMaxAllowedOcclusion(errorCorrection);
    final maxSafeOcclusionPercent = maxSafeOcclusionRatio * 100.0;

    if (occlusionRatio > maxSafeOcclusionRatio) {
      warnings.add('EXCESSIVE_LOGO_OCCLUSION');
      recommendations.add(
        'Logo covers ${occlusionPercent.toStringAsFixed(1)}% of matrix, exceeding the ${maxSafeOcclusionPercent.toStringAsFixed(1)}% recovery budget for ${errorCorrection.name.toUpperCase()} ECC. Increase ECC level or shrink logo.',
      );
    } else if (occlusionRatio > maxSafeOcclusionRatio * 0.8) {
      warnings.add('HIGH_LOGO_OCCLUSION');
      recommendations.add('Logo occlusion is within budget (${occlusionPercent.toStringAsFixed(1)}%), but leaves little margin for physical surface damage.');
    }

    // 3. Quiet Zone Check
    final quietZoneSufficient = quietZone >= 4;
    if (!quietZoneSufficient) {
      warnings.add('INSUFFICIENT_QUIET_ZONE');
      recommendations.add('Quiet zone is $quietZone modules (standard requires at least 4 modules to prevent false edge mergers).');
    }

    // 4. Shape focus penalty
    var shapePenalty = 0.0;
    switch (moduleShape) {
      case QrModuleShape.square:
        break;
      case QrModuleShape.rounded:
      case QrModuleShape.liquid:
        shapePenalty = 3.0;
        break;
      case QrModuleShape.dots:
      case QrModuleShape.diamond:
      case QrModuleShape.cyberGrid:
        shapePenalty = 6.0;
        break;
    }

    // 5. Environmental Stress Scores
    // Standard condition score
    var baseScore = 100.0;
    if (minContrast < 7.0) baseScore -= (7.0 - minContrast) * 8.0;
    if (minContrast < 4.5) baseScore -= (4.5 - minContrast) * 16.0;
    if (occlusionRatio > maxSafeOcclusionRatio) {
      baseScore -= (occlusionRatio - maxSafeOcclusionRatio) * 200.0;
    } else if (occlusionRatio > 0) {
      baseScore -= (occlusionRatio / maxSafeOcclusionRatio) * 15.0;
    }
    if (!quietZoneSufficient) baseScore -= (4 - quietZone) * 7.0;
    baseScore -= shapePenalty;
    if (roundTripConfidence < 1.0) baseScore -= (1.0 - roundTripConfidence) * 50.0;
    final standardScore = baseScore.clamp(0.0, 100.0);

    // Glare stress: contrast effectively reduced by 35%
    final glareContrast = minContrast * 0.65;
    var glareScore = standardScore;
    if (glareContrast < 4.5) glareScore -= (4.5 - glareContrast) * 12.0;
    glareScore = glareScore.clamp(0.0, 100.0);

    // Low lighting: noisy thresholding reduces score by 15-20% on sub-optimal contrast
    final lowLightScore = (standardScore * (minContrast >= 5.0 ? 0.92 : 0.75)).clamp(0.0, 100.0);

    // Angular perspective tilt (30°): reduces effective module area
    final angleTiltScore = (standardScore * (moduleShape == QrModuleShape.square ? 0.95 : 0.88)).clamp(0.0, 100.0);

    // Distance optical blur: softens edges
    final distanceBlurScore = (standardScore * (moduleShape == QrModuleShape.dots ? 0.80 : 0.92)).clamp(0.0, 100.0);

    // Overall weighted composite score
    final overallScore = (standardScore * 0.50 +
            glareScore * 0.15 +
            lowLightScore * 0.15 +
            angleTiltScore * 0.10 +
            distanceBlurScore * 0.10)
        .clamp(0.0, 100.0);

    final isScannable = overallScore >= 55.0 && minContrast >= 3.0 && occlusionRatio <= maxSafeOcclusionRatio;

    if (recommendations.isEmpty) {
      recommendations.add('Optimal configuration: excellent contrast (${minContrast.toStringAsFixed(1)}:1) and robust machine scannability.');
    }

    return ScannabilityReport(
      overallScore: double.parse(overallScore.toStringAsFixed(1)),
      isScannable: isScannable,
      contrastRatio: double.parse(minContrast.toStringAsFixed(2)),
      michelsonContrast: double.parse(michelson.toStringAsFixed(3)),
      logoOcclusionPercentage: double.parse(occlusionPercent.toStringAsFixed(1)),
      maxSafeOcclusionPercentage: double.parse(maxSafeOcclusionPercent.toStringAsFixed(1)),
      quietZoneModules: quietZone,
      quietZoneSufficient: quietZoneSufficient,
      roundTripConfidence: roundTripConfidence,
      warningFlags: warnings,
      recommendations: recommendations,
      simulationScores: SimulatedEnvironmentScore(
        standardLightScore: double.parse(standardScore.toStringAsFixed(1)),
        glareLightingScore: double.parse(glareScore.toStringAsFixed(1)),
        lowLightingScore: double.parse(lowLightScore.toStringAsFixed(1)),
        angleTiltScore: double.parse(angleTiltScore.toStringAsFixed(1)),
        distanceBlurScore: double.parse(distanceBlurScore.toStringAsFixed(1)),
      ),
    );
  }
}
