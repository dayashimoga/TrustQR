import '../../qr_generator_engine.dart';

/// Pure-Dart resolution-independent vector SVG exporter.
class SvgExporter {
  const SvgExporter();

  /// Exports [matrix] as a scalable vector graphics (SVG) XML document string.
  String export({
    required QrMatrix matrix,
    QrModuleShape moduleShape = QrModuleShape.square,
    QrColorConfig colorConfig = const QrColorConfig(),
    QrEyeStyle eyeStyle = const QrEyeStyle(),
    QrLogoConfig? logoConfig,
    int moduleSize = 10,
    int quietZone = 4,
    double? displayWidth,
    double? displayHeight,
  }) {
    final dim = matrix.dimension;
    final totalModules = dim + quietZone * 2;
    final canvasSize = totalModules * moduleSize;
    final ms = moduleSize.toDouble();
    final qz = quietZone.toDouble();

    final buffer = StringBuffer();

    // SVG Header
    final widthAttr = displayWidth != null ? ' width="$displayWidth"' : ' width="$canvasSize"';
    final heightAttr = displayHeight != null ? ' height="$displayHeight"' : ' height="$canvasSize"';
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $canvasSize $canvasSize"$widthAttr$heightAttr>',
    );

    // Definitions (<defs>) for Gradients
    final hasGradient = colorConfig.gradientType != QrGradientType.none;
    final gradId = 'qr_grad_${matrix.dimension}';
    final moduleFill = hasGradient ? 'url(#$gradId)' : QrColorConfig.toCssHex(colorConfig.foregroundColorHex);
    final bgFill = QrColorConfig.toCssHex(colorConfig.backgroundColorHex);

    if (hasGradient) {
      buffer.writeln('  <defs>');
      if (colorConfig.gradientType == QrGradientType.linear) {
        // Linear gradient
        final rad = colorConfig.linearAngleDegrees * 3.141592653589793 / 180.0;
        final x1 = (50 - 50 * (rad > 0 ? 1 : -1)).clamp(0, 100);
        final y1 = 0;
        final x2 = 100 - x1;
        final y2 = 100;
        buffer.writeln('    <linearGradient id="$gradId" x1="$x1%" y1="$y1%" x2="$x2%" y2="$y2%">');
      } else {
        // Radial gradient
        buffer.writeln('    <radialGradient id="$gradId" cx="50%" cy="50%" r="${(colorConfig.radialRadius * 50).toStringAsFixed(1)}%" fx="50%" fy="50%">');
      }

      if (colorConfig.stops.isNotEmpty) {
        for (final stop in colorConfig.stops) {
          final pct = (stop.offset * 100.0).toStringAsFixed(1);
          final stopColor = QrColorConfig.toCssHex(stop.colorHex);
          buffer.writeln('      <stop offset="$pct%" stop-color="$stopColor" />');
        }
      } else {
        final fgHex = QrColorConfig.toCssHex(colorConfig.foregroundColorHex);
        buffer.writeln('      <stop offset="0%" stop-color="$fgHex" />');
        buffer.writeln('      <stop offset="100%" stop-color="$fgHex" />');
      }

      if (colorConfig.gradientType == QrGradientType.linear) {
        buffer.writeln('    </linearGradient>');
      } else {
        buffer.writeln('    </radialGradient>');
      }
      buffer.writeln('  </defs>');
    }

    // 1. Background
    buffer.writeln('  <rect width="$canvasSize" height="$canvasSize" fill="$bgFill" />');

    // 2. Finder Patterns
    _renderEyePatterns(
      buffer,
      dim: dim,
      ms: ms,
      qz: qz,
      eyeStyle: eyeStyle,
      defaultColor: moduleFill,
      bgColor: bgFill,
    );

    // 3. Logo Cutout Bounds
    final logoCutout = logoConfig?.calculateCutoutModuleBounds(dim);

