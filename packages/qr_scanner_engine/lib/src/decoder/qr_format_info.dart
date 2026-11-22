/// QR Code Error Correction Levels defined in ISO/IEC 18004.
enum QrEccLevel {
  L(bits: 0x01, recoveryCapacity: 0.07),
  M(bits: 0x00, recoveryCapacity: 0.15),
  Q(bits: 0x03, recoveryCapacity: 0.25),
  H(bits: 0x02, recoveryCapacity: 0.30);

  final int bits;
  final double recoveryCapacity;

  const QrEccLevel({required this.bits, required this.recoveryCapacity});

  static QrEccLevel fromBits(int bits) {
    switch (bits & 0x03) {
      case 0x01:
        return QrEccLevel.L;
      case 0x00:
        return QrEccLevel.M;
      case 0x03:
        return QrEccLevel.Q;
      case 0x02:
        return QrEccLevel.H;
      default:
        return QrEccLevel.M;
    }
  }
}

/// Decoded QR Format Information containing Error Correction Level and Data Mask Pattern.
class QrFormatInfo {
  final QrEccLevel eccLevel;
  final int maskPattern;
  final int rawBits;

  const QrFormatInfo({
    required this.eccLevel,
    required this.maskPattern,
    required this.rawBits,
  });

  /// Standard XOR mask for QR Format Information bits (101010000010010_2).
  static const int formatInfoMask = 0x5412;

  /// Generator polynomial for BCH(15, 5): $x^{10} + x^8 + x^5 + x^4 + x^2 + x + 1$ (10100110111_2 = 0x537).
  static const int bchGenerator = 0x537;

  /// Table of all 32 valid 15-bit format patterns XORed with 0x5412.
  static final Map<int, int> _validFormatPatterns = _generateValidFormatTable();

  static Map<int, int> _generateValidFormatTable() {
    final table = <int, int>{};
    for (var data = 0; data < 32; data++) {
      var bch = data << 10;
      for (var i = 4; i >= 0; i--) {
        if ((bch & (1 << (i + 10))) != 0) {
          bch ^= bchGenerator << i;
        }
      }
      final pattern = ((data << 10) | bch) ^ formatInfoMask;
      table[pattern] = data;
    }
    return table;
  }

  /// Calculates Hamming distance (number of differing bits) between two 15-bit integers.
  static int _hammingDistance(int a, int b) {
    var diff = (a ^ b) & 0x7FFF;
    var count = 0;
    while (diff != 0) {
      count += diff & 1;
      diff >>= 1;
    }
    return count;
  }

  /// Decodes format info with BCH(15, 5) error correction (corrects up to 3 bit errors).
  ///
  /// Can take either of the two duplicate format info readings from the matrix.
  static QrFormatInfo? decode(int maskedFormatBits) {
    var bestPattern = -1;
    var bestDistance = 4; // Can correct up to 3 bit errors

    for (final pattern in _validFormatPatterns.keys) {
      final distance = _hammingDistance(maskedFormatBits, pattern);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestPattern = pattern;
      }
    }

    if (bestPattern == -1) return null;

    final data5Bits = _validFormatPatterns[bestPattern]!;
    final eccBits = (data5Bits >> 3) & 0x03;
    final maskPattern = data5Bits & 0x07;

    return QrFormatInfo(
      eccLevel: QrEccLevel.fromBits(eccBits),
      maskPattern: maskPattern,
      rawBits: bestPattern,
    );
  }

  /// Evaluates two redundant readings of format info from the QR matrix.
  static QrFormatInfo? decodeBestOfTwo(int format1, int format2) {
    final result1 = decode(format1);
    if (result1 != null) return result1;
    return decode(format2);
  }
}
