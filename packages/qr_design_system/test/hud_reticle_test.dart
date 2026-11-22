import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('HudScannerReticle Widget Tests', () {
    testWidgets('Renders scanning state with default status telemetry and laser sweep', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: HudScannerReticle(
              state: ScannerHudState.scanning,
            ),
          ),
        ),
      );

      expect(find.byType(HudScannerReticle), findsOneWidget);
      expect(find.text('SCANNING // ZERO-TRUST FIREWALL ACTIVE'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance animation frame
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HudScannerReticle), findsOneWidget);
    });

    testWidgets('Renders all HUD states with appropriate status telemetry', (tester) async {
      for (final state in ScannerHudState.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: CyberTheme.dark(),
            home: Scaffold(
              body: HudScannerReticle(state: state),
            ),
          ),
        );

        expect(find.byType(HudScannerReticle), findsOneWidget);
        switch (state) {
          case ScannerHudState.idle:
            expect(find.text('READY // ALIGN QR CODE'), findsOneWidget);
            break;
          case ScannerHudState.scanning:
            expect(find.text('SCANNING // ZERO-TRUST FIREWALL ACTIVE'), findsOneWidget);
            break;
          case ScannerHudState.safe:
            expect(find.text('VERIFIED // SAFE PAYLOAD'), findsOneWidget);
            break;
          case ScannerHudState.warning:
            expect(find.text('CAUTION // SUSPICIOUS ANOMALY'), findsOneWidget);
            break;
          case ScannerHudState.threat:
            expect(find.text('THREAT DETECTED // ACCESS QUARANTINED'), findsOneWidget);
            break;
        }
      }
    });

    testWidgets('Supports custom status text and center overlay widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: HudScannerReticle(
              state: ScannerHudState.safe,
              statusText: 'TRUSTED INSTITUTION SIGNATURE',
              centerOverlay: Icon(Icons.check_circle, size: 48, color: CyberColors.neonEmerald),
            ),
          ),
        ),
      );

      expect(find.text('TRUSTED INSTITUTION SIGNATURE'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Transitions states dynamically via didUpdateWidget', (tester) async {
      var state = ScannerHudState.idle;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: CyberTheme.dark(),
              home: Scaffold(
                body: HudScannerReticle(state: state),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => state = ScannerHudState.scanning),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('READY // ALIGN QR CODE'), findsOneWidget);

      // Trigger transition to scanning
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('SCANNING // ZERO-TRUST FIREWALL ACTIVE'), findsOneWidget);
    });
  });
}