    // 4. Data Modules
    buffer.writeln('  <!-- Data Modules -->');
    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim; x++) {
        // Skip finder areas
        if (_isFinderModule(x, y, dim)) continue;

        // Skip logo cutout area
        if (logoCutout != null &&
            x >= logoCutout.left &&
            x <= logoCutout.right &&
            y >= logoCutout.top &&
            y <= logoCutout.bottom) {
          continue;
        }

        if (matrix.get(x, y)) {
          final px = (x + qz) * ms;
          final py = (y + qz) * ms;
          _renderModule(buffer, px: px, py: py, ms: ms, shape: moduleShape, fill: moduleFill);
        }
      }
    }

    // 5. Embedded Logo Render
    if (logoCutout != null) {
      final lx = (logoCutout.left + qz) * ms;
      final ly = (logoCutout.top + qz) * ms;
      final lw = logoCutout.width * ms;
      final lh = logoCutout.height * ms;
      final logoBg = QrColorConfig.toCssHex(logoConfig?.backgroundColorHex ?? 0xFFFFFFFF);

      buffer.writeln('  <!-- Embedded Logo -->');
      buffer.writeln('  <rect x="$lx" y="$ly" width="$lw" height="$lh" rx="${ms * 0.5}" ry="${ms * 0.5}" fill="$logoBg" />');

      if (logoConfig?.svgPathData != null) {
        final svgFill = QrColorConfig.toCssHex(logoConfig?.svgFillHex ?? colorConfig.foregroundColorHex);
        buffer.writeln('  <g transform="translate($lx, $ly)">');
        buffer.writeln('    <path d="${logoConfig!.svgPathData}" fill="$svgFill" />');
        buffer.writeln('  </g>');
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  bool _isFinderModule(int x, int y, int dim) {
    if (x < 7 && y < 7) return true; // Top-left
    if (x >= dim - 7 && y < 7) return true; // Top-right
    if (x < 7 && y >= dim - 7) return true; // Bottom-left
    return false;
  }

  void _renderEyePatterns(
    StringBuffer buffer, {
    required int dim,
    required double ms,
    required double qz,
    required QrEyeStyle eyeStyle,
    required String defaultColor,
    required String bgColor,
  }) {
    final frameColor = eyeStyle.frameColorHex != null
        ? QrColorConfig.toCssHex(eyeStyle.frameColorHex!)
        : defaultColor;
    final pupilColor = eyeStyle.pupilColorHex != null
        ? QrColorConfig.toCssHex(eyeStyle.pupilColorHex!)
        : defaultColor;

    final corners = [
      [qz * ms, qz * ms], // Top-left
      [(dim - 7 + qz) * ms, qz * ms], // Top-right
      [qz * ms, (dim - 7 + qz) * ms], // Bottom-left
    ];

    buffer.writeln('  <!-- Finder Eye Patterns -->');
    for (final corner in corners) {
      final fx = corner[0];
      final fy = corner[1];

      // 1. Eye Outer Frame (7x7 modules)
      switch (eyeStyle.frameShape) {
        case QrEyeFrameShape.square:
          buffer.writeln('  <path fill-rule="evenodd" d="M $fx $fy h ${7 * ms} v ${7 * ms} h ${-7 * ms} Z M ${fx + ms} ${fy + ms} v ${5 * ms} h ${5 * ms} v ${-5 * ms} Z" fill="$frameColor" />');
          break;
        case QrEyeFrameShape.rounded:
          buffer.writeln('  <rect x="$fx" y="$fy" width="${7 * ms}" height="${7 * ms}" rx="${ms * 1.5}" ry="${ms * 1.5}" fill="$frameColor" />');
          buffer.writeln('  <rect x="${fx + ms}" y="${fy + ms}" width="${5 * ms}" height="${5 * ms}" rx="${ms * 0.8}" ry="${ms * 0.8}" fill="$bgColor" />');
          break;
        case QrEyeFrameShape.circle:
          buffer.writeln('  <circle cx="${fx + 3.5 * ms}" cy="${fy + 3.5 * ms}" r="${3.5 * ms}" fill="$frameColor" />');
          buffer.writeln('  <circle cx="${fx + 3.5 * ms}" cy="${fy + 3.5 * ms}" r="${2.5 * ms}" fill="$bgColor" />');
          break;
        case QrEyeFrameShape.squircle:
          buffer.writeln('  <rect x="$fx" y="$fy" width="${7 * ms}" height="${7 * ms}" rx="${ms * 2.5}" ry="${ms * 2.5}" fill="$frameColor" />');
          buffer.writeln('  <rect x="${fx + ms}" y="${fy + ms}" width="${5 * ms}" height="${5 * ms}" rx="${ms * 1.5}" ry="${ms * 1.5}" fill="$bgColor" />');
          break;
        case QrEyeFrameShape.hexagonal:
          final cx = fx + 3.5 * ms;
          final cy = fy + 3.5 * ms;
          final rOuter = 3.5 * ms;
          final rInner = 2.5 * ms;
          buffer.writeln('  <polygon points="${_polygonPoints(cx, cy, rOuter, 6)}" fill="$frameColor" />');
          buffer.writeln('  <polygon points="${_polygonPoints(cx, cy, rInner, 6)}" fill="$bgColor" />');
          break;
      }

      // 2. Eye Inner Pupil (3x3 modules centered)
      final px = fx + 2.0 * ms;
      final py = fy + 2.0 * ms;
      final cx = fx + 3.5 * ms;
      final cy = fy + 3.5 * ms;

      switch (eyeStyle.pupilShape) {
        case QrEyePupilShape.square:
          buffer.writeln('  <rect x="$px" y="$py" width="${3 * ms}" height="${3 * ms}" fill="$pupilColor" />');
          break;
        case QrEyePupilShape.rounded:
          buffer.writeln('  <rect x="$px" y="$py" width="${3 * ms}" height="${3 * ms}" rx="${ms * 0.6}" ry="${ms * 0.6}" fill="$pupilColor" />');
          break;
        case QrEyePupilShape.circle:
          buffer.writeln('  <circle cx="$cx" cy="$cy" r="${1.5 * ms}" fill="$pupilColor" />');
          break;
        case QrEyePupilShape.diamond:
          buffer.writeln('  <polygon points="$cx,$py ${fx + 5 * ms},$cy $cx,${fy + 5 * ms} $px,$cy" fill="$pupilColor" />');
          break;
      }
    }
  }

  void _renderModule(
    StringBuffer buffer, {
    required double px,
    required double py,
    required double ms,
    required QrModuleShape shape,
    required String fill,
  }) {
    switch (shape) {
      case QrModuleShape.square:
        buffer.writeln('  <rect x="$px" y="$py" width="$ms" height="$ms" fill="$fill" />');
        break;
      case QrModuleShape.rounded:
        buffer.writeln('  <rect x="$px" y="$py" width="$ms" height="$ms" rx="${ms * 0.3}" ry="${ms * 0.3}" fill="$fill" />');
        break;
      case QrModuleShape.dots:
        buffer.writeln('  <circle cx="${px + ms / 2}" cy="${py + ms / 2}" r="${ms * 0.45}" fill="$fill" />');
        break;
      case QrModuleShape.diamond:
        final cx = px + ms / 2;
        final cy = py + ms / 2;
        buffer.writeln('  <polygon points="$cx,$py ${px + ms},$cy $cx,${py + ms} $px,$cy" fill="$fill" />');
        break;
      case QrModuleShape.liquid:
        buffer.writeln('  <rect x="$px" y="$py" width="$ms" height="$ms" rx="${ms * 0.45}" ry="${ms * 0.45}" fill="$fill" />');
        break;
      case QrModuleShape.cyberGrid:
        final c = ms * 0.25;
        buffer.writeln(
          '  <polygon points="${px + c},$py ${px + ms - c},$py ${px + ms},${py + c} ${px + ms},${py + ms - c} ${px + ms - c},${py + ms} ${px + c},${py + ms} $px,${py + ms - c} $px,${py + c}" fill="$fill" />',
        );
        break;
    }
  }

  String _polygonPoints(double cx, double cy, double radius, int sides) {
    final points = <String>[];
    for (var i = 0; i < sides; i++) {
      final x = cx + radius * (i == 0 || i == 3 ? 0 : (i == 1 || i == 2 ? 0.866025 : -0.866025));
      final y = cy + radius * (i == 0 ? -1 : (i == 3 ? 1 : 0.5 * (i == 1 || i == 5 ? -1 : 1)));
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return points.join(' ');
  }
}
