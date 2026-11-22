import 'dart:typed_data';

/// Galois field arithmetic $GF(2^8)$ for ISO/IEC 18004 Reed-Solomon encoding.
class QrGaloisField {
  static const int primitive = 0x11D; // 285

  final Uint8List expTable = Uint8List(512);
  final Uint8List logTable = Uint8List(256);

  static final QrGaloisField instance = QrGaloisField._internal();

  factory QrGaloisField() => instance;

  QrGaloisField._internal() {
    var x = 1;
    for (var i = 0; i < 255; i++) {
      expTable[i] = x;
      expTable[i + 255] = x;
      logTable[x] = i;
      x <<= 1;
      if (x >= 256) {
        x ^= primitive;
      }
    }
    expTable[510] = expTable[0];
    expTable[511] = expTable[1];
  }

  int add(int a, int b) => a ^ b;

  int subtract(int a, int b) => a ^ b;

  int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return expTable[logTable[a] + logTable[b]];
  }

  int inverse(int a) {
    if (a == 0) throw ArgumentError('Cannot take inverse of zero in GF(256)');
    return expTable[255 - logTable[a]];
  }

  int divide(int a, int b) {
    if (b == 0) throw ArgumentError('Division by zero in GF(256)');
    if (a == 0) return 0;
    return expTable[(logTable[a] - logTable[b] + 255) % 255];
  }

  int exp(int a) => expTable[a % 255];

  int log(int a) {
    if (a == 0) throw ArgumentError('Cannot take log of zero in GF(256)');
    return logTable[a];
  }
}

/// Polynomial over Galois Field $GF(2^8)$ for Reed-Solomon codeword calculations.
class QrPolynomial {
  final Uint8List coefficients;
  final QrGaloisField field;

  QrPolynomial(this.field, List<int> coeffs)
      : coefficients = _normalizeCoefficients(coeffs);

  static Uint8List _normalizeCoefficients(List<int> coeffs) {
    if (coeffs.isEmpty) return Uint8List(1);
    var firstNonZero = 0;
    while (firstNonZero < coeffs.length - 1 && coeffs[firstNonZero] == 0) {
      firstNonZero++;
    }
    final len = coeffs.length - firstNonZero;
    final res = Uint8List(len);
    for (var i = 0; i < len; i++) {
      res[i] = coeffs[firstNonZero + i] & 0xFF;
    }
    return res;
  }

  int get degree => coefficients.length - 1;

  int getCoefficient(int degreeIndex) {
    final idx = coefficients.length - 1 - degreeIndex;
    if (idx < 0 || idx >= coefficients.length) return 0;
    return coefficients[idx];
  }

  /// Multiplies this polynomial by another polynomial over GF(256).
  QrPolynomial multiply(QrPolynomial other) {
    if (coefficients.length == 1 && coefficients[0] == 0) return this;
    if (other.coefficients.length == 1 && other.coefficients[0] == 0) return other;

    final newCoeffs = Uint8List(coefficients.length + other.coefficients.length - 1);
    for (var i = 0; i < coefficients.length; i++) {
      final a = coefficients[i];
      if (a == 0) continue;
      for (var j = 0; j < other.coefficients.length; j++) {
        final b = other.coefficients[j];
        if (b == 0) continue;
        newCoeffs[i + j] ^= field.multiply(a, b);
      }
    }
    return QrPolynomial(field, newCoeffs);
  }

  /// Generates the standard Reed-Solomon generator polynomial for [numEccCodewords]:
  /// $g(x) = (x - \alpha^0)(x - \alpha^1)\dots(x - \alpha^{numEcc - 1})$
  static QrPolynomial createGenerator(QrGaloisField field, int numEccCodewords) {
    var poly = QrPolynomial(field, [1]);
    for (var i = 0; i < numEccCodewords; i++) {
      poly = poly.multiply(QrPolynomial(field, [1, field.exp(i)]));
    }
    return poly;
  }

  /// Calculates the Reed-Solomon error correction remainder codewords for [data].
  static Uint8List calculateRemainder(
    QrGaloisField field,
    Uint8List data,
    int numEccCodewords,
  ) {
    final generator = createGenerator(field, numEccCodewords);

    // Multiply data polynomial by x^numEcc
    final remainder = Uint8List(numEccCodewords);
    final dataLength = data.length;

    for (var i = 0; i < dataLength; i++) {
      final factor = data[i] ^ remainder[0];
      for (var j = 0; j < numEccCodewords - 1; j++) {
        remainder[j] = remainder[j + 1] ^ field.multiply(factor, generator.coefficients[j + 1]);
      }
      remainder[numEccCodewords - 1] = field.multiply(factor, generator.coefficients[numEccCodewords]);
    }

    return remainder;
  }
}
