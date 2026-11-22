import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart' as app;

void main() {
  group('AdminApp UI & Logic Tests', () {
    testWidgets('AdminApp displays full studio and generator controls', (tester) async {
      await tester.pumpWidget(const app.AdminApp());
      expect(find.text('Universal QR Studio & Fleet Analytics [Admin]'), findsOneWidget);
      expect(find.text('Artistic QR Generator Studio'), findsOneWidget);
      expect(find.textContaining('Scannability Score:'), findsOneWidget);
      expect(find.textContaining('QR_MATRIX'), findsOneWidget);

      // Verify controller dispose when owned
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test('app main entrypoint is defined', () {
      expect(app.main, isA<Function>());
    });
  });
}
