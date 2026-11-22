import 'dart:math' as math;
import '../../qr_generator_engine.dart';

/// Standards-compliant pure-Dart artistic rasterizer for QR matrices.
class QrMatrixRasterizer {
  const QrMatrixRasterizer();

  /// Rasterizes [matrix] into a [QrGeneratedImage] with artistic styling.
  QrGeneratedImage rasterize({
    required QrMatrix matrix,
    QrModuleShape moduleShape = QrModuleShape.square,
    QrColorConfig colorConfig = const QrColorConfig(),
    QrEyeStyle eyeStyle = const QrEyeStyle(),
    QrLogoConfig? logoConfig,
    int moduleSize = 10,
    int quietZone = 4,
  }) {
    final dim = matrix.dimension;
    final totalModules = dim + 2 * quietZone;
    final imgWidth = totalModules * moduleSize;
    final imgHeight = totalModules * moduleSize;

    final image = QrGeneratedImage(width: imgWidth, height: imgHeight);

    // 1. Fill entire background
    image.fillRect(0, 0, imgWidth, imgHeight, colorConfig.backgroundColorHex);

    // 2. Render 3 Finder Eyes (Top-Left, Top-Right, Bottom-Left)
    _renderFinderEye(image, quietZone, 0, 0, dim, eyeStyle, colorConfig, moduleSize);
    _renderFinderEye(image, quietZone, dim - 7, 0, dim, eyeStyle, colorConfig, moduleSize);
    _renderFinderEye(image, quietZone, 0, dim - 7, dim, eyeStyle, colorConfig, moduleSize);

    // 3. Render Data / Alignment / Timing modules
    for (var my = 0; my < dim; my++) {
      for (var mx = 0; mx < dim; mx++) {
        // Skip finder eye 7x7 regions (handled separately)
        if (_isInsideFinder(mx, my, dim)) continue;

        // Skip logo cutout modules (handled separately)
        if (matrix.getType(mx, my) == QrModuleType.logoArea) continue;

        if (matrix.get(mx, my)) {
          final u = (mx + 0.5) / dim;
          final v = (my + 0.5) / dim;
          final color = colorConfig.getColorAt(u, v);
          final px = (quietZone + mx) * moduleSize;
          final py = (quietZone + my) * moduleSize;

          _renderModule(
            image,
            px,
            py,
            mx,
            my,
            matrix,
            moduleShape,
            color,
            moduleSize,
          );
        }
      }
    }

    // 4. Render center logo area (if configured)
    if (logoConfig != null) {
      _renderLogoCutout(image, quietZone, dim, logoConfig, moduleSize);
    }

    return image;
  }

  bool _isInsideFinder(int x, int y, int dim) {
    if (x < 7 && y < 7) return true; // Top-Left
    if (x >= dim - 7 && y < 7) return true; // Top-Right
    if (x < 7 && y >= dim - 7) return true; // Bottom-Left
    return false;
  }

  void _renderFinderEye(
    QrGeneratedImage image,
    int quietZone,
    int eyeModuleX,
    int eyeModuleY,
    int dim,
    QrEyeStyle eyeStyle,
    QrColorConfig colorConfig,
    int ms,
  ) {
    final px = (quietZone + eyeModuleX) * ms;
    final py = (quietZone + eyeModuleY) * ms;
    final eyeSize = 7 * ms;

    final u = (eyeModuleX + 3.5) / dim;
    final v = (eyeModuleY + 3.5) / dim;
    final defaultColor = colorConfig.getColorAt(u, v);
    final frameColor = eyeStyle.frameColorHex ?? defaultColor;
    final pupilColor = eyeStyle.pupilColorHex ?? defaultColor;
    final bgColor = colorConfig.backgroundColorHex;

    // Draw outer frame (7x7 with inner 5x5 cutout)
    _drawEyeFrame(
      image,
      px,
      py,
      eyeSize,
      eyeStyle.frameShape,
      frameColor,
      bgColor,
      ms,
    );

    // Draw inner pupil (3x3 at offset 2 modules)
    final pupilPx = px + 2 * ms;
    final pupilPy = py + 2 * ms;
    final pupilSize = 3 * ms;

    _drawEyePupil(
      image,
      pupilPx,
      pupilPy,
      pupilSize,
      eyeStyle.pupilShape,
      pupilColor,
      ms,
    );
  }

