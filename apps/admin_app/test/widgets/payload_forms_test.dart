import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/widgets/payload_forms/payload_form_dispatcher.dart';

void main() {
  group('PayloadFormDispatcher Widget Tests', () {
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

    testWidgets('renders all format chips and exercises input fields across all 15 formats', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(PayloadFormDispatcher(controller: controller)));
      expect(find.text('QR Payload & Format'), findsOneWidget);

      // 1. URL
      expect(find.byKey(const Key('url_input_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('url_input_field')), 'https://cyber-precision.org');
      expect(controller.urlAddress, 'https://cyber-precision.org');

      // 2. Wi-Fi
      await tester.tap(find.text('WIFI'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wifi_ssid_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('wifi_ssid_field')), 'CyberMesh_5G');
      await tester.enterText(find.byKey(const Key('wifi_password_field')), 'SecretKey99!');
      expect(controller.wifiSsid, 'CyberMesh_5G');
      expect(controller.wifiPassword, 'SecretKey99!');
      // Toggle hidden SSID checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.wifiIsHidden, isTrue);

      // 3. vCard
      await tester.tap(find.text('VCARD'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('vcard_fn_field')), 'Dr. Vance');
      await tester.enterText(find.byKey(const Key('vcard_org_field')), 'Cyber Corp');
      await tester.enterText(find.byKey(const Key('vcard_title_field')), 'Architect');
      await tester.enterText(find.byKey(const Key('vcard_phone_field')), '+1-555-0100');
      await tester.enterText(find.byKey(const Key('vcard_email_field')), 'vance@cyber.org');
      expect(controller.vcardFormattedName, 'Dr. Vance');
      expect(controller.vcardOrg, 'Cyber Corp');
      expect(controller.vcardTitle, 'Architect');
      expect(controller.vcardPhone, '+1-555-0100');
      expect(controller.vcardEmail, 'vance@cyber.org');

      // 4. MeCard
      await tester.tap(find.text('MECARD'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('mecard_name_field')), 'Vance,Alex');
      await tester.enterText(find.byKey(const Key('mecard_phone_field')), '+1-555-0100');
      await tester.enterText(find.byKey(const Key('mecard_email_field')), 'alex@cyber.org');
      expect(controller.mecardName, 'Vance,Alex');
      expect(controller.mecardPhone, '+1-555-0100');
      expect(controller.mecardEmail, 'alex@cyber.org');

      // 5. Geo
      await tester.tap(find.text('GEO'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('geo_lat_field')), '52.5200');
      await tester.enterText(find.byKey(const Key('geo_lng_field')), '13.4050');
      await tester.enterText(find.byKey(const Key('geo_query_field')), 'Berlin Node');
      expect(controller.geoLat, 52.5200);
      expect(controller.geoLng, 13.4050);
      expect(controller.geoQuery, 'Berlin Node');

      // 6. Event
      await tester.tap(find.text('EVENT'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('event_summary_field')), 'Security Keynote');
      await tester.enterText(find.byKey(const Key('event_location_field')), 'Hall B');
      await tester.enterText(find.byKey(const Key('event_desc_field')), 'Detailed tech briefing');
      expect(controller.eventSummary, 'Security Keynote');
      expect(controller.eventLocation, 'Hall B');
      expect(controller.eventDescription, 'Detailed tech briefing');

      // 7. Email
      await tester.tap(find.text('EMAIL'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_to_field')), 'test@cyber.org');
      await tester.enterText(find.byKey(const Key('email_subject_field')), 'Audit Report');
      await tester.enterText(find.byKey(const Key('email_body_field')), 'Audit confirmed.');
      expect(controller.emailTo, 'test@cyber.org');
      expect(controller.emailSubject, 'Audit Report');
      expect(controller.emailBody, 'Audit confirmed.');

      // 8. SMS
      await tester.tap(find.text('SMS'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sms_phone_field')), '+15550199');
      await tester.enterText(find.byKey(const Key('sms_msg_field')), 'Your OTP is 1234');
      expect(controller.smsPhone, '+15550199');
      expect(controller.smsMessage, 'Your OTP is 1234');

      // 9. Tel
      await tester.tap(find.text('TEL'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tel_phone_field')), '+15559999');
      expect(controller.telPhone, '+15559999');

      // 10. OtpAuth
      await tester.tap(find.text('OTPAUTH'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('otp_account_field')), 'user@domain.com');
      await tester.enterText(find.byKey(const Key('otp_issuer_field')), 'SecureAuth');
      await tester.enterText(find.byKey(const Key('otp_secret_field')), 'JBSWY3DPEHPK3PXP');
      expect(controller.otpAccount, 'user@domain.com');
      expect(controller.otpIssuer, 'SecureAuth');
      expect(controller.otpSecret, 'JBSWY3DPEHPK3PXP');

      // 11. UPI
      await tester.tap(find.text('UPI'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('upi_vpa_field')), 'user@bank');
      await tester.enterText(find.byKey(const Key('upi_payee_field')), 'User Shop');
      await tester.enterText(find.byKey(const Key('upi_amount_field')), '199.50');
      await tester.enterText(find.byKey(const Key('upi_note_field')), 'Invoice #42');
      expect(controller.upiVpa, 'user@bank');
      expect(controller.upiPayee, 'User Shop');
      expect(controller.upiAmount, 199.50);
      expect(controller.upiNote, 'Invoice #42');

      // 12. EPC
      await tester.tap(find.text('EPC'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('epc_bic_field')), 'BICBANKXX');
      await tester.enterText(find.byKey(const Key('epc_recipient_field')), 'GmbH Tech');
      await tester.enterText(find.byKey(const Key('epc_iban_field')), 'DE89370400440532013000');
      await tester.enterText(find.byKey(const Key('epc_amount_field')), '350.00');
      await tester.enterText(find.byKey(const Key('epc_remittance_field')), 'REF123');
      expect(controller.epcBic, 'BICBANKXX');
      expect(controller.epcRecipient, 'GmbH Tech');
      expect(controller.epcIban, 'DE89370400440532013000');
      expect(controller.epcAmount, 350.00);
      expect(controller.epcRemittance, 'REF123');

      // 13. Crypto
      await tester.tap(find.text('CRYPTO'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('crypto_amount_field')), '1.25');
      await tester.enterText(find.byKey(const Key('crypto_addr_field')), '0x1234567890abcdef');
      expect(controller.cryptoAmount, '1.25');
      expect(controller.cryptoAddress, '0x1234567890abcdef');

      // 14. GS1
      await tester.tap(find.text('GS1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('gs1_gtin_field')), '01234567890128');
      await tester.enterText(find.byKey(const Key('gs1_serial_field')), 'SN9999');
      await tester.enterText(find.byKey(const Key('gs1_batch_field')), 'LOT42');
      expect(controller.gs1Gtin, '01234567890128');
      expect(controller.gs1Serial, 'SN9999');
      expect(controller.gs1Batch, 'LOT42');

      // 15. PlainText
      await tester.tap(find.text('PLAINTEXT'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('plaintext_field')), 'Plain text payload for testing');
      expect(controller.plainTextContent, 'Plain text payload for testing');
    });

    testWidgets('toggles raw override mode and inputs custom raw content', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(PayloadFormDispatcher(controller: controller)));

      // Tap raw override switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(controller.useManualRawPayload, isTrue);
      expect(find.byKey(const Key('manual_raw_payload_field')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('manual_raw_payload_field')), 'OVERRIDDEN_CUSTOM_PAYLOAD');
      expect(controller.manualRawPayload, 'OVERRIDDEN_CUSTOM_PAYLOAD');
      expect(controller.effectivePayload, 'OVERRIDDEN_CUSTOM_PAYLOAD');
    });
  });
}
