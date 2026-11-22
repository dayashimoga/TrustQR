import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';

/// Translucent frosted glass container widget with subtle border sheen and glow.
class CyberGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? glowColor;
  final double? width;
  final double? height;

  const CyberGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CyberTokens.spacingMd),
    this.margin,
    this.borderRadius = CyberTokens.radiusMd,
    this.blur = CyberTokens.glassBlurMd,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = CyberTokens.borderWidthThin,
    this.onTap,
    this.hasGlow = false,
    this.glowColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? CyberColors.slateCard.withValues(alpha: 0.70)
        : CyberColors.lightCard.withValues(alpha: 0.85);
    final defaultBorder = isDark
        ? (borderColor ?? CyberColors.glassBorderDark)
        : (borderColor ?? CyberColors.glassBorderLight);

    final resolvedBorderColor = borderColor ?? defaultBorder;
    final resolvedGlowColor = glowColor ?? CyberColors.neonCyan;

    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: resolvedBorderColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    Widget result;
    if (blur > 0) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: cardContent,
        ),
      );
    } else {
      result = cardContent;
    }

    if (hasGlow) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: CyberTokens.neonGlow(resolvedGlowColor, blur: 16.0),
        ),
        child: result,
      );
    }

    if (onTap != null) {
      result = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: resolvedGlowColor.withValues(alpha: 0.15),
          highlightColor: resolvedGlowColor.withValues(alpha: 0.08),
          child: result,
        ),
      );
    }

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }

    return result;
  }
}