  void _drawEyeFrame(
    QrGeneratedImage image,
    int x0,
    int y0,
    int size,
    QrEyeFrameShape shape,
    int frameColor,
    int bgColor,
    int ms,
  ) {
    final outerR = size / 2.0;
    final innerR = (5 * ms) / 2.0;

    for (var dy = 0; dy < size; dy++) {
      for (var dx = 0; dx < size; dx++) {
        final curX = x0 + dx;
        final curY = y0 + dy;
        final relX = (dx + 0.5) - outerR;
        final relY = (dy + 0.5) - outerR;

        var inOuter = false;
        var inInner = false;

        switch (shape) {
          case QrEyeFrameShape.square:
            inOuter = true;
            inInner = dx >= ms && dx < size - ms && dy >= ms && dy < size - ms;
            break;

          case QrEyeFrameShape.rounded:
            final rOuter = 0.6 * ms;
            final rInner = 0.3 * ms;
            inOuter = _isInsideRoundedRect(dx.toDouble(), dy.toDouble(), size.toDouble(), size.toDouble(), rOuter);
            inInner = _isInsideRoundedRect(dx - ms.toDouble(), dy - ms.toDouble(), (5 * ms).toDouble(), (5 * ms).toDouble(), rInner);
            break;

          case QrEyeFrameShape.circle:
            final dist = math.sqrt(relX * relX + relY * relY);
            inOuter = dist <= outerR;
            inInner = dist < innerR;
            break;

          case QrEyeFrameShape.squircle:
            final normX = relX / outerR;
            final normY = relY / outerR;
            final superDist = math.pow(normX, 4) + math.pow(normY, 4);
            inOuter = superDist <= 1.0;

            final innerNormX = relX / innerR;
            final innerNormY = relY / innerR;
            inInner = (math.pow(innerNormX, 4) + math.pow(innerNormY, 4)) < 1.0;
            break;

          case QrEyeFrameShape.hexagonal:
            inOuter = _isInsideHexagon(relX, relY, outerR);
            inInner = _isInsideHexagon(relX, relY, innerR);
            break;
        }

        if (inOuter && !inInner) {
          image.setPixel(curX, curY, frameColor);
        } else if (inInner) {
          image.setPixel(curX, curY, bgColor);
        }
      }
    }
  }

  void _drawEyePupil(
    QrGeneratedImage image,
    int x0,
    int y0,
    int size,
    QrEyePupilShape shape,
    int pupilColor,
    int ms,
  ) {
    final r = size / 2.0;
    for (var dy = 0; dy < size; dy++) {
      for (var dx = 0; dx < size; dx++) {
        final curX = x0 + dx;
        final curY = y0 + dy;
        final relX = (dx + 0.5) - r;
        final relY = (dy + 0.5) - r;

        var inside = false;
        switch (shape) {
          case QrEyePupilShape.square:
            inside = true;
            break;
          case QrEyePupilShape.rounded:
            inside = _isInsideRoundedRect(dx.toDouble(), dy.toDouble(), size.toDouble(), size.toDouble(), 0.8 * ms);
            break;
          case QrEyePupilShape.circle:
            inside = (relX * relX + relY * relY) <= (r * r);
            break;
          case QrEyePupilShape.diamond:
            inside = (relX.abs() / r + relY.abs() / r) <= 1.0;
            break;
        }

        if (inside) {
          image.setPixel(curX, curY, pupilColor);
        }
      }
    }
  }

  bool _isInsideRoundedRect(double x, double y, double w, double h, double r) {
    if (x < 0 || y < 0 || x >= w || y >= h) return false;
    // Corners
    if (x < r && y < r) {
      return (x - r) * (x - r) + (y - r) * (y - r) <= r * r;
    }
    if (x >= w - r && y < r) {
      return (x - (w - r)) * (x - (w - r)) + (y - r) * (y - r) <= r * r;
    }
    if (x < r && y >= h - r) {
      return (x - r) * (x - r) + (y - (h - r)) * (y - (h - r)) <= r * r;
    }
    if (x >= w - r && y >= h - r) {
      return (x - (w - r)) * (x - (w - r)) + (y - (h - r)) * (y - (h - r)) <= r * r;
    }
    return true;
  }

  bool _isInsideHexagon(double x, double y, double r) {
    final q2x = x.abs();
    final q2y = y.abs();
    if (q2x > r || q2y > r * 0.8660254) return false;
    return 2.0 * 0.8660254 * r - 0.8660254 * q2x - q2y >= 0;
  }

