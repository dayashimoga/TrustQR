/// Universal QR decoding and threat inspection engine.
library qr_scanner_engine;

import 'package:qr_core/qr_core.dart';

/// Configuration options for scanning pipelines.
class ScannerOptions {
  final bool enableThreatFirewall;
  final bool enableBatchDetection;
  final bool autoCopyResult;

  const ScannerOptions({
    this.enableThreatFirewall = true,
    this.enableBatchDetection = false,
    this.autoCopyResult = false,
  });
}

/// Result of a QR decoding operation.
class ScanDecodeResult {
  final String rawContent;
  final QrPayloadType payloadType;
  final SecurityThreatLevel threatLevel;
  final double confidence;
  final DateTime timestamp;

  const ScanDecodeResult({
    required this.rawContent,
    required this.payloadType,
    required this.threatLevel,
    this.confidence = 1.0,
    required this.timestamp,
  });
}

/// Abstract contract for QR scanner implementations.
abstract class QrScannerEngine {
  Future<ScanDecodeResult> decodeFromRawString(String content, {ScannerOptions? options});
}

/// Default implementation of [QrScannerEngine].
class DefaultQrScannerEngine implements QrScannerEngine {
  final ScannerOptions defaultOptions;

  const DefaultQrScannerEngine({this.defaultOptions = const ScannerOptions()});

  @override
  Future<ScanDecodeResult> decodeFromRawString(String content, {ScannerOptions? options}) async {
    final opts = options ?? defaultOptions;
    final payloadType = _detectPayloadType(content);
    final threatLevel = opts.enableThreatFirewall
        ? _inspectThreat(content, payloadType)
        : SecurityThreatLevel.safe;

    return ScanDecodeResult(
      rawContent: content,
      payloadType: payloadType,
      threatLevel: threatLevel,
      confidence: 1.0,
      timestamp: DateTime.now(),
    );
  }

  QrPayloadType _detectPayloadType(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return QrPayloadType.url;
    if (lower.startsWith('wifi:')) return QrPayloadType.wifi;
    if (lower.startsWith('begin:vcard')) return QrPayloadType.vcard;
    if (lower.startsWith('mecard:')) return QrPayloadType.mecard;
    if (lower.startsWith('geo:')) return QrPayloadType.geo;
    if (lower.startsWith('begin:vevent')) return QrPayloadType.event;
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) return QrPayloadType.email;
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) return QrPayloadType.sms;
    if (lower.startsWith('tel:')) return QrPayloadType.tel;
    if (lower.startsWith('otpauth://')) return QrPayloadType.otpauth;
    if (lower.startsWith('upi://')) return QrPayloadType.upi;
    if (lower.startsWith('bitcoin:') || lower.startsWith('ethereum:')) return QrPayloadType.crypto;
    return QrPayloadType.plainText;
  }

  SecurityThreatLevel _inspectThreat(String raw, QrPayloadType type) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('javascript:') || lower.contains('data:text/html') || lower.contains('vbscript:')) {
      return SecurityThreatLevel.critical;
    }
    if (lower.startsWith('http://')) {
      return SecurityThreatLevel.caution;
    }
    return SecurityThreatLevel.safe;
  }
}
