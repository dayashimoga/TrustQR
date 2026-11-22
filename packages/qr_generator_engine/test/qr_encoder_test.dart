import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

void main() {
  group('QR Polynomial & Galois Field Tests', () {
    final field = QrGaloisField.instance;

    test('Galois Field basic arithmetic', () {
      final f2 = QrGaloisField();
      expect(identical(f2, field), isTrue);

      expect(field.add(5, 3), equals(5 ^ 3));
      expect(field.subtract(5, 3), equals(5 ^ 3));
      expect(field.divide(10, 2), equals(field.multiply(10, field.inverse(2))));
      expect(field.divide(0, 5), equals(0));
      expect(() => field.divide(5, 0), throwsArgumentError);
      expect(() => field.log(0), throwsArgumentError);

      expect(field.multiply(0, 5), equals(0));
      expect(field.multiply(5, 0), equals(0));
      expect(field.multiply(1, 42), equals(42));
      expect(field.inverse(1), equals(1));

      for (var a = 1; a < 256; a++) {
        final inv = field.inverse(a);
        expect(field.multiply(a, inv), equals(1));
      }

      expect(() => field.inverse(0), throwsArgumentError);
    });

    test('Polynomial operations', () {
      final p1 = QrPolynomial(field, [1, 2]); // x + 2
      final p2 = QrPolynomial(field, [1, 3]); // x + 3
      final product = p1.multiply(p2); // x^2 + (2^3)x + 6 in GF(2^8)
      expect(product.degree, equals(2));

      // Test evaluation at x
      expect(p1.getCoefficient(0), equals(2));
      expect(p1.getCoefficient(1), equals(1));
      expect(p1.getCoefficient(5), equals(0));

      // Test zero polynomial multiply
      final zeroPoly = QrPolynomial(field, [0]);
      expect(zeroPoly.multiply(p1), equals(zeroPoly));
      expect(p1.multiply(zeroPoly), equals(zeroPoly));

      // Test generator polynomial creation
      final gen7 = QrPolynomial.createGenerator(field, 7);
      expect(gen7.degree, equals(7));

      final gen10 = QrPolynomial.createGenerator(field, 10);
      expect(gen10.degree, equals(10));
    });
  });

  group('QR Version & Geometry Tests', () {
    test('Dimension calculation for versions 1 to 10', () {
      for (var v = 1; v <= 10; v++) {
        final table = QrVersionTable.getVersion(v);
        expect(table.version, equals(v));
        expect(table.dimension, equals(17 + 4 * v));
      }
      expect(() => QrVersionTable.getVersion(0), throwsArgumentError);
      expect(() => QrVersionTable.getVersion(11), throwsArgumentError);
    });

    test('Block configurations across all ECC levels', () {
      for (var v = 1; v <= 10; v++) {
        final table = QrVersionTable.getVersion(v);
        for (final ecc in QrErrorCorrectionLevel.values) {
          final config = table.getBlockConfig(ecc);
          expect(config.totalDataCodewords, greaterThan(0));
          expect(config.totalCodewords, greaterThan(config.totalDataCodewords));
          expect(config.numBlocksGroup1, greaterThan(0));
          expect(config.eccCodewordsPerBlock, greaterThan(0));
        }
      }
    });

    test('Alignment coordinates', () {
      final v1 = QrVersionTable.getVersion(1);
      expect(v1.alignmentPositions, isEmpty);

      final v2 = QrVersionTable.getVersion(2);
      expect(v2.alignmentPositions, equals([6, 18]));

      final v7 = QrVersionTable.getVersion(7);
      expect(v7.alignmentPositions, equals([6, 22, 38]));
      expect(v7.getVersionInfoBits(), isNotNull);
      expect(v1.getVersionInfoBits(), isNull);
    });

    test('findOptimalVersion lookup and capacity overflow', () {
      final v1 = QrVersionTable.findOptimalVersion(
        dataByteCount: 10,
        eccLevel: QrErrorCorrectionLevel.medium,
      );
      expect(v1.version, equals(1));

      final v3 = QrVersionTable.findOptimalVersion(
        dataByteCount: 35,
        eccLevel: QrErrorCorrectionLevel.medium,
      );
      expect(v3.version, equals(3));

      expect(
        () => QrVersionTable.findOptimalVersion(
          dataByteCount: 99999,
          eccLevel: QrErrorCorrectionLevel.high,
        ),
        throwsArgumentError,
      );
    });
  });

  group('QR Matrix Structure Tests', () {
    test('Matrix creation, get, set and boundaries', () {
      final matrix = QrMatrix(21);
      expect(matrix.dimension, equals(21));
      expect(matrix.get(0, 0), isFalse);

      matrix.set(5, 5, true, type: QrModuleType.timing);
      expect(matrix.get(5, 5), isTrue);
      expect(matrix.getType(5, 5), equals(QrModuleType.timing));

      matrix.set(5, 5, false);
      expect(matrix.get(5, 5), isFalse);

      // Clamping / out-of-bounds checks
      expect(matrix.get(-1, 0), isFalse);
      expect(matrix.get(21, 0), isFalse);
      expect(matrix.getType(-1, 0), equals(QrModuleType.data));
      matrix.set(-1, 0, true); // no-op

      final cloned = matrix.clone();
      expect(cloned.dimension, equals(21));
      cloned.set(0, 0, true);
      expect(cloned.get(0, 0), isTrue);
      expect(matrix.get(0, 0), isFalse);
    });
  });

  group('ISO/IEC 18004 QR Encoder Tests', () {
    final encoder = QrEncoder();

    test('Encodes pure Numeric mode payload', () {
      final matrix = encoder.encode('123456789012345', eccLevel: QrErrorCorrectionLevel.low);
      expect(matrix.dimension, equals(21)); // Fits in Version 1
      expect(matrix.get(0, 0), isTrue); // Top-left finder outer
      expect(matrix.get(2, 2), isTrue); // Top-left finder pupil
      expect(matrix.get(1, 1), isFalse); // Top-left finder inner white space
    });

    test('Encodes Alphanumeric mode payload', () {
      final matrix = encoder.encode('HELLO WORLD 123', eccLevel: QrErrorCorrectionLevel.medium);
      expect(matrix.dimension, equals(21));
    });

    test('Encodes Byte mode UTF-8 payload', () {
      final matrix = encoder.encode('https://universal-qr.org/secure', eccLevel: QrErrorCorrectionLevel.high);
      expect(matrix.dimension, greaterThanOrEqualTo(21));
    });

    test('Encodes across all 4 ECC levels', () {
      for (final ecc in QrErrorCorrectionLevel.values) {
        final matrix = encoder.encode('test-payload-1234', eccLevel: ecc);
        expect(matrix.dimension, greaterThanOrEqualTo(21));
      }
    });

    test('Supports fixedVersion and fixedMaskPattern override', () {
      final matrix = encoder.encode(
        'fixed',
        fixedVersion: 2,
        fixedMaskPattern: 3,
        eccLevel: QrErrorCorrectionLevel.medium,
      );
      expect(matrix.dimension, equals(25)); // Version 2 is 25x25
    });

    test('Version 7+ encodes version information blocks', () {
      final matrix = encoder.encode(
        'https://universal-qr.org/enterprise-v7-info',
        fixedVersion: 7,
        eccLevel: QrErrorCorrectionLevel.medium,
      );
      expect(matrix.dimension, equals(45)); // Version 7 is 45x45
      // Verify version info modules placed
      expect(matrix.getType(0, matrix.dimension - 11), equals(QrModuleType.versionInfo));
    });

    test('Larger payload automatically steps up version table', () {
      final longPayload = 'A' * 120;
      final matrix = encoder.encode(longPayload, eccLevel: QrErrorCorrectionLevel.medium);
      expect(matrix.dimension, greaterThan(25)); // Steps up to version 5+
    });
  });
}
