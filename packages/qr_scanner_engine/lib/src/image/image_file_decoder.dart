import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'image_buffer.dart';

/// Pure-Dart image file decoder supporting BMP, PNG, and uncompressed pixel buffers.
class ImageFileDecoder {
  /// Decodes raw file bytes into an [ImageBuffer].
  static ImageBuffer? decodeFileBytes(Uint8List fileBytes) {
    if (fileBytes.length < 8) return null;

    // Check for PNG signature (0x89, 0x50, 0x4E, 0x47)
    if (fileBytes[0] == 0x89 &&
        fileBytes[1] == 0x50 &&
        fileBytes[2] == 0x4E &&
        fileBytes[3] == 0x47) {
      return _decodePng(fileBytes);
    }

    // Check for BMP signature ('BM' = 0x42, 0x4D)
    if (fileBytes.length >= 14 && fileBytes[0] == 0x42 && fileBytes[1] == 0x4D) {
      return _decodeBmp(fileBytes);
    }

    return null;
  }

  static ImageBuffer? _decodePng(Uint8List bytes) {
    try {
      var offset = 8;
      var width = 0;
      var height = 0;
      var colorType = 6;
      final idatChunks = BytesBuilder();

      while (offset + 8 <= bytes.length) {
        final byteData = ByteData.sublistView(bytes, offset, offset + 8);
        final length = byteData.getUint32(0, Endian.big);
        final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
        offset += 8;

        if (offset + length > bytes.length) break;

        if (type == 'IHDR') {
          final ihdr = ByteData.sublistView(bytes, offset, offset + length);
          width = ihdr.getUint32(0, Endian.big);
          height = ihdr.getUint32(4, Endian.big);
          colorType = ihdr.getUint8(9);
        } else if (type == 'IDAT') {
          idatChunks.add(bytes.sublist(offset, offset + length));
        } else if (type == 'IEND') {
          break;
        }

        offset += length + 4; // Skip chunk data + 4-byte CRC
      }

      if (width <= 0 || height <= 0) return null;

      final uncompressed = Uint8List.fromList(zlib.decode(idatChunks.takeBytes()));
      final rgbaBytes = Uint8List(width * height * 4);

      final bpp = colorType == 6 ? 4 : (colorType == 2 ? 3 : 1);

      var srcOffset = 0;
      var dstOffset = 0;

      for (var y = 0; y < height; y++) {
        if (srcOffset >= uncompressed.length) break;
        final filter = uncompressed[srcOffset++];

        if (filter == 0) {
          if (bpp == 4) {
            rgbaBytes.setRange(dstOffset, dstOffset + width * 4, uncompressed, srcOffset);
            dstOffset += width * 4;
            srcOffset += width * 4;
          } else if (bpp == 3) {
            for (var x = 0; x < width; x++) {
              final r = uncompressed[srcOffset++];
              final g = uncompressed[srcOffset++];
              final b = uncompressed[srcOffset++];
              rgbaBytes[dstOffset++] = r;
              rgbaBytes[dstOffset++] = g;
              rgbaBytes[dstOffset++] = b;
              rgbaBytes[dstOffset++] = 0xFF;
            }
          }
        } else {
          if (bpp == 4) {
            rgbaBytes.setRange(dstOffset, dstOffset + width * 4, uncompressed, srcOffset);
            dstOffset += width * 4;
            srcOffset += width * 4;
          }
        }
      }

      return ImageBuffer(width: width, height: height, bytes: rgbaBytes);
    } catch (_) {
      return null;
    }
  }

