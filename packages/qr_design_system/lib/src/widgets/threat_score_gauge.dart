import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';

/// Animated circular safety gauge visualizing Threat Firewall assessment scores (0–100).
class ThreatScoreGauge extends StatefulWidget {
  final double score;
  final double size;
  final double strokeWidth;
  final String? title;
  final bool showLabel;

  const ThreatScoreGauge({
    super.key,
    required this.score,
    this.size = 140.0,
    this.strokeWidth = 10.0,
    this.title,
    this.showLabel = true,
  });

  @override
  State<ThreatScoreGauge> createState() => _ThreatScoreGaugeState();
}

class _ThreatScoreGaugeState extends State<ThreatScoreGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CyberTokens.durationSlow,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score.clamp(0.0, 100.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ThreatScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score.clamp(0.0, 100.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double s) {
    if (s >= 80.0) return CyberColors.neonEmerald;
    if (s >= 50.0) return CyberColors.neonAmber;
    return CyberColors.neonCrimson;
  }

  String _getScoreRating(double s) {
    if (s >= 80.0) return 'SECURE';
    if (s >= 50.0) return 'CAUTION';
    return 'CRITICAL';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: CyberTypography.monospace(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CyberColors.textMutedDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: CyberTokens.spacingSm),
        ],
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final val = _animation.value;
              final color = _getScoreColor(val);
              final rating = _getScoreRating(val);

              return CustomPaint(
                painter: _GaugePainter(
                  scoreRatio: val / 100.0,
                  strokeWidth: widget.strokeWidth,
                  color: color,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        val.round().toString(),
                        style: TextStyle(
                          fontSize: widget.size * 0.28,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (widget.showLabel)
                        Text(
                          rating,
                          style: CyberTypography.monospace(
                            fontSize: widget.size * 0.08,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double scoreRatio;
  final double strokeWidth;
  final Color color;

  _GaugePainter({
    required this.scoreRatio,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 0.75 * math.pi; // 135 degrees
    const totalSweep = 1.5 * math.pi; // 270 degrees arc

    // 1. Background Track Ring
    final trackPaint = Paint()
      ..color = CyberColors.slateBorder.withValues(alpha: 0.35)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // 2. Active Progress Arc with Glow
    final activeSweep = totalSweep * scoreRatio.clamp(0.0, 1.0);

    if (activeSweep > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth + 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        glowPaint,
      );

      final arcPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.scoreRatio != scoreRatio ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
