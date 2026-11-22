import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:user_app/src/widgets/payload_action_card.dart';

void main() {
  group('PayloadActionCard Format & Action Tests', () {
    testWidgets('Renders UrlPayload with host, scheme, and triggers open/copy actions', (tester) async {
      String? executedAction;
      String? executedDetails;
      String? copiedText;

      final payload = UrlPayload(uri: Uri.parse('https://cyberqr.network/trust'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: payload,
              onActionExecuted: (act, det) {
                executedAction = act;
                executedDetails = det;
              },
              onCopyRequested: (txt) => copiedText = txt,
            ),
          ),
        ),
      );

      expect(find.text('URL'), findsOneWidget);
      expect(find.text('url'), findsOneWidget);
      expect(find.text('cyberqr.network'), findsOneWidget);
      expect(find.text('HTTPS'), findsOneWidget);
      expect(find.text('https://cyberqr.network/trust'), findsOneWidget);

      // Tap Copy URL
      await tester.tap(find.text('Copy URL'));
      await tester.pumpAndSettle();
      expect(copiedText, equals('https://cyberqr.network/trust'));
      expect(find.text('URL copied to clipboard'), findsOneWidget);

      // Tap Open Safe Link
      await tester.tap(find.text('Open Safe Link'));
      expect(executedAction, equals('open_url'));
      expect(executedDetails, equals('https://cyberqr.network/trust'));
    });

    testWidgets('UrlPayload respects quarantine lock and override unlock', (tester) async {
      final payload = UrlPayload(uri: Uri.parse('http://phishing.site/login'));

      // Locked state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: payload,
              isQuarantined: true,
              isActionUnlocked: false,
            ),
          ),
        ),
      );

      expect(find.text('Link Quarantined'), findsOneWidget);

      // Unlocked state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: payload,
              isQuarantined: true,
              isActionUnlocked: true,
            ),
          ),
        ),
      );

      expect(find.text('Open Safe Link'), findsOneWidget);
    });

    testWidgets('Renders WifiPayload with SSID, auth, and actions', (tester) async {
      String? executedAction;
      String? copiedText;

      const payload = WifiPayload(
        ssid: 'CyberLab',
        password: 'neonP@ssw0rd',
        authType: WifiAuthType.wpa,
        isHidden: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: payload,
              onActionExecuted: (act, _) => executedAction = act,
              onCopyRequested: (txt) => copiedText = txt,
            ),
          ),
        ),
      );

      expect(find.text('CyberLab'), findsOneWidget);
      expect(find.text('WPA'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);

      // Tap Connect Network
      await tester.tap(find.text('Connect Network'));
      expect(executedAction, equals('connect_wifi'));

      // Tap Copy Password
      await tester.tap(find.text('Copy Password'));
      await tester.pumpAndSettle();
      expect(copiedText, equals('neonP@ssw0rd'));
    });

    testWidgets('Renders VCardPayload and MeCardPayload with contact info and save action', (tester) async {
      String? executedAction;
      const vcard = VCardPayload(
        formattedName: 'Alice Smith',
        phoneNumbers: ['+15550199'],
        emails: ['alice@corp.org'],
        organization: 'Apex Labs',
        title: 'Chief Architect',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: vcard,
              onActionExecuted: (act, _) => executedAction = act,
            ),
          ),
        ),
      );

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('+15550199'), findsOneWidget);
      expect(find.text('alice@corp.org'), findsOneWidget);
      expect(find.text('Apex Labs'), findsOneWidget);
      expect(find.text('Chief Architect'), findsOneWidget);

      await tester.tap(find.text('Save Contact'));
      expect(executedAction, equals('save_contact'));

      // MeCard
      const mecard = MeCardPayload(
        name: 'Bob Jones',
        telephone: '+15550188',
        email: 'bob@corp.org',
        note: 'Project Lead',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: mecard,
              onActionExecuted: (act, _) => executedAction = act,
            ),
          ),
        ),
      );

      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Project Lead'), findsOneWidget);
    });

    testWidgets('Renders OtpAuthPayload with account, issuer, and copy secret action', (tester) async {
      String? copiedText;
      const payload = OtpAuthPayload(
        accountName: 'Acme:alice@example.com',
        issuer: 'Acme',
        secret: 'JBSWY3DPEHPK3PXP',
        otpType: OtpType.totp,
        digits: 6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: payload,
              onCopyRequested: (txt) => copiedText = txt,
            ),
          ),
        ),
      );

      expect(find.text('Acme:alice@example.com'), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('TOTP'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      await tester.tap(find.text('Copy Code'));
      await tester.pumpAndSettle();
      expect(copiedText, equals('JBSWY3DPEHPK3PXP'));
    });

    testWidgets('Renders UpiPaymentPayload and EpcPaymentPayload with payment actions', (tester) async {
      String? executedAction;
      const upi = UpiPaymentPayload(
        payeeVpa: 'merchant@upi',
        payeeName: 'ApexStore',
        amount: 500.00,
        currency: 'INR',
        transactionNote: 'Order42',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: upi,
              onActionExecuted: (act, _) => executedAction = act,
            ),
          ),
        ),
      );

      expect(find.text('ApexStore'), findsOneWidget);
      expect(find.text('merchant@upi'), findsOneWidget);
      expect(find.text('INR 500.00'), findsOneWidget);

      await tester.tap(find.text('Pay via UPI'));
      expect(executedAction, equals('pay_upi'));

      // EPC Payment
      const epc = EpcPaymentPayload(
        recipientName: 'EuroCorp',
        iban: 'DE89370400440532013000',
        bic: 'DEUTDEDBFXX',
        amount: 250.00,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(payload: epc),
          ),
        ),
      );

      expect(find.text('EuroCorp'), findsOneWidget);
      expect(find.text('DE89370400440532013000'), findsOneWidget);
      expect(find.text('EUR 250.00'), findsOneWidget);
    });

    testWidgets('Renders CryptoPaymentPayload and GeoPayload with map/copy actions', (tester) async {
      String? executedAction;
      const crypto = CryptoPaymentPayload(
        currency: CryptoCurrency.bitcoin,
        address: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
        amount: '0.05',
        label: 'Satoshi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(payload: crypto),
          ),
        ),
      );

      expect(find.text('BITCOIN'), findsOneWidget);
      expect(find.text('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'), findsOneWidget);
      expect(find.text('0.05 BITCOIN'), findsOneWidget);

      // Geo Payload
      const geo = GeoPayload(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 50.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: geo,
              onActionExecuted: (act, _) => executedAction = act,
            ),
          ),
        ),
      );

      expect(find.text('37.774900'), findsOneWidget);
      expect(find.text('-122.419400'), findsOneWidget);
      expect(find.text('50.00 m'), findsOneWidget);

      await tester.tap(find.text('Open in Maps'));
      expect(executedAction, equals('open_map'));
    });

    testWidgets('Renders Email, SMS, Tel, Event, GS1, and PlainText payloads', (tester) async {
      // Email
      const email = EmailPayload(to: 'support@universalqr.org', subject: 'Inquiry', body: 'Hello');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: email))));
      expect(find.text('support@universalqr.org'), findsOneWidget);
      expect(find.text('Inquiry'), findsOneWidget);

      // SMS
      const sms = SmsPayload(phoneNumber: '+1234567890', message: 'Check-in');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: sms))));
      expect(find.text('+1234567890'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);

      // Tel
      const tel = TelPayload(phoneNumber: '+18005550199');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: tel))));
      expect(find.text('+18005550199'), findsOneWidget);

      // Event
      final event = EventPayload(summary: 'Cyber Expo 2026', location: 'Neo Tokyo', dtStart: DateTime(2026, 11, 22));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: event))));
      expect(find.text('Cyber Expo 2026'), findsOneWidget);
      expect(find.text('Neo Tokyo'), findsOneWidget);

      // GS1
      const gs1 = Gs1DigitalLinkPayload(gtin: '09520123456788', serialNumber: '10001');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: gs1))));
      expect(find.text('09520123456788'), findsOneWidget);

      // PlainText
      String? copied;
      const plain = PlainTextPayload(text: 'Universal Cyber Platform Token 2026');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayloadActionCard(
              payload: plain,
              onCopyRequested: (txt) => copied = txt,
            ),
          ),
        ),
      );
      expect(find.text('Universal Cyber Platform Token 2026'), findsOneWidget);
      await tester.tap(find.text('Copy Content'));
      expect(copied, equals('Universal Cyber Platform Token 2026'));
    });

    testWidgets('Triggers action and copy buttons for remaining formats', (tester) async {
      final actions = <String>[];
      final copied = <String>[];

      void onAction(String a, String d) => actions.add(a);
      void onCopy(String c) => copied.add(c);

      // 1. VCard copy details
      const vcard = VCardPayload(formattedName: 'Bob');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: vcard, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Copy Details'));
      await tester.pump();

      // 2. MeCard save contact and copy details
      const mecard = MeCardPayload(name: 'Charlie');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: mecard, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Save Contact'));
      await tester.tap(find.text('Copy Details'));
      await tester.pump();

      // 3. UPI copy VPA
      const upi = UpiPaymentPayload(payeeVpa: 'u@upi', payeeName: 'U');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: upi, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Copy VPA'));
      await tester.pump();

      // 4. EPC copy IBAN
      const epc = EpcPaymentPayload(recipientName: 'R', iban: 'DE123', bic: 'B');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: epc, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Copy IBAN'));
      await tester.pump();

      // 5. Crypto copy Address
      const crypto = CryptoPaymentPayload(currency: CryptoCurrency.bitcoin, address: '123');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: crypto, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Copy Address'));
      await tester.pump();

      // 6. Geo copy Coordinates
      const geo = GeoPayload(latitude: 10, longitude: 20);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: geo, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Copy Coordinates'));
      await tester.pump();

      // 7. Email compose & copy
      const email = EmailPayload(to: 'a@b.com');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: email, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Compose Email'));
      await tester.tap(find.text('Copy Email'));
      await tester.pump();

      // 8. SMS send & copy
      const sms = SmsPayload(phoneNumber: '1234');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: sms, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Send SMS'));
      await tester.tap(find.text('Copy Number'));
      await tester.pump();

      // 9. Tel call & copy
      const tel = TelPayload(phoneNumber: '5678');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: tel, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Call'));
      await tester.tap(find.text('Copy Number'));
      await tester.pump();

      // 10. Event add & copy
      final event = EventPayload(summary: 'Meet', dtStart: DateTime(2026, 1, 1));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: event, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Add Event'));
      await tester.tap(find.text('Copy Details'));
      await tester.pump();

      // 11. GS1 lookup & copy
      const gs1 = Gs1DigitalLinkPayload(gtin: '0123');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PayloadActionCard(payload: gs1, onActionExecuted: onAction, onCopyRequested: onCopy))));
      await tester.tap(find.text('Lookup GS1'));
      await tester.tap(find.text('Copy GTIN'));
      await tester.pump();

      expect(actions.isNotEmpty, isTrue);
      expect(copied.isNotEmpty, isTrue);
    });
  });
}
