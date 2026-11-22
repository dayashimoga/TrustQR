import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';

/// Typography helper definitions for the Admin Application.
class AdminTypography {
  static const TextStyle headerLarge = TextStyle(
    fontFamily: CyberTypography.fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: CyberColors.textPrimaryDark,
  );

  static const TextStyle headerMedium = TextStyle(
    fontFamily: CyberTypography.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    color: CyberColors.textPrimaryDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: CyberTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: CyberColors.textPrimaryDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: CyberTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: CyberColors.textSecondaryDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: CyberTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: CyberColors.textMutedDark,
  );

  static const TextStyle codeSmall = TextStyle(
    fontFamily: CyberTypography.monospaceFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.75,
    color: CyberColors.neonCyan,
  );
}
