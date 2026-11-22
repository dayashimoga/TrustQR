import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';
import 'responsive_layout.dart';

/// Navigation item descriptor for the adaptive workspace shell.
class WorkspaceNavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;

  const WorkspaceNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
  });
}

/// Adaptive multi-pane workspace shell for phone, tablet, and desktop form-factors.
///
/// Automatically switches between:
/// - Compact (< 600px): Bottom Navigation Bar
/// - Medium (600px – 1024px): Navigation Rail with two-pane split view
/// - Expanded (> 1024px): Full Navigation Sidebar with multi-pane inspector and keyboard shortcuts
class AdaptiveWorkspaceShell extends StatelessWidget {
  final List<WorkspaceNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget body;
  final Widget? secondaryPane;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final VoidCallback? onOpenShortcut;
  final VoidCallback? onSaveShortcut;
  final VoidCallback? onSearchShortcut;
  final VoidCallback? onGenerateShortcut;

  const AdaptiveWorkspaceShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.body,
    this.secondaryPane,
    this.title = 'Universal QR',
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.onOpenShortcut,
    this.onSaveShortcut,
    this.onSearchShortcut,
    this.onGenerateShortcut,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, breakpoint) {
        Widget shell;
        switch (breakpoint) {
          case ResponsiveBreakpoint.compact:
            shell = _buildCompactLayout(context);
            break;
          case ResponsiveBreakpoint.medium:
            shell = _buildMediumLayout(context);
            break;
          case ResponsiveBreakpoint.expanded:
            shell = _buildExpandedLayout(context);
            break;
        }

        // Attach desktop keyboard shortcuts
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            // Ctrl/Cmd + O (Open / Upload)
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => onOpenShortcut?.call(),
            const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () => onOpenShortcut?.call(),

            // Ctrl/Cmd + S (Save / Scan)
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => onSaveShortcut?.call(),
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => onSaveShortcut?.call(),

            // Ctrl/Cmd + F (Search / Filter)
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => onSearchShortcut?.call(),
            const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () => onSearchShortcut?.call(),

            // Ctrl/Cmd + G (Generate)
            const SingleActivator(LogicalKeyboardKey.keyG, control: true): () => onGenerateShortcut?.call(),
            const SingleActivator(LogicalKeyboardKey.keyG, meta: true): () => onGenerateShortcut?.call(),

            // Ctrl + 1..9 (Tab switching)
            for (var i = 0; i < items.length && i < 9; i++)
              SingleActivator(LogicalKeyboardKey(0x31 + i), control: true): () => onIndexChanged(i),
          },
          child: Focus(
            autofocus: true,
            child: shell,
          ),
        );
      },
    );
  }

  /// Compact mobile layout (< 600px): AppBar + Body + Bottom NavigationBar
  Widget _buildCompactLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, items.length - 1),
        onDestinationSelected: onIndexChanged,
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Badge(
              isLabelVisible: item.badgeCount != null && item.badgeCount! > 0,
              label: Text(item.badgeCount?.toString() ?? ''),
              child: Icon(item.icon),
            ),
            selectedIcon: Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  /// Medium tablet layout (600px – 1024px): NavigationRail + split view
  Widget _buildMediumLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex.clamp(0, items.length - 1),
            onDestinationSelected: onIndexChanged,
            labelType: NavigationRailLabelType.all,
            destinations: items.map((item) {
              return NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: item.badgeCount != null && item.badgeCount! > 0,
                  label: Text(item.badgeCount?.toString() ?? ''),
                  child: Icon(item.icon),
                ),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: secondaryPane == null
                ? body
                : Row(
                    children: [
                      Expanded(flex: 3, child: body),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(flex: 2, child: secondaryPane!),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Expanded desktop layout (> 1024px): Full Navigation Sidebar + Workspace + Inspector Pane
  Widget _buildExpandedLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (240px)
          SizedBox(
            width: 240,
            child: Container(
              color: CyberColors.obsidianBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Header
                  Container(
                    padding: const EdgeInsets.all(CyberTokens.spacingLg),
                    child: Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: CyberTokens.spacingSm),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: CyberColors.neonCyan,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: CyberTokens.spacingSm),
                  // Nav Items List
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;
                        final color = isSelected ? CyberColors.neonCyan : CyberColors.textMutedDark;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? CyberColors.slateCard : Colors.transparent,
                            borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                            border: Border.all(
                              color: isSelected ? CyberColors.neonCyan.withValues(alpha: 0.4) : Colors.transparent,
                              width: 1.0,
                            ),
                            boxShadow: isSelected
                                ? CyberTokens.neonGlow(CyberColors.neonCyan, blur: 8.0)
                                : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                              color: color,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : CyberColors.textSecondaryDark,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            trailing: item.badgeCount != null && item.badgeCount! > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CyberColors.neonCyan.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(CyberTokens.radiusPill),
                                    ),
                                    child: Text(
                                      item.badgeCount.toString(),
                                      style: CyberTypography.monospace(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: CyberColors.neonCyan,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => onIndexChanged(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),

          // Central Main Workspace
          Expanded(
            child: Column(
              children: [
                if (actions != null && actions!.isNotEmpty)
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: CyberTokens.spacingMd),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: CyberColors.slateBorder)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),

          // Right Inspector Pane (Optional)
          if (secondaryPane != null) ...[
            const VerticalDivider(width: 1, thickness: 1),
            SizedBox(
              width: 360,
              child: Container(
                color: CyberColors.obsidianBackground,
                child: secondaryPane!,
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
