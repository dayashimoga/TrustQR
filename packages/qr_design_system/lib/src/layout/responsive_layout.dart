import 'package:flutter/material.dart';
import '../tokens/cyber_tokens.dart';

/// Form-factor breakpoints for adaptive cross-platform UI.
enum ResponsiveBreakpoint {
  /// Mobile phones / compact narrow windows (< 600px).
  compact,

  /// Tablets, foldables, and medium windows (600px – 1024px).
  medium,

  /// Laptops, desktops, and large displays (> 1024px).
  expanded,
}

/// Helper utilities and builder for responsive layout transitions.
class ResponsiveLayout {
  /// Resolves the active [ResponsiveBreakpoint] from the current [BuildContext].
  static ResponsiveBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < CyberTokens.breakpointCompactMax) {
      return ResponsiveBreakpoint.compact;
    } else if (width <= CyberTokens.breakpointMediumMax) {
      return ResponsiveBreakpoint.medium;
    } else {
      return ResponsiveBreakpoint.expanded;
    }
  }

  /// True if current window width is in the compact mobile breakpoint (< 600px).
  static bool isCompact(BuildContext context) => of(context) == ResponsiveBreakpoint.compact;

  /// True if current window width is in the medium tablet breakpoint (600px – 1024px).
  static bool isMedium(BuildContext context) => of(context) == ResponsiveBreakpoint.medium;

  /// True if current window width is in the expanded desktop breakpoint (> 1024px).
  static bool isExpanded(BuildContext context) => of(context) == ResponsiveBreakpoint.expanded;

  /// Resolves a value corresponding to the active breakpoint.
  static T value<T>({
    required BuildContext context,
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final bp = of(context);
    switch (bp) {
      case ResponsiveBreakpoint.compact:
        return compact;
      case ResponsiveBreakpoint.medium:
        return medium ?? compact;
      case ResponsiveBreakpoint.expanded:
        return expanded ?? medium ?? compact;
    }
  }
}

/// Widget that rebuilds whenever window dimensions transition across breakpoints.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveBreakpoint breakpoint) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final ResponsiveBreakpoint bp;
        if (width < CyberTokens.breakpointCompactMax) {
          bp = ResponsiveBreakpoint.compact;
        } else if (width <= CyberTokens.breakpointMediumMax) {
          bp = ResponsiveBreakpoint.medium;
        } else {
          bp = ResponsiveBreakpoint.expanded;
        }
        return builder(context, bp);
      },
    );
  }
}