  static ImageBuffer? _decodeBmp(Uint8List bytes) {
    try {
      final byteData = ByteData.sublistView(bytes);
      final pixelOffset = byteData.getUint32(10, Endian.little);
      final headerSize = byteData.getUint32(14, Endian.little);

      if (headerSize < 40) return null;

      final width = byteData.getInt32(18, Endian.little);
      final heightRaw = byteData.getInt32(22, Endian.little);
      final bpp = byteData.getUint16(28, Endian.little);
      final compression = byteData.getUint32(30, Endian.little);

      // Only uncompressed RGB (0) is supported directly
      if (compression != 0) return null;
      if (bpp != 24 && bpp != 32 && bpp != 8) return null;

      final isTopDown = heightRaw < 0;
      final height = heightRaw.abs();
      final rowStride = ((width * bpp + 31) ~/ 32) * 4;

      final rgbaBytes = Uint8List(width * height * 4);

      for (var y = 0; y < height; y++) {
        final srcY = isTopDown ? y : (height - 1 - y);
        final srcRowOffset = pixelOffset + srcY * rowStride;
        final dstRowOffset = y * width * 4;

        if (bpp == 24) {
          for (var x = 0; x < width; x++) {
            final srcIdx = srcRowOffset + x * 3;
            final dstIdx = dstRowOffset + x * 4;
            if (srcIdx + 2 < bytes.length) {
              final b = bytes[srcIdx];
              final g = bytes[srcIdx + 1];
              final r = bytes[srcIdx + 2];
              rgbaBytes[dstIdx] = r;
              rgbaBytes[dstIdx + 1] = g;
              rgbaBytes[dstIdx + 2] = b;
              rgbaBytes[dstIdx + 3] = 255;
            }
          }
        } else if (bpp == 32) {
          for (var x = 0; x < width; x++) {
            final srcIdx = srcRowOffset + x * 4;
            final dstIdx = dstRowOffset + x * 4;
            if (srcIdx + 3 < bytes.length) {
              final b = bytes[srcIdx];
              final g = bytes[srcIdx + 1];
              final r = bytes[srcIdx + 2];
              final a = bytes[srcIdx + 3];
              rgbaBytes[dstIdx] = r;
              rgbaBytes[dstIdx + 1] = g;
              rgbaBytes[dstIdx + 2] = b;
              rgbaBytes[dstIdx + 3] = a;
            }
          }
        } else if (bpp == 8) {
          // Grayscale palette assumed
          for (var x = 0; x < width; x++) {
            final srcIdx = srcRowOffset + x;
            final dstIdx = dstRowOffset + x * 4;
            if (srcIdx < bytes.length) {
              final lum = bytes[srcIdx];
              rgbaBytes[dstIdx] = lum;
              rgbaBytes[dstIdx + 1] = lum;
              rgbaBytes[dstIdx + 2] = lum;
              rgbaBytes[dstIdx + 3] = 255;
            }
          }
        }
      }

      return ImageBuffer(
        bytes: rgbaBytes,
        width: width,
        height: height,
        format: ImageColorFormat.rgba8888,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encodes an [ImageBuffer] to a valid standard uncompressed 24-bit BMP byte array.
  static Uint8List encodeBmp(ImageBuffer buffer) {
    final width = buffer.width;
    final height = buffer.height;
    final rowPadding = (4 - ((width * 3) % 4)) % 4;
    final rowStride = width * 3 + rowPadding;
    final imageSize = rowStride * height;
    final fileSize = 54 + imageSize;

    final bytes = Uint8List(fileSize);
    final data = ByteData.sublistView(bytes);

    // Bitmap File Header (14 bytes)
    data.setUint8(0, 0x42); // 'B'
    data.setUint8(1, 0x4D); // 'M'
    data.setUint32(2, fileSize, Endian.little);
    data.setUint32(6, 0, Endian.little);
    data.setUint32(10, 54, Endian.little); // Pixel data offset

    // DIB Header (BITMAPINFOHEADER - 40 bytes)
    data.setUint32(14, 40, Endian.little); // Header size
    data.setInt32(18, width, Endian.little);
    data.setInt32(22, height, Endian.little); // Positive = bottom-up
    data.setUint16(26, 1, Endian.little); // Color planes
    data.setUint16(28, 24, Endian.little); // 24 bits per pixel
    data.setUint32(30, 0, Endian.little); // BI_RGB (uncompressed)
    data.setUint32(34, imageSize, Endian.little);
    data.setInt32(38, 2835, Endian.little); // ~72 DPI
    data.setInt32(42, 2835, Endian.little);
    data.setUint32(46, 0, Endian.little);
    data.setUint32(50, 0, Endian.little);

    final luminance = buffer.getLuminance();

    for (var y = 0; y < height; y++) {
      // BMP bottom-up
      final srcY = height - 1 - y;
      final dstRowOffset = 54 + y * rowStride;
      final srcRowOffset = srcY * width;

      for (var x = 0; x < width; x++) {
        final lum = luminance[srcRowOffset + x];
        final dstIdx = dstRowOffset + x * 3;
        bytes[dstIdx] = lum; // B
        bytes[dstIdx + 1] = lum; // G
        bytes[dstIdx + 2] = lum; // R
      }
    }

    return bytes;
  }
}

/// Helper for generating standards-compliant test QR bit matrices and synthetic images for testing.
class QrTestPatternGenerator {
  /// Generates the standard 26 codewords (16 data + 10 Reed-Solomon ECC) for a Version 1 QR code with ECC Level M.
  static Uint8List createVersion1Codewords(String text) {
    final textBytes = utf8.encode(text);
    const totalDataCodewords = 16;
    final dataCodewords = Uint8List(totalDataCodewords);

    var bitPos = 0;
    void writeBits(int value, int count) {
      for (var i = count - 1; i >= 0; i--) {
        final bit = (value >> i) & 1;
        final byteIdx = bitPos >> 3;
        final bitIdx = 7 - (bitPos & 7);
        if (byteIdx < totalDataCodewords) {
          dataCodewords[byteIdx] |= (bit << bitIdx);
        }
        bitPos++;
      }
    }

    writeBits(4, 4); // Byte mode (0100)
    writeBits(min(textBytes.length, 14), 8); // Character count

    for (var i = 0; i < textBytes.length && i < 14; i++) {
      writeBits(textBytes[i], 8);
    }
    writeBits(0, 4); // Terminator

    // Pad with standard alternating bytes: 0xEC, 0x11
    var padByte = 0xEC;
    final currentByteIdx = (bitPos + 7) >> 3;
    for (var i = currentByteIdx; i < totalDataCodewords; i++) {
      dataCodewords[i] = padByte;
      padByte = padByte == 0xEC ? 0x11 : 0xEC;
    }

    // Compute Reed-Solomon ECC Codewords (10 codewords for V1-M)
    final eccCodewords = _computeReedSolomonEcc(dataCodewords, 10);

    final fullCodewords = Uint8List(26);
    fullCodewords.setRange(0, 16, dataCodewords);
    fullCodewords.setRange(16, 26, eccCodewords);
    return fullCodewords;
  }

  /// Creates a synthetic ISO/IEC 18004 Version 1 QR code matrix (21x21) encoding [text] in Byte Mode (ECC Level M).
  static BinarizedBitMatrix createVersion1Matrix(String text) {
    const dim = 21;
    final matrix = BinarizedBitMatrix(dim, dim);

    // 1. Draw Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawFinderPattern(matrix, 0, 0);
    _drawFinderPattern(matrix, dim - 7, 0);
    _drawFinderPattern(matrix, 0, dim - 7);

    // 2. Draw Separators around Finder Patterns
    for (var i = 0; i < 8; i++) {
      matrix.set(7, i, false);
      matrix.set(i, 7, false);
      matrix.set(dim - 8, i, false);
      matrix.set(dim - 1 - i, 7, false);
      matrix.set(7, dim - 1 - i, false);
      matrix.set(i, dim - 8, false);
    }

    // 3. Draw Timing Patterns (Row 6 and Column 6)
    for (var i = 8; i < dim - 8; i++) {
      matrix.set(i, 6, (i % 2) == 0);
      matrix.set(6, i, (i % 2) == 0);
    }

    // 4. Dark Module at (8, 4*1 + 9 = 13)
    matrix.set(8, 13, true);

    // 5. Build Byte-Mode Data Payload for Version 1 (16 data codewords, 10 ECC codewords)
    final fullCodewords = createVersion1Codewords(text);

    // 7. Write Format Info: ECC Level M (00) + Mask 0 (000) = 00000 -> XORed with 0x5412 = 0x5412
    _writeFormatInfo(matrix, dim, 0x5412);

    // 8. Write data bits with Mask 0 ((row + col) % 2 == 0)
    var byteIdx = 0;
    var bitIdx = 7;
    var readingUp = true;

    for (var rightCol = dim - 1; rightCol > 0; rightCol -= 2) {
      if (rightCol == 6) rightCol--;

      for (var i = 0; i < dim; i++) {
        final row = readingUp ? (dim - 1 - i) : i;

        for (var c = 0; c < 2; c++) {
          final col = rightCol - c;
          if (!_isFunctionPattern(col, row, dim)) {
            var bit = false;
            if (byteIdx < 26) {
              bit = ((fullCodewords[byteIdx] >> bitIdx) & 1) != 0;
              bitIdx--;
              if (bitIdx < 0) {
                bitIdx = 7;
                byteIdx++;
              }
            }
            // Apply Mask 0: invert if (row + col) % 2 == 0
            if ((row + col) % 2 == 0) {
              bit = !bit;
            }
            matrix.set(col, row, bit);
          }
        }
      }
      readingUp = !readingUp;
    }

    return matrix;
  }

  static void _drawFinderPattern(BinarizedBitMatrix matrix, int startX, int startY) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final isBorder = x == 0 || x == 6 || y == 0 || y == 6;
        final isCenter = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        matrix.set(startX + x, startY + y, isBorder || isCenter);
      }
    }
  }

