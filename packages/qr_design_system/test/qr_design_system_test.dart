import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberTokens & GlassmorphicCard Tests', () {
    test('Dark Cyber Theme initializes with expected palette', () {
      final theme = CyberTokens.createDarkCyberTheme();
      expect(theme.scaffoldBackgroundColor, equals(CyberTokens.obsidianBackground));
      expect(theme.colorScheme.primary, equals(CyberTokens.neonCyan));
    });

    testWidgets('GlassmorphicCard renders child correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: const Text('Cyber Precision HUD', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      );

      expect(find.text('Cyber Precision HUD'), findsOneWidget);
    });
  });
}
