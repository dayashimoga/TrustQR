import 'dart:isolate';
import 'dart:typed_data';
import '../decoder/qr_matrix_decoder.dart';
import '../detector/multi_qr_detector.dart';
import '../detector/qr_detector.dart';
import '../image/image_buffer.dart';

/// Request payload sent to background isolate for QR decoding.
class _IsolateDecodeRequest {
  final Uint8List bytes;
  final int width;
  final int height;
  final int formatIndex;
  final bool multiQr;

  const _IsolateDecodeRequest({
    required this.bytes,
    required this.width,
    required this.height,
    required this.formatIndex,
    required this.multiQr,
  });
}

/// Offloads compute-intensive binarization, perspective grid sampling, and Reed-Solomon decoding
/// to background Dart isolates, keeping the Flutter UI thread at 60/120 FPS.
class IsolateQrDecoder {
  /// Decodes a single QR code in a background isolate.
  static Future<String?> decodeSingle(ImageBuffer buffer) async {
    try {
      final request = _IsolateDecodeRequest(
        bytes: buffer.bytes,
        width: buffer.width,
        height: buffer.height,
        formatIndex: buffer.format.index,
        multiQr: false,
      );

      final results = await Isolate.run(() => _decodeInIsolate(request));
      return results.isNotEmpty ? results.first : null;
    } catch (_) {
      // Fallback to synchronous in-thread decoding if isolate spawn fails
      return decodeSynchronous(buffer);
    }
  }

  /// Decodes multiple QR codes from a single image in a background isolate.
  static Future<List<String>> decodeMultiple(ImageBuffer buffer) async {
    try {
      final request = _IsolateDecodeRequest(
        bytes: buffer.bytes,
        width: buffer.width,
        height: buffer.height,
        formatIndex: buffer.format.index,
        multiQr: true,
      );

      return await Isolate.run(() => _decodeInIsolate(request));
    } catch (_) {
      return decodeMultipleSynchronous(buffer);
    }
  }

  /// Entry point executed inside the spawned Dart isolate.
  static List<String> _decodeInIsolate(_IsolateDecodeRequest req) {
    final buffer = ImageBuffer(
      bytes: req.bytes,
      width: req.width,
      height: req.height,
      format: ImageColorFormat.values[req.formatIndex],
    );

    if (req.multiQr) {
      return decodeMultipleSynchronous(buffer);
    } else {
      final result = decodeSynchronous(buffer);
      return result != null ? [result] : const [];
    }
  }

  /// Decodes a single QR code synchronously on the current thread.
  static String? decodeSynchronous(ImageBuffer buffer) {
    final binarizer = const AdaptiveBinarizer();
    final matrix = binarizer.binarize(buffer);

    final detector = QrDetector();
    final decoder = QrMatrixDecoder();

    var patterns = detector.findFinderPatterns(matrix);
    var effectiveMatrix = matrix;

    if (patterns.length < 3) {
      final inverted = matrix.inverted();
      final invertedPatterns = detector.findFinderPatterns(inverted);
      if (invertedPatterns.length >= 3) {
        patterns = invertedPatterns;
        effectiveMatrix = inverted;
      }
    }

    final triplet = detector.orderBestFinderPatterns(patterns);
    if (triplet != null) {
      final dimension = detector.computeDimension(triplet);
      if (dimension >= 21) {
        final sampled = detector.sampleGrid(effectiveMatrix, triplet, dimension);
        var content = decoder.decode(sampled);
        if (content != null) return content;

        // Try inverted sampled matrix
        content = decoder.decode(sampled.inverted());
        if (content != null) return content;
      }
    }

    // Try multi-QR detector as fallback
    final multi = MultiQrDetector(detector: detector, matrixDecoder: decoder);
    final detected = multi.detectMultiple(effectiveMatrix);
    return detected.isNotEmpty ? detected.first.content : null;
  }

  /// Decodes multiple QR codes synchronously on the current thread.
  static List<String> decodeMultipleSynchronous(ImageBuffer buffer) {
    final binarizer = const AdaptiveBinarizer();
    final matrix = binarizer.binarize(buffer);

    final multi = MultiQrDetector();
    var detected = multi.detectMultiple(matrix);
    if (detected.isEmpty) {
      detected = multi.detectMultiple(matrix.inverted());
    }
    return detected.map((e) => e.content).toList();
  }
}
