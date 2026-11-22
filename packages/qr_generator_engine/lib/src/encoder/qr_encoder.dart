import 'dart:convert';
import 'dart:typed_data';
import '../../qr_generator_engine.dart';

/// Standards-compliant ISO/IEC 18004 QR Matrix Encoder.
class QrEncoder {
  const QrEncoder();

  QrGaloisField get _field => QrGaloisField.instance;

  /// Encodes [content] into a fully standards-compliant [QrMatrix].
  QrMatrix encode(
    String content, {
    QrErrorCorrectionLevel eccLevel = QrErrorCorrectionLevel.medium,
    int? fixedVersion,
    int? fixedMaskPattern,
  }) {
    // 1. Analyze content to select optimal encoding mode
    final mode = _detectEncodingMode(content);

    // 2. Encode payload data to bits and determine optimal version
    final versionTable = fixedVersion != null
        ? QrVersionTable.getVersion(fixedVersion)
        : _selectVersionForPayload(content, mode, eccLevel);

    final blockConfig = versionTable.getBlockConfig(eccLevel);
    final bitBuffer = _buildBitStream(content, mode, versionTable.version, blockConfig.totalDataCodewords);

    // 3. Block splitting & Reed-Solomon Error Correction encoding
    final finalCodewords = _generateInterleavedCodewords(bitBuffer, blockConfig);

    // 4. Create matrix and place reserved function patterns
    final matrix = QrMatrix(versionTable.dimension);
    _placeFunctionPatterns(matrix, versionTable);

    // 5. Select optimal mask pattern (or use fixedMaskPattern)
    final bestMask = fixedMaskPattern ?? _findBestMaskPattern(matrix, finalCodewords, versionTable, eccLevel);

    // 6. Final matrix synthesis with selected mask and format info
    final finalMatrix = _buildFinalMatrix(matrix, finalCodewords, bestMask, versionTable, eccLevel);

    return finalMatrix;
  }

  int _detectEncodingMode(String content) {
    if (content.isEmpty) return 4; // Byte
    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(content);
    if (isNumeric) return 1; // Numeric

    const alphanumericChars = r'^[0-9A-Z $%*+\-./:]+$';
    final isAlphanumeric = RegExp(alphanumericChars).hasMatch(content);
    if (isAlphanumeric) return 2; // Alphanumeric

    return 4; // Byte (UTF-8)
  }

  QrVersionTable _selectVersionForPayload(
    String content,
    int mode,
    QrErrorCorrectionLevel eccLevel,
  ) {
    for (var v = 1; v <= 10; v++) {
      final table = QrVersionTable.getVersion(v);
      final maxDataCodewords = table.getBlockConfig(eccLevel).totalDataCodewords;
      final neededBits = _calculateNeededBits(content, mode, v);
      if (neededBits <= maxDataCodewords * 8) {
        return table;
      }
    }
    return QrVersionTable.getVersion(10);
  }

  int _calculateNeededBits(String content, int mode, int version) {
    var bits = 4; // Mode indicator
    if (mode == 1) {
      // Numeric
      bits += version <= 9 ? 10 : 12;
      final fullTriplets = content.length ~/ 3;
      bits += fullTriplets * 10;
      final rem = content.length % 3;
      if (rem == 2) bits += 7;
      if (rem == 1) bits += 4;
    } else if (mode == 2) {
      // Alphanumeric
      bits += version <= 9 ? 9 : 11;
      final fullPairs = content.length ~/ 2;
      bits += fullPairs * 11;
      if (content.length % 2 == 1) bits += 6;
    } else {
      // Byte
      bits += version <= 9 ? 8 : 16;
      bits += utf8.encode(content).length * 8;
    }
    bits += 4; // Terminator
    return bits;
  }

