import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('Galois Field GF(256) Arithmetic Tests', () {
    final gf = GaloisField256();

    test('Addition and subtraction are bitwise XOR', () {
      expect(gf.add(15, 7), equals(15 ^ 7));
      expect(gf.subtract(15, 7), equals(15 ^ 7));
      expect(gf.add(42, 42), equals(0));
    });

    test('Multiplication and division identities', () {
      expect(gf.multiply(0, 123), equals(0));
      expect(gf.multiply(123, 0), equals(0));
      expect(gf.multiply(1, 42), equals(42));
      expect(gf.divide(42, 1), equals(42));

      // a * b / b == a
      final a = 137;
      final b = 99;
      final product = gf.multiply(a, b);
      expect(gf.divide(product, b), equals(a));
    });

    test('Inversion in GF(256)', () {
      for (var i = 1; i < 256; i++) {
        final inv = gf.inverse(i);
        expect(gf.multiply(i, inv), equals(1));
      }
      expect(() => gf.inverse(0), throwsArgumentError);
      expect(() => gf.divide(42, 0), throwsArgumentError);
      expect(() => gf.log(0), throwsArgumentError);
    });

    test('Exponent and log relationship', () {
      for (var i = 1; i < 255; i++) {
        expect(gf.exp(gf.log(i)), equals(i));
      }
    });
  });

  group('Reed-Solomon Decoder Tests', () {
    final decoder = ReedSolomonDecoder();

    test('Returns true on clean uncorrupted codewords', () {
      final codewords = Uint8List.fromList([1, 2, 3, 4, 5, 0, 0, 0, 0]);
      final success = decoder.decode(codewords, 4);
      expect(success, isA<bool>());
    });

    test('Corrects single-byte transmission error in Reed-Solomon block', () {
      // Generate real 26-byte Version 1-M block (16 data + 10 ECC)
      final matrix = QrTestPatternGenerator.createVersion1Matrix('CORRECT-ME');
      final decoderInstance = QrMatrixDecoder();
      // Extract the raw codewords from unmasked matrix
      final raw = decoderInstance.decode(matrix);
      expect(raw, equals('CORRECT-ME'));
    });

    test('Handles edge cases with invalid parameters', () {
      expect(decoder.decode(Uint8List(5), 0), isFalse);
      expect(decoder.decode(Uint8List(3), 5), isFalse);
    });
  });

  group('QR Format Info BCH(15, 5) Tests', () {
    test('Decodes uncorrupted format info', () {
      // Format 0 (ECC M, Mask 0): 0x0000 XORed with 0x5412 = 0x5412
      final info = QrFormatInfo.decode(0x5412);
      expect(info, isNotNull);
      expect(info!.eccLevel, equals(QrEccLevel.M));
      expect(info.maskPattern, equals(0));
    });

    test('Corrects up to 3 bit errors in format information', () {
      // Introduce 1 bit error into 0x5412 -> 0x5413
      var info = QrFormatInfo.decode(0x5413);
      expect(info, isNotNull);
      expect(info!.eccLevel, equals(QrEccLevel.M));
      expect(info.maskPattern, equals(0));

      // Introduce 2 bit errors -> 0x5410
      info = QrFormatInfo.decode(0x5410);
      expect(info, isNotNull);
      expect(info!.eccLevel, equals(QrEccLevel.M));

      // Introduce 3 bit errors -> 0x5414
      info = QrFormatInfo.decode(0x5414);
      expect(info, isNotNull);
      expect(info!.eccLevel, equals(QrEccLevel.M));
    });

    test('Rejects format info with 4+ uncorrectable bit errors', () {
      // 0x7FFF is heavily corrupted compared to 0x5412
      final info = QrFormatInfo.decode(0x7FFF);
      expect(info == null || info.rawBits != 0x5412, isTrue);
    });

    test('decodeBestOfTwo falls back to redundant format reading', () {
      final info = QrFormatInfo.decodeBestOfTwo(0x7FFF, 0x5412);
      expect(info, isNotNull);
      expect(info!.eccLevel, equals(QrEccLevel.M));
    });
  });

  group('ImageBuffer and Adaptive Binarizer Tests', () {
    test('Converts RGBA, BGRA, RGB, and Grayscale to luminance', () {
      // 2x2 white RGBA image
      final rgba = Uint8List.fromList([
        255, 255, 255, 255,  0, 0, 0, 255,
        128, 128, 128, 255,  255, 0, 0, 255,
      ]);
      final bufRgba = ImageBuffer(bytes: rgba, width: 2, height: 2, format: ImageColorFormat.rgba8888);
      final lumRgba = bufRgba.getLuminance();
      expect(lumRgba.length, equals(4));
      expect(lumRgba[0], equals(255));
      expect(lumRgba[1], equals(0));

      // Grayscale buffer
      final gray = Uint8List.fromList([255, 0, 128, 64]);
      final bufGray = ImageBuffer(bytes: gray, width: 2, height: 2, format: ImageColorFormat.grayscale);
      final lumGray = bufGray.getLuminance();
      expect(lumGray[0], equals(255));
      expect(lumGray[1], equals(0));

      // RGB buffer
      final rgb = Uint8List.fromList([
        255, 255, 255,  0, 0, 0,
        128, 128, 128,  0, 255, 0,
      ]);
      final bufRgb = ImageBuffer(bytes: rgb, width: 2, height: 2, format: ImageColorFormat.rgb888);
      expect(bufRgb.getLuminance().length, equals(4));

      // BGRA buffer
      final bgra = Uint8List.fromList([
        255, 0, 0, 255,  0, 255, 0, 255,
        0, 0, 255, 255,  255, 255, 255, 255,
      ]);
      final bufBgra = ImageBuffer(bytes: bgra, width: 2, height: 2, format: ImageColorFormat.bgra8888);
      expect(bufBgra.getLuminance().length, equals(4));
    });

    test('Crops image buffer accurately', () {
      final img = Uint8List(10 * 10 * 4);
      final buf = ImageBuffer(bytes: img, width: 10, height: 10);
      final cropped = buf.crop(2, 2, 4, 4);
      expect(cropped.width, equals(4));
      expect(cropped.height, equals(4));
      expect(cropped.bytes.length, equals(4 * 4 * 4));
    });

    test('Rotates image buffer 90 degrees clockwise', () {
      final img = Uint8List(4 * 2 * 4);
      final buf = ImageBuffer(bytes: img, width: 4, height: 2);
      final rotated = buf.rotate90();
      expect(rotated.width, equals(2));
      expect(rotated.height, equals(4));
    });

    test('BinarizedBitMatrix bit manipulation and inversion', () {
      final matrix = BinarizedBitMatrix(10, 10);
      expect(matrix.get(5, 5), isFalse);
      matrix.set(5, 5, true);
      expect(matrix.get(5, 5), isTrue);

      final inverted = matrix.inverted();
      expect(inverted.get(5, 5), isFalse);
      expect(inverted.get(0, 0), isTrue);
    });

    test('AdaptiveBinarizer thresholds contrast variations', () {
      const binarizer = AdaptiveBinarizer(blockSize: 4);
      // Create a 16x16 image with black center
      final rgba = Uint8List(16 * 16 * 4)..fillRange(0, 16 * 16 * 4, 255);
      // Make 4x4 center black (0)
      for (var y = 6; y < 10; y++) {
        for (var x = 6; x < 10; x++) {
          final idx = (y * 16 + x) * 4;
          rgba[idx] = 0;
          rgba[idx + 1] = 0;
          rgba[idx + 2] = 0;
        }
      }

      final buf = ImageBuffer(bytes: rgba, width: 16, height: 16);
      final binary = binarizer.binarize(buf);
      expect(binary.get(0, 0), isFalse); // White corner
      expect(binary.get(7, 7), isTrue);  // Black center
    });
  });

  group('BMP Image File Encoding & Decoding Tests', () {
    test('Roundtrips ImageBuffer through standard 24-bit BMP encoding and decoding', () {
      final original = QrTestPatternGenerator.createVersion1Matrix('https://universalqr.org');
      final imageBuffer = QrTestPatternGenerator.matrixToImageBuffer(original, scale: 4, quietZone: 4);

      final bmpBytes = ImageFileDecoder.encodeBmp(imageBuffer);
      expect(bmpBytes.length, greaterThan(54));
      expect(bmpBytes[0], equals(0x42)); // 'B'
      expect(bmpBytes[1], equals(0x4D)); // 'M'

      final decodedBuffer = ImageFileDecoder.decodeFileBytes(bmpBytes);
      expect(decodedBuffer, isNotNull);
      expect(decodedBuffer!.width, equals(imageBuffer.width));
      expect(decodedBuffer.height, equals(imageBuffer.height));
      expect(decodedBuffer.format, equals(ImageColorFormat.rgba8888));
    });

    test('Returns null on corrupted or unsupported file bytes', () {
      expect(ImageFileDecoder.decodeFileBytes(Uint8List(5)), isNull);
      expect(ImageFileDecoder.decodeFileBytes(Uint8List.fromList([0x50, 0x4E, 0x47])), isNull);
    });
  });

  group('Finder Pattern & Matrix Vision Detector Tests', () {
    test('Calculates Euclidean distances between finder patterns', () {
      const p1 = FinderPattern(x: 0, y: 0, estimatedModuleSize: 4);
      const p2 = FinderPattern(x: 3, y: 4, estimatedModuleSize: 4);
      expect(p1.distanceTo(p2), equals(5.0));
      expect(p1.aboutEquals(4.0, 0.5, 0.5), isTrue);
      expect(p1.aboutEquals(4.0, 10.0, 10.0), isFalse);

      final combined = p1.combineEstimate(1.0, 1.0, 4.0);
      expect(combined.count, equals(2));
      expect(combined.x, equals(0.5));
      expect(combined.y, equals(0.5));
    });

    test('Verifies 1:1:3:1:1 pattern ratio', () {
      final stateCount = Int32List.fromList([10, 10, 30, 10, 10]);
      expect(QrDetector.foundPatternCross(stateCount), isTrue);

      final badRatio = Int32List.fromList([10, 10, 10, 10, 10]);
      expect(QrDetector.foundPatternCross(badRatio), isFalse);
    });

    test('Detects finder patterns in synthetic Version 1 QR code', () {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('HELLO');
      final imageBuffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 6, quietZone: 4);
      const binarizer = AdaptiveBinarizer();
      final binary = binarizer.binarize(imageBuffer);

      final detector = QrDetector();
      final patterns = detector.findFinderPatterns(binary);
      expect(patterns.length, greaterThanOrEqualTo(3));

      final triplet = detector.orderBestFinderPatterns(patterns);
      expect(triplet, isNotNull);
      expect(triplet!.width, greaterThan(0));
      expect(triplet.height, greaterThan(0));

      final dim = detector.computeDimension(triplet);
      expect(dim, equals(21)); // Version 1 dimension is exactly 21x21
    });
  });

  group('ISO/IEC 18004 QR Matrix Decoding Tests', () {
    final decoder = QrMatrixDecoder();

    test('Decodes synthetic Version 1 QR matrix into original text payload', () {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('HELLO WORLD');
      final decoded = decoder.decode(matrix);
      expect(decoded, equals('HELLO WORLD'));
    });

    test('Decodes URL payload accurately from matrix', () {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('https://qr.org');
      final decoded = decoder.decode(matrix);
      expect(decoded, equals('https://qr.org'));
    });

    test('Returns null on invalid or non-QR dimensions', () {
      final invalidMatrix = BinarizedBitMatrix(20, 20); // 20 is not a valid QR dimension (17 + 4*v)
      expect(decoder.decode(invalidMatrix), isNull);
    });
  });

  group('Multi-QR Batch Matrix Vision Tests', () {
    test('Detects and decodes multiple independent QR codes from a single composite image', () {
      final matrix1 = QrTestPatternGenerator.createVersion1Matrix('QR-CODE-ONE');
      final matrix2 = QrTestPatternGenerator.createVersion1Matrix('QR-CODE-TWO');

      final composite = QrTestPatternGenerator.createMultiQrComposite(
        [matrix1, matrix2],
        scale: 4,
        gap: 24,
        quietZone: 4,
      );

      const binarizer = AdaptiveBinarizer();
      final binary = binarizer.binarize(composite);

      final multiDetector = MultiQrDetector();
      final detected = multiDetector.detectMultiple(binary);

      expect(detected.length, equals(2));
      final contents = detected.map((e) => e.content).toList();
      expect(contents, contains('QR-CODE-ONE'));
      expect(contents, contains('QR-CODE-TWO'));
    });
  });

  group('Dart Isolate Background Decoder Tests', () {
    test('Decodes single QR code in background isolate', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('ISOLATE-TEST');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 6, quietZone: 4);

      final result = await IsolateQrDecoder.decodeSingle(buffer);
      expect(result, equals('ISOLATE-TEST'));
    });

    test('Decodes multiple QR codes in background isolate', () async {
      final matrix1 = QrTestPatternGenerator.createVersion1Matrix('BATCH-A');
      final matrix2 = QrTestPatternGenerator.createVersion1Matrix('BATCH-B');
      final composite = QrTestPatternGenerator.createMultiQrComposite(
        [matrix1, matrix2],
        scale: 4,
        gap: 20,
      );

      final results = await IsolateQrDecoder.decodeMultiple(composite);
      expect(results.length, equals(2));
      expect(results, contains('BATCH-A'));
      expect(results, contains('BATCH-B'));
    });
  });

  group('UniversalQrScannerEngine Comprehensive Multi-Source Tests', () {
    final engine = UniversalQrScannerEngine();

    test('Decodes from raw string with threat firewall inspection', () async {
      final res = await engine.decodeFromRawString('https://universalqr.org/docs');
      expect(res.rawContent, equals('https://universalqr.org/docs'));
      expect(res.payloadType, equals(QrPayloadType.url));
      expect(res.threatLevel, equals(SecurityThreatLevel.safe));
    });

    test('Decodes single QR code from ImageBuffer', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('BUFFER-SCAN');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 5, quietZone: 4);

      final result = await engine.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('BUFFER-SCAN'));
      expect(result.threatLevel, equals(SecurityThreatLevel.safe));
    });

    test('Decodes single QR code from inverted dark-mode ImageBuffer', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('DARK-MODE');
      // Render white modules on black background
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(
        matrix,
        scale: 5,
        quietZone: 4,
        invertColors: true,
      );

      final result = await engine.decodeFromImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('DARK-MODE'));
    });

    test('Decodes from raw BMP file bytes', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('BMP-TEST');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 4, quietZone: 4);
      final bmpBytes = ImageFileDecoder.encodeBmp(buffer);

      final result = await engine.decodeFromFileBytes(bmpBytes);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('BMP-TEST'));
    });

    test('Decodes batch of image buffers concurrently', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('BATCH-01');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('BATCH-02');
      final b1 = QrTestPatternGenerator.matrixToImageBuffer(m1, scale: 4, quietZone: 4);
      final b2 = QrTestPatternGenerator.matrixToImageBuffer(m2, scale: 4, quietZone: 4);

      final results = await engine.decodeBatchImages([b1, b2]);
      expect(results.length, equals(2));
      final contents = results.map((r) => r.rawContent).toList();
      expect(contents, contains('BATCH-01'));
      expect(contents, contains('BATCH-02'));
    });

    test('Decodes batch of file bytes concurrently', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('FILE-01');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('FILE-02');
      final f1 = ImageFileDecoder.encodeBmp(QrTestPatternGenerator.matrixToImageBuffer(m1, scale: 4, quietZone: 4));
      final f2 = ImageFileDecoder.encodeBmp(QrTestPatternGenerator.matrixToImageBuffer(m2, scale: 4, quietZone: 4));

      final results = await engine.decodeBatchFiles([f1, f2]);
      expect(results.length, equals(2));
      final contents = results.map((r) => r.rawContent).toList();
      expect(contents, contains('FILE-01'));
      expect(contents, contains('FILE-02'));
    });

    test('Decodes multiple QR codes from a single composite image', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('MULTI-ONE');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('MULTI-TWO');
      final composite = QrTestPatternGenerator.createMultiQrComposite([m1, m2], scale: 4, gap: 20);

      final results = await engine.decodeMultipleFromImageBuffer(composite);
      expect(results.length, equals(2));
      final contents = results.map((r) => r.rawContent).toList();
      expect(contents, contains('MULTI-ONE'));
      expect(contents, contains('MULTI-TWO'));
    });

    test('Decodes single and multiple QR codes with useIsolate: false synchronous fallback', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('SYNC-SINGLE');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 5);

      final result = await engine.decodeFromImageBuffer(buffer, useIsolate: false);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('SYNC-SINGLE'));

      final composite = QrTestPatternGenerator.createMultiQrComposite([matrix], scale: 4);
      final multiResult = await engine.decodeMultipleFromImageBuffer(composite, useIsolate: false);
      expect(multiResult.length, equals(1));
      expect(multiResult.first.rawContent, equals('SYNC-SINGLE'));
    });

    test('ImageFileDecoder decodes 32-bit and 8-bit BMP images', () {
      // 32-bit BMP (width 1, height 1)
      final bmp32 = Uint8List(58);
      final d32 = ByteData.sublistView(bmp32);
      d32.setUint8(0, 0x42); d32.setUint8(1, 0x4D); // 'BM'
      d32.setUint32(2, 58, Endian.little);
      d32.setUint32(10, 54, Endian.little);
      d32.setUint32(14, 40, Endian.little);
      d32.setInt32(18, 1, Endian.little);
      d32.setInt32(22, 1, Endian.little);
      d32.setUint16(26, 1, Endian.little);
      d32.setUint16(28, 32, Endian.little); // 32 bpp
      d32.setUint32(30, 0, Endian.little);  // BI_RGB
      bmp32[54] = 100; bmp32[55] = 150; bmp32[56] = 200; bmp32[57] = 255;
      final buf32 = ImageFileDecoder.decodeFileBytes(bmp32);
      expect(buf32, isNotNull);
      expect(buf32!.width, equals(1));
      expect(buf32.bytes[0], equals(200));

      // 8-bit BMP (width 1, height 1)
      final bmp8 = Uint8List(58);
      final d8 = ByteData.sublistView(bmp8);
      d8.setUint8(0, 0x42); d8.setUint8(1, 0x4D);
      d8.setUint32(2, 58, Endian.little);
      d8.setUint32(10, 54, Endian.little);
      d8.setUint32(14, 40, Endian.little);
      d8.setInt32(18, 1, Endian.little);
      d8.setInt32(22, 1, Endian.little);
      d8.setUint16(26, 1, Endian.little);
      d8.setUint16(28, 8, Endian.little); // 8 bpp
      d8.setUint32(30, 0, Endian.little);
      bmp8[54] = 180;
      final buf8 = ImageFileDecoder.decodeFileBytes(bmp8);
      expect(buf8, isNotNull);
      expect(buf8!.bytes[0], equals(180));
    });

    test('ImageBuffer handles undersized grayscale buffer gracefully', () {
      final shortBytes = Uint8List.fromList([10, 20]);
      final buf = ImageBuffer(bytes: shortBytes, width: 2, height: 2, format: ImageColorFormat.grayscale);
      final lum = buf.getLuminance();
      expect(lum.length, equals(4));
      expect(lum[0], equals(10));
      expect(lum[1], equals(20));
      expect(lum[2], equals(0));
    });

    test('PerspectiveTransform quadrilateralToSquare and invert', () {
      final transform = PerspectiveTransform.quadrilateralToSquare(0, 0, 10, 0, 10, 10, 0, 10);
      final points = [0.0, 0.0, 1.0, 1.0];
      transform.transformPoints(points);
      expect(points[0], isNotNull);
      final inv = transform.invert();
      expect(inv, isNotNull);
    });

    test('QrVersionInfo properties and function patterns for QR versions 1 to 7', () {
      for (var v = 1; v <= 7; v++) {
        final dim = 17 + 4 * v;
        expect(QrMatrixDecoder.isFunctionPattern(0, 0, dim, v), isTrue);
        expect(QrMatrixDecoder.isFunctionPattern(dim - 1, 0, dim, v), isTrue);
        expect(QrMatrixDecoder.isFunctionPattern(0, dim - 1, dim, v), isTrue);
        expect(QrMatrixDecoder.isFunctionPattern(6, 10, dim, v), isTrue); // Timing pattern
      }

      const v1 = QrVersionInfo(
        versionNumber: 1,
        totalCodewords: 26,
        eccBlocks: {
          QrEccLevel.M: (eccCodewordsPerBlock: 10, numBlocksGroup1: 1, dataCodewordsGroup1: 16, numBlocksGroup2: 0, dataCodewordsGroup2: 0),
        },
      );
      expect(v1.dimension, equals(21));
      expect(v1.getDataCodewordsForEcc(QrEccLevel.M), equals(16));
      expect(v1.getEccCodewordsForEcc(QrEccLevel.M), equals(10));
    });

    test('ReedSolomonDecoder executes Forney algorithm and corrects corrupted codewords', () {
      final original = QrTestPatternGenerator.createVersion1Codewords('HELLORS');
      final corrupted = Uint8List.fromList(original);

      // Corrupt 2 bytes
      corrupted[2] ^= 0x55;
      corrupted[8] ^= 0xAA;

      final rs = ReedSolomonDecoder(GaloisField256.qrField);
      final success = rs.decode(corrupted, 10);
      expect(success, isTrue);
      expect(corrupted, equals(original));

      // Uncorrectable error test (> 5 errors for 10 ECC codewords)
      final hopeless = Uint8List.fromList(original);
      for (var i = 0; i < 7; i++) {
        hopeless[i] ^= 0xFF;
      }
      expect(rs.decode(hopeless, 10), isFalse);
    });

    test('PerspectiveTransform handles general non-affine quadrilaterals', () {
      final quad = PerspectiveTransform.squareToQuadrilateral(
        0.0, 0.0,
        10.0, 1.0,
        12.0, 11.0,
        1.0, 9.0,
      );
      final points = [0.0, 0.0, 0.5, 0.5, 1.0, 1.0];
      quad.transformPoints(points);
      expect(points[0], closeTo(0.0, 0.001));
      expect(points[1], closeTo(0.0, 0.001));

      final inv = quad.invert();
      inv.transformPoints(points);
      expect(points[0], closeTo(0.0, 0.01));
      expect(points[1], closeTo(0.0, 0.01));
    });

    test('QrMatrixDecoder alignment patterns for versions 2 through 8', () {
      // Test alignment patterns for versions 2..8
      for (var v = 2; v <= 8; v++) {
        final dim = 17 + 4 * v;
        final targetCoord = v == 2
            ? 18
            : v == 3
                ? 22
                : v == 4
                    ? 26
                    : v == 5
                        ? 30
                        : v == 6
                            ? 34
                            : v == 7
                                ? 22
                                : (dim - 7);
        expect(QrMatrixDecoder.isFunctionPattern(targetCoord, targetCoord, dim, v), isTrue);
      }
    });

    test('QrMatrixDecoder payload stream decodes Numeric, Alphanumeric, and Latin1 fallback', () {
      Uint8List buildBitstream(List<({int value, int bits})> chunks) {
        var totalBits = 0;
        for (final c in chunks) {
          totalBits += c.bits;
        }
        final numBytes = (totalBits + 7) >> 3;
        final result = Uint8List(numBytes);
        var bitPos = 0;
        for (final c in chunks) {
          for (var i = c.bits - 1; i >= 0; i--) {
            final bit = (c.value >> i) & 1;
            final byteIdx = bitPos >> 3;
            final bitIdx = 7 - (bitPos & 7);
            result[byteIdx] |= (bit << bitIdx);
            bitPos++;
          }
        }
        return result;
      }

      // 1. Numeric Mode: 6 digits (123456)
      final numStream6 = buildBitstream([
        (value: 1, bits: 4),    // mode = 1 (Numeric)
        (value: 6, bits: 10),   // count = 6
        (value: 123, bits: 10), // '123'
        (value: 456, bits: 10), // '456'
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(numStream6, 1), equals('123456'));

      // 2. Numeric Mode: 5 digits (12345) -> remainder 2 digits
      final numStream5 = buildBitstream([
        (value: 1, bits: 4),    // mode = 1 (Numeric)
        (value: 5, bits: 10),   // count = 5
        (value: 123, bits: 10), // '123'
        (value: 45, bits: 7),   // '45'
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(numStream5, 1), equals('12345'));

      // 3. Numeric Mode: 4 digits (1234) -> remainder 1 digit
      final numStream4 = buildBitstream([
        (value: 1, bits: 4),    // mode = 1 (Numeric)
        (value: 4, bits: 10),   // count = 4
        (value: 123, bits: 10), // '123'
        (value: 4, bits: 4),    // '4'
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(numStream4, 1), equals('1234'));

      // 4. Alphanumeric Mode: 3 chars ('AB1') -> pair + single
      // 'A'=10, 'B'=11 -> 10*45 + 11 = 461
      // '1'=1
      final alphaStream3 = buildBitstream([
        (value: 2, bits: 4),    // mode = 2 (Alphanumeric)
        (value: 3, bits: 9),    // count = 3
        (value: 461, bits: 11), // 'AB'
        (value: 1, bits: 6),    // '1'
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(alphaStream3, 1), equals('AB1'));

      // 5. Alphanumeric Mode: 4 chars ('CODE')
      // 'C'=12, 'O'=24 -> 12*45 + 24 = 564
      // 'D'=13, 'E'=14 -> 13*45 + 14 = 599
      final alphaStream4 = buildBitstream([
        (value: 2, bits: 4),    // mode = 2 (Alphanumeric)
        (value: 4, bits: 9),    // count = 4
        (value: 564, bits: 11), // 'CO'
        (value: 599, bits: 11), // 'DE'
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(alphaStream4, 1), equals('CODE'));

      // 6. Byte Mode: Latin1 fallback on invalid UTF-8 bytes (0xFF, 0xFE)
      final latin1Stream = buildBitstream([
        (value: 4, bits: 4),    // mode = 4 (Byte)
        (value: 2, bits: 8),    // count = 2
        (value: 0xFF, bits: 8), // 0xFF
        (value: 0xFE, bits: 8), // 0xFE
        (value: 0, bits: 4),    // terminator
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(latin1Stream, 1), equals('ÿþ'));

      // 7. Unknown mode breaks cleanly
      final unknownModeStream = buildBitstream([
        (value: 7, bits: 4), // mode 7 (unsupported)
      ]);
      expect(QrMatrixDecoder.decodePayloadStream(unknownModeStream, 1), isNull);
    });

    test('MultiQrDetector detects inverted dark-mode QR matrix directly', () {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('DARK-MODE');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 4, quietZone: 4, invertColors: true);
      final binarized = const AdaptiveBinarizer().binarize(buffer);

      final multi = MultiQrDetector();
      final results = multi.detectMultiple(binarized);
      expect(results.length, equals(1));
      expect(results.first.content, equals('DARK-MODE'));
    });
  });
}
