import 'package:flutter/material.dart';
import '../accessibility/cyber_accessibility.dart';
import 'cyber_colors.dart';
import 'cyber_tokens.dart';
import 'cyber_typography.dart';

/// Comprehensive Cyber-Precision theme generator for dark, light, and high-contrast modes.
class CyberTheme {
  /// Generates the futuristic dark cyber-precision theme.
  static ThemeData dark() {
    final textTheme = CyberTypography.createTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberColors.obsidianBackground,
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.neonCyan,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF003840),
        onPrimaryContainer: CyberColors.neonCyan,
        secondary: CyberColors.neonEmerald,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF003D20),
        onSecondaryContainer: CyberColors.neonEmerald,
        tertiary: CyberColors.neonPurple,
        surface: CyberColors.slateCard,
        onSurface: CyberColors.textPrimaryDark,
        error: CyberColors.neonCrimson,
        onError: Colors.black,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: CyberColors.slateCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
          side: const BorderSide(color: CyberColors.slateBorder, width: CyberTokens.borderWidthThin),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: CyberColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: CyberColors.neonCyan),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberColors.neonCyan,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CyberTokens.radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberColors.neonCyan,
          side: const BorderSide(color: CyberColors.neonCyan, width: CyberTokens.borderWidthMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CyberTokens.radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberColors.obsidianBackground.withValues(alpha: 0.90),
        indicatorColor: CyberColors.neonCyan.withValues(alpha: 0.20),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: CyberColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: CyberColors.textMutedDark, fontSize: 12, fontWeight: FontWeight.w400);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CyberColors.neonCyan);
          }
          return const IconThemeData(color: CyberColors.textMutedDark);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: CyberColors.obsidianBackground,
        indicatorColor: CyberColors.neonCyan.withValues(alpha: 0.20),
        elevation: 0,
        selectedIconTheme: const IconThemeData(color: CyberColors.neonCyan),
        unselectedIconTheme: const IconThemeData(color: CyberColors.textMutedDark),
        selectedLabelTextStyle: const TextStyle(color: CyberColors.neonCyan, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: CyberColors.textMutedDark),
      ),
      dividerTheme: const DividerThemeData(
        color: CyberColors.slateBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Generates the crisp alabaster light theme.
  static ThemeData light() {
    final textTheme = CyberTypography.createTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CyberColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: CyberColors.electricBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD6E4FF),
        onPrimaryContainer: CyberColors.electricBlue,
        secondary: Color(0xFF009660),
        onSecondary: Colors.white,
        surface: CyberColors.lightCard,
        onSurface: CyberColors.textPrimaryLight,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: CyberColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
          side: const BorderSide(color: CyberColors.lightBorder, width: CyberTokens.borderWidthThin),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: CyberColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: CyberColors.electricBlue),
      ),
      dividerTheme: const DividerThemeData(
        color: CyberColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// High-contrast dark theme exceeding WCAG AAA contrast requirements (>7:1).
  static ThemeData highContrastDark() {
    final textTheme = CyberTypography.createTextTheme(isDark: true).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.neonCyan,
        onPrimary: Colors.black,
        secondary: CyberColors.neonEmerald,
        onSecondary: Colors.black,
        surface: Color(0xFF0A0F1D),
        onSurface: Colors.white,
        error: Color(0xFFFF1744),
        onError: Colors.black,
        outline: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0F1D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
          side: const BorderSide(color: Colors.white, width: CyberTokens.borderWidthBold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: CyberColors.neonCyan),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white,
        thickness: 2.0,
        space: 2.0,
      ),
    );
  }

  /// High-contrast light theme exceeding WCAG AAA contrast requirements (>7:1).
  static ThemeData highContrastLight() {
    final textTheme = CyberTypography.createTextTheme(isDark: false).apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0033CC),
        onPrimary: Colors.white,
        secondary: Color(0xFF007A3D),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Color(0xFFB71C1C),
        onError: Colors.white,
        outline: Colors.black,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
          side: const BorderSide(color: Colors.black, width: CyberTokens.borderWidthBold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0033CC)),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.black,
        thickness: 2.0,
        space: 2.0,
      ),
    );
  }

  /// Automatically resolves the appropriate theme based on context and accessibility flags.
  static ThemeData resolve(BuildContext context, {bool isDark = true, bool? highContrast}) {
    final isHc = highContrast ?? CyberAccessibility.isHighContrast(context);
    if (isHc) {
      return isDark ? highContrastDark() : highContrastLight();
    }
    return isDark ? dark() : light();
  }
}
