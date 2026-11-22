import 'dart:typed_data';
import '../../qr_generator_engine.dart';

/// Exception thrown when a configured logo violates QR code occlusion safety limits.
class QrLogoOcclusionException implements Exception {
  final String message;
  final double occlusionRatio;
  final double maxAllowedRatio;

  const QrLogoOcclusionException({
    required this.message,
    required this.occlusionRatio,
    required this.maxAllowedRatio,
  });

  @override
  String toString() => 'QrLogoOcclusionException: $message (occlusion: ${(occlusionRatio * 100).toStringAsFixed(1)}%, max: ${(maxAllowedRatio * 100).toStringAsFixed(1)}%)';
}

/// Bounding rectangle in module coordinates.
class ModuleRect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const ModuleRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  int get width => right - left + 1;
  int get height => bottom - top + 1;
  int get moduleCount => width * height;
}

/// Configuration for embedding center logos or icons inside a QR code.
class QrLogoConfig {
  /// Raw RGBA / PNG bytes of the logo to embed (optional in matrix-only mode).
  final Uint8List? rawBytes;

  /// Width and height of the logo relative to the total QR matrix dimension (e.g. 0.20 = 20%).
  final double sizeRatio;

  /// Clear padding around the logo in modules (quiet zone within the QR data area).
  final int quietZoneModules;

  /// Corner radius in pixels for the logo cutout box.
  final int borderRadius;

  /// Background color fill behind the logo (ARGB, e.g. 0xFFFFFFFF for crisp white).
  final int? backgroundColorHex;

  /// Whether to clear underlying QR modules in the matrix to prevent visual clashes.
  final bool clearUnderlyingModules;

  const QrLogoConfig({
    this.rawBytes,
    this.sizeRatio = 0.20,
    this.quietZoneModules = 1,
    this.borderRadius = 6,
    this.backgroundColorHex = 0xFFFFFFFF,
    this.clearUnderlyingModules = true,
  });

  /// Computes the total cutout width/height in modules (including inner quiet zone).
  int calculateCutoutSizeInModules(int dimension) {
    var rawSize = (dimension * sizeRatio).round();
    if (rawSize < 1) rawSize = 1;
    // Align parity so logo is centered symmetrically
    if ((dimension - rawSize) % 2 != 0) {
      rawSize++;
    }
    final totalSize = rawSize + 2 * quietZoneModules;
    // Cap to ensure it never touches finder patterns
    final maxSafeSize = dimension - 16;
    return totalSize.clamp(1, maxSafeSize > 1 ? maxSafeSize : 1);
  }

  /// Calculates the bounding module rectangle for the logo cutout.
  ModuleRect calculateCutoutModuleBounds(int dimension) {
    final size = calculateCutoutSizeInModules(dimension);
    final start = (dimension - size) ~/ 2;
    return ModuleRect(
      left: start,
      top: start,
      right: start + size - 1,
      bottom: start + size - 1,
    );
  }

  /// Calculates the ratio of modules occluded by the logo relative to total modules.
  double calculateOcclusionRatio(int dimension) {
    final bounds = calculateCutoutModuleBounds(dimension);
    return bounds.moduleCount / (dimension * dimension);
  }

  /// Returns the maximum safe occlusion ratio for the specified error correction level.
  static double getMaxAllowedOcclusion(QrErrorCorrectionLevel eccLevel) {
    switch (eccLevel) {
      case QrErrorCorrectionLevel.low:
        return 0.05; // 5% (budget is 7%)
      case QrErrorCorrectionLevel.medium:
        return 0.12; // 12% (budget is 15%)
      case QrErrorCorrectionLevel.quartile:
        return 0.20; // 20% (budget is 25%)
      case QrErrorCorrectionLevel.high:
        return 0.26; // 26% (budget is 30%)
    }
  }

  /// Validates that the logo size does not exceed the ECC budget or collide with finder patterns.
  bool validateOcclusion(int dimension, QrErrorCorrectionLevel eccLevel) {
    final ratio = calculateOcclusionRatio(dimension);
    final maxAllowed = getMaxAllowedOcclusion(eccLevel);
    if (ratio > maxAllowed) {
      return false;
    }

    final bounds = calculateCutoutModuleBounds(dimension);
    // Finder patterns are 8x8 in 3 corners:
    // Top-left: [0..7, 0..7]
    if (bounds.left < 8 && bounds.top < 8) return false;
    // Top-right: [dim - 8..dim - 1, 0..7]
    if (bounds.right >= dimension - 8 && bounds.top < 8) return false;
    // Bottom-left: [0..7, dim - 8..dim - 1]
    if (bounds.left < 8 && bounds.bottom >= dimension - 8) return false;

    return true;
  }

  /// Carves out the logo area in [matrix], setting modules to light and marking type [QrModuleType.logoArea].
  void carveLogoArea(QrMatrix matrix) {
    if (!clearUnderlyingModules) return;

    final bounds = calculateCutoutModuleBounds(matrix.dimension);
    for (var y = bounds.top; y <= bounds.bottom; y++) {
      for (var x = bounds.left; x <= bounds.right; x++) {
        matrix.set(x, y, false, type: QrModuleType.logoArea);
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'sizeRatio': sizeRatio,
    'quietZoneModules': quietZoneModules,
    'borderRadius': borderRadius,
    'backgroundColorHex': backgroundColorHex != null
        ? '0x${backgroundColorHex!.toRadixString(16).padLeft(8, '0')}'
        : null,
    'clearUnderlyingModules': clearUnderlyingModules,
  };

  factory QrLogoConfig.fromJson(Map<String, dynamic> json) {
    int? parseHex(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.parse(val.toString().replaceAll('#', '').replaceFirst('0x', ''), radix: 16);
    }

    return QrLogoConfig(
      sizeRatio: (json['sizeRatio'] as num?)?.toDouble() ?? 0.20,
      quietZoneModules: json['quietZoneModules'] as int? ?? 1,
      borderRadius: json['borderRadius'] as int? ?? 6,
      backgroundColorHex: parseHex(json['backgroundColorHex']),
      clearUnderlyingModules: json['clearUnderlyingModules'] as bool? ?? true,
    );
  }
}
