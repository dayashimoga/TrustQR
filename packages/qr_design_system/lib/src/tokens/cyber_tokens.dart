import 'package:flutter/material.dart';
import 'cyber_colors.dart';
import 'cyber_theme.dart';

/// Design constants for elevation, spacing, animation durations, and blur filters.
class CyberTokens {
  // Palette Aliases (backward compatibility)
  static const Color obsidianBackground = CyberColors.obsidianBackground;
  static const Color slateCard = CyberColors.slateCard;
  static const Color neonCyan = CyberColors.neonCyan;
  static const Color neonEmerald = CyberColors.neonEmerald;
  static const Color neonAmber = CyberColors.neonAmber;
  static const Color neonCrimson = CyberColors.neonCrimson;
  static const Color cyberTextPrimary = CyberColors.textPrimaryDark;
  static const Color cyberTextMuted = CyberColors.textMutedDark;

  static ThemeData createDarkCyberTheme() => CyberTheme.dark();

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusPill = 999.0;

  // Glassmorphic Blur Sigmas
  static const double glassBlurNone = 0.0;
  static const double glassBlurSm = 8.0;
  static const double glassBlurMd = 16.0;
  static const double glassBlurLg = 24.0;

  // Border Widths
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthBold = 2.5;

  // Layout Spacing & Paddings
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSweep = Duration(milliseconds: 2000);

  // Responsive Breakpoints
  static const double breakpointCompactMax = 600.0;
  static const double breakpointMediumMax = 1024.0;

  // Default Box Shadows
  static List<BoxShadow> neonGlow(Color color, {double blur = 12.0, double spread = 0.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
