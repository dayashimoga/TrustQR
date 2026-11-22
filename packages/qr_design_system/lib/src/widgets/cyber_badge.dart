import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';

/// Semantic styling type for CyberBadge.
enum CyberBadgeType {
  neutral,
  safe,
  warning,
  threat,
  info,
  accent,
}

/// Cyber-Precision pill status badge with optional glowing indicator dot.
class CyberBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final CyberBadgeType type;
  final bool isPill;
  final bool showPulseDot;

  const CyberBadge({
    super.key,
    required this.text,
    this.icon,
    this.type = CyberBadgeType.neutral,
    this.isPill = true,
    this.showPulseDot = false,
  });

  Color _getColor() {
    switch (type) {
      case CyberBadgeType.neutral:
        return CyberColors.textMutedDark;
      case CyberBadgeType.safe:
        return CyberColors.neonEmerald;
      case CyberBadgeType.warning:
        return CyberColors.neonAmber;
      case CyberBadgeType.threat:
        return CyberColors.neonCrimson;
      case CyberBadgeType.info:
        return CyberColors.neonCyan;
      case CyberBadgeType.accent:
        return CyberColors.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isPill ? CyberTokens.radiusPill : CyberTokens.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulseDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: CyberTokens.neonGlow(color, blur: 4.0),
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: CyberTypography.monospace(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
