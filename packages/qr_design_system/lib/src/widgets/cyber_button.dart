import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';

/// Style variants for the futuristic CyberButton.
enum CyberButtonVariant {
  /// Solid neon cyan background with dark text and active glow.
  primary,

  /// Frosted glassmorphic card background with neon border sheen.
  secondary,

  /// Crimson danger button for quarantine and permanent deletion actions.
  danger,

  /// Transparent background with neon stroked border.
  outline,
}

/// Cyber-Precision interactive button with neon glow, hover/press animations,
/// loading spinner, and accessibility semantics.
class CyberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CyberButtonVariant variant;
  final double height;
  final double? width;
  final bool isFullWidth;

  const CyberButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.variant = CyberButtonVariant.primary,
    this.height = 48.0,
    this.width,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Color border;
    List<BoxShadow> shadows = [];

    switch (variant) {
      case CyberButtonVariant.primary:
        bg = isEnabled ? CyberColors.neonCyan : CyberColors.slateCardSecondary;
        fg = isEnabled ? Colors.black : CyberColors.textMutedDark;
        border = isEnabled ? CyberColors.neonCyan : Colors.transparent;
        if (isEnabled) shadows = CyberTokens.neonGlow(CyberColors.neonCyan, blur: 12.0);
        break;

      case CyberButtonVariant.secondary:
        bg = isEnabled ? CyberColors.slateCard : CyberColors.slateCardSecondary;
        fg = isEnabled ? CyberColors.textPrimaryDark : CyberColors.textMutedDark;
        border = isEnabled ? CyberColors.glassBorderDark : CyberColors.slateBorder;
        break;

      case CyberButtonVariant.danger:
        bg = isEnabled ? CyberColors.neonCrimson : CyberColors.slateCardSecondary;
        fg = isEnabled ? Colors.white : CyberColors.textMutedDark;
        border = isEnabled ? CyberColors.neonCrimson : Colors.transparent;
        if (isEnabled) shadows = CyberTokens.neonGlow(CyberColors.neonCrimson, blur: 12.0);
        break;

      case CyberButtonVariant.outline:
        bg = Colors.transparent;
        fg = isEnabled ? CyberColors.neonCyan : CyberColors.textMutedDark;
        border = isEnabled ? CyberColors.neonCyan : CyberColors.slateBorder;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    final buttonWidget = AnimatedContainer(
      duration: CyberTokens.durationFast,
      height: height,
      width: isFullWidth ? double.infinity : width,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: border, width: 1.0),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: buttonWidget,
    );
  }
}
