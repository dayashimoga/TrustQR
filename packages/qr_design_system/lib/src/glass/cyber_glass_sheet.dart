import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';

/// Frosted glass bottom sheet or modal container with top drag handle and header.
class CyberGlassSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  const CyberGlassSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.borderRadius = CyberTokens.radiusLg,
    this.blur = CyberTokens.glassBlurLg,
    this.backgroundColor,
    this.borderColor,
    this.showHandle = true,
    this.padding = const EdgeInsets.all(CyberTokens.spacingLg),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? CyberColors.slateCard.withValues(alpha: 0.85)
        : CyberColors.lightCard.withValues(alpha: 0.90);
    final defaultBorder = isDark ? CyberColors.glassBorderDark : CyberColors.glassBorderLight;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border(
              top: BorderSide(
                color: borderColor ?? defaultBorder,
                width: CyberTokens.borderWidthThin,
              ),
            ),
          ),
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: CyberTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (title != null || trailing != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: CyberTokens.spacingMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.25,
                              ),
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
