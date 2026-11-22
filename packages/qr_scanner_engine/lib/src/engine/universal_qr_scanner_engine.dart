import 'dart:typed_data';
import 'package:qr_core/qr_core.dart';
import '../../qr_scanner_engine.dart';

/// High-performance universal QR decoding engine supporting multi-source inputs,
/// Dart background isolate offloading, multi-QR batch matrix vision, and Zero-Trust firewall inspection.
class UniversalQrScannerEngine implements QrScannerEngine {
  final ScannerOptions defaultOptions;
  final QrThreatFirewall _firewall;

  UniversalQrScannerEngine({
    this.defaultOptions = const ScannerOptions(),
    QrThreatFirewall? firewall,
  }) : _firewall = firewall ??
            QrThreatFirewall(
              trustedInstitutionalKeys: defaultOptions.trustedInstitutionalKeys ?? {},
            );

  @override
  Future<ScanDecodeResult> decodeFromRawString(String content, {ScannerOptions? options}) async {
    final opts = options ?? defaultOptions;
    final payloadType = QrPayloadParser.detectType(content);

    ThreatAssessment assessment;
    if (opts.enableThreatFirewall) {
      assessment = _firewall.inspectRaw(
        content,
        customTrustedKeys: opts.trustedInstitutionalKeys,
      );
    } else {
      assessment = const ThreatAssessment(
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        findings: [],
        isActionAllowed: true,
        summary: 'Firewall inspection bypassed by scanner configuration.',
      );
    }

    return ScanDecodeResult(
      rawContent: content,
      payloadType: payloadType,
      threatLevel: assessment.threatLevel,
      threatAssessment: assessment,
      confidence: 1.0,
      timestamp: DateTime.now(),
    );
  }

  /// Decodes a single QR code from a raw camera or screenshot pixel buffer.
  Future<ScanDecodeResult?> decodeFromImageBuffer(
    ImageBuffer buffer, {
    ScannerOptions? options,
    bool useIsolate = true,
  }) async {
    final rawText = useIsolate
        ? await IsolateQrDecoder.decodeSingle(buffer)
        : IsolateQrDecoder.decodeSynchronous(buffer);

    if (rawText == null || rawText.isEmpty) {
      return null;
    }

    return decodeFromRawString(rawText, options: options);
  }

  /// Detects and decodes multiple QR codes from a single composite image or document.
  Future<List<ScanDecodeResult>> decodeMultipleFromImageBuffer(
    ImageBuffer buffer, {
    ScannerOptions? options,
    bool useIsolate = true,
  }) async {
    final rawTexts = useIsolate
        ? await IsolateQrDecoder.decodeMultiple(buffer)
        : IsolateQrDecoder.decodeMultipleSynchronous(buffer);

    final results = <ScanDecodeResult>[];
    for (final text in rawTexts) {
      results.add(await decodeFromRawString(text, options: options));
    }
    return results;
  }

  /// Decodes a QR code from raw file bytes (BMP or supported image formats).
  Future<ScanDecodeResult?> decodeFromFileBytes(
    Uint8List fileBytes, {
    ScannerOptions? options,
    bool useIsolate = true,
  }) async {
    final buffer = ImageFileDecoder.decodeFileBytes(fileBytes);
    if (buffer == null) return null;
    return decodeFromImageBuffer(buffer, options: options, useIsolate: useIsolate);
  }

  /// Decodes a batch of image buffers concurrently.
  Future<List<ScanDecodeResult>> decodeBatchImages(
    List<ImageBuffer> buffers, {
    ScannerOptions? options,
    bool useIsolates = true,
  }) async {
    final futures = buffers.map(
      (b) => decodeFromImageBuffer(b, options: options, useIsolate: useIsolates),
    );
    final results = await Future.wait(futures);
    return results.whereType<ScanDecodeResult>().toList();
  }

  /// Decodes a batch of image file bytes concurrently.
  Future<List<ScanDecodeResult>> decodeBatchFiles(
    List<Uint8List> fileBytesList, {
    ScannerOptions? options,
    bool useIsolates = true,
  }) async {
    final futures = fileBytesList.map(
      (f) => decodeFromFileBytes(f, options: options, useIsolate: useIsolates),
    );
    final results = await Future.wait(futures);
    return results.whereType<ScanDecodeResult>().toList();
  }
}
