import 'dart:typed_data';

/// Rendered raster image representing a generated and styled QR code.
class QrGeneratedImage {
  final int width;
  final int height;
  final Uint8List rgbaBytes;

  QrGeneratedImage({
    required this.width,
    required this.height,
    Uint8List? bytes,
  }) : rgbaBytes = bytes ?? Uint8List(width * height * 4);

  /// Total number of pixels in image.
  int get pixelCount => width * height;

  /// Gets 32-bit ARGB color at pixel (x, y).
  int getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0;
    final idx = (y * width + x) * 4;
    final r = rgbaBytes[idx];
    final g = rgbaBytes[idx + 1];
    final b = rgbaBytes[idx + 2];
    final a = rgbaBytes[idx + 3];
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Sets 32-bit ARGB color at pixel (x, y).
  void setPixel(int x, int y, int argb) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final idx = (y * width + x) * 4;
    rgbaBytes[idx] = (argb >> 16) & 0xFF; // R
    rgbaBytes[idx + 1] = (argb >> 8) & 0xFF; // G
    rgbaBytes[idx + 2] = argb & 0xFF; // B
    rgbaBytes[idx + 3] = (argb >> 24) & 0xFF; // A
  }

  /// Fills a solid rectangle with an ARGB color.
  void fillRect(int x0, int y0, int w, int h, int argb) {
    final xEnd = (x0 + w).clamp(0, width);
    final yEnd = (y0 + h).clamp(0, height);
    final startX = x0.clamp(0, width);
    final startY = y0.clamp(0, height);

    for (var y = startY; y < yEnd; y++) {
      for (var x = startX; x < xEnd; x++) {
        setPixel(x, y, argb);
      }
    }
  }

  /// Exports image as pure-Dart uncompressed 24-bit BMP binary byte stream.
  Uint8List toBmp() {
    // 24-bit BMP: 3 bytes per pixel (BGR order), rows padded to 4-byte boundary
    final rowStride = ((width * 3 + 3) ~/ 4) * 4;
    final imageSize = rowStride * height;
    const headerSize = 14 + 40; // FileHeader + InfoHeader
    final fileSize = headerSize + imageSize;

    final bytes = Uint8List(fileSize);
    final data = ByteData.view(bytes.buffer);

    // 1. BITMAPFILEHEADER (14 bytes)
    bytes[0] = 0x42; // 'B'
    bytes[1] = 0x4D; // 'M'
    data.setUint32(2, fileSize, Endian.little);
    data.setUint16(6, 0, Endian.little); // Reserved 1
    data.setUint16(8, 0, Endian.little); // Reserved 2
    data.setUint32(10, headerSize, Endian.little); // Pixel data offset

    // 2. BITMAPINFOHEADER (40 bytes)
    data.setUint32(14, 40, Endian.little); // DIB header size
    data.setInt32(18, width, Endian.little);
    data.setInt32(22, height, Endian.little); // Positive = bottom-up
    data.setUint16(26, 1, Endian.little); // Planes = 1
    data.setUint16(28, 24, Endian.little); // Bits per pixel = 24
    data.setUint32(30, 0, Endian.little); // BI_RGB (uncompressed)
    data.setUint32(34, imageSize, Endian.little);
    data.setInt32(38, 2835, Endian.little); // ~72 DPI horizontal (pixels/meter)
    data.setInt32(42, 2835, Endian.little); // ~72 DPI vertical
    data.setUint32(46, 0, Endian.little); // Colors in color table
    data.setUint32(50, 0, Endian.little); // Important color count

    // 3. Pixel data in bottom-up row order
    var offset = headerSize;
    for (var y = height - 1; y >= 0; y--) {
      for (var x = 0; x < width; x++) {
        final argb = getPixel(x, y);
        bytes[offset++] = argb & 0xFF; // Blue
        bytes[offset++] = (argb >> 8) & 0xFF; // Green
        bytes[offset++] = (argb >> 16) & 0xFF; // Red
      }
      // Row padding to 4-byte multiple
      final pad = rowStride - (width * 3);
      for (var p = 0; p < pad; p++) {
        bytes[offset++] = 0;
      }
    }

    return bytes;
  }
}
