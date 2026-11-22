import 'dart:typed_data';

/// Pixel color format of an incoming raw image buffer.
enum ImageColorFormat {
  rgba8888,
  bgra8888,
  rgb888,
  grayscale,
}

/// Raw image buffer container for camera frames, screenshots, and decoded image files.
class ImageBuffer {
  final Uint8List bytes;
  final int width;
  final int height;
  final ImageColorFormat format;

  const ImageBuffer({
    required this.bytes,
    required this.width,
    required this.height,
    this.format = ImageColorFormat.rgba8888,
  });

  /// Total number of pixels.
  int get pixelCount => width * height;

  /// Extracts 8-bit grayscale luminance array ($Y = 0.299R + 0.587G + 0.114B$).
  Uint8List getLuminance() {
    if (format == ImageColorFormat.grayscale) {
      if (bytes.length >= pixelCount) {
        return bytes.sublist(0, pixelCount);
      }
      final out = Uint8List(pixelCount);
      out.setRange(0, bytes.length, bytes);
      return out;
    }

    final luminance = Uint8List(pixelCount);
    final stride = format == ImageColorFormat.rgb888 ? 3 : 4;
    final isBgra = format == ImageColorFormat.bgra8888;

    for (var i = 0, p = 0; p < pixelCount && (i + stride - 1) < bytes.length; p++, i += stride) {
      final r = isBgra ? bytes[i + 2] : bytes[i];
      final g = bytes[i + 1];
      final b = isBgra ? bytes[i] : bytes[i + 2];
      // Fast integer luminance: (r * 77 + g * 150 + b * 29) >> 8
      luminance[p] = ((r * 77 + g * 150 + b * 29) >> 8) & 0xFF;
    }

    return luminance;
  }

  /// Crops a sub-region of the image buffer.
  ImageBuffer crop(int left, int top, int cropWidth, int cropHeight) {
    final safeLeft = left.clamp(0, width - 1);
    final safeTop = top.clamp(0, height - 1);
    final safeWidth = cropWidth.clamp(1, width - safeLeft);
    final safeHeight = cropHeight.clamp(1, height - safeTop);

    final stride = format == ImageColorFormat.grayscale
        ? 1
        : format == ImageColorFormat.rgb888
            ? 3
            : 4;

    final croppedBytes = Uint8List(safeWidth * safeHeight * stride);
    for (var y = 0; y < safeHeight; y++) {
      final srcOffset = ((safeTop + y) * width + safeLeft) * stride;
      final dstOffset = y * safeWidth * stride;
      final length = safeWidth * stride;
      croppedBytes.setRange(dstOffset, dstOffset + length, bytes.sublist(srcOffset, srcOffset + length));
    }

    return ImageBuffer(
      bytes: croppedBytes,
      width: safeWidth,
      height: safeHeight,
      format: format,
    );
  }

  /// Rotates the image 90 degrees clockwise.
  ImageBuffer rotate90() {
    final stride = format == ImageColorFormat.grayscale
        ? 1
        : format == ImageColorFormat.rgb888
            ? 3
            : 4;
    final newWidth = height;
    final newHeight = width;
    final rotated = Uint8List(newWidth * newHeight * stride);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final srcIdx = (y * width + x) * stride;
        final dstIdx = (x * newWidth + (newWidth - 1 - y)) * stride;
        for (var b = 0; b < stride; b++) {
          rotated[dstIdx + b] = bytes[srcIdx + b];
        }
      }
    }

    return ImageBuffer(
      bytes: rotated,
      width: newWidth,
      height: newHeight,
      format: format,
    );
  }
}

/// 2D binary bit matrix resulting from thresholding and binarization.
class BinarizedBitMatrix {
  final int width;
  final int height;
  final Uint8List _bits;

  BinarizedBitMatrix(this.width, this.height) : _bits = Uint8List((width * height + 7) >> 3);

  BinarizedBitMatrix.fromBits(this.width, this.height, Uint8List bits) : _bits = bits;

  /// Returns true if module at (x, y) is black/set.
  bool get(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    final index = y * width + x;
    return (_bits[index >> 3] & (1 << (index & 7))) != 0;
  }

  /// Sets bit at (x, y) to value (true = black, false = white).
  void set(int x, int y, bool value) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final index = y * width + x;
    final byteIdx = index >> 3;
    final bitMask = 1 << (index & 7);
    if (value) {
      _bits[byteIdx] |= bitMask;
    } else {
      _bits[byteIdx] &= ~bitMask;
    }
  }

  /// Inverts the bit matrix (useful for reading white-on-black inverted QR codes).
  BinarizedBitMatrix inverted() {
    final invertedBits = Uint8List(_bits.length);
    for (var i = 0; i < _bits.length; i++) {
      invertedBits[i] = ~_bits[i] & 0xFF;
    }
    return BinarizedBitMatrix.fromBits(width, height, invertedBits);
  }
}

/// Adaptive local-block thresholding binarizer.
///
/// Divides image into 8x8 blocks, calculates local threshold per block, and
/// interpolates boundaries to accurately segment QR modules under uneven lighting.
class AdaptiveBinarizer {
  final int blockSize;

  const AdaptiveBinarizer({this.blockSize = 8});

  BinarizedBitMatrix binarize(ImageBuffer buffer) {
    final luminance = buffer.getLuminance();
    final width = buffer.width;
    final height = buffer.height;
    final matrix = BinarizedBitMatrix(width, height);

    final subWidth = (width + blockSize - 1) ~/ blockSize;
    final subHeight = (height + blockSize - 1) ~/ blockSize;
    final blockThresholds = List<int>.filled(subWidth * subHeight, 0);

    // Step 1: Compute average luminance per block
    for (var by = 0; by < subHeight; by++) {
      for (var bx = 0; bx < subWidth; bx++) {
        var sum = 0;
        var count = 0;
        final startY = by * blockSize;
        final endY = (startY + blockSize).clamp(0, height);
        final startX = bx * blockSize;
        final endX = (startX + blockSize).clamp(0, width);

        for (var y = startY; y < endY; y++) {
          final rowOffset = y * width;
          for (var x = startX; x < endX; x++) {
            sum += luminance[rowOffset + x];
            count++;
          }
        }
        blockThresholds[by * subWidth + bx] = count > 0 ? (sum ~/ count) : 128;
      }
    }

    // Step 2: Threshold each pixel using neighbor-averaged block threshold
    for (var y = 0; y < height; y++) {
      final by = (y ~/ blockSize).clamp(0, subHeight - 1);
      final rowOffset = y * width;

      for (var x = 0; x < width; x++) {
        final bx = (x ~/ blockSize).clamp(0, subWidth - 1);

        // Average 3x3 surrounding block thresholds
        var threshSum = 0;
        var threshCount = 0;
        for (var dy = -1; dy <= 1; dy++) {
          final ny = by + dy;
          if (ny < 0 || ny >= subHeight) continue;
          final nOffset = ny * subWidth;
          for (var dx = -1; dx <= 1; dx++) {
            final nx = bx + dx;
            if (nx < 0 || nx >= subWidth) continue;
            threshSum += blockThresholds[nOffset + nx];
            threshCount++;
          }
        }

        var threshold = threshCount > 0 ? (threshSum ~/ threshCount) : 128;
        if (threshold < 85) threshold = 85;
        final pixelLum = luminance[rowOffset + x];
        // In QR code, black module = true (pixel is darker than threshold)
        matrix.set(x, y, pixelLum < threshold);
      }
    }

    return matrix;
  }
}
