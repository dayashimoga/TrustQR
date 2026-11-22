import 'dart:math' as math;

/// Gradient type for QR module and eye styling.
enum QrGradientType {
  none,
  linear,
  radial,
}

/// A color stop along a color gradient.
class QrColorStop {
  /// Normalized position of the stop along the gradient axis (0.0 to 1.0).
  final double offset;

  /// ARGB hex color representation (e.g. 0xFF00FFCC).
  final int colorHex;

  const QrColorStop({
    required this.offset,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'offset': offset,
    'colorHex': '0x${colorHex.toRadixString(16).padLeft(8, '0')}',
  };

  factory QrColorStop.fromJson(Map<String, dynamic> json) {
    final hexRaw = json['colorHex'];
    final colorVal = hexRaw is int
        ? hexRaw
        : int.parse(hexRaw.toString().replaceAll('#', '').replaceFirst('0x', ''), radix: 16);
    return QrColorStop(
      offset: (json['offset'] as num).toDouble(),
      colorHex: colorVal,
    );
  }
}

/// Complete color and gradient configuration for QR matrix rendering.
class QrColorConfig {
  /// Default solid foreground color (ARGB).
  final int foregroundColorHex;

  /// Canvas background color (ARGB).
  final int backgroundColorHex;

  /// Type of gradient to apply to dark modules.
  final QrGradientType gradientType;

  /// Angle in degrees for linear gradient (0 = left-to-right, 90 = top-to-bottom, 45 = diagonal).
  final double linearAngleDegrees;

  /// Radius scale for radial gradient (1.0 spans edge to edge).
  final double radialRadius;

  /// Color stops for linear or radial gradient.
  final List<QrColorStop> stops;

  const QrColorConfig({
    this.foregroundColorHex = 0xFF000000,
    this.backgroundColorHex = 0xFFFFFFFF,
    this.gradientType = QrGradientType.none,
    this.linearAngleDegrees = 45.0,
    this.radialRadius = 0.75,
    this.stops = const [],
  });

  /// Factory for standard solid color foreground and background.
  factory QrColorConfig.solid(int foregroundHex, {int backgroundHex = 0xFFFFFFFF}) {
    return QrColorConfig(
      foregroundColorHex: foregroundHex,
      backgroundColorHex: backgroundHex,
      gradientType: QrGradientType.none,
    );
  }

  /// Factory for linear gradient across the matrix.
  factory QrColorConfig.linear(
    List<QrColorStop> stops, {
    double angleDegrees = 45.0,
    int backgroundHex = 0xFFFFFFFF,
  }) {
    return QrColorConfig(
      foregroundColorHex: stops.isNotEmpty ? stops.first.colorHex : 0xFF000000,
      backgroundColorHex: backgroundHex,
      gradientType: QrGradientType.linear,
      linearAngleDegrees: angleDegrees,
      stops: stops,
    );
  }

  /// Factory for radial gradient from center outward.
  factory QrColorConfig.radial(
    List<QrColorStop> stops, {
    double radius = 0.75,
    int backgroundHex = 0xFFFFFFFF,
  }) {
    return QrColorConfig(
      foregroundColorHex: stops.isNotEmpty ? stops.first.colorHex : 0xFF000000,
      backgroundColorHex: backgroundHex,
      gradientType: QrGradientType.radial,
      radialRadius: radius,
      stops: stops,
    );
  }

  /// Samples the ARGB color at normalized coordinates [u, v] (each in range 0.0 to 1.0).
  int getColorAt(double u, double v) {
    if (gradientType == QrGradientType.none || stops.isEmpty) {
      return foregroundColorHex;
    }

    if (stops.length == 1) {
      return stops.first.colorHex;
    }

    if (gradientType == QrGradientType.linear) {
      final rad = linearAngleDegrees * math.pi / 180.0;
      final cosA = math.cos(rad);
      final sinA = math.sin(rad);

      // Project (u - 0.5, v - 0.5) along gradient unit vector
      final du = u - 0.5;
      final dv = v - 0.5;
      final proj = du * cosA + dv * sinA;
      // Map [-0.5, 0.5] to [0.0, 1.0]
      final t = (proj + 0.5).clamp(0.0, 1.0);
      return _interpolateStops(t);
    } else {
      // Radial from center (0.5, 0.5)
      final du = u - 0.5;
      final dv = v - 0.5;
      final dist = math.sqrt(du * du + dv * dv);
      final maxDist = radialRadius * 0.70710678; // Corner distance normalizer
      final t = (maxDist > 0 ? dist / maxDist : 0.0).clamp(0.0, 1.0);
      return _interpolateStops(t);
    }
  }