  void _renderModule(
    QrGeneratedImage image,
    int px,
    int py,
    int mx,
    int my,
    QrMatrix matrix,
    QrModuleShape shape,
    int color,
    int ms,
  ) {
    switch (shape) {
      case QrModuleShape.square:
        image.fillRect(px, py, ms, ms, color);
        break;

      case QrModuleShape.rounded:
        final r = ms * 0.35;
        for (var dy = 0; dy < ms; dy++) {
          for (var dx = 0; dx < ms; dx++) {
            if (_isInsideRoundedRect(dx.toDouble(), dy.toDouble(), ms.toDouble(), ms.toDouble(), r)) {
              image.setPixel(px + dx, py + dy, color);
            }
          }
        }
        break;

      case QrModuleShape.dots:
        final center = ms / 2.0;
        final radius = ms * 0.44;
        final r2 = radius * radius;
        for (var dy = 0; dy < ms; dy++) {
          for (var dx = 0; dx < ms; dx++) {
            final relX = (dx + 0.5) - center;
            final relY = (dy + 0.5) - center;
            if (relX * relX + relY * relY <= r2) {
              image.setPixel(px + dx, py + dy, color);
            }
          }
        }
        break;

      case QrModuleShape.diamond:
        final center = ms / 2.0;
        for (var dy = 0; dy < ms; dy++) {
          for (var dx = 0; dx < ms; dx++) {
            final relX = (dx + 0.5) - center;
            final relY = (dy + 0.5) - center;
            if ((relX.abs() / center + relY.abs() / center) <= 1.0) {
              image.setPixel(px + dx, py + dy, color);
            }
          }
        }
        break;

      case QrModuleShape.cyberGrid:
        // Cyber square with chamfered corners and center accent
        for (var dy = 0; dy < ms; dy++) {
          for (var dx = 0; dx < ms; dx++) {
            final isCornerCut = (dx == 0 && dy == 0) ||
                (dx == ms - 1 && dy == 0) ||
                (dx == 0 && dy == ms - 1) ||
                (dx == ms - 1 && dy == ms - 1);
            if (!isCornerCut) {
              image.setPixel(px + dx, py + dy, color);
            }
          }
        }
        break;

      case QrModuleShape.liquid:
        // Organic connected liquid modules: bridges adjacent dark neighbors and rounds outer corners
        final topDark = my > 0 && matrix.get(mx, my - 1);
        final bottomDark = my < matrix.dimension - 1 && matrix.get(mx, my + 1);
        final leftDark = mx > 0 && matrix.get(mx - 1, my);
        final rightDark = mx < matrix.dimension - 1 && matrix.get(mx + 1, my);

        final cornerR = ms * 0.45;

        for (var dy = 0; dy < ms; dy++) {
          for (var dx = 0; dx < ms; dx++) {
            var inside = true;

            // Top-Left corner
            if (dx < cornerR && dy < cornerR && !topDark && !leftDark) {
              final d = (dx - cornerR) * (dx - cornerR) + (dy - cornerR) * (dy - cornerR);
              if (d > cornerR * cornerR) inside = false;
            }
            // Top-Right corner
            if (dx >= ms - cornerR && dy < cornerR && !topDark && !rightDark) {
              final d = (dx - (ms - cornerR)) * (dx - (ms - cornerR)) + (dy - cornerR) * (dy - cornerR);
              if (d > cornerR * cornerR) inside = false;
            }
            // Bottom-Left corner
            if (dx < cornerR && dy >= ms - cornerR && !bottomDark && !leftDark) {
              final d = (dx - cornerR) * (dx - cornerR) + (dy - (ms - cornerR)) * (dy - (ms - cornerR));
              if (d > cornerR * cornerR) inside = false;
            }
            // Bottom-Right corner
            if (dx >= ms - cornerR && dy >= ms - cornerR && !bottomDark && !rightDark) {
              final d = (dx - (ms - cornerR)) * (dx - (ms - cornerR)) + (dy - (ms - cornerR)) * (dy - (ms - cornerR));
              if (d > cornerR * cornerR) inside = false;
            }

            if (inside) {
              image.setPixel(px + dx, py + dy, color);
            }
          }
        }
        break;
    }
  }

  void _renderLogoCutout(
    QrGeneratedImage image,
    int quietZone,
    int dim,
    QrLogoConfig logoConfig,
    int ms,
  ) {
    final bounds = logoConfig.calculateCutoutModuleBounds(dim);
    final px = (quietZone + bounds.left) * ms;
    final py = (quietZone + bounds.top) * ms;
    final w = bounds.width * ms;
    final h = bounds.height * ms;
    final bgColor = logoConfig.backgroundColorHex ?? 0xFFFFFFFF;
    final r = logoConfig.borderRadius.toDouble();

    for (var dy = 0; dy < h; dy++) {
      for (var dx = 0; dx < w; dx++) {
        if (_isInsideRoundedRect(dx.toDouble(), dy.toDouble(), w.toDouble(), h.toDouble(), r)) {
          image.setPixel(px + dx, py + dy, bgColor);
        }
      }
    }
  }
}
