import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  final navItems = [
    const WorkspaceNavItem(id: 'scanner', label: 'Scanner', icon: Icons.qr_code_scanner, badgeCount: 2),
    const WorkspaceNavItem(id: 'vault', label: 'Vault', icon: Icons.inventory_2, selectedIcon: Icons.inventory_2_rounded),
    const WorkspaceNavItem(id: 'analytics', label: 'Fleet Analytics', icon: Icons.analytics),
    const WorkspaceNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
  ];

  group('ResponsiveLayout & Breakpoints Tests', () {
    testWidgets('Resolves compact breakpoint for width < 600px', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late ResponsiveBreakpoint bp;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            builder: (context, breakpoint) {
              bp = breakpoint;
              return Text('Breakpoint: ${breakpoint.name}');
            },
          ),
        ),
      );

      expect(bp, equals(ResponsiveBreakpoint.compact));
      expect(find.text('Breakpoint: compact'), findsOneWidget);
    });

    testWidgets('Resolves medium breakpoint for 600px <= width <= 1024px', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late ResponsiveBreakpoint bp;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            builder: (context, breakpoint) {
              bp = breakpoint;
              return Text('Breakpoint: ${breakpoint.name}');
            },
          ),
        ),
      );

      expect(bp, equals(ResponsiveBreakpoint.medium));
      expect(find.text('Breakpoint: medium'), findsOneWidget);
    });

    testWidgets('Resolves expanded breakpoint for width > 1024px', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late ResponsiveBreakpoint bp;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            builder: (context, breakpoint) {
              bp = breakpoint;
              return Text('Breakpoint: ${breakpoint.name}');
            },
          ),
        ),
      );

      expect(bp, equals(ResponsiveBreakpoint.expanded));
      expect(find.text('Breakpoint: expanded'), findsOneWidget);
    });

    testWidgets('ResponsiveLayout.value helper resolves correct tier values', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late int resolvedColumns;
      late bool isMed;
      late bool isComp;
      late bool isExp;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isComp = ResponsiveLayout.isCompact(context);
              isMed = ResponsiveLayout.isMedium(context);
              isExp = ResponsiveLayout.isExpanded(context);
              resolvedColumns = ResponsiveLayout.value<int>(
                context: context,
                compact: 1,
                medium: 2,
                expanded: 4,
              );
              return Text('Cols: $resolvedColumns');
            },
          ),
        ),
      );

      expect(isComp, isFalse);
      expect(isMed, isTrue);
      expect(isExp, isFalse);
      expect(resolvedColumns, equals(2));
    });

    testWidgets('ResponsiveLayout.value resolves compact and expanded fallbacks', (tester) async {
      // 1. Compact
      tester.view.physicalSize = const Size(350, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveLayout.isCompact(context), isTrue);
              final val = ResponsiveLayout.value<String>(context: context, compact: 'phone');
              return Text(val);
            },
          ),
        ),
      );
      expect(find.text('phone'), findsOneWidget);

      // 2. Expanded
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveLayout.isExpanded(context), isTrue);
              final val = ResponsiveLayout.value<String>(
                context: context,
                compact: 'phone',
                expanded: 'desktop',
              );
              return Text(val);
            },
          ),
        ),
      );
      expect(find.text('desktop'), findsOneWidget);
    });
  });

  group('AdaptiveWorkspaceShell Tests', () {
    testWidgets('Compact Layout (< 600px): Renders Bottom NavigationBar and changes index', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: AdaptiveWorkspaceShell(
                items: navItems,
                currentIndex: selectedIndex,
                title: 'Compact QR',
                actions: [
                  IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                ],
                body: Center(child: Text('Active Tab: ${navItems[selectedIndex].label}')),
                onIndexChanged: (i) => setState(() => selectedIndex = i),
              ),
            );
          },
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Active Tab: Scanner'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Tap Vault in navigation bar
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
      expect(find.text('Active Tab: Vault'), findsOneWidget);
    });

    testWidgets('Medium Layout (600px–1024px): Renders NavigationRail and two-pane split', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: AdaptiveWorkspaceShell(
                items: navItems,
                currentIndex: selectedIndex,
                title: 'Tablet QR',
                body: const Center(child: Text('Main Workspace Body')),
                secondaryPane: const Center(child: Text('Inspector Detail Pane')),
                onIndexChanged: (i) => setState(() => selectedIndex = i),
              ),
            );
          },
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Main Workspace Body'), findsOneWidget);
      expect(find.text('Inspector Detail Pane'), findsOneWidget);

      // Tap Settings in rail
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(3));
    });

    testWidgets('Expanded Layout (> 1024px): Renders Sidebar and multi-pane workspace', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: AdaptiveWorkspaceShell(
                items: navItems,
                currentIndex: selectedIndex,
                title: 'Studio Pro',
                leading: const Icon(Icons.shield, color: CyberColors.neonCyan),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
                ],
                body: const Center(child: Text('Desktop Canvas')),
                secondaryPane: const Center(child: Text('Inspector Toolset')),
                onIndexChanged: (i) => setState(() => selectedIndex = i),
              ),
            );
          },
        ),
      );

      expect(find.text('Studio Pro'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.text('Fleet Analytics'), findsOneWidget);
      expect(find.text('Desktop Canvas'), findsOneWidget);
      expect(find.text('Inspector Toolset'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tap item in sidebar
      await tester.tap(find.text('Fleet Analytics'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(2));
    });

    testWidgets('Keyboard shortcuts trigger open, save, search, generate, and tab index', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var opened = false;
      var saved = false;
      var searched = false;
      var generated = false;
      var currentIdx = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: AdaptiveWorkspaceShell(
                items: navItems,
                currentIndex: currentIdx,
                body: const Text('Keyboard Shell'),
                onIndexChanged: (i) => setState(() => currentIdx = i),
                onOpenShortcut: () => opened = true,
                onSaveShortcut: () => saved = true,
                onSearchShortcut: () => searched = true,
                onGenerateShortcut: () => generated = true,
              ),
            );
          },
        ),
      );

      // Simulate Ctrl+O
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(opened, isTrue);

      // Simulate Ctrl+S
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(saved, isTrue);

      // Simulate Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(searched, isTrue);

      // Simulate Ctrl+G
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(generated, isTrue);

      // Simulate Ctrl+2 (switches to index 1, 'Vault')
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(currentIdx, equals(1));
    });
  });
}
