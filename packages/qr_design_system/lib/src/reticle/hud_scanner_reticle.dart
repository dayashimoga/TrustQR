import 'dart:math' as math;
import 'package:flutter/material.dart';
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
/// laser sweep line, and threat state transitions.
class HudScannerReticle extends StatefulWidget {
  final ScannerHudState state;
  final double reticleSize;
  final double cornerLength;
  final double cornerStrokeWidth;
  final bool showLaserSweep;
  final bool showCrosshair;
  final String? statusText;
  final Widget? centerOverlay;

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

    if (widget.state == ScannerHudState.scanning) {
      _sweepController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HudScannerReticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ScannerHudState.scanning && !_sweepController.isAnimating) {
      _sweepController.repeat(reverse: true);
    } else if (widget.state != ScannerHudState.scanning && _sweepController.isAnimating) {
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

  String _getDefaultStatusText() {
    switch (widget.state) {
      case ScannerHudState.idle:
        return 'READY // ALIGN QR CODE';
      case ScannerHudState.scanning:
        return 'SCANNING // ZERO-TRUST FIREWALL ACTIVE';
      case ScannerHudState.safe:
        return 'VERIFIED // SAFE PAYLOAD';
      case ScannerHudState.warning:
        return 'CAUTION // SUSPICIOUS ANOMALY';
      case ScannerHudState.threat:
        return 'THREAT DETECTED // ACCESS QUARANTINED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();
    final statusText = widget.statusText ?? _getDefaultStatusText();

    return Center(
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
                    sweepPosition: widget.state == ScannerHudState.scanning ? _sweepAnimation.value : null,
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
                    boxShadow: CyberTokens.neonGlow(stateColor, blur: 6.0),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: CyberTypography.monospace(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: stateColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering glowing corner tracking brackets, crosshair, and laser sweep.
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

    // Corner Paint with Glow
    final cornerPaint = Paint()
      ..color = stateColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = stateColor.withValues(alpha: 0.4)
      ..strokeWidth = strokeWidth + 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // 1. Top-Left Corner
    _drawCorner(canvas, glowPaint, 0, 0, cornerLength, true, true);
    _drawCorner(canvas, cornerPaint, 0, 0, cornerLength, true, true);

    // 2. Top-Right Corner
    _drawCorner(canvas, glowPaint, w, 0, cornerLength, false, true);
    _drawCorner(canvas, cornerPaint, w, 0, cornerLength, false, true);

    // 3. Bottom-Left Corner
    _drawCorner(canvas, glowPaint, 0, h, cornerLength, true, false);
    _drawCorner(canvas, cornerPaint, 0, h, cornerLength, true, false);

    // 4. Bottom-Right Corner
    _drawCorner(canvas, glowPaint, w, h, cornerLength, false, false);
    _drawCorner(canvas, cornerPaint, w, h, cornerLength, false, false);

    // 5. Crosshairs at Center
    if (showCrosshair) {
      final crossPaint = Paint()
        ..color = stateColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.0;
      final cx = w / 2;
      final cy = h / 2;
      const gap = 8.0;
      const arm = 14.0;

      canvas.drawLine(Offset(cx - gap - arm, cy), Offset(cx - gap, cy), crossPaint);
      canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + arm, cy), crossPaint);
      canvas.drawLine(Offset(cx, cy - gap - arm), Offset(cx, cy - gap), crossPaint);
      canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + arm), crossPaint);
    }

    // 6. Laser Sweep Line
    if (sweepPosition != null) {
      final sweepY = h * sweepPosition!;
      final laserPaint = Paint()
        ..color = stateColor
        ..strokeWidth = 2.0;

      final laserGlow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            stateColor.withValues(alpha: 0.25),
            stateColor.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromLTRB(0, math.max(0, sweepY - 24), w, sweepY));

      // Glow beam trail above sweep line
      canvas.drawRect(Rect.fromLTRB(4, math.max(0, sweepY - 24), w - 4, sweepY), laserGlow);

      // Sharp laser line
      canvas.drawLine(Offset(4, sweepY), Offset(w - 4, sweepY), laserPaint);
    }
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double len,
    bool isLeft,
    bool isTop,
  ) {
    final dx = isLeft ? len : -len;
    final dy = isTop ? len : -len;

    final path = Path()
      ..moveTo(x + dx, y)
      ..lineTo(x, y)
      ..lineTo(x, y + dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HudReticlePainter oldDelegate) {
    return oldDelegate.stateColor != stateColor ||
        oldDelegate.sweepPosition != sweepPosition ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