  Uint8List _buildBitStream(String content, int mode, int version, int totalDataCodewords) {
    final bits = <bool>[];

    void writeBits(int value, int count) {
      for (var i = count - 1; i >= 0; i--) {
        bits.add(((value >> i) & 1) != 0);
      }
    }

    // 1. Mode indicator (4 bits)
    writeBits(mode, 4);

    // 2. Character count indicator
    if (mode == 1) {
      final countBits = version <= 9 ? 10 : 12;
      writeBits(content.length, countBits);
      for (var i = 0; i < content.length; i += 3) {
        final remaining = content.length - i;
        if (remaining >= 3) {
          final val = int.parse(content.substring(i, i + 3));
          writeBits(val, 10);
        } else if (remaining == 2) {
          final val = int.parse(content.substring(i, i + 2));
          writeBits(val, 7);
        } else {
          final val = int.parse(content.substring(i, i + 1));
          writeBits(val, 4);
        }
      }
    } else if (mode == 2) {
      const alphanumericChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:';
      final countBits = version <= 9 ? 9 : 11;
      writeBits(content.length, countBits);
      for (var i = 0; i < content.length; i += 2) {
        final remaining = content.length - i;
        if (remaining >= 2) {
          final c1 = alphanumericChars.indexOf(content[i]);
          final c2 = alphanumericChars.indexOf(content[i + 1]);
          writeBits(c1 * 45 + c2, 11);
        } else {
          final c = alphanumericChars.indexOf(content[i]);
          writeBits(c, 6);
        }
      }
    } else {
      final bytes = utf8.encode(content);
      final countBits = version <= 9 ? 8 : 16;
      writeBits(bytes.length, countBits);
      for (final b in bytes) {
        writeBits(b, 8);
      }
    }

    // 3. Terminator (up to 4 zero bits)
    final maxBits = totalDataCodewords * 8;
    final termLen = (maxBits - bits.length).clamp(0, 4);
    for (var i = 0; i < termLen; i++) {
      bits.add(false);
    }

    // 4. Pad to byte boundary
    while (bits.length % 8 != 0 && bits.length < maxBits) {
      bits.add(false);
    }

    // 5. Convert to byte array
    final dataBytes = Uint8List(totalDataCodewords);
    for (var i = 0; i < bits.length && (i >> 3) < totalDataCodewords; i++) {
      if (bits[i]) {
        dataBytes[i >> 3] |= (1 << (7 - (i & 7)));
      }
    }

    // 6. Pad remaining capacity with alternating pad bytes: 0xEC, 0x11
    var padByte = 0xEC;
    final currentByteIdx = (bits.length + 7) >> 3;
    for (var i = currentByteIdx; i < totalDataCodewords; i++) {
      dataBytes[i] = padByte;
      padByte = padByte == 0xEC ? 0x11 : 0xEC;
    }

    return dataBytes;
  }

  Uint8List _generateInterleavedCodewords(Uint8List dataBytes, QrBlockConfig config) {
    final numBlocks1 = config.numBlocksGroup1;
    final dataLen1 = config.dataCodewordsGroup1;
    final numBlocks2 = config.numBlocksGroup2;
    final dataLen2 = config.dataCodewordsGroup2;
    final totalBlocks = numBlocks1 + numBlocks2;
    final eccPerBlock = config.eccCodewordsPerBlock;

    final dataBlocks = <Uint8List>[];
    final eccBlocks = <Uint8List>[];

    var offset = 0;
    for (var i = 0; i < totalBlocks; i++) {
      final len = i < numBlocks1 ? dataLen1 : dataLen2;
      final blockData = dataBytes.sublist(offset, offset + len);
      offset += len;
      dataBlocks.add(blockData);

      final ecc = QrPolynomial.calculateRemainder(_field, blockData, eccPerBlock);
      eccBlocks.add(ecc);
    }

    // Interleave data codewords across all blocks
    final totalCodewords = config.totalCodewords;
    final result = Uint8List(totalCodewords);
    var resIdx = 0;

    final maxDataLength = dataLen2 > dataLen1 ? dataLen2 : dataLen1;
    for (var i = 0; i < maxDataLength; i++) {
      for (var b = 0; b < totalBlocks; b++) {
        final bLen = b < numBlocks1 ? dataLen1 : dataLen2;
        if (i < bLen) {
          result[resIdx++] = dataBlocks[b][i];
        }
      }
    }

    // Interleave ECC codewords across all blocks
    for (var i = 0; i < eccPerBlock; i++) {
      for (var b = 0; b < totalBlocks; b++) {
        result[resIdx++] = eccBlocks[b][i];
      }
    }

    return result;
  }

