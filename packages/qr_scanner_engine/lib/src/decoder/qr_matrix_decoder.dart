import 'dart:convert';
import 'dart:typed_data';
import 'galois_field.dart';
import 'qr_format_info.dart';
import '../image/image_buffer.dart';

/// Version specifications and Reed-Solomon block partition configuration.
class QrVersionInfo {
  final int versionNumber;
  final int totalCodewords;
  final Map<QrEccLevel, ({int eccCodewordsPerBlock, int numBlocksGroup1, int dataCodewordsGroup1, int numBlocksGroup2, int dataCodewordsGroup2})> eccBlocks;

  const QrVersionInfo({
    required this.versionNumber,
    required this.totalCodewords,
    required this.eccBlocks,
  });

  int get dimension => 17 + 4 * versionNumber;

  /// Returns total data codewords for the specified ECC level.
  int getDataCodewordsForEcc(QrEccLevel ecc) {
    final blk = eccBlocks[ecc]!;
    return (blk.numBlocksGroup1 * blk.dataCodewordsGroup1) +
        (blk.numBlocksGroup2 * blk.dataCodewordsGroup2);
  }

  /// Returns total ECC codewords for the specified ECC level.
  int getEccCodewordsForEcc(QrEccLevel ecc) {
    final blk = eccBlocks[ecc]!;
    final totalBlocks = blk.numBlocksGroup1 + blk.numBlocksGroup2;
    return totalBlocks * blk.eccCodewordsPerBlock;
  }
}

/// Standard QR Matrix Decoder.
///
/// Implements ISO/IEC 18004 format extraction, unmasking, bit-stream zig-zag reading,
/// Reed-Solomon block de-interleaving and error correction, and multi-mode decoding.
class QrMatrixDecoder {
  final ReedSolomonDecoder rsDecoder;

  QrMatrixDecoder({ReedSolomonDecoder? rsDecoder})
      : rsDecoder = rsDecoder ?? ReedSolomonDecoder();

  static final Map<int, QrVersionInfo> _versionTable = _buildVersionTable();

