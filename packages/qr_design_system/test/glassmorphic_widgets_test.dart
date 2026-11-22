import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberGlassCard Widget Tests', () {
    testWidgets('Renders child with default padding, blur, and border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberGlassCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('Renders with zero blur directly without BackdropFilter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberGlassCard(
              blur: 0,
              child: Text('Crisp Card'),
            ),
          ),
        ),
      );

      expect(find.text('Crisp Card'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: Scaffold(
            body: CyberGlassCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Renders with glow shadow and margin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberGlassCard(
              hasGlow: true,
              glowColor: CyberColors.neonCyan,
              margin: EdgeInsets.all(20),
              width: 200,
              height: 100,
              child: Text('Glowing Box'),
            ),
          ),
        ),
      );

      expect(find.text('Glowing Box'), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });
  });

  group('CyberGlassSheet Widget Tests', () {
    testWidgets('Renders child, title, and drag handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberGlassSheet(
              title: 'Threat Detection Alert',
              trailing: Icon(Icons.close),
              showHandle: true,
              child: Text('Sheet Body Content'),
            ),
          ),
        ),
      );

      expect(find.text('Threat Detection Alert'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Sheet Body Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('Renders without handle and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CyberTheme.dark(),
          home: const Scaffold(
            body: CyberGlassSheet(
              showHandle: false,
              backgroundColor: CyberColors.slateCard,
              borderColor: CyberColors.neonCyan,
              child: Text('Minimal Sheet'),
            ),
          ),
        ),
      );

      expect(find.text('Minimal Sheet'), findsOneWidget);
    });
  });
}
