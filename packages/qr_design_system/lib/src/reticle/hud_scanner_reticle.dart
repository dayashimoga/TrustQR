import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../accessibility/cyber_accessibility.dart';
import '../l10n/cyber_localizations.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';

/// State of the interactive scanner HUD reticle.
enum ScannerHudState {
  /// Waiting for viewfinder input (cyan corners, steady).
  idle,

  /// Actively analyzing camera or image frames (animated laser sweep).
  scanning,

  /// Payload verified safe or authentic TrustQR (emerald green glow).
  safe,

  /// Suspicious threat detected or low confidence (amber warning).
  warning,

  /// Malicious threat blocked or signature invalid (crimson red alarm).
  threat,
}

/// Interactive futuristic HUD scanner reticle with animated corner tracking brackets,
/// laser sweep line, threat state transitions, WCAG semantics, and reduced-motion support.
class HudScannerReticle extends StatefulWidget {
  final ScannerHudState state;
  final double reticleSize;
  final double cornerLength;
  final double cornerStrokeWidth;
  final bool showLaserSweep;
  final bool showCrosshair;
  final String? statusText;
  final Widget? centerOverlay;
  final bool? reducedMotion;

  const HudScannerReticle({
    super.key,
    this.state = ScannerHudState.scanning,
    this.reticleSize = 260.0,
    this.cornerLength = 32.0,
    this.cornerStrokeWidth = 3.5,
    this.showLaserSweep = true,
    this.showCrosshair = true,
    this.statusText,
    this.centerOverlay,
    this.reducedMotion,
  });

  @override
  State<HudScannerReticle> createState() => _HudScannerReticleState();
}

class _HudScannerReticleState extends State<HudScannerReticle> with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: CyberTokens.durationSweep,
    );
    _sweepAnimation = CurvedAnimation(
      parent: _sweepController,
      curve: Curves.easeInOut,
    );

    if (widget.state == ScannerHudState.scanning && widget.reducedMotion != true) {
      _sweepController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HudScannerReticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isReduced = widget.reducedMotion ?? false;
    if (widget.state == ScannerHudState.scanning && !isReduced && !_sweepController.isAnimating) {
      _sweepController.repeat(reverse: true);
    } else if ((widget.state != ScannerHudState.scanning || isReduced) && _sweepController.isAnimating) {
      _sweepController.stop();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  Color _getStateColor() {
    switch (widget.state) {
      case ScannerHudState.idle:
        return CyberColors.neonCyan;
      case ScannerHudState.scanning:
        return CyberColors.neonCyan;
      case ScannerHudState.safe:
        return CyberColors.neonEmerald;
      case ScannerHudState.warning:
        return CyberColors.neonAmber;
      case ScannerHudState.threat:
        return CyberColors.neonCrimson;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CyberLocalizations.of(context);
    final isReducedMotion = widget.reducedMotion ?? CyberAccessibility.isReducedMotion(context);

    // Adjust controller if reduced motion dynamically enabled
    if (isReducedMotion && _sweepController.isAnimating) {
      _sweepController.stop();
    } else if (!isReducedMotion && widget.state == ScannerHudState.scanning && !_sweepController.isAnimating) {
      _sweepController.repeat(reverse: true);
    }

    final stateColor = _getStateColor();
    final statusText = widget.statusText ?? localizations.reticleStatus(widget.state);

    final sweepPosition = isReducedMotion
        ? (widget.state == ScannerHudState.scanning ? 0.5 : null)
        : (widget.state == ScannerHudState.scanning ? _sweepAnimation.value : null);

    return Semantics(
      container: true,
      liveRegion: true,
      label: localizations.a11yScannerReticle,
      value: statusText,
      hint: localizations.a11yScannerReticleHint,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.reticleSize,
              height: widget.reticleSize,
              child: AnimatedBuilder(
                animation: _sweepAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _HudReticlePainter(
                      stateColor: stateColor,
                      cornerLength: widget.cornerLength,
                      strokeWidth: widget.cornerStrokeWidth,
                      sweepPosition: widget.showLaserSweep ? sweepPosition : null,
                      showCrosshair: widget.showCrosshair,
                    ),
                    child: widget.centerOverlay != null
                        ? Center(child: widget.centerOverlay)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: CyberTokens.spacingMd),
            // HUD Status Telemetry Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: CyberColors.obsidianBackground.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(CyberTokens.radiusPill),
                border: Border.all(color: stateColor.withValues(alpha: 0.5), width: 1.0),
                boxShadow: CyberTokens.neonGlow(stateColor, blur: 8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: stateColor,
                      shape: BoxShape.circle,
                      boxShadow: CyberTokens.neonGlow(stateColor, blur: 4.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: CyberTypography.monospace(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: stateColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudReticlePainter extends CustomPainter {
  final Color stateColor;
  final double cornerLength;
  final double strokeWidth;
  final double? sweepPosition;
  final bool showCrosshair;

  _HudReticlePainter({
    required this.stateColor,
    required this.cornerLength,
    required this.strokeWidth,
    required this.sweepPosition,
    required this.showCrosshair,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Corner Paint (Cyber Brackets)
    final cornerPaint = Paint()
      ..color = stateColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Subtle guide grid paint
    final guidePaint = Paint()
      ..color = stateColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw full outer bounding guide (faint)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), guidePaint);

    // Draw 4 corner brackets
    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLength, 0), cornerPaint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, h), Offset(cornerLength, h), cornerPaint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(w, h), Offset(w - cornerLength, h), cornerPaint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLength), cornerPaint);

    // Center Crosshair target
    if (showCrosshair) {
      final crosshairPaint = Paint()
        ..color = stateColor.withValues(alpha: 0.40)
        ..strokeWidth = 1.5;
      const crossSize = 12.0;
      final cx = w / 2;
      final cy = h / 2;

      canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx - 3, cy), crosshairPaint);
      canvas.drawLine(Offset(cx + 3, cy), Offset(cx + crossSize, cy), crosshairPaint);
      canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy - 3), crosshairPaint);
      canvas.drawLine(Offset(cx, cy + 3), Offset(cx, cy + crossSize), crosshairPaint);
    }

    // Animated Laser Sweep Line & Gradient Trail
    if (sweepPosition != null) {
      final y = sweepPosition! * h;
      final laserPaint = Paint()
        ..color = stateColor
        ..strokeWidth = 2.0;

      // Glow beam
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            stateColor.withValues(alpha: 0.0),
            stateColor.withValues(alpha: 0.25),
          ],
        ).createShader(Rect.fromLTWH(0, math.max(0, y - 24), w, 24));

      canvas.drawRect(Rect.fromLTWH(0, math.max(0, y - 24), w, 24), glowPaint);
      canvas.drawLine(Offset(0, y), Offset(w, y), laserPaint);

      // Edge laser nodes
      final nodePaint = Paint()
        ..color = stateColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, y), 3.0, nodePaint);
      canvas.drawCircle(Offset(w, y), 3.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudReticlePainter oldDelegate) {
    return oldDelegate.stateColor != stateColor ||
        oldDelegate.sweepPosition != sweepPosition ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.showCrosshair != showCrosshair;
  }
}
