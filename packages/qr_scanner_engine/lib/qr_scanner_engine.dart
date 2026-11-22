/// Universal QR decoding and threat inspection engine.
library qr_scanner_engine;

import 'package:qr_core/qr_core.dart';
import 'src/security/threat_assessment.dart';
import 'src/security/qr_threat_firewall.dart';

export 'src/security/threat_assessment.dart';
export 'src/security/qr_threat_firewall.dart';

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

/// Default implementation of [QrScannerEngine] backed by [QrThreatFirewall].
class DefaultQrScannerEngine implements QrScannerEngine {
  final ScannerOptions defaultOptions;
  final QrThreatFirewall _firewall;

  DefaultQrScannerEngine({
    this.defaultOptions = const ScannerOptions(),
    QrThreatFirewall? firewall,
  }) : _firewall = firewall ?? QrThreatFirewall(trustedInstitutionalKeys: defaultOptions.trustedInstitutionalKeys ?? {});

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
}
