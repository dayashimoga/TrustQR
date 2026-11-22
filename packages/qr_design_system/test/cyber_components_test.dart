import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberButton Widget Tests', () {
    testWidgets('Renders all button variants correctly', (tester) async {
      for (final variant in CyberButtonVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: CyberTheme.dark(),
            home: Scaffold(
              body: CyberButton(
                label: 'Action ${variant.name}',
                icon: Icons.flash_on,
                variant: variant,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Action ${variant.name}'), findsOneWidget);
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
      }
    });

    testWidgets('Triggers onPressed callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: Scaffold(
            body: CyberButton(
              label: 'Launch Scan',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Scan'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Displays progress indicator and ignores tap when isLoading is true', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: Scaffold(
            body: CyberButton(
              label: 'Generating...',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating...'), findsNothing);

      await tester.tap(find.byType(CyberButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('Renders disabled state when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberButton(
              label: 'Locked Feature',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('Locked Feature'), findsOneWidget);
    });
  });

  group('CyberBadge Widget Tests', () {
    testWidgets('Renders all badge types with custom icon or pulse dot', (tester) async {
      for (final type in CyberBadgeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: CyberTheme.dark(),
            home: Scaffold(
              body: Row(
                children: [
                  CyberBadge(text: 'TAG_${type.name}', type: type, icon: Icons.tag),
                  CyberBadge(text: 'PULSE_${type.name}', type: type, showPulseDot: true, isPill: false),
                ],
              ),
            ),
          ),
        );

        expect(find.text('TAG_${type.name}'), findsOneWidget);
        expect(find.text('PULSE_${type.name}'), findsOneWidget);
      }
    });
  });

  group('ThreatScoreGauge Widget Tests', () {
    testWidgets('Renders secure score tier (>=80)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: ThreatScoreGauge(
              score: 95.0,
              title: 'SAFETY SCORE',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('SAFETY SCORE'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('SECURE'), findsOneWidget);
    });

    testWidgets('Renders caution tier (50-79) and critical tier (<50)', (tester) async {
      // Caution tier
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: ThreatScoreGauge(score: 65.0),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('CAUTION'), findsOneWidget);

      // Critical tier
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: ThreatScoreGauge(score: 25.0, showLabel: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('25'), findsOneWidget);
      expect(find.text('CRITICAL'), findsNothing); // showLabel is false
    });

    testWidgets('Animates score changes via didUpdateWidget', (tester) async {
      var score = 30.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: Scaffold(
                body: ThreatScoreGauge(score: score),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => score = 90.0),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('30'), findsOneWidget);

      // Trigger update
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('90'), findsOneWidget);
    });
  });

  group('TrustQrBadge Widget Tests', () {
    testWidgets('Renders authentic TrustQR badge in full card and compact modes', (tester) async {
      // Full mode
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: Scaffold(
            body: TrustQrBadge(
              isAuthentic: true,
              institutionName: 'Global Transit Authority',
              keyId: 'ed25519:e4a1b8c2',
              isCompact: false,
            ),
          ),
        ),
      );

      expect(find.text('TRUSTQR VERIFIED'), findsOneWidget);
      expect(find.text('Global Transit Authority'), findsOneWidget);
      expect(find.text('KEY: ed25519:e4a1b8c2'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);

      // Compact mode
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: TrustQrBadge(
              isAuthentic: true,
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('TRUSTQR VERIFIED'), findsOneWidget);
    });

    testWidgets('Renders tampered / invalid signature badge in full and compact modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: TrustQrBadge(
              isAuthentic: false,
              institutionName: 'Unknown Spoofed Issuer',
              isCompact: false,
            ),
          ),
        ),
      );

      expect(find.text('SIGNATURE INVALID'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);

      // Compact invalid
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: TrustQrBadge(
              isAuthentic: false,
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('SIGNATURE INVALID'), findsOneWidget);
    });
  });
}