  static Map<int, QrVersionInfo> _buildVersionTable() {
    return {
      1: QrVersionInfo(
        versionNumber: 1,
        totalCodewords: 26,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 7, numBlocksGroup1: 1, dataCodewordsGroup1: 19, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 10, numBlocksGroup1: 1, dataCodewordsGroup1: 16, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 13, numBlocksGroup1: 1, dataCodewordsGroup1: 13, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.H: (eccCodewordsPerBlock: 17, numBlocksGroup1: 1, dataCodewordsGroup1: 9, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      ),
      2: QrVersionInfo(
        versionNumber: 2,
        totalCodewords: 44,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 10, numBlocksGroup1: 1, dataCodewordsGroup1: 34, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 16, numBlocksGroup1: 1, dataCodewordsGroup1: 28, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 22, numBlocksGroup1: 1, dataCodewordsGroup1: 22, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.H: (eccCodewordsPerBlock: 28, numBlocksGroup1: 1, dataCodewordsGroup1: 16, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      ),
      3: QrVersionInfo(
        versionNumber: 3,
        totalCodewords: 70,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 15, numBlocksGroup1: 1, dataCodewordsGroup1: 55, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 26, numBlocksGroup1: 1, dataCodewordsGroup1: 44, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 17, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.H: (eccCodewordsPerBlock: 22, numBlocksGroup1: 2, dataCodewordsGroup1: 13, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      ),
      4: QrVersionInfo(
        versionNumber: 4,
        totalCodewords: 100,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 20, numBlocksGroup1: 1, dataCodewordsGroup1: 80, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 32, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 26, numBlocksGroup1: 2, dataCodewordsGroup1: 24, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.H: (eccCodewordsPerBlock: 16, numBlocksGroup1: 4, dataCodewordsGroup1: 9, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      ),
      5: QrVersionInfo(
        versionNumber: 5,
        totalCodewords: 134,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 26, numBlocksGroup1: 1, dataCodewordsGroup1: 108, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 24, numBlocksGroup1: 2, dataCodewordsGroup1: 43, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 15, numBlocksGroup2: 2, dataCodewordsGroup2: 16),
          QrEccLevel.H: (eccCodewordsPerBlock: 22, numBlocksGroup1: 2, dataCodewordsGroup1: 11, numBlocksGroup2: 2, dataCodewordsGroup2: 12),
        },
      ),
      6: QrVersionInfo(
        versionNumber: 6,
        totalCodewords: 172,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 68, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 16, numBlocksGroup1: 4, dataCodewordsGroup1: 27, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 24, numBlocksGroup1: 4, dataCodewordsGroup1: 19, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.H: (eccCodewordsPerBlock: 28, numBlocksGroup1: 4, dataCodewordsGroup1: 15, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      ),
      7: QrVersionInfo(
        versionNumber: 7,
        totalCodewords: 196,
        eccBlocks: {
          QrEccLevel.L: (eccCodewordsPerBlock: 20, numBlocksGroup1: 2, dataCodewordsGroup1: 78, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.M: (eccCodewordsPerBlock: 18, numBlocksGroup1: 4, dataCodewordsGroup1: 31, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
          QrEccLevel.Q: (eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 14, numBlocksGroup2: 4, dataCodewordsGroup2: 15),
          QrEccLevel.H: (eccCodewordsPerBlock: 26, numBlocksGroup1: 4, dataCodewordsGroup1: 13, numBlocksGroup2: 1, dataCodewordsGroup2: 14),
        },
      ),
    };
  }

  /// Decodes a perspective-aligned QR module matrix.
  String? decode(BinarizedBitMatrix matrix) {
    final dimension = matrix.width;
    if (matrix.width != matrix.height || dimension < 21 || ((dimension - 17) % 4) != 0) {
      return null;
    }

    final versionNumber = (dimension - 17) ~/ 4;
    final versionInfo = _versionTable[versionNumber];
    if (versionInfo == null) return null;

    // 1. Read Format Info (try both reading 1 and reading 2)
    final formatInfo1 = _readFormatInfo1(matrix, dimension);
    final formatInfo2 = _readFormatInfo2(matrix, dimension);
    final formatInfo = QrFormatInfo.decodeBestOfTwo(formatInfo1, formatInfo2);
    if (formatInfo == null) return null;

    // 2. Unmask matrix
    final unmasked = _unmaskMatrix(matrix, dimension, formatInfo.maskPattern, versionNumber);

    // 3. Read raw bit stream in zig-zag order
    final rawCodewords = _readRawCodewords(unmasked, dimension, versionNumber, versionInfo.totalCodewords);
    if (rawCodewords == null) return null;

    // 4. De-interleave and correct Reed-Solomon blocks
    final dataBytes = _correctAndDeinterleave(rawCodewords, versionInfo, formatInfo.eccLevel);
    if (dataBytes == null) return null;

    // 5. Decode payload modes
    return decodePayloadStream(dataBytes, versionNumber);
  }

  int _readFormatInfo1(BinarizedBitMatrix matrix, int dim) {
    var bits = 0;
    if (matrix.get(0, 8)) bits |= (1 << 14);
    if (matrix.get(1, 8)) bits |= (1 << 13);
    if (matrix.get(2, 8)) bits |= (1 << 12);
    if (matrix.get(3, 8)) bits |= (1 << 11);
    if (matrix.get(4, 8)) bits |= (1 << 10);
    if (matrix.get(5, 8)) bits |= (1 << 9);
    if (matrix.get(7, 8)) bits |= (1 << 8);
    if (matrix.get(8, 8)) bits |= (1 << 7);
    if (matrix.get(8, 7)) bits |= (1 << 6);
    if (matrix.get(8, 5)) bits |= (1 << 5);
    if (matrix.get(8, 4)) bits |= (1 << 4);
    if (matrix.get(8, 3)) bits |= (1 << 3);
    if (matrix.get(8, 2)) bits |= (1 << 2);
    if (matrix.get(8, 1)) bits |= (1 << 1);
    if (matrix.get(8, 0)) bits |= (1 << 0);
    return bits;
  }

  int _readFormatInfo2(BinarizedBitMatrix matrix, int dim) {
    var bits = 0;
    // bits 0..6 at bottom-left: (8, dim-1) to (8, dim-7)
    for (var i = 0; i < 7; i++) {
      if (matrix.get(8, dim - 1 - i)) {
        bits |= (1 << i);
      }
    }
    // bits 7..14 at top-right: (dim-8, 8) to (dim-1, 8)
    for (var i = 7; i < 15; i++) {
      if (matrix.get(dim - 15 + i, 8)) {
        bits |= (1 << i);
      }
    }
    return bits;
  }

  /// Checks if a module at (col, row) is part of a function pattern (not data).
  static bool isFunctionPattern(int col, int row, int dim, int version) {
    // Top-left finder eye (8x8 including separator)
    if (col <= 8 && row <= 8) return true;
    // Top-right finder eye
    if (col >= dim - 8 && row <= 8) return true;
    // Bottom-left finder eye
    if (col <= 8 && row >= dim - 8) return true;
    // Timing patterns (horizontal row 6, vertical col 6)
    if (row == 6 || col == 6) return true;
    // Dark module at (8, 4*version + 9)
    if (col == 8 && row == 4 * version + 9) return true;

    // Alignment patterns for version >= 2
    if (version >= 2) {
      final alignPositions = _getAlignmentPatternPositions(version, dim);
      for (final ax in alignPositions) {
        for (final ay in alignPositions) {
          // Avoid corners occupied by finders
          if ((ax <= 8 && ay <= 8) || (ax >= dim - 8 && ay <= 8) || (ax <= 8 && ay >= dim - 8)) {
            continue;
          }
          if ((col - ax).abs() <= 2 && (row - ay).abs() <= 2) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static List<int> _getAlignmentPatternPositions(int version, int dim) {
    if (version < 2) return const [];
    if (version == 2) return [6, 18];
    if (version == 3) return [6, 22];
    if (version == 4) return [6, 26];
    if (version == 5) return [6, 30];
    if (version == 6) return [6, 34];
    if (version == 7) return [6, 22, 38];
    return [6, dim - 7];
  }

  BinarizedBitMatrix _unmaskMatrix(BinarizedBitMatrix matrix, int dim, int maskPattern, int version) {
    final unmasked = BinarizedBitMatrix(dim, dim);
    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim; x++) {
        var val = matrix.get(x, y);
        if (!isFunctionPattern(x, y, dim, version)) {
          if (_isMaskInverted(maskPattern, x, y)) {
            val = !val;
          }
        }
        unmasked.set(x, y, val);
      }
    }
    return unmasked;
  }

  static bool _isMaskInverted(int mask, int col, int row) {
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
        return ((row ~/ 2) + (col ~/ 3)) % 2 == 0;
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

  Uint8List? _readRawCodewords(BinarizedBitMatrix matrix, int dim, int version, int totalCodewords) {
    final codewords = Uint8List(totalCodewords);
    var currentByte = 0;
    var bitCount = 0;
    var byteCount = 0;
    var readingUp = true;

    for (var rightCol = dim - 1; rightCol > 0; rightCol -= 2) {
      // Skip vertical timing pattern at column 6
      if (rightCol == 6) rightCol--;

      for (var i = 0; i < dim; i++) {
        final row = readingUp ? (dim - 1 - i) : i;

        for (var c = 0; c < 2; c++) {
          final col = rightCol - c;
          if (!isFunctionPattern(col, row, dim, version)) {
            final bit = matrix.get(col, row) ? 1 : 0;
            currentByte = (currentByte << 1) | bit;
            bitCount++;

            if (bitCount == 8) {
              if (byteCount < totalCodewords) {
                codewords[byteCount++] = currentByte;
              }
              currentByte = 0;
              bitCount = 0;
            }
          }
        }
      }
      readingUp = !readingUp;
    }

    return byteCount == totalCodewords ? codewords : null;
  }

  Uint8List? _correctAndDeinterleave(Uint8List rawCodewords, QrVersionInfo version, QrEccLevel ecc) {
    final blockConfig = version.eccBlocks[ecc]!;
    final numBlocks1 = blockConfig.numBlocksGroup1;
    final dataPerBlock1 = blockConfig.dataCodewordsGroup1;
    final numBlocks2 = blockConfig.numBlocksGroup2;
    final dataPerBlock2 = blockConfig.dataCodewordsGroup2;
    final totalBlocks = numBlocks1 + numBlocks2;
    final eccPerBlock = blockConfig.eccCodewordsPerBlock;

    final blocks = List<Uint8List>.generate(totalBlocks, (i) {
      final dataCount = i < numBlocks1 ? dataPerBlock1 : dataPerBlock2;
      return Uint8List(dataCount + eccPerBlock);
    });

    // De-interleave data codewords
    var rawIdx = 0;
    final maxDataLength = dataPerBlock2 > dataPerBlock1 ? dataPerBlock2 : dataPerBlock1;
    for (var i = 0; i < maxDataLength; i++) {
      for (var b = 0; b < totalBlocks; b++) {
        final dataLen = b < numBlocks1 ? dataPerBlock1 : dataPerBlock2;
        if (i < dataLen && rawIdx < rawCodewords.length) {
          blocks[b][i] = rawCodewords[rawIdx++];
        }
      }
    }

    // De-interleave ECC codewords
    for (var i = 0; i < eccPerBlock; i++) {
      for (var b = 0; b < totalBlocks; b++) {
        final dataLen = b < numBlocks1 ? dataPerBlock1 : dataPerBlock2;
        if (rawIdx < rawCodewords.length) {
          blocks[b][dataLen + i] = rawCodewords[rawIdx++];
        }
      }
    }

    // Correct Reed-Solomon errors in each block
    for (var b = 0; b < totalBlocks; b++) {
      final success = rsDecoder.decode(blocks[b], eccPerBlock);
      if (!success) {
        return null; // Uncorrectable transmission error
      }
    }

    // Concatenate corrected data codewords
    final totalDataCodewords = version.getDataCodewordsForEcc(ecc);
    final result = Uint8List(totalDataCodewords);
    var offset = 0;
    for (var b = 0; b < totalBlocks; b++) {
      final dataLen = b < numBlocks1 ? dataPerBlock1 : dataPerBlock2;
      result.setRange(offset, offset + dataLen, blocks[b].sublist(0, dataLen));
      offset += dataLen;
    }

    return result;
  }

  /// Decodes payload data bytes across numeric, alphanumeric, and byte modes.
  static String? decodePayloadStream(Uint8List dataBytes, int version) {
    var bitPos = 0;
    final totalBits = dataBytes.length * 8;

    int readBits(int count) {
      var val = 0;
      for (var i = 0; i < count; i++) {
        if (bitPos >= totalBits) return val;
        final byteIdx = bitPos >> 3;
        final bitIdx = 7 - (bitPos & 7);
        val = (val << 1) | ((dataBytes[byteIdx] >> bitIdx) & 1);
        bitPos++;
      }
      return val;
    }

    final buffer = StringBuffer();
    const alphanumericChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:';

    while (bitPos + 4 <= totalBits) {
      final mode = readBits(4);
      if (mode == 0) break; // Terminator

      if (mode == 1) {
        // Numeric Mode
        final countBits = version <= 9 ? 10 : version <= 26 ? 12 : 14;
        var count = readBits(countBits);
        while (count >= 3 && bitPos + 10 <= totalBits) {
          final val = readBits(10);
          buffer.write(val.toString().padLeft(3, '0'));
          count -= 3;
        }
        if (count == 2 && bitPos + 7 <= totalBits) {
          final val = readBits(7);
          buffer.write(val.toString().padLeft(2, '0'));
        } else if (count == 1 && bitPos + 4 <= totalBits) {
          final val = readBits(4);
          buffer.write(val.toString());
        }
      } else if (mode == 2) {
        // Alphanumeric Mode
        final countBits = version <= 9 ? 9 : version <= 26 ? 11 : 13;
        var count = readBits(countBits);
        while (count >= 2 && bitPos + 11 <= totalBits) {
          final val = readBits(11);
          final c1 = val ~/ 45;
          final c2 = val % 45;
          if (c1 < alphanumericChars.length) buffer.write(alphanumericChars[c1]);
          if (c2 < alphanumericChars.length) buffer.write(alphanumericChars[c2]);
          count -= 2;
        }
        if (count == 1 && bitPos + 6 <= totalBits) {
          final val = readBits(6);
          if (val < alphanumericChars.length) buffer.write(alphanumericChars[val]);
        }
      } else if (mode == 4) {
        // Byte Mode (UTF-8 / ISO-8859-1)
        final countBits = version <= 9 ? 8 : 16;
        final count = readBits(countBits);
        final bytes = Uint8List(count);
        for (var i = 0; i < count; i++) {
          if (bitPos + 8 <= totalBits) {
            bytes[i] = readBits(8);
          }
        }
        try {
          buffer.write(utf8.decode(bytes));
        } catch (_) {
          buffer.write(latin1.decode(bytes));
        }
      } else {
        // Other / unknown modes: break
        break;
      }
    }

    final decoded = buffer.toString();
    return decoded.isNotEmpty ? decoded : null;
  }
}
