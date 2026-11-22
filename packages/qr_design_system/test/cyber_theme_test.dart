import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberColors & Palette Tokens Tests', () {
    test('CyberColors defines complete futuristic color palette', () {
      expect(CyberColors.obsidianBackground, equals(const Color(0xFF070A0F)));
      expect(CyberColors.slateCard, equals(const Color(0xFF0F172A)));
      expect(CyberColors.slateCardSecondary, equals(const Color(0xFF1E293B)));
      expect(CyberColors.slateBorder, equals(const Color(0xFF334155)));

      expect(CyberColors.lightBackground, equals(const Color(0xFFF8FAFC)));
      expect(CyberColors.lightCard, equals(const Color(0xFFFFFFFF)));
      expect(CyberColors.lightCardSecondary, equals(const Color(0xFFF1F5F9)));
      expect(CyberColors.lightBorder, equals(const Color(0xFFCBD5E1)));

      expect(CyberColors.neonCyan, equals(const Color(0xFF00F5FF)));
      expect(CyberColors.neonEmerald, equals(const Color(0xFF00FF88)));
      expect(CyberColors.neonAmber, equals(const Color(0xFFFFB800)));
      expect(CyberColors.neonCrimson, equals(const Color(0xFFFF3366)));
      expect(CyberColors.neonPurple, equals(const Color(0xFFB026FF)));
      expect(CyberColors.electricBlue, equals(const Color(0xFF0066FF)));

      expect(CyberColors.textPrimaryDark, isNotNull);
      expect(CyberColors.textSecondaryDark, isNotNull);
      expect(CyberColors.textMutedDark, isNotNull);

      expect(CyberColors.textPrimaryLight, isNotNull);
      expect(CyberColors.textSecondaryLight, isNotNull);
      expect(CyberColors.textMutedLight, isNotNull);
    });

    test('CyberTokens constants and helper methods work as expected', () {
      expect(CyberTokens.radiusXs, equals(4.0));
      expect(CyberTokens.radiusSm, equals(8.0));
      expect(CyberTokens.radiusMd, equals(16.0));
      expect(CyberTokens.radiusLg, equals(24.0));
      expect(CyberTokens.radiusXl, equals(32.0));
      expect(CyberTokens.radiusPill, equals(999.0));

      expect(CyberTokens.glassBlurNone, equals(0.0));
      expect(CyberTokens.glassBlurSm, equals(8.0));
      expect(CyberTokens.glassBlurMd, equals(16.0));
      expect(CyberTokens.glassBlurLg, equals(24.0));

      expect(CyberTokens.borderWidthThin, equals(1.0));
      expect(CyberTokens.borderWidthMedium, equals(1.5));
      expect(CyberTokens.borderWidthThick, equals(2.0));

      expect(CyberTokens.spacingXs, equals(4.0));
      expect(CyberTokens.spacingSm, equals(8.0));
      expect(CyberTokens.spacingMd, equals(16.0));
      expect(CyberTokens.spacingLg, equals(24.0));
      expect(CyberTokens.spacingXl, equals(32.0));

      expect(CyberTokens.durationFast, equals(const Duration(milliseconds: 150)));
      expect(CyberTokens.durationNormal, equals(const Duration(milliseconds: 300)));
      expect(CyberTokens.durationSlow, equals(const Duration(milliseconds: 500)));
      expect(CyberTokens.durationSweep, equals(const Duration(milliseconds: 2000)));

      expect(CyberTokens.breakpointCompactMax, equals(600.0));
      expect(CyberTokens.breakpointMediumMax, equals(1024.0));

      final glow = CyberTokens.neonGlow(CyberColors.neonCyan, blur: 14.0, spread: 2.0);
      expect(glow.length, equals(1));
      expect(glow.first.blurRadius, equals(14.0));
      expect(glow.first.spreadRadius, equals(2.0));
    });
  });

  group('CyberTypography Tests', () {
    test('createTextTheme creates complete dark and light text themes', () {
      final darkTheme = CyberTypography.createTextTheme(isDark: true);
      expect(darkTheme.displayLarge?.color, equals(CyberColors.textPrimaryDark));
      expect(darkTheme.bodyLarge?.color, equals(CyberColors.textPrimaryDark));
      expect(darkTheme.bodyMedium?.color, equals(CyberColors.textSecondaryDark));
      expect(darkTheme.labelSmall?.color, equals(CyberColors.textMutedDark));

      final lightTheme = CyberTypography.createTextTheme(isDark: false);
      expect(lightTheme.displayLarge?.color, equals(CyberColors.textPrimaryLight));
      expect(lightTheme.bodyLarge?.color, equals(CyberColors.textPrimaryLight));
      expect(lightTheme.bodyMedium?.color, equals(CyberColors.textSecondaryLight));
      expect(lightTheme.labelSmall?.color, equals(CyberColors.textMutedLight));
    });

    test('monospace style provides high-tech typography defaults', () {
      final style = CyberTypography.monospace(fontSize: 14, color: CyberColors.neonEmerald);
      expect(style.fontFamily, equals('monospace'));
      expect(style.fontSize, equals(14));
      expect(style.color, equals(CyberColors.neonEmerald));
      expect(style.letterSpacing, equals(1.0));
    });
  });

  group('CyberTheme Generation Tests', () {
    test('CyberTheme.dark generates valid dark Material 3 theme', () {
      final theme = CyberTheme.dark();
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(CyberColors.obsidianBackground));
      expect(theme.colorScheme.primary, equals(CyberColors.neonCyan));
      expect(theme.colorScheme.secondary, equals(CyberColors.neonEmerald));
      expect(theme.colorScheme.surface, equals(CyberColors.slateCard));
      expect(theme.colorScheme.error, equals(CyberColors.neonCrimson));
      expect(theme.cardTheme.color, equals(CyberColors.slateCard));
      expect(theme.appBarTheme.backgroundColor, equals(Colors.transparent));
      expect(theme.navigationBarTheme.indicatorColor, isNotNull);
      expect(theme.navigationRailTheme.selectedIconTheme?.color, equals(CyberColors.neonCyan));
    });

    test('CyberTheme.light generates valid light Material 3 theme', () {
      final theme = CyberTheme.light();
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(CyberColors.lightBackground));
      expect(theme.colorScheme.primary, equals(CyberColors.electricBlue));
      expect(theme.colorScheme.surface, equals(CyberColors.lightCard));
      expect(theme.cardTheme.color, equals(CyberColors.lightCard));
    });
  });
}
