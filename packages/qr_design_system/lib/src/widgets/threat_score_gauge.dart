import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../accessibility/cyber_accessibility.dart';
import '../l10n/cyber_localizations.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';

/// Animated circular safety gauge visualizing Threat Firewall assessment scores (0–100).
///
/// Complies with WCAG 2.1 AA screen-reader semantics and respects reduced-motion preferences.
class ThreatScoreGauge extends StatefulWidget {
  final double score;
  final double size;
  final double strokeWidth;
  final String? title;
  final bool showLabel;
  final bool? reducedMotion;

  const ThreatScoreGauge({
    super.key,
    required this.score,
    this.size = 140.0,
    this.strokeWidth = 10.0,
    this.title,
    this.showLabel = true,
    this.reducedMotion,
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

    if (widget.reducedMotion != true) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ThreatScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score.clamp(0.0, 100.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

      if (widget.reducedMotion == true) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
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

  @override
  Widget build(BuildContext context) {
    final localizations = CyberLocalizations.of(context);
    final isReducedMotion = widget.reducedMotion ?? CyberAccessibility.isReducedMotion(context);

    if (isReducedMotion && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }

    final effectiveVal = isReducedMotion
        ? widget.score.clamp(0.0, 100.0)
        : _animation.value;
    final rating = localizations.threatRating(effectiveVal);
    final titleText = widget.title ?? localizations.threatScore;

    return Semantics(
      container: true,
      label: titleText,
      value: localizations.threatScoreReading(effectiveVal.toInt(), rating),
      hint: localizations.a11yThreatGaugeHint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titleText,
            style: CyberTypography.monospace(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CyberColors.textMutedDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: CyberTokens.spacingSm),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final val = isReducedMotion ? widget.score.clamp(0.0, 100.0) : _animation.value;
                final color = _getScoreColor(val);
                final currentRating = localizations.threatRating(val);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _ThreatGaugePainter(
                        score: val,
                        color: color,
                        strokeWidth: widget.strokeWidth,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          val.toStringAsFixed(0),
                          style: CyberTypography.monospace(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        if (widget.showLabel) ...[
                          const SizedBox(height: 2),
                          Text(
                            currentRating,
                            style: CyberTypography.monospace(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatGaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final double strokeWidth;

  _ThreatGaugePainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 135.0 * (math.pi / 180.0);
    const sweepTotalAngle = 270.0 * (math.pi / 180.0);

    // Track Paint
    final trackPaint = Paint()
      ..color = CyberColors.slateBorder
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotalAngle,
      false,
      trackPaint,
    );

    // Progress Arc Paint
    final progressSweep = sweepTotalAngle * (score.clamp(0.0, 100.0) / 100.0);
    if (progressSweep > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThreatGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
