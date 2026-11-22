import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/widgets/trust_qr_signer_card.dart';

void main() {
  group('TrustQrSignerCard Widget Tests', () {
    late StudioController controller;

    setUp(() {
      controller = StudioController();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );
    }

    testWidgets('toggles Ed25519 signing and renders verification badge and URI', (tester) async {
      await tester.pumpWidget(createTestApp(TrustQrSignerCard(controller: controller)));

      expect(find.text('TrustQR Cryptographic Signer'), findsOneWidget);
      expect(controller.isTrustQrEnabled, isFalse);

      // Toggle switch ON
      await tester.tap(find.byKey(const Key('trust_qr_toggle_switch')));
      await tester.pumpAndSettle();

      expect(controller.isTrustQrEnabled, isTrue);
      expect(find.byKey(const Key('trust_qr_issuer_field')), findsOneWidget);
      expect(find.byKey(const Key('trust_qr_key_id_field')), findsOneWidget);
      expect(find.text('VALID ED25519 SIGNATURE'), findsOneWidget);
      expect(find.textContaining('trustqr://v1?'), findsOneWidget);

      // Edit issuer field
      await tester.enterText(find.byKey(const Key('trust_qr_issuer_field')), 'Global Authority Network');
      expect(controller.authorityIssuer, 'Global Authority Network');

      // Edit key ID field
      await tester.enterText(find.byKey(const Key('trust_qr_key_id_field')), 'node-auth-42');
      expect(controller.keyId, 'node-auth-42');

      // Tap regenerate keypair
      await tester.tap(find.byTooltip('Regenerate Ed25519 Keypair'));
      await tester.pumpAndSettle();
      expect(controller.activeKeyPair, isNotNull);

      // Toggle switch OFF
      await tester.tap(find.byKey(const Key('trust_qr_toggle_switch')));
      await tester.pumpAndSettle();
      expect(controller.isTrustQrEnabled, isFalse);
      expect(find.text('VALID ED25519 SIGNATURE'), findsNothing);
    });
  });
}