  void _placeFunctionPatterns(QrMatrix matrix, QrVersionTable version) {
    final dim = matrix.dimension;

    // 1. Finder patterns (7x7) at (0,0), (dim-7, 0), (0, dim-7)
    _drawFinderPattern(matrix, 0, 0);
    _drawFinderPattern(matrix, dim - 7, 0);
    _drawFinderPattern(matrix, 0, dim - 7);

    // 2. Separators around finders
    for (var i = 0; i < 8; i++) {
      // Top-left
      matrix.set(7, i, false, type: QrModuleType.separator);
      matrix.set(i, 7, false, type: QrModuleType.separator);
      // Top-right
      matrix.set(dim - 8, i, false, type: QrModuleType.separator);
      matrix.set(dim - 1 - i, 7, false, type: QrModuleType.separator);
      // Bottom-left
      matrix.set(7, dim - 1 - i, false, type: QrModuleType.separator);
      matrix.set(i, dim - 8, false, type: QrModuleType.separator);
    }

    // 3. Timing patterns (Row 6 and Column 6)
    for (var i = 8; i < dim - 8; i++) {
      final isDark = (i % 2) == 0;
      matrix.set(i, 6, isDark, type: QrModuleType.timing);
      matrix.set(6, i, isDark, type: QrModuleType.timing);
    }

    // 4. Alignment patterns for Version >= 2
    if (version.version >= 2) {
      final positions = version.alignmentPositions;
      for (final ax in positions) {
        for (final ay in positions) {
          // Skip corners occupied by finder patterns
          if ((ax <= 8 && ay <= 8) || (ax >= dim - 8 && ay <= 8) || (ax <= 8 && ay >= dim - 8)) {
            continue;
          }
          _drawAlignmentPattern(matrix, ax, ay);
        }
      }
    }

    // 5. Dark module at (8, 4*version + 9)
    matrix.set(8, 4 * version.version + 9, true, type: QrModuleType.formatInfo);

    // 6. Reserve format info modules (along finder eyes)
    for (var i = 0; i < 9; i++) {
      if (i != 6) {
        matrix.setType(i, 8, QrModuleType.formatInfo);
        matrix.setType(8, i, QrModuleType.formatInfo);
      }
    }
    for (var i = 0; i < 8; i++) {
      matrix.setType(dim - 1 - i, 8, QrModuleType.formatInfo);
      matrix.setType(8, dim - 1 - i, QrModuleType.formatInfo);
    }

    // 7. Reserve version info modules for version >= 7
    if (version.version >= 7) {
      for (var i = 0; i < 6; i++) {
        for (var j = 0; j < 3; j++) {
          matrix.setType(i, dim - 11 + j, QrModuleType.versionInfo);
          matrix.setType(dim - 11 + j, i, QrModuleType.versionInfo);
        }
      }
    }
  }

  void _drawFinderPattern(QrMatrix matrix, int startX, int startY) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final isBorder = x == 0 || x == 6 || y == 0 || y == 6;
        final isPupil = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        final isDark = isBorder || isPupil;

        QrModuleType type;
        if (isBorder) {
          type = QrModuleType.finderOuter;
        } else if (isPupil) {
          type = QrModuleType.finderPupil;
        } else {
          type = QrModuleType.finderInner;
        }