  /// Interpolates ARGB value at normalized position [t] along stops.
  int _interpolateStops(double t) {
    if (t <= stops.first.offset) return stops.first.colorHex;
    if (t >= stops.last.offset) return stops.last.colorHex;

    for (var i = 0; i < stops.length - 1; i++) {
      final s0 = stops[i];
      final s1 = stops[i + 1];
      if (t >= s0.offset && t <= s1.offset) {
        final span = s1.offset - s0.offset;
        final factor = span > 0 ? (t - s0.offset) / span : 0.0;
        return _lerpArgb(s0.colorHex, s1.colorHex, factor);
      }
    }
    return stops.last.colorHex;
  }

  /// Linear interpolation between two 32-bit ARGB colors.
  static int _lerpArgb(int c1, int c2, double factor) {
    final a1 = (c1 >> 24) & 0xFF;
    final r1 = (c1 >> 16) & 0xFF;
    final g1 = (c1 >> 8) & 0xFF;
    final b1 = c1 & 0xFF;

    final a2 = (c2 >> 24) & 0xFF;
    final r2 = (c2 >> 16) & 0xFF;
    final g2 = (c2 >> 8) & 0xFF;
    final b2 = c2 & 0xFF;

    final a = (a1 + (a2 - a1) * factor).round().clamp(0, 255);
    final r = (r1 + (r2 - r1) * factor).round().clamp(0, 255);
    final g = (g1 + (g2 - g1) * factor).round().clamp(0, 255);
    final b = (b1 + (b2 - b1) * factor).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Computes relative luminance of an ARGB color per ITU-R BT.709.
  static double relativeLuminance(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;

    final rLin = (r <= 0.03928) ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gLin = (g <= 0.03928) ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bLin = (b <= 0.03928) ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
  }

  /// Computes WCAG 2.1 contrast ratio between two ARGB colors (1.0 to 21.0).
  static double contrastRatio(int colorA, int colorB) {
    final lumA = relativeLuminance(colorA);
    final lumB = relativeLuminance(colorB);
    final lighter = math.max(lumA, lumB);
    final darker = math.min(lumA, lumB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Converts ARGB int to CSS hex color (#RRGGBB).
  static String toCssHex(int argb) {
    final r = ((argb >> 16) & 0xFF).toRadixString(16).padLeft(2, '0');
    final g = ((argb >> 8) & 0xFF).toRadixString(16).padLeft(2, '0');
    final b = (argb & 0xFF).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'foregroundColorHex': '0x${foregroundColorHex.toRadixString(16).padLeft(8, '0')}',
    'backgroundColorHex': '0x${backgroundColorHex.toRadixString(16).padLeft(8, '0')}',
    'gradientType': gradientType.name,
    'linearAngleDegrees': linearAngleDegrees,
    'radialRadius': radialRadius,
    'stops': stops.map((s) => s.toJson()).toList(),
  };

  factory QrColorConfig.fromJson(Map<String, dynamic> json) {
    int parseHex(dynamic val, int defaultVal) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      return int.parse(val.toString().replaceAll('#', '').replaceFirst('0x', ''), radix: 16);
    }

    final stopsJson = json['stops'] as List<dynamic>? ?? [];
    return QrColorConfig(
      foregroundColorHex: parseHex(json['foregroundColorHex'], 0xFF000000),
      backgroundColorHex: parseHex(json['backgroundColorHex'], 0xFFFFFFFF),
      gradientType: QrGradientType.values.byName(json['gradientType'] as String? ?? 'none'),
      linearAngleDegrees: (json['linearAngleDegrees'] as num?)?.toDouble() ?? 45.0,
      radialRadius: (json['radialRadius'] as num?)?.toDouble() ?? 0.75,
      stops: stopsJson.map((s) => QrColorStop.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