  static void _writeFormatInfo(BinarizedBitMatrix matrix, int dim, int formatBits) {
    // Top-left
    matrix.set(0, 8, (formatBits & (1 << 14)) != 0);
    matrix.set(1, 8, (formatBits & (1 << 13)) != 0);
    matrix.set(2, 8, (formatBits & (1 << 12)) != 0);
    matrix.set(3, 8, (formatBits & (1 << 11)) != 0);
    matrix.set(4, 8, (formatBits & (1 << 10)) != 0);
    matrix.set(5, 8, (formatBits & (1 << 9)) != 0);
    matrix.set(7, 8, (formatBits & (1 << 8)) != 0);
    matrix.set(8, 8, (formatBits & (1 << 7)) != 0);
    matrix.set(8, 7, (formatBits & (1 << 6)) != 0);
    matrix.set(8, 5, (formatBits & (1 << 5)) != 0);
    matrix.set(8, 4, (formatBits & (1 << 4)) != 0);
    matrix.set(8, 3, (formatBits & (1 << 3)) != 0);
    matrix.set(8, 2, (formatBits & (1 << 2)) != 0);
    matrix.set(8, 1, (formatBits & (1 << 1)) != 0);
    matrix.set(8, 0, (formatBits & (1 << 0)) != 0);

    // Duplicate around bottom-left and top-right
    for (var i = 0; i < 7; i++) {
      matrix.set(8, dim - 1 - i, (formatBits & (1 << i)) != 0);
    }
    for (var i = 7; i < 15; i++) {
      matrix.set(dim - 15 + i, 8, (formatBits & (1 << i)) != 0);
    }
  }

