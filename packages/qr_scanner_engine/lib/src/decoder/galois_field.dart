import 'dart:typed_data';

/// Galois Field $GF(2^8)$ arithmetic with primitive polynomial $x^8 + x^4 + x^3 + x^2 + 1$ (0x11D).
class GaloisField256 {
  static const int primitive = 0x11D; // 285

  final Uint8List expTable = Uint8List(512);
  final Uint8List logTable = Uint8List(256);

  static final GaloisField256 qrField = GaloisField256._internal();

  factory GaloisField256() => qrField;

  GaloisField256._internal() {
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
    // expTable at 510, 511
    expTable[510] = expTable[0];
    expTable[511] = expTable[1];
  }

  int add(int a, int b) => a ^ b;

  int subtract(int a, int b) => a ^ b;

  int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return expTable[logTable[a] + logTable[b]];
  }

  int divide(int a, int b) {
    if (b == 0) throw ArgumentError('Division by zero in GF(256)');
    if (a == 0) return 0;
    return expTable[logTable[a] - logTable[b] + 255];
  }

  int inverse(int a) {
    if (a == 0) throw ArgumentError('Cannot invert zero in GF(256)');
    return expTable[255 - logTable[a]];
  }

  int exp(int power) => expTable[power % 255];

  int log(int value) {
    if (value == 0) throw ArgumentError('Cannot take log of zero in GF(256)');
    return logTable[value];
  }
}

/// Pure-Dart Reed-Solomon Error Correction Decoder for QR Codes.
///
/// Implements Berlekamp-Massey error locator polynomial reconstruction,
/// Chien search root finding, and Forney error magnitude computation.
class ReedSolomonDecoder {
  final GaloisField256 field;

  ReedSolomonDecoder([GaloisField256? field]) : field = field ?? GaloisField256.qrField;

  /// Decodes [received] codewords in-place using [numEccCodewords] error-correction symbols.
  ///
  /// Returns `true` if received data has 0 errors or all errors were successfully corrected.
  /// Returns `false` if errors exceed the error-correcting capability $t = \lfloor \text{ECC} / 2 \rfloor$.
  bool decode(Uint8List received, int numEccCodewords) {
    if (numEccCodewords <= 0 || received.length < numEccCodewords) {
      return false;
    }

    // Step 1: Compute syndromes S_0 to S_{numEcc - 1}
    // S_i = sum_{j=0}^{n-1} received[j] * (alpha^i)^(n - 1 - j)
    final syndromes = Uint8List(numEccCodewords);
    var hasError = false;

    for (var i = 0; i < numEccCodewords; i++) {
      var eval = 0;
      final alpha = field.exp(i);
      for (var j = 0; j < received.length; j++) {
        eval = field.multiply(eval, alpha) ^ received[j];
      }
      syndromes[i] = eval;
      if (eval != 0) {
        hasError = true;
      }
    }

    // No errors detected
    if (!hasError) return true;

    // Step 2: Berlekamp-Massey algorithm to find error locator polynomial Lambda(x)
    var c = Uint8List(numEccCodewords + 1).. [0] = 1;
    var b = Uint8List(numEccCodewords + 1).. [0] = 1;
    var l = 0;
    var m = 1;
    var bDiscrepancy = 1;

    for (var n = 0; n < numEccCodewords; n++) {
      var discrepancy = syndromes[n];
      for (var i = 1; i <= l; i++) {
        discrepancy ^= field.multiply(c[i], syndromes[n - i]);
      }

      if (discrepancy == 0) {
        m++;
      } else if (2 * l <= n) {
        final t = Uint8List.fromList(c);
        final factor = field.divide(discrepancy, bDiscrepancy);
        for (var i = 0; i <= numEccCodewords - m; i++) {
          c[i + m] ^= field.multiply(factor, b[i]);
        }
        l = n + 1 - l;
        b = t;
        bDiscrepancy = discrepancy;
        m = 1;
      } else {
        final factor = field.divide(discrepancy, bDiscrepancy);
        for (var i = 0; i <= numEccCodewords - m; i++) {
          c[i + m] ^= field.multiply(factor, b[i]);
        }
        m++;
      }
    }

    // Max errors that can be corrected
    if (l == 0 || l > (numEccCodewords ~/ 2)) {
      return false;
    }

    // Step 3: Chien search to find roots of error locator polynomial
    final errorPositions = <int>[];
    final numDataCodewords = received.length;

    for (var i = 0; i < numDataCodewords; i++) {
      // Evaluate Lambda(alpha^(-i))
      final alphaInv = field.exp(255 - (i % 255));
      var sum = 0;
      var term = 1;
      for (var j = 0; j <= l; j++) {
        sum ^= field.multiply(c[j], term);
        term = field.multiply(term, alphaInv);
      }
      if (sum == 0) {
        // Root found, error is at position numDataCodewords - 1 - i
        final pos = numDataCodewords - 1 - i;
        if (pos >= 0 && pos < numDataCodewords) {
          errorPositions.add(pos);
        }
      }
    }

    if (errorPositions.length != l) {
      // Could not find all roots
      return false;
    }

    // Step 4: Compute error evaluator polynomial Omega(x) = Syndrome(x) * Lambda(x) mod x^numEcc
    final omega = Uint8List(numEccCodewords);
    for (var i = 0; i < numEccCodewords; i++) {
      var val = 0;
      for (var j = 0; j <= i && j <= l; j++) {
        val ^= field.multiply(syndromes[i - j], c[j]);
      }
      omega[i] = val;
    }

    // Step 5: Forney algorithm to calculate error magnitude at each position
    for (final pos in errorPositions) {
      final xi = field.exp((numDataCodewords - 1 - pos) % 255);
      final xiInv = field.inverse(xi);

      // Evaluate Omega(xiInv)
      var omegaVal = 0;
      var xiTerm = 1;
      for (var i = 0; i < numEccCodewords; i++) {
        omegaVal ^= field.multiply(omega[i], xiTerm);
        xiTerm = field.multiply(xiTerm, xiInv);
      }

      // Evaluate Lambda'(xiInv) (formal derivative of Lambda)
      var lambdaPrimeVal = 0;
      var derivTerm = 1;
      for (var i = 1; i <= l; i += 2) {
        // Odd powers in characteristic 2
        lambdaPrimeVal ^= field.multiply(c[i], derivTerm);
        derivTerm = field.multiply(derivTerm, field.multiply(xiInv, xiInv));
      }

      if (lambdaPrimeVal == 0) {
        return false;
      }

      // Forney magnitude with b=0 (QR generator starts at alpha^0): e_k = (X_k * Omega(X_k^-1)) / Lambda'(X_k^-1)
      final num = field.multiply(omegaVal, xi);
      final magnitude = field.divide(num, lambdaPrimeVal);
      // Correct error
      received[pos] ^= magnitude;
    }

    return true;
  }
}
