import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart';

void main() {
  group('AdminApp UI & Logic Tests', () {
    testWidgets('AdminApp displays full studio and generator controls', (tester) async {
      await tester.pumpWidget(const AdminApp());
      expect(find.text('Universal QR Studio & Fleet Analytics [Admin]'), findsOneWidget);
      expect(find.text('Artistic QR Generator Studio'), findsOneWidget);
      expect(find.textContaining('Scannability Score:'), findsOneWidget);
      expect(find.textContaining('QR_MATRIX'), findsOneWidget);
    });
  });
}

