import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/main.dart';

void main() {
  group('UserApp UI & Logic Tests', () {
    testWidgets('UserApp launches with restricted scanner workspace title', (tester) async {
      await tester.pumpWidget(const UserApp());
      expect(find.text('Universal QR Scanner [User App]'), findsOneWidget);
      expect(find.text('Restricted Scanner Workspace'), findsOneWidget);
    });

    testWidgets('UserApp performs scan and shows threat level', (tester) async {
      await tester.pumpWidget(const UserApp());
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'https://secure.example.com');
      await tester.tap(find.text('Execute Threat-Audited Scan'));
      await tester.pump();

      expect(find.textContaining('Type: url'), findsOneWidget);
      expect(find.textContaining('Threat Level: safe'), findsOneWidget);
    });
  });
}
