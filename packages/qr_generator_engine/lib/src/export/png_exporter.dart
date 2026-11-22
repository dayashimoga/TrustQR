import 'dart:io';
import 'dart:typed_data';
import '../rasterizer/qr_generated_image.dart';
import 'crc32.dart';

/// Pure-Dart high-DPI PNG image exporter.
///
/// Produces ISO/IEC 15948 compliant PNG files with custom DPI (pHYs chunk)
/// and zlib deflated scanlines (IDAT).
class PngExporter {
  const PngExporter();

  /// Standard 8-byte PNG file signature.
  static const List<int> pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Exports [image] to PNG format with the specified [dpi].
  Uint8List export(QrGeneratedImage image, {int dpi = 300}) {
    final builder = BytesBuilder(copy: false);

    // 1. Signature
    builder.add(pngSignature);

    // 2. IHDR Chunk (13 bytes)
    final ihdrData = Uint8List(13);
    final ihdrView = ByteData.view(ihdrData.buffer);
    ihdrView.setUint32(0, image.width, Endian.big);
    ihdrView.setUint32(4, image.height, Endian.big);
    ihdrData[8] = 8; // Bit depth: 8 bits per channel
    ihdrData[9] = 6; // Color type: 6 (RGBA)
    ihdrData[10] = 0; // Compression method: 0 (deflate)
    ihdrData[11] = 0; // Filter method: 0 (standard)
    ihdrData[12] = 0; // Interlace: 0 (no interlace)
    _writeChunk(builder, 'IHDR', ihdrData);

    // 3. pHYs Chunk (Physical pixel dimensions / DPI)
    // 1 inch = 0.0254 meters => pixels/meter = dpi / 0.0254 = dpi * 39.37007874
    final physData = Uint8List(9);
    final physView = ByteData.view(physData.buffer);
    final ppm = (dpi * 39.37007874).round();
    physView.setUint32(0, ppm, Endian.big);
    physView.setUint32(4, ppm, Endian.big);
    physData[8] = 1; // Unit: meter
    _writeChunk(builder, 'pHYs', physData);

    // 4. IDAT Chunk (Filtered scanlines + zlib deflate)
    final scanlineStride = 1 + image.width * 4;
    final uncompressed = Uint8List(image.height * scanlineStride);
    var destOffset = 0;
    var srcOffset = 0;

    for (var y = 0; y < image.height; y++) {
      uncompressed[destOffset++] = 0; // Filter type 0 (None)
      final rowBytes = image.width * 4;
      uncompressed.setRange(destOffset, destOffset + rowBytes, image.rgbaBytes, srcOffset);
      destOffset += rowBytes;
      srcOffset += rowBytes;
    }

    final compressed = zlib.encode(uncompressed);
    _writeChunk(builder, 'IDAT', Uint8List.fromList(compressed));

    // 5. IEND Chunk (0 bytes data)
    _writeChunk(builder, 'IEND', Uint8List(0));

    return builder.takeBytes();
  }

  void _writeChunk(BytesBuilder builder, String type, Uint8List data) {
    final typeBytes = Uint8List.fromList(type.codeUnits);
    final chunkHeader = Uint8List(4);
    ByteData.view(chunkHeader.buffer).setUint32(0, data.length, Endian.big);
    builder.add(chunkHeader);

    // Compute CRC over Type + Data
    final crcPayload = Uint8List(4 + data.length);
    crcPayload.setRange(0, 4, typeBytes);
    crcPayload.setRange(4, 4 + data.length, data);
    final crc = Crc32.compute(crcPayload);

    builder.add(typeBytes);
    builder.add(data);

    final crcHeader = Uint8List(4);
    ByteData.view(crcHeader.buffer).setUint32(0, crc, Endian.big);
    builder.add(crcHeader);
  }
}
