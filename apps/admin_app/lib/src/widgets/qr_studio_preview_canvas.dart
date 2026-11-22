import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import '../state/studio_controller.dart';

/// Interactive preview canvas rendering the styled QR code in real-time with export controls.
class QrStudioPreviewCanvas extends StatelessWidget {
  final StudioController controller;

  const QrStudioPreviewCanvas({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final matrix = controller.currentMatrix;
        final image = controller.currentImage;

        return CyberGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Live QR Matrix Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberTokens.neonCyan,
                    ),
                  ),
                  if (controller.isTrustQrEnabled)
                    const CyberBadge(
                      text: 'TRUSTQR SIGNED',
                      type: CyberBadgeType.safe,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Central QR Preview Box
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(controller.backgroundColorHex),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CyberTokens.neonCyan.withAlpha(128), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: CyberTokens.neonCyan.withAlpha(38),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: matrix == null || image == null
                      ? const Center(child: CircularProgressIndicator())
                      : CustomPaint(
                          painter: _QrCanvasPainter(
                            image: image,
                            matrix: matrix,
                            controller: controller,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Export Action Buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  CyberButton(
                    key: const Key('export_png_button'),
                    label: 'Export PNG (300 DPI)',
                    icon: Icons.image,
                    variant: CyberButtonVariant.primary,
                    onPressed: () {
                      controller.exportPng();
                      _showExportNotification(context);
                    },
                  ),
                  CyberButton(
                    key: const Key('export_svg_button'),
                    label: 'Export Vector SVG',
                    icon: Icons.code,
                    variant: CyberButtonVariant.secondary,
                    onPressed: () {
                      controller.exportSvg();
                      _showExportNotification(context);
                    },
                  ),
                  CyberButton(
                    key: const Key('export_pdf_button'),
                    label: 'Print PDF',
                    icon: Icons.picture_as_pdf,
                    variant: CyberButtonVariant.secondary,
                    onPressed: () {
                      controller.exportPdf();
                      _showExportNotification(context);
                    },
                  ),
                  CyberButton(
                    key: const Key('export_bmp_button'),
                    label: '24-bit BMP',
                    icon: Icons.file_present,
                    variant: CyberButtonVariant.secondary,
                    onPressed: () {
                      controller.exportBmp();
                      _showExportNotification(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Export Status Message
              if (controller.lastExportMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CyberTokens.obsidianBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CyberTokens.neonEmerald),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: CyberTokens.neonEmerald, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.lastExportMessage!,
                          style: const TextStyle(fontSize: 11, color: CyberTokens.neonEmerald),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ASCII Matrix Representation Collapsible Box
              ExpansionTile(
                initiallyExpanded: true,
                title: const Text('ASCII Matrix Diagnostic', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CyberTokens.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.matrixRepresentation,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: CyberTokens.neonCyan),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportNotification(BuildContext context) {
    final msg = controller.lastExportMessage ?? 'File exported successfully';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: CyberTokens.slateCard,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _QrCanvasPainter extends CustomPainter {
  final QrGeneratedImage image;
  final QrMatrix matrix;
  final StudioController controller;

  _QrCanvasPainter({
    required this.image,
    required this.matrix,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dim = matrix.dimension;
    const quietZone = 4;
    final totalModules = dim + 2 * quietZone;
    final moduleSize = size.width / totalModules;

    final paintFg = Paint()..style = PaintingStyle.fill;
    final paintEye = Paint()..style = PaintingStyle.fill;

    // Draw data modules
    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim; x++) {
        // Skip finder eyes (handled separately)
        if (_isFinder(x, y, dim)) continue;

        // Skip logo cutout
        if (matrix.getType(x, y) == QrModuleType.logoArea) continue;

        if (matrix.get(x, y)) {
          final px = (x + quietZone) * moduleSize;
          final py = (y + quietZone) * moduleSize;
          paintFg.color = Color(controller.foregroundColorHex);

          _drawModule(canvas, px, py, moduleSize, controller.moduleShape, paintFg);
        }
      }
    }

    // Draw 3 Finder Eyes
    paintEye.color = Color(controller.eyeFrameColorHex ?? controller.foregroundColorHex);
    _drawEye(canvas, quietZone * moduleSize, quietZone * moduleSize, moduleSize, paintEye);
    _drawEye(canvas, (quietZone + dim - 7) * moduleSize, quietZone * moduleSize, moduleSize, paintEye);
    _drawEye(canvas, quietZone * moduleSize, (quietZone + dim - 7) * moduleSize, moduleSize, paintEye);

    // Draw logo area if active
    if (controller.hasLogo) {
      final logoWidth = dim * controller.logoSizeRatio * moduleSize;
      final logoOffset = (size.width - logoWidth) / 2;
      final logoRect = Rect.fromLTWH(logoOffset, logoOffset, logoWidth, logoWidth);

      final bgPaint = Paint()..color = Color(controller.backgroundColorHex);
      final borderPaint = Paint()
        ..color = CyberTokens.neonAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(RRect.fromRectAndRadius(logoRect, const Radius.circular(6)), bgPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(logoRect, const Radius.circular(6)), borderPaint);
    }
  }

  bool _isFinder(int x, int y, int dim) {
    if (x < 7 && y < 7) return true;
    if (x >= dim - 7 && y < 7) return true;
    if (x < 7 && y >= dim - 7) return true;
    return false;
  }

  void _drawModule(Canvas canvas, double px, double py, double ms, QrModuleShape shape, Paint paint) {
    final rect = Rect.fromLTWH(px, py, ms, ms);
    switch (shape) {
      case QrModuleShape.square:
        canvas.drawRect(rect, paint);
        break;
      case QrModuleShape.rounded:
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(ms * 0.3)), paint);
        break;
      case QrModuleShape.dots:
        canvas.drawCircle(Offset(px + ms / 2, py + ms / 2), ms * 0.42, paint);
        break;
      case QrModuleShape.diamond:
        final path = Path()
          ..moveTo(px + ms / 2, py)
          ..lineTo(px + ms, py + ms / 2)
          ..lineTo(px + ms / 2, py + ms)
          ..lineTo(px, py + ms / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case QrModuleShape.liquid:
      case QrModuleShape.cyberGrid:
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(ms * 0.15)), paint);
        break;
    }
  }

  void _drawEye(Canvas canvas, double px, double py, double ms, Paint paint) {
    // 7x7 outer frame
    final outerRect = Rect.fromLTWH(px, py, 7 * ms, 7 * ms);
    final innerCutout = Rect.fromLTWH(px + ms, py + ms, 5 * ms, 5 * ms);
    final pupilRect = Rect.fromLTWH(px + 2 * ms, py + 2 * ms, 3 * ms, 3 * ms);

    final bgPaint = Paint()..color = Color(controller.backgroundColorHex);

    if (controller.eyeFrameShape == QrEyeFrameShape.circle) {
      canvas.drawCircle(Offset(px + 3.5 * ms, py + 3.5 * ms), 3.5 * ms, paint);
      canvas.drawCircle(Offset(px + 3.5 * ms, py + 3.5 * ms), 2.5 * ms, bgPaint);
    } else {
      canvas.drawRect(outerRect, paint);
      canvas.drawRect(innerCutout, bgPaint);
    }

    // Pupil
    if (controller.eyePupilShape == QrEyePupilShape.diamond) {
      final cx = px + 3.5 * ms;
      final cy = py + 3.5 * ms;
      final path = Path()
        ..moveTo(cx, cy - 1.5 * ms)
        ..lineTo(cx + 1.5 * ms, cy)
        ..lineTo(cx, cy + 1.5 * ms)
        ..lineTo(cx - 1.5 * ms, cy)
        ..close();
      canvas.drawPath(path, paint);
    } else if (controller.eyePupilShape == QrEyePupilShape.circle) {
      canvas.drawCircle(Offset(px + 3.5 * ms, py + 3.5 * ms), 1.5 * ms, paint);
    } else {
      canvas.drawRect(pupilRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) => true;
}
