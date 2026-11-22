import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Centralized accessibility utilities for WCAG 2.1 AA compliance,
/// screen-reader announcements, high-contrast detection, and reduced-motion handling.
class CyberAccessibility {
  const CyberAccessibility._();

  /// Determines whether the user or system environment requested reduced motion.
  static bool isReducedMotion(BuildContext context) {
    return (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
  }

  /// Determines whether the user or system environment requested high contrast.
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.maybeHighContrastOf(context) ?? false;
  }

  /// Resolves an animation duration, collapsing to [Duration.zero] when reduced motion is enabled.
  static Duration resolveDuration(BuildContext context, Duration normalDuration) {
    return isReducedMotion(context) ? Duration.zero : normalDuration;
  }

  /// Announces a message via the platform's accessibility screen reader (TalkBack / VoiceOver / Narrator).
  static void announce(BuildContext context, String message) {
    if (message.isEmpty) return;
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final view = View.maybeOf(context) ?? PlatformDispatcher.instance.implicitView;
    if (view != null) {
      SemanticsService.sendAnnouncement(view, message, direction);
    }
  }

  /// Wraps an interactive child widget with standard button semantics.
  static Widget wrapButton({
    required Widget child,
    required String label,
    String? hint,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    final effectiveLabel = isLoading ? '$label, loading' : label;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: effectiveLabel,
      hint: hint,
      child: child,
    );
  }

  /// Wraps a dynamic status widget in an accessibility live region so updates are spoken.
  static Widget wrapLiveRegion({
    required Widget child,
    required String label,
    String? value,
    String? hint,
  }) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      value: value,
      hint: hint,
      child: child,
    );
  }
}
