import 'package:flutter/material.dart';
import 'cyber_colors.dart';

/// Cyber-Precision typography styles.
class CyberTypography {
  static const String fontFamily = 'Roboto';
  static const String monospaceFontFamily = 'monospace';

  static TextTheme createTextTheme({bool isDark = true}) {
    final primary = isDark ? CyberColors.textPrimaryDark : CyberColors.textPrimaryLight;
    final secondary = isDark ? CyberColors.textSecondaryDark : CyberColors.textSecondaryLight;
    final muted = isDark ? CyberColors.textMutedDark : CyberColors.textMutedLight;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.25,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: muted,
      ),
    );
  }

  /// High-tech monospace text style for coordinates, telemetry, hashes, and tokens.
  static TextStyle monospace({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: monospaceFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color ?? CyberColors.neonCyan,
    );
  }
}
