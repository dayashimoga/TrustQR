import 'package:test/test.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('SchemaValidator Tests', () {
    test('validateUrl validates schemes and hosts', () {
      expect(SchemaValidator.validateUrl('https://example.com').isValid, isTrue);
      expect(SchemaValidator.validateUrl('http://insecure.org/path?q=1').isValid, isTrue);
      expect(SchemaValidator.validateUrl('ftp://files.org').isValid, isFalse);
      expect(SchemaValidator.validateUrl('javascript:alert(1)').isValid, isFalse);
      expect(SchemaValidator.validateUrl('   ').isValid, isFalse);
      expect(SchemaValidator.validateUrl('not-a-url').isValid, isFalse);
    });

    test('validateEmail validates RFC compliant emails', () {
      expect(SchemaValidator.validateEmail('user@example.com').isValid, isTrue);
      expect(SchemaValidator.validateEmail('john.doe+tag@sub.domain.co.uk').isValid, isTrue);
      expect(SchemaValidator.validateEmail('invalid-email').isValid, isFalse);
      expect(SchemaValidator.validateEmail('@nodomain.com').isValid, isFalse);
      expect(SchemaValidator.validateEmail('user@').isValid, isFalse);
      expect(SchemaValidator.validateEmail('').isValid, isFalse);
    });

    test('validateCoordinates checks latitude and longitude boundaries', () {
      expect(SchemaValidator.validateCoordinates(0.0, 0.0).isValid, isTrue);
      expect(SchemaValidator.validateCoordinates(90.0, 180.0).isValid, isTrue);
      expect(SchemaValidator.validateCoordinates(-90.0, -180.0).isValid, isTrue);
      expect(SchemaValidator.validateCoordinates(90.1, 0.0).isValid, isFalse);
      expect(SchemaValidator.validateCoordinates(-90.1, 0.0).isValid, isFalse);
      expect(SchemaValidator.validateCoordinates(0.0, 180.1).isValid, isFalse);
      expect(SchemaValidator.validateCoordinates(0.0, -180.1).isValid, isFalse);
    });

    test('validateUpiVpa validates UPI virtual payment addresses', () {
      expect(SchemaValidator.validateUpiVpa('merchant@okaxis').isValid, isTrue);
      expect(SchemaValidator.validateUpiVpa('user.name-123@okhdfcbank').isValid, isTrue);
      expect(SchemaValidator.validateUpiVpa('invalidvpa').isValid, isFalse);
      expect(SchemaValidator.validateUpiVpa('@bank').isValid, isFalse);
      expect(SchemaValidator.validateUpiVpa('').isValid, isFalse);
    });

    test('validateIban validates international bank account numbers', () {
      expect(SchemaValidator.validateIban('DE89370400440532013000').isValid, isTrue);
      expect(SchemaValidator.validateIban('GB29 XAAA 0101 2354 3211 99').isValid, isTrue);
      expect(SchemaValidator.validateIban('TOOSHORT').isValid, isFalse);
      expect(SchemaValidator.validateIban('12345678901234567890').isValid, isFalse);
    });

    test('validateBase32Secret validates Base32 character sets', () {
      expect(SchemaValidator.validateBase32Secret('JBSWY3DPEHPK3PXP').isValid, isTrue);
      expect(SchemaValidator.validateBase32Secret('jbsw y3dp ehpk 3pxp').isValid, isTrue);
      expect(SchemaValidator.validateBase32Secret('INVALID890!').isValid, isFalse);
      expect(SchemaValidator.validateBase32Secret('').isValid, isFalse);
    });
  });
}