  static bool _isFunctionPattern(int col, int row, int dim) {
    if (col <= 8 && row <= 8) return true;
    if (col >= dim - 8 && row <= 8) return true;
    if (col <= 8 && row >= dim - 8) return true;
    if (row == 6 || col == 6) return true;
    if (col == 8 && row == 13) return true;
    return false;
  }

  static Uint8List _computeReedSolomonEcc(Uint8List data, int numEcc) {
    // Polynomial division over GF(256)
    // Precomputed generator polynomial for 10 ECC codewords (V1-M):
    // g(x) = x^10 + 216x^9 + 194x^8 + 159x^7 + 111x^6 + 199x^5 + 94x^4 + 95x^3 + 113x^2 + 157x + 193
    const gen = [1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193];

    // GF(256) multiplication lookup
    final exp = Uint8List(512);
    final log = Uint8List(256);
    var x = 1;
    for (var i = 0; i < 255; i++) {
      exp[i] = x;
      exp[i + 255] = x;
      log[x] = i;
      x <<= 1;
      if (x >= 256) x ^= 0x11D;
    }

    int mul(int a, int b) => (a == 0 || b == 0) ? 0 : exp[log[a] + log[b]];

    final remainder = Uint8List(numEcc);
    for (var i = 0; i < data.length; i++) {
      final factor = data[i] ^ remainder[0];
      for (var j = 0; j < numEcc - 1; j++) {
        remainder[j] = remainder[j + 1] ^ mul(factor, gen[j + 1]);
      }
      remainder[numEcc - 1] = mul(factor, gen[numEcc]);
    }

    return remainder;
  }

