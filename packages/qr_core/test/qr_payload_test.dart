import 'package:test/test.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('QrPayload Tests - 15 Structured Formats', () {
    // 1. URL
    test('1. UrlPayload: parsing, validation, serialization, equality', () {
      const raw = 'https://universal-qr.org/scan?ref=test';
      final payload = QrPayloadParser.parse(raw) as UrlPayload;

      expect(payload.type, equals(QrPayloadType.url));
      expect(payload.host, equals('universal-qr.org'));
      expect(payload.scheme, equals('https'));
      expect(payload.path, equals('/scan'));
      expect(payload.queryParameters['ref'], equals('test'));
      expect(payload.validate().isValid, isTrue);
      expect(payload.toRawPayload(), equals(raw));
      expect(payload.toJson()['host'], equals('universal-qr.org'));

      final samePayload = UrlPayload(uri: Uri.parse(raw));
      expect(payload, equals(samePayload));
      expect(payload.hashCode, equals(samePayload.hashCode));

      final invalid = UrlPayload(uri: Uri.parse('ftp://invalid.com'));
      expect(invalid.validate().isValid, isFalse);
    });

    // 2. Wi-Fi
    test('2. WifiPayload: parsing all auth types, hidden, escaped chars, validation', () {
      const raw = r'WIFI:S:Office\;Guest;T:WPA;P:secret\:123;H:true;;';
      final payload = QrPayloadParser.parse(raw) as WifiPayload;

      expect(payload.type, equals(QrPayloadType.wifi));
      expect(payload.ssid, equals('Office;Guest'));
      expect(payload.password, equals('secret:123'));
      expect(payload.authType, equals(WifiAuthType.wpa));
      expect(payload.isHidden, isTrue);
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['ssid'], equals('Office;Guest'));
      expect(json['authType'], equals('wpa'));
      expect(json['isHidden'], isTrue);

      // Variations
      final wep = QrPayloadParser.parse('WIFI:S:Net;T:WEP;P:12345;;') as WifiPayload;
      expect(wep.authType, equals(WifiAuthType.wep));

      final wpa2 = QrPayloadParser.parse('WIFI:S:Net;T:WPA2;P:pass;;') as WifiPayload;
      expect(wpa2.authType, equals(WifiAuthType.wpa2));

      final wpa3 = QrPayloadParser.parse('WIFI:S:Net;T:WPA3;P:pass;;') as WifiPayload;
      expect(wpa3.authType, equals(WifiAuthType.wpa3));

      final openNet = QrPayloadParser.parse('WIFI:S:OpenWifi;T:nopass;P:;;') as WifiPayload;
      expect(openNet.authType, equals(WifiAuthType.none));
      expect(openNet.validate().isValid, isTrue);
      expect(openNet.toRawPayload(), equals('WIFI:S:OpenWifi;T:nopass;P:;H:false;;'));

      // Invalids
      const emptySsid = WifiPayload(ssid: '');
      expect(emptySsid.validate().isValid, isFalse);

      const emptySecuredPass = WifiPayload(ssid: 'Net', password: '', authType: WifiAuthType.wpa);
      expect(emptySecuredPass.validate().isValid, isFalse);

      expect(payload, equals(WifiPayload(ssid: 'Office;Guest', password: 'secret:123', authType: WifiAuthType.wpa, isHidden: true)));
      expect(payload.hashCode, equals(WifiPayload(ssid: 'Office;Guest', password: 'secret:123', authType: WifiAuthType.wpa, isHidden: true).hashCode));
    });

    // 3. vCard
    test('3. VCardPayload: parsing 3.0 lines, name, phone, emails, validation, raw output', () {
      const raw = '''BEGIN:VCARD
VERSION:3.0
N:Doe;John;;;
FN:John Doe
ORG:Acme Corp
TITLE:Lead Architect
TEL:+1-555-0199
TEL:+1-555-0200
EMAIL:john.doe@acme.com
URL:https://acme.com
ADR:;;123 Main St;Springfield;IL;62701;USA
NOTE:Specialist in QR security
END:VCARD''';

      final payload = QrPayloadParser.parse(raw) as VCardPayload;
      expect(payload.type, equals(QrPayloadType.vcard));
      expect(payload.formattedName, equals('John Doe'));
      expect(payload.firstName, equals('John'));
      expect(payload.lastName, equals('Doe'));
      expect(payload.organization, equals('Acme Corp'));
      expect(payload.title, equals('Lead Architect'));
      expect(payload.phoneNumbers.length, equals(2));
      expect(payload.phoneNumbers[0], equals('+1-555-0199'));
      expect(payload.emails, contains('john.doe@acme.com'));
      expect(payload.urls, contains('https://acme.com'));
      expect(payload.addresses.first, contains('123 Main St'));
      expect(payload.note, equals('Specialist in QR security'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['formattedName'], equals('John Doe'));
      expect(json['organization'], equals('Acme Corp'));
      expect(json['title'], equals('Lead Architect'));
      expect(json['phoneNumbers'], equals(['+1-555-0199', '+1-555-0200']));
      expect(json['emails'], equals(['john.doe@acme.com']));
      expect(json['urls'], equals(['https://acme.com']));
      expect(json['note'], equals('Specialist in QR security'));

      final rawOut = payload.toRawPayload();
      expect(rawOut, contains('BEGIN:VCARD'));
      expect(rawOut, contains('FN:John Doe'));
      expect(rawOut, contains('END:VCARD'));

      // Invalids
      const invalidName = VCardPayload(formattedName: '');
      expect(invalidName.validate().isValid, isFalse);

      const invalidEmail = VCardPayload(formattedName: 'Valid', emails: ['not-an-email']);
      expect(invalidEmail.validate().isValid, isFalse);
    });

    // 4. MeCard
    test('4. MeCardPayload: parsing, escaped colons, validation, raw output', () {
      const raw = 'MECARD:N:Smith,Jane;TEL:5551234;EMAIL:jane@test.org;URL:https://jane.me;NOTE:Notes here;ADR:Boston, MA;;';
      final payload = QrPayloadParser.parse(raw) as MeCardPayload;

      expect(payload.type, equals(QrPayloadType.mecard));
      expect(payload.name, equals('Smith,Jane'));
      expect(payload.telephone, equals('5551234'));
      expect(payload.email, equals('jane@test.org'));
      expect(payload.url, equals('https://jane.me'));
      expect(payload.note, equals('Notes here'));
      expect(payload.address, equals('Boston, MA'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['name'], equals('Smith,Jane'));
      expect(json['telephone'], equals('5551234'));
      expect(json['email'], equals('jane@test.org'));
      expect(json['url'], equals('https://jane.me'));
      expect(json['note'], equals('Notes here'));
      expect(json['address'], equals('Boston, MA'));

      final serialized = payload.toRawPayload();
      expect(serialized, startsWith('MECARD:N:Smith,Jane;'));
      expect(serialized, endsWith(';;'));

      const invalidName = MeCardPayload(name: '');
      expect(invalidName.validate().isValid, isFalse);

      const invalidEmail = MeCardPayload(name: 'Valid', email: 'bad-email');
      expect(invalidEmail.validate().isValid, isFalse);
    });

    // 5. Geographic Coordinates
    test('5. GeoPayload: parsing coordinates with altitude and query, validation', () {
      const raw = 'geo:37.7749,-122.4194,15.5?q=San+Francisco';
      final payload = QrPayloadParser.parse(raw) as GeoPayload;

      expect(payload.type, equals(QrPayloadType.geo));
      expect(payload.latitude, equals(37.7749));
      expect(payload.longitude, equals(-122.4194));
      expect(payload.altitude, equals(15.5));
      expect(payload.query, equals('San Francisco'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['latitude'], equals(37.7749));
      expect(json['longitude'], equals(-122.4194));
      expect(json['altitude'], equals(15.5));
      expect(json['query'], equals('San Francisco'));

      final rawOut = payload.toRawPayload();
      expect(rawOut, contains('geo:37.7749,-122.4194,15.5?q=San%20Francisco'));

      const outOfRangeLat = GeoPayload(latitude: 91.0, longitude: 0.0);
      expect(outOfRangeLat.validate().isValid, isFalse);

      const outOfRangeLng = GeoPayload(latitude: 0.0, longitude: 185.0);
      expect(outOfRangeLng.validate().isValid, isFalse);
    });

    // 6. iCalendar VEVENT Event
    test('6. EventPayload: parsing date formats, location, description, validation', () {
      const raw = '''BEGIN:VEVENT
SUMMARY:Global Tech Summit
DTSTART:20261201T090000Z
DTEND:20261201T170000Z
LOCATION:Moscone Center
DESCRIPTION:Universal QR Platform Keynote
END:VEVENT''';

      final payload = QrPayloadParser.parse(raw) as EventPayload;
      expect(payload.type, equals(QrPayloadType.event));
      expect(payload.summary, equals('Global Tech Summit'));
      expect(payload.dtStart.year, equals(2026));
      expect(payload.dtStart.month, equals(12));
      expect(payload.dtStart.day, equals(1));
      expect(payload.dtStart.hour, equals(9));
      expect(payload.dtEnd?.hour, equals(17));
      expect(payload.location, equals('Moscone Center'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['summary'], equals('Global Tech Summit'));
      expect(json['location'], equals('Moscone Center'));
      expect(json['description'], equals('Universal QR Platform Keynote'));
      expect(json['isAllDay'], isFalse);

      final rawOut = payload.toRawPayload();
      expect(rawOut, contains('BEGIN:VEVENT'));
      expect(rawOut, contains('SUMMARY:Global Tech Summit'));
      expect(rawOut, contains('END:VEVENT'));

      // Invalids
      final invalidDates = EventPayload(
        summary: 'Invalid Time Event',
        dtStart: DateTime.utc(2026, 12, 2),
        dtEnd: DateTime.utc(2026, 12, 1),
      );
      expect(invalidDates.validate().isValid, isFalse);

      final emptySummary = EventPayload(
        summary: '',
        dtStart: DateTime.now(),
      );
      expect(emptySummary.validate().isValid, isFalse);
    });

    // 7. Email
    test('7. EmailPayload: mailto and MATMSG formats, query params, validation', () {
      const mailtoRaw = 'mailto:security@universal-qr.org?subject=Bug+Report&body=Threat+Detected&cc=team@universal-qr.org';
      final p1 = QrPayloadParser.parse(mailtoRaw) as EmailPayload;

      expect(p1.type, equals(QrPayloadType.email));
      expect(p1.to, equals('security@universal-qr.org'));
      expect(p1.subject, equals('Bug Report'));
      expect(p1.body, equals('Threat Detected'));
      expect(p1.cc, equals('team@universal-qr.org'));
      expect(p1.validate().isValid, isTrue);

      final json = p1.toJson();
      expect(json['to'], equals('security@universal-qr.org'));
      expect(json['subject'], equals('Bug Report'));
      expect(json['body'], equals('Threat Detected'));
      expect(json['cc'], equals('team@universal-qr.org'));

      const matmsgRaw = 'MATMSG:TO:admin@test.com;SUB:Hello;BODY:World;;';
      final p2 = QrPayloadParser.parse(matmsgRaw) as EmailPayload;
      expect(p2.to, equals('admin@test.com'));
      expect(p2.subject, equals('Hello'));
      expect(p2.body, equals('World'));
      expect(p2.validate().isValid, isTrue);

      const invalidEmail = EmailPayload(to: 'not-an-email');
      expect(invalidEmail.validate().isValid, isFalse);
    });

    // 8. SMS
    test('8. SmsPayload: sms and smsto formats, message encoding, validation', () {
      const smsRaw = 'sms:+15551234567?body=Secure+Confirmation+Code';
      final p1 = QrPayloadParser.parse(smsRaw) as SmsPayload;
      expect(p1.type, equals(QrPayloadType.sms));
      expect(p1.phoneNumber, equals('+15551234567'));
      expect(p1.message, equals('Secure Confirmation Code'));
      expect(p1.validate().isValid, isTrue);
      expect(p1.toRawPayload(), contains('sms:+15551234567?body=Secure%20Confirmation%20Code'));

      final json = p1.toJson();
      expect(json['phoneNumber'], equals('+15551234567'));
      expect(json['message'], equals('Secure Confirmation Code'));

      const smstoRaw = 'smsto:+15559876543:Hello There';
      final p2 = QrPayloadParser.parse(smstoRaw) as SmsPayload;
      expect(p2.phoneNumber, equals('+15559876543'));
      expect(p2.message, equals('Hello There'));

      const invalid = SmsPayload(phoneNumber: '');
      expect(invalid.validate().isValid, isFalse);
    });

    // 9. Telephone
    test('9. TelPayload: tel: prefix, validation, serialization', () {
      const telRaw = 'tel:+1-800-555-0199';
      final payload = QrPayloadParser.parse(telRaw) as TelPayload;
      expect(payload.type, equals(QrPayloadType.tel));
      expect(payload.phoneNumber, equals('+1-800-555-0199'));
      expect(payload.validate().isValid, isTrue);
      expect(payload.toRawPayload(), equals(telRaw));

      final json = payload.toJson();
      expect(json['phoneNumber'], equals('+1-800-555-0199'));

      const emptyTel = TelPayload(phoneNumber: '');
      expect(emptyTel.validate().isValid, isFalse);
    });

    // 10. OTP / 2FA Authenticator
    test('10. OtpAuthPayload: TOTP, HOTP, issuer in path vs query, digits, algorithms, validation', () {
      const totpRaw = 'otpauth://totp/UniversalQR:admin@universal-qr.org?secret=JBSWY3DPEHPK3PXP&issuer=UniversalQR&algorithm=SHA256&digits=8&period=60';
      final p1 = QrPayloadParser.parse(totpRaw) as OtpAuthPayload;

      expect(p1.type, equals(QrPayloadType.otpauth));
      expect(p1.otpType, equals(OtpType.totp));
      expect(p1.issuer, equals('UniversalQR'));
      expect(p1.accountName, equals('admin@universal-qr.org'));
      expect(p1.secret, equals('JBSWY3DPEHPK3PXP'));
      expect(p1.algorithm, equals(OtpAlgorithm.sha256));
      expect(p1.digits, equals(8));
      expect(p1.period, equals(60));
      expect(p1.validate().isValid, isTrue);

      final json = p1.toJson();
      expect(json['accountName'], equals('admin@universal-qr.org'));
      expect(json['issuer'], equals('UniversalQR'));
      expect(json['algorithm'], equals('sha256'));
      expect(json['digits'], equals(8));
      expect(json['period'], equals(60));

      final rawOut = p1.toRawPayload();
      expect(rawOut, contains('otpauth://totp/'));
      expect(rawOut, contains('secret=JBSWY3DPEHPK3PXP'));

      // HOTP with counter
      const hotpRaw = 'otpauth://hotp/Bank:user?secret=JBSWY3DPEHPK3PXP&counter=42';
      final p2 = QrPayloadParser.parse(hotpRaw) as OtpAuthPayload;
      expect(p2.otpType, equals(OtpType.hotp));
      expect(p2.counter, equals(42));
      expect(p2.toRawPayload(), contains('counter=42'));

      // Invalids
      const invalidSecret = OtpAuthPayload(accountName: 'user', secret: 'BADSECRET!#%');
      expect(invalidSecret.validate().isValid, isFalse);

      const invalidDigits = OtpAuthPayload(accountName: 'user', secret: 'JBSWY3DPEHPK3PXP', digits: 7);
      expect(invalidDigits.validate().isValid, isFalse);

      const invalidPeriod = OtpAuthPayload(accountName: 'user', secret: 'JBSWY3DPEHPK3PXP', period: 0);
      expect(invalidPeriod.validate().isValid, isFalse);
    });

    // 11. UPI Payment
    test('11. UpiPaymentPayload: VPA, amount, currency, note, merchant code, validation', () {
      const upiRaw = 'upi://pay?pa=merchant@okaxis&pn=Merchant+Store&am=249.50&cu=INR&tn=Invoice+101&mc=5411&tr=TXN999';
      final payload = QrPayloadParser.parse(upiRaw) as UpiPaymentPayload;

      expect(payload.type, equals(QrPayloadType.upi));
      expect(payload.payeeVpa, equals('merchant@okaxis'));
      expect(payload.payeeName, equals('Merchant Store'));
      expect(payload.amount, equals(249.50));
      expect(payload.currency, equals('INR'));
      expect(payload.transactionNote, equals('Invoice 101'));
      expect(payload.merchantCode, equals('5411'));
      expect(payload.transactionRef, equals('TXN999'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['payeeVpa'], equals('merchant@okaxis'));
      expect(json['payeeName'], equals('Merchant Store'));
      expect(json['amount'], equals(249.50));
      expect(json['currency'], equals('INR'));
      expect(json['transactionNote'], equals('Invoice 101'));
      expect(json['merchantCode'], equals('5411'));
      expect(json['transactionRef'], equals('TXN999'));

      final rawOut = payload.toRawPayload();
      expect(rawOut, contains('pa=merchant%40okaxis'));
      expect(rawOut, contains('am=249.50'));

      const invalidVpa = UpiPaymentPayload(payeeVpa: 'invalid-vpa', payeeName: 'Store');
      expect(invalidVpa.validate().isValid, isFalse);

      const invalidAmount = UpiPaymentPayload(payeeVpa: 'user@bank', payeeName: 'Store', amount: -10);
      expect(invalidAmount.validate().isValid, isFalse);
    });

    // 12. European EPC / SEPA Payment QR
    test('12. EpcPaymentPayload: BCD format, BIC, IBAN, amount, remittance, validation', () {
      const epcRaw = '''BCD
002
1
SCT
DEUTDEDDFXX
Acme European GmbH
DE89370400440532013000
EUR1500.00

Invoice 2026-X
''';

      final payload = QrPayloadParser.parse(epcRaw) as EpcPaymentPayload;
      expect(payload.type, equals(QrPayloadType.epc));
      expect(payload.bic, equals('DEUTDEDDFXX'));
      expect(payload.recipientName, equals('Acme European GmbH'));
      expect(payload.iban, equals('DE89370400440532013000'));
      expect(payload.amount, equals(1500.00));
      expect(payload.remittanceInfo, equals('Invoice 2026-X'));
      expect(payload.validate().isValid, isTrue);

      final json = payload.toJson();
      expect(json['bic'], equals('DEUTDEDDFXX'));
      expect(json['recipientName'], equals('Acme European GmbH'));
      expect(json['iban'], equals('DE89370400440532013000'));
      expect(json['amount'], equals(1500.00));
      expect(json['remittanceInfo'], equals('Invoice 2026-X'));

      final rawOut = payload.toRawPayload();
      expect(rawOut, startsWith('BCD\n002\n1\nSCT\nDEUTDEDDFXX\nAcme European GmbH\nDE89370400440532013000\nEUR1500.00'));

      const invalidIban = EpcPaymentPayload(bic: 'BIC', recipientName: 'Name', iban: 'BAD_IBAN');
      expect(invalidIban.validate().isValid, isFalse);
    });

    // 13. Cryptocurrency Payment
    test('13. CryptoPaymentPayload: Bitcoin, Ethereum, Solana, Litecoin schemes, query params', () {
      const btcRaw = 'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.025&label=Donation&message=Thank+You';
      final btc = QrPayloadParser.parse(btcRaw) as CryptoPaymentPayload;
      expect(btc.type, equals(QrPayloadType.crypto));
      expect(btc.currency, equals(CryptoCurrency.bitcoin));
      expect(btc.address, equals('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'));
      expect(btc.amount, equals('0.025'));
      expect(btc.label, equals('Donation'));
      expect(btc.message, equals('Thank You'));
      expect(btc.validate().isValid, isTrue);

      final json = btc.toJson();
      expect(json['currency'], equals('bitcoin'));
      expect(json['address'], equals('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'));
      expect(json['amount'], equals('0.025'));
      expect(json['label'], equals('Donation'));
      expect(json['message'], equals('Thank You'));

      expect(btc.toRawPayload(), contains('bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?'));

      const ethRaw = 'ethereum:0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe?value=1.5';
      final eth = QrPayloadParser.parse(ethRaw) as CryptoPaymentPayload;
      expect(eth.currency, equals(CryptoCurrency.ethereum));
      expect(eth.amount, equals('1.5'));

      const solRaw = 'solana:7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';
      final sol = QrPayloadParser.parse(solRaw) as CryptoPaymentPayload;
      expect(sol.currency, equals(CryptoCurrency.solana));

      const emptyAddress = CryptoPaymentPayload(currency: CryptoCurrency.bitcoin, address: '');
      expect(emptyAddress.validate().isValid, isFalse);
    });

    // 14. GS1 Digital Link
    test('14. Gs1DigitalLinkPayload: URI format and AI element string format, validation', () {
      const gs1UriRaw = 'https://id.gs1.org/01/09520123456788/21/XYZ789?10=BATCH42&17=261231';
      final p1 = QrPayloadParser.parse(gs1UriRaw) as Gs1DigitalLinkPayload;

      expect(p1.type, equals(QrPayloadType.gs1));
      expect(p1.gtin, equals('09520123456788'));
      expect(p1.serialNumber, equals('XYZ789'));
      expect(p1.batchLot, equals('BATCH42'));
      expect(p1.expiryDate, equals('261231'));
      expect(p1.validate().isValid, isTrue);

      final json = p1.toJson();
      expect(json['gtin'], equals('09520123456788'));
      expect(json['serialNumber'], equals('XYZ789'));
      expect(json['batchLot'], equals('BATCH42'));
      expect(json['expiryDate'], equals('261231'));

      final rawOut = p1.toRawPayload();
      expect(rawOut, contains('https://id.gs1.org/01/09520123456788/21/XYZ789'));
      expect(rawOut, contains('10=BATCH42'));

      // AI format
      const gs1AiRaw = '(01)09520123456788(21)SER123(10)LOT99';
      final p2 = QrPayloadParser.parse(gs1AiRaw) as Gs1DigitalLinkPayload;
      expect(p2.type, equals(QrPayloadType.gs1));
      expect(p2.gtin, equals('09520123456788'));
      expect(p2.serialNumber, equals('SER123'));
      expect(p2.batchLot, equals('LOT99'));
      expect(p2.validate().isValid, isTrue);

      const invalidGtin = Gs1DigitalLinkPayload(gtin: '1234');
      expect(invalidGtin.validate().isValid, isFalse);
    });

    // 15. Plain Text & JSON
    test('15. PlainTextPayload: plain string and valid JSON parsing, validation', () {
      const textRaw = 'Universal QR Scanner Platform v1.0';
      final p1 = QrPayloadParser.parse(textRaw) as PlainTextPayload;
      expect(p1.type, equals(QrPayloadType.plainText));
      expect(p1.isJson, isFalse);
      expect(p1.text, equals(textRaw));
      expect(p1.validate().isValid, isTrue);

      const jsonRaw = '{"service":"qr_platform","version":1,"active":true}';
      final p2 = QrPayloadParser.parse(jsonRaw) as PlainTextPayload;
      expect(p2.type, equals(QrPayloadType.plainText));
      expect(p2.isJson, isTrue);
      expect(p2.jsonData['service'], equals('qr_platform'));
      expect(p2.jsonData['version'], equals(1));
      expect(p2.validate().isValid, isTrue);

      final json = p2.toJson();
      expect(json['text'], equals(jsonRaw));
      expect(json['isJson'], isTrue);
      expect(json['jsonData']['service'], equals('qr_platform'));

      const empty = PlainTextPayload(text: '');
      expect(empty.validate().isValid, isFalse);
    });

    // QrItem copyWith and fromJson
    test('QrItem copyWith, fromJson, toJson round-trip', () {
      final now = DateTime.now();
      final item = QrItem(
        id: 'item-1',
        rawContent: 'https://example.com',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.safe,
        createdAt: now,
        isFavorite: false,
        tags: ['web'],
      );

      final copy = item.copyWith(isFavorite: true, tags: ['web', 'starred']);
      expect(copy.isFavorite, isTrue);
      expect(copy.tags, equals(['web', 'starred']));
      expect(copy.id, equals('item-1'));

      final json = copy.toJson();
      final restored = QrItem.fromJson(json);
      expect(restored.id, equals(copy.id));
      expect(restored.rawContent, equals(copy.rawContent));
      expect(restored.payloadType, equals(copy.payloadType));
      expect(restored.threatLevel, equals(copy.threatLevel));
      expect(restored.isFavorite, isTrue);
      expect(restored.tags, equals(['web', 'starred']));

      final defaultCopy = item.copyWith();
      expect(defaultCopy.id, equals(item.id));
      expect(defaultCopy.rawContent, equals(item.rawContent));
      expect(defaultCopy.payloadType, equals(item.payloadType));
      expect(defaultCopy.threatLevel, equals(item.threatLevel));
      expect(defaultCopy.createdAt, equals(item.createdAt));
      expect(defaultCopy.isFavorite, equals(item.isFavorite));
      expect(defaultCopy.tags, equals(item.tags));
    });

    test('Edge cases and optional constructor branches', () {
      // OtpAuth with SHA512
      const otp512 = 'otpauth://totp/IssuerOnly?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512';
      final otp = QrPayloadParser.parse(otp512) as OtpAuthPayload;
      expect(otp.algorithm, equals(OtpAlgorithm.sha512));
      expect(otp.toRawPayload(), contains('algorithm=SHA512'));

      // Event without dtEnd
      final eventNoEnd = EventPayload(
        summary: 'Open Ended Event',
        dtStart: DateTime.utc(2026, 11, 22),
      );
      expect(eventNoEnd.toRawPayload(), isNot(contains('DTEND:')));
      expect(eventNoEnd.toRawPayload(), isNot(contains('LOCATION:')));
      expect(eventNoEnd.toRawPayload(), isNot(contains('DESCRIPTION:')));

      // Geo without query or altitude
      const geoSimple = GeoPayload(latitude: 10.0, longitude: 20.0);
      expect(geoSimple.toRawPayload(), equals('geo:10.0,20.0'));

      // SMS without body
      const smsSimple = SmsPayload(phoneNumber: '+1000');
      expect(smsSimple.toRawPayload(), equals('sms:+1000'));

      // Email without subject/body
      const emailSimple = EmailPayload(to: 'simple@test.com');
      expect(emailSimple.toRawPayload(), equals('mailto:simple@test.com'));

      // Crypto with litecoin
      const ltcRaw = 'litecoin:LTCAddress123';
      final ltc = QrPayloadParser.parse(ltcRaw) as CryptoPaymentPayload;
      expect(ltc.currency, equals(CryptoCurrency.litecoin));
      expect(ltc.toRawPayload(), equals('litecoin:LTCAddress123'));

      // Crypto with other currency
      const otherCrypto = CryptoPaymentPayload(currency: CryptoCurrency.other, address: 'XRPAddress');
      expect(otherCrypto.toRawPayload(), equals('other:XRPAddress'));

      // GS1 detection via plain 01 digits
      final gs1Digits = QrPayloadParser.detectType('0109520123456788');
      expect(gs1Digits, equals(QrPayloadType.gs1));
    });
  });
}
