/// Cyber-Precision glassmorphic design tokens and widgets.
library qr_design_system;

import 'package:flutter/material.dart';

/// Cyber-Precision design palette tokens.
class CyberTokens {
  static const Color obsidianBackground = Color(0xFF090D14);
  static const Color slateCard = Color(0xFF131B2A);
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonEmerald = Color(0xFF00FF88);
  static const Color neonAmber = Color(0xFFFFB800);
  static const Color neonCrimson = Color(0xFFFF3366);
  static const Color cyberTextPrimary = Color(0xFFF1F5F9);
  static const Color cyberTextMuted = Color(0xFF94A3B8);

  static ThemeData createDarkCyberTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: obsidianBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonEmerald,
        surface: slateCard,
        error: neonCrimson,
      ),
    );
  }
}

/// Glassmorphic translucent container card.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CyberTokens.slateCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? CyberTokens.neonCyan.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
