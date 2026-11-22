import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberAccessibility Utilities Tests', () {
    testWidgets('CyberAccessibility detects normal vs reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(CyberAccessibility.isReducedMotion(context), isFalse);
              expect(CyberAccessibility.resolveDuration(context, const Duration(seconds: 1)),
                  equals(const Duration(seconds: 1)));
              return const SizedBox();
            },
          ),
        ),
      );

      // With disableAnimations enabled
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                expect(CyberAccessibility.isReducedMotion(context), isTrue);
                expect(CyberAccessibility.resolveDuration(context, const Duration(seconds: 1)),
                    equals(Duration.zero));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // With accessibleNavigation enabled
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true),
            child: Builder(
              builder: (context) {
                expect(CyberAccessibility.isReducedMotion(context), isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('CyberAccessibility detects normal vs high contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(CyberAccessibility.isHighContrast(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(highContrast: true),
            child: Builder(
              builder: (context) {
                expect(CyberAccessibility.isHighContrast(context), isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('CyberAccessibility.announce invokes without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              CyberAccessibility.announce(context, 'Test announcement');
              CyberAccessibility.announce(context, ''); // empty check
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('CyberAccessibility helper wrappers wrap with correct semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              CyberAccessibility.wrapButton(
                child: const Text('Click me'),
                label: 'Test Button',
                hint: 'Double tap to execute',
                isEnabled: true,
                isLoading: false,
              ),
              CyberAccessibility.wrapButton(
                child: const Text('Busy'),
                label: 'Save',
                isLoading: true,
              ),
              CyberAccessibility.wrapLiveRegion(
                child: const Text('Status live'),
                label: 'Live telemetry',
                value: '42 items scanned',
              ),
            ],
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true && w.properties.label == 'Test Button',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Save, loading',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true && w.properties.value == '42 items scanned',
        ),
        findsOneWidget,
      );
    });
  });

  group('CyberTheme High-Contrast Mode Tests', () {
    test('CyberTheme.highContrastDark produces WCAG AAA compliant tokens', () {
      final theme = CyberTheme.highContrastDark();
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(Colors.black));
      expect(theme.colorScheme.surface, equals(const Color(0xFF0A0F1D)));
      expect(theme.colorScheme.onSurface, equals(Colors.white));
      expect(theme.colorScheme.outline, equals(Colors.white));
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, equals(Colors.white));
      expect(shape.side.width, equals(CyberTokens.borderWidthBold));
      expect(theme.dividerTheme.color, equals(Colors.white));
    });

    test('CyberTheme.highContrastLight produces WCAG AAA compliant tokens', () {
      final theme = CyberTheme.highContrastLight();
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(Colors.white));
      expect(theme.colorScheme.surface, equals(Colors.white));
      expect(theme.colorScheme.onSurface, equals(Colors.black));
      expect(theme.colorScheme.outline, equals(Colors.black));
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, equals(Colors.black));
      expect(shape.side.width, equals(CyberTokens.borderWidthBold));
      expect(theme.dividerTheme.color, equals(Colors.black));
    });

    testWidgets('CyberTheme.resolve selects appropriate theme variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final normalDark = CyberTheme.resolve(context, isDark: true);
              expect(normalDark.scaffoldBackgroundColor, equals(CyberColors.obsidianBackground));

              final normalLight = CyberTheme.resolve(context, isDark: false);
              expect(normalLight.scaffoldBackgroundColor, equals(CyberColors.lightBackground));

              final forcedHcDark = CyberTheme.resolve(context, isDark: true, highContrast: true);
              expect(forcedHcDark.scaffoldBackgroundColor, equals(Colors.black));

              final forcedHcLight = CyberTheme.resolve(context, isDark: false, highContrast: true);
              expect(forcedHcLight.scaffoldBackgroundColor, equals(Colors.white));

              return const SizedBox();
            },
          ),
        ),
      );

      // Context with high-contrast MediaQuery
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(highContrast: true),
            child: Builder(
              builder: (context) {
                final autoHcDark = CyberTheme.resolve(context, isDark: true);
                expect(autoHcDark.scaffoldBackgroundColor, equals(Colors.black));

                final autoHcLight = CyberTheme.resolve(context, isDark: false);
                expect(autoHcLight.scaffoldBackgroundColor, equals(Colors.white));

                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('WCAG Screen Reader Semantics & Reduced-Motion Tests on Widgets', () {
    testWidgets('HudScannerReticle exposes complete WCAG semantics and states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.scanning),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.liveRegion == true &&
              w.properties.label == 'QR Scanner Viewfinder' &&
              w.properties.value == 'SCANNING // ZERO-TRUST FIREWALL ACTIVE',
        ),
        findsOneWidget,
      );

      // Change to warning state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.warning),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.value == 'CAUTION // SUSPICIOUS ANOMALY',
        ),
        findsOneWidget,
      );

      // Change to threat state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.threat),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.value == 'THREAT DETECTED // ACCESS QUARANTINED',
        ),
        findsOneWidget,
      );
    });

    testWidgets('HudScannerReticle respects reduced-motion flag and MediaQuery', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(
              state: ScannerHudState.scanning,
              reducedMotion: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      // In reduced motion, widget builds and runs cleanly without infinite sweeps
      expect(find.byType(HudScannerReticle), findsOneWidget);

      // Test with MediaQuery disableAnimations
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: HudScannerReticle(state: ScannerHudState.scanning),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HudScannerReticle), findsOneWidget);

      // Dynamic toggle from normal motion (animating) to reduced motion and back
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.scanning, reducedMotion: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Toggle to reduced motion dynamically
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.scanning, reducedMotion: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Toggle back to normal motion dynamically
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudScannerReticle(state: ScannerHudState.scanning, reducedMotion: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('ThreatScoreGauge exposes WCAG Semantics and reduced-motion instant render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThreatScoreGauge(
              score: 88.0,
              reducedMotion: true,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Threat Safety Score' &&
              w.properties.value == '88 out of 100, SECURE',
        ),
        findsOneWidget,
      );

      // Caution score
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThreatScoreGauge(
              score: 62.0,
              reducedMotion: true,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.value == '62 out of 100, CAUTION',
        ),
        findsOneWidget,
      );

      // Critical score
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThreatScoreGauge(
              score: 25.0,
              reducedMotion: true,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.value == '25 out of 100, CRITICAL',
        ),
        findsOneWidget,
      );
    });

    testWidgets('TrustQrBadge exposes WCAG Semantics in compact and full modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TrustQrBadge(
                  isAuthentic: true,
                  institutionName: 'Apex Trust Authority',
                  isCompact: true,
                ),
                TrustQrBadge(
                  isAuthentic: false,
                  institutionName: 'Rogue Entity',
                  keyId: 'KEY-0099',
                  issuedAt: DateTime(2026, 11, 22),
                  isCompact: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'TrustQR Cryptographic Authenticity Badge' &&
              w.properties.value == 'TRUSTQR VERIFIED: Apex Trust Authority',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.value == 'SIGNATURE INVALID: Rogue Entity',
        ),
        findsOneWidget,
      );
    });

    testWidgets('CyberButton exposes button semantics, tooltip, and loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CyberButton(
                  label: 'Generate QR',
                  onPressed: () {},
                  tooltip: 'Create new customized QR code',
                  semanticHint: 'Double tap to open generator canvas',
                ),
                CyberButton(
                  label: 'Export PNG',
                  onPressed: () {},
                  isLoading: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.enabled == true &&
              w.properties.label == 'Generate QR' &&
              w.properties.hint == 'Double tap to open generator canvas',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Export PNG, loading',
        ),
        findsOneWidget,
      );
    });

    testWidgets('CyberGlassCard exposes button semantics when onTap or semanticLabel is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CyberGlassCard(
                  onTap: () {},
                  semanticLabel: 'Scan History Card',
                  semanticHint: 'Double tap to view details',
                  child: const Text('Record 1'),
                ),
                const CyberGlassCard(
                  child: Text('Static Container'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.enabled == true &&
              w.properties.label == 'Scan History Card' &&
              w.properties.hint == 'Double tap to view details',
        ),
        findsOneWidget,
      );

      expect(find.text('Static Container'), findsOneWidget);
    });

    testWidgets('ThreatScoreGauge dynamic toggle to reduced motion stops animating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThreatScoreGauge(score: 75.0, reducedMotion: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Toggle to reduced motion dynamically
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThreatScoreGauge(score: 85.0, reducedMotion: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('CyberGlassSheet renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: CyberGlassSheet(
              title: 'Light Sheet',
              child: Text('Sheet content in light mode'),
            ),
          ),
        ),
      );

      expect(find.text('Light Sheet'), findsOneWidget);
      expect(find.text('Sheet content in light mode'), findsOneWidget);
    });

    testWidgets('AdaptiveWorkspaceShell renders Medium layout without secondaryPane', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveWorkspaceShell(
            currentIndex: 0,
            onIndexChanged: (_) {},
            items: const [
              WorkspaceNavItem(id: 'scan', label: 'Scanner', icon: Icons.qr_code_scanner),
              WorkspaceNavItem(id: 'vault', label: 'Vault', icon: Icons.lock_outline),
            ],
            body: const Text('Primary Only Content'),
            secondaryPane: null,
          ),
        ),
      );

      expect(find.text('Primary Only Content'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