  /// Renders a [BinarizedBitMatrix] to an [ImageBuffer] with configurable scale and quiet zone.
  static ImageBuffer matrixToImageBuffer(
    BinarizedBitMatrix matrix, {
    int scale = 8,
    int quietZone = 4,
    bool invertColors = false,
  }) {
    final dim = matrix.width;
    final totalModules = dim + quietZone * 2;
    final imageWidth = totalModules * scale;
    final imageHeight = imageWidth;
    final rgba = Uint8List(imageWidth * imageHeight * 4);

    final blackColor = invertColors ? 255 : 0;
    final whiteColor = invertColors ? 0 : 255;

    for (var my = 0; my < totalModules; my++) {
      for (var mx = 0; mx < totalModules; mx++) {
        final qx = mx - quietZone;
        final qy = my - quietZone;

        final isBlack = (qx >= 0 && qx < dim && qy >= 0 && qy < dim) && matrix.get(qx, qy);
        final color = isBlack ? blackColor : whiteColor;

        for (var py = 0; py < scale; py++) {
          final rowOffset = ((my * scale + py) * imageWidth) * 4;
          for (var px = 0; px < scale; px++) {
            final colOffset = (mx * scale + px) * 4;
            final idx = rowOffset + colOffset;
            rgba[idx] = color;
            rgba[idx + 1] = color;
            rgba[idx + 2] = color;
            rgba[idx + 3] = 255;
          }
        }
      }
    }

    return ImageBuffer(
      bytes: rgba,
      width: imageWidth,
      height: imageHeight,
      format: ImageColorFormat.rgba8888,
    );
  }

  /// Creates a multi-QR composite image containing [matrices] arranged horizontally or in a grid.
  static ImageBuffer createMultiQrComposite(
    List<BinarizedBitMatrix> matrices, {
    int scale = 4,
    int gap = 20,
    int quietZone = 4,
  }) {
    final singleSize = (matrices.first.width + quietZone * 2) * scale;
    final totalWidth = matrices.length * singleSize + (matrices.length + 1) * gap;
    final totalHeight = singleSize + gap * 2;
    final rgba = Uint8List(totalWidth * totalHeight * 4)..fillRange(0, totalWidth * totalHeight * 4, 255);

    for (var i = 0; i < matrices.length; i++) {
      final img = matrixToImageBuffer(matrices[i], scale: scale, quietZone: quietZone);
      final startX = gap + i * (singleSize + gap);
      final startY = gap;

      for (var y = 0; y < img.height; y++) {
        final srcRow = y * img.width * 4;
        final dstRow = (startY + y) * totalWidth * 4;
        for (var x = 0; x < img.width; x++) {
          final srcIdx = srcRow + x * 4;
          final dstIdx = dstRow + (startX + x) * 4;
          rgba[dstIdx] = img.bytes[srcIdx];
          rgba[dstIdx + 1] = img.bytes[srcIdx + 1];
          rgba[dstIdx + 2] = img.bytes[srcIdx + 2];
          rgba[dstIdx + 3] = 255;
        }
      }
    }

    return ImageBuffer(
      bytes: rgba,
      width: totalWidth,
      height: totalHeight,
      format: ImageColorFormat.rgba8888,
    );
  }
}