        matrix.set(startX + x, startY + y, isDark, type: type);
      }
    }
  }

  void _drawAlignmentPattern(QrMatrix matrix, int centerX, int centerY) {
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        final isDark = dx.abs() == 2 || dy.abs() == 2 || (dx == 0 && dy == 0);
        matrix.set(centerX + dx, centerY + dy, isDark, type: QrModuleType.alignment);
      }
    }
  }

  int _findBestMaskPattern(
    QrMatrix baseMatrix,
    Uint8List codewords,
    QrVersionTable version,
    QrErrorCorrectionLevel eccLevel,
  ) {
    var bestMask = 0;
    var lowestPenalty = 0x7FFFFFFF;

    for (var mask = 0; mask < 8; mask++) {
      final testMatrix = _buildFinalMatrix(baseMatrix, codewords, mask, version, eccLevel);
      final penalty = _calculateMaskPenalty(testMatrix);
      if (penalty < lowestPenalty) {
        lowestPenalty = penalty;
        bestMask = mask;
      }
    }

    return bestMask;
  }

  QrMatrix _buildFinalMatrix(
    QrMatrix baseMatrix,
    Uint8List codewords,
    int maskPattern,
    QrVersionTable version,
    QrErrorCorrectionLevel eccLevel,
  ) {
    final matrix = baseMatrix.clone();
    final dim = matrix.dimension;

    // 1. Place data bits in zig-zag order with mask pattern
    var byteIdx = 0;
    var bitIdx = 7;
    var readingUp = true;

    for (var rightCol = dim - 1; rightCol > 0; rightCol -= 2) {
      if (rightCol == 6) rightCol--; // Skip vertical timing column

      for (var i = 0; i < dim; i++) {
        final row = readingUp ? (dim - 1 - i) : i;

        for (var c = 0; c < 2; c++) {
          final col = rightCol - c;
          if (!matrix.isFunctionPattern(col, row)) {
            var bit = false;
            if (byteIdx < codewords.length) {
              bit = ((codewords[byteIdx] >> bitIdx) & 1) != 0;
              bitIdx--;
              if (bitIdx < 0) {
                bitIdx = 7;
                byteIdx++;
              }
            }

            // Invert if mask condition holds
            if (_isMaskInverted(maskPattern, col, row)) {
              bit = !bit;
            }

            matrix.set(col, row, bit, type: QrModuleType.data);
          }
        }
      }
      readingUp = !readingUp;
    }

    // 2. Write format information
    _writeFormatInfo(matrix, eccLevel, maskPattern);

    // 3. Write version information for version >= 7
    if (version.version >= 7) {
      _writeVersionInfo(matrix, version);
    }

    return matrix;
  }

  bool _isMaskInverted(int mask, int col, int row) {
    switch (mask) {
      case 0:
        return (row + col) % 2 == 0;
      case 1:
        return row % 2 == 0;
      case 2:
        return col % 3 == 0;
      case 3:
        return (row + col) % 3 == 0;
      case 4:
        return (row ~/ 2 + col ~/ 3) % 2 == 0;
      case 5:
        return ((row * col) % 2) + ((row * col) % 3) == 0;
      case 6:
        return (((row * col) % 2) + ((row * col) % 3)) % 2 == 0;
      case 7:
        return (((row + col) % 2) + ((row * col) % 3)) % 2 == 0;
      default:
        return false;
    }
  }

  void _writeFormatInfo(QrMatrix matrix, QrErrorCorrectionLevel eccLevel, int maskPattern) {
    final dim = matrix.dimension;
    // Map eccLevel to standard 2-bit code: L=01, M=00, Q=11, H=10
    final eccCode = switch (eccLevel) {
      QrErrorCorrectionLevel.low => 0x01,
      QrErrorCorrectionLevel.medium => 0x00,
      QrErrorCorrectionLevel.quartile => 0x03,
      QrErrorCorrectionLevel.high => 0x02,
    };

    final data5 = (eccCode << 3) | (maskPattern & 0x07);

    // Calculate BCH(15, 5) error correction code with generator polynomial 0x537 (1335)
    var bch = data5 << 10;
    const g = 0x537;
    for (var i = 4; i >= 0; i--) {
      if ((bch & (1 << (i + 10))) != 0) {
        bch ^= (g << i);
      }
    }

    // XOR with standard format mask 0x5412 (21522)
    final formatBits = ((data5 << 10) | bch) ^ 0x5412;

    // Top-left reading
    final tlCoords = [
      (0, 8), (1, 8), (2, 8), (3, 8), (4, 8), (5, 8),
      (7, 8), (8, 8), (8, 7), (8, 5), (8, 4), (8, 3),
      (8, 2), (8, 1), (8, 0),
    ];

    for (var i = 0; i < 15; i++) {
      final isDark = ((formatBits >> (14 - i)) & 1) != 0;
      final (x, y) = tlCoords[i];
      matrix.set(x, y, isDark, type: QrModuleType.formatInfo);
    }

    // Split duplicate reading (bottom-left and top-right)
    // Bits 0..6 at bottom-left: (8, dim-1) to (8, dim-7)
    for (var i = 0; i < 7; i++) {
      final isDark = ((formatBits >> i) & 1) != 0;
      matrix.set(8, dim - 1 - i, isDark, type: QrModuleType.formatInfo);
    }

    // Bits 7..14 at top-right: (dim-8, 8) to (dim-1, 8)
    for (var i = 7; i < 15; i++) {
      final isDark = ((formatBits >> i) & 1) != 0;
      matrix.set(dim - 15 + i, 8, isDark, type: QrModuleType.formatInfo);
    }
  }

  void _writeVersionInfo(QrMatrix matrix, QrVersionTable version) {
    final bits = version.getVersionInfoBits();
    if (bits == null) return;
    final dim = matrix.dimension;

    for (var i = 0; i < 18; i++) {
      final isDark = ((bits >> i) & 1) != 0;
      final a = i ~/ 3;
      final b = i % 3;

      // Bottom-left block: (b, dim - 11 + a)
      matrix.set(b, dim - 11 + a, isDark, type: QrModuleType.versionInfo);
      // Top-right block: (dim - 11 + a, b)
      matrix.set(dim - 11 + a, b, isDark, type: QrModuleType.versionInfo);
    }
  }

  /// Calculates ISO/IEC 18004 penalty scores N1, N2, N3, N4 to optimize mask selection.
  int _calculateMaskPenalty(QrMatrix matrix) {
    final dim = matrix.dimension;
    var penalty = 0;

    // N1: 5 or more consecutive identical modules in rows and columns
    for (var y = 0; y < dim; y++) {
      var runLen = 1;
      var last = matrix.get(0, y);
      for (var x = 1; x < dim; x++) {
        final cur = matrix.get(x, y);
        if (cur == last) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          runLen = 1;
          last = cur;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }

    for (var x = 0; x < dim; x++) {
      var runLen = 1;
      var last = matrix.get(x, 0);
      for (var y = 1; y < dim; y++) {
        final cur = matrix.get(x, y);
        if (cur == last) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          runLen = 1;
          last = cur;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }

    // N2: 2x2 blocks of identical modules (3 points each)
    for (var y = 0; y < dim - 1; y++) {
      for (var x = 0; x < dim - 1; x++) {
        final val = matrix.get(x, y);
        if (matrix.get(x + 1, y) == val &&
            matrix.get(x, y + 1) == val &&
            matrix.get(x + 1, y + 1) == val) {
          penalty += 3;
        }
      }
    }

    // N3: Patterns matching 1:1:3:1:1 with 4 white modules before or after
    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim - 10; x++) {
        if (_isFinderLikePattern(matrix, x, y, horizontal: true)) {
          penalty += 40;
        }
      }
    }
    for (var x = 0; x < dim; x++) {
      for (var y = 0; y < dim - 10; y++) {
        if (_isFinderLikePattern(matrix, x, y, horizontal: false)) {
          penalty += 40;
        }
      }
    }

    // N4: Proportion of dark modules deviating from 50%
    var darkCount = 0;
    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim; x++) {
        if (matrix.get(x, y)) darkCount++;
      }
    }
    final total = dim * dim;
    final percentage = (darkCount * 100) ~/ total;
    final prevMultiple = (percentage ~/ 5) * 5;
    final nextMultiple = prevMultiple + 5;
    final diff1 = (prevMultiple - 50).abs() ~/ 5;
    final diff2 = (nextMultiple - 50).abs() ~/ 5;
    penalty += (diff1 < diff2 ? diff1 : diff2) * 10;

    return penalty;
  }

  bool _isFinderLikePattern(QrMatrix matrix, int startX, int startY, {required bool horizontal}) {
    // 1:1:3:1:1 pattern with 4 white modules: 10111010000 or 00001011101
    // Read 11 consecutive bits
    var bits = 0;
    for (var i = 0; i < 11; i++) {
      final x = horizontal ? startX + i : startX;
      final y = horizontal ? startY : startY + i;
      if (matrix.get(x, y)) {
        bits |= (1 << (10 - i));
      }
    }
    // Pattern 1: 10111010000 = 0x5D0 (1488)
    // Pattern 2: 00001011101 = 0x05D (93)
    return bits == 0x5D0 || bits == 0x05D;
  }
}
