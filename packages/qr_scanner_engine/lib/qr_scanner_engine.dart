/// Universal QR decoding and threat inspection engine.
library qr_scanner_engine;

import 'package:qr_core/qr_core.dart';
import 'src/engine/universal_qr_scanner_engine.dart';
import 'src/security/threat_assessment.dart';

export 'src/security/threat_assessment.dart';
export 'src/security/qr_threat_firewall.dart';
export 'src/image/image_buffer.dart';
export 'src/image/image_file_decoder.dart';
export 'src/decoder/galois_field.dart';
export 'src/decoder/qr_format_info.dart';
export 'src/decoder/qr_matrix_decoder.dart';
export 'src/detector/finder_pattern.dart';
export 'src/detector/qr_detector.dart';
export 'src/detector/multi_qr_detector.dart';
export 'src/isolate/isolate_qr_decoder.dart';
export 'src/engine/universal_qr_scanner_engine.dart';
export 'src/pipeline/pipeline_options.dart';
export 'src/pipeline/pipeline_scan_result.dart';
export 'src/pipeline/scan_to_vault_pipeline.dart';

/// Configuration options for scanning pipelines.
class ScannerOptions {
  final bool enableThreatFirewall;
  final bool enableBatchDetection;
  final bool autoCopyResult;
  final Map<String, CryptoPublicKey>? trustedInstitutionalKeys;

  const ScannerOptions({
    this.enableThreatFirewall = true,
    this.enableBatchDetection = false,
    this.autoCopyResult = false,
    this.trustedInstitutionalKeys,
  });
}

/// Result of a QR decoding operation.
class ScanDecodeResult {
  final String rawContent;
  final QrPayloadType payloadType;
  final SecurityThreatLevel threatLevel;
  final ThreatAssessment threatAssessment;
  final double confidence;
  final DateTime timestamp;

  const ScanDecodeResult({
    required this.rawContent,
    required this.payloadType,
    required this.threatLevel,
    required this.threatAssessment,
    this.confidence = 1.0,
    required this.timestamp,
  });
}

/// Abstract contract for QR scanner implementations.
abstract class QrScannerEngine {
  Future<ScanDecodeResult> decodeFromRawString(String content, {ScannerOptions? options});
}

/// Default implementation of [QrScannerEngine] backed by [UniversalQrScannerEngine].
class DefaultQrScannerEngine extends UniversalQrScannerEngine {
  DefaultQrScannerEngine({
    super.defaultOptions,
    super.firewall,
  });
}
