import 'dart:async';
import 'dart:typed_data';
import 'package:qr_core/qr_core.dart';
import '../../qr_scanner_engine.dart';

/// End-to-end integration coordinator orchestrating QR decoding, Zero-Trust threat
/// inspection, auto-categorization, deduplication, and encrypted offline vault recording.
class ScanToVaultPipeline {
  final UniversalQrScannerEngine scanner;
  final QrThreatFirewall firewall;
  final QrVault? vault;
  final PipelineOptions defaultOptions;

  ScanToVaultPipeline({
    UniversalQrScannerEngine? scanner,
    QrThreatFirewall? firewall,
    this.vault,
    this.defaultOptions = const PipelineOptions(),
  })  : scanner = scanner ?? UniversalQrScannerEngine(),
        firewall = firewall ?? QrThreatFirewall();

  /// Processes a raw string payload through the entire security and vault pipeline.
  Future<PipelineScanResult> processRawString(
    String rawContent, {
    PipelineOptions? options,
    String? title,
    String? notes,
  }) async {
    final opts = options ?? defaultOptions;
    final stopwatch = Stopwatch()..start();
    return _executePipeline(rawContent, opts, stopwatch, title: title, notes: notes);
  }

  /// Decodes and processes a single image buffer (camera preview frame or screenshot).
  Future<PipelineScanResult?> processImageBuffer(
    ImageBuffer buffer, {
    PipelineOptions? options,
    String? title,
    String? notes,
  }) async {
    final opts = options ?? defaultOptions;
    final stopwatch = Stopwatch()..start();

    final decoded = await scanner.decodeFromImageBuffer(
      buffer,
      options: ScannerOptions(
        enableThreatFirewall: false, // We run firewall inspection in the unified pipeline stage
        trustedInstitutionalKeys: opts.trustedInstitutionalKeys,
      ),
      useIsolate: opts.useIsolate,
    );

    if (decoded == null) return null;
    return _executePipeline(decoded.rawContent, opts, stopwatch, title: title, notes: notes);
  }

  /// Decodes and processes raw image file bytes (e.g. BMP).
  Future<PipelineScanResult?> processFileBytes(
    Uint8List fileBytes, {
    PipelineOptions? options,
    String? title,
    String? notes,
  }) async {
    final opts = options ?? defaultOptions;
    final stopwatch = Stopwatch()..start();

    final decoded = await scanner.decodeFromFileBytes(
      fileBytes,
      options: ScannerOptions(
        enableThreatFirewall: false,
        trustedInstitutionalKeys: opts.trustedInstitutionalKeys,
      ),
      useIsolate: opts.useIsolate,
    );

    if (decoded == null) return null;
    return _executePipeline(decoded.rawContent, opts, stopwatch, title: title, notes: notes);
  }

  /// Detects and processes all QR codes present within a composite multi-QR image.
  Future<List<PipelineScanResult>> processMultiQrImage(
    ImageBuffer buffer, {
    PipelineOptions? options,
  }) async {
    final opts = options ?? defaultOptions;
    final decodedList = await scanner.decodeMultipleFromImageBuffer(
      buffer,
      options: ScannerOptions(
        enableThreatFirewall: false,
        trustedInstitutionalKeys: opts.trustedInstitutionalKeys,
      ),
      useIsolate: opts.useIsolate,
    );

    final results = <PipelineScanResult>[];
    for (final item in decodedList) {
      final stopwatch = Stopwatch()..start();
      final res = await _executePipeline(item.rawContent, opts, stopwatch);
      results.add(res);
    }
    return results;
  }

  /// Processes a batch of image buffers, emitting a stream of pipeline results as they complete.
  Stream<PipelineScanResult> processBatchImagesStream(
    List<ImageBuffer> buffers, {
    PipelineOptions? options,
  }) async* {
    final opts = options ?? defaultOptions;
    for (final buffer in buffers) {
      final result = await processImageBuffer(buffer, options: opts);
      if (result != null) {
        yield result;
      }
    }
  }

  /// Processes a batch of image files, emitting a stream of pipeline results as they complete.
  Stream<PipelineScanResult> processBatchFilesStream(
    List<Uint8List> fileBytesList, {
    PipelineOptions? options,
  }) async* {
    final opts = options ?? defaultOptions;
    for (final bytes in fileBytesList) {
      final result = await processFileBytes(bytes, options: opts);
      if (result != null) {
        yield result;
      }
    }
  }

  /// Concurrently processes a batch of image buffers and returns the list of valid results.
  Future<List<PipelineScanResult>> processBatchImages(
    List<ImageBuffer> buffers, {
    PipelineOptions? options,
  }) async {
    final opts = options ?? defaultOptions;
    final futures = buffers.map((b) => processImageBuffer(b, options: opts));
    final results = await Future.wait(futures);
    return results.whereType<PipelineScanResult>().toList();
  }

  /// Concurrently processes a batch of image files and returns the list of valid results.
  Future<List<PipelineScanResult>> processBatchFiles(
    List<Uint8List> fileBytesList, {
    PipelineOptions? options,
  }) async {
    final opts = options ?? defaultOptions;
    final futures = fileBytesList.map((f) => processFileBytes(f, options: opts));
    final results = await Future.wait(futures);
    return results.whereType<PipelineScanResult>().toList();
  }

  /// Internal pipeline execution logic connecting parser -> firewall -> vault.
  Future<PipelineScanResult> _executePipeline(
    String rawContent,
    PipelineOptions opts,
    Stopwatch stopwatch, {
    String? title,
    String? notes,
  }) async {
    // 1. TrustQR metadata detection and inner payload unwrapping
    final trustQrEnvelope = TrustQrEnvelope.tryParse(rawContent);
    final isTrustQr = trustQrEnvelope != null;
    final trustQrIssuer = trustQrEnvelope?.issuer;

    // 2. Structured payload parsing across all 15 formats (unwraps TrustQR inner payload if present)
    final effectiveContent = trustQrEnvelope?.payload ?? rawContent;
    final payload = QrPayloadParser.parse(effectiveContent);

    // 3. Zero-Trust security threat firewall inspection
    ThreatAssessment assessment;
    if (opts.enableThreatFirewall) {
      assessment = firewall.inspectRaw(
        rawContent,
        customTrustedKeys: opts.trustedInstitutionalKeys,
      );
    } else {
      assessment = const ThreatAssessment(
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        findings: [],
        isActionAllowed: true,
        summary: 'Security firewall inspection disabled by pipeline options.',
      );
    }

    // 4. Offline vault deduplication and recording
    QrVaultItem? vaultItem;
    var isDeduplicated = false;

    if (opts.saveToVault && vault != null) {
      // Deduplication check
      if (opts.autoDeduplicate) {
        final recentItems = await vault!.query(
          const QrVaultFilter(
            origin: QrItemOrigin.scanned,
          ),
        );

        final now = DateTime.now().toUtc();
        final duplicate = recentItems.where((i) {
          if (i.rawContent != rawContent) return false;
          final age = now.difference(i.createdAt.toUtc());
          return age <= opts.deduplicationWindow;
        }).firstOrNull;

        if (duplicate != null) {
          isDeduplicated = true;
          vaultItem = duplicate;
        }
      }

      // Record to vault if not deduplicated and not blocked by quarantine
      if (!isDeduplicated) {
        final isCriticalBlocked =
            opts.blockVaultOnCriticalThreat && assessment.threatLevel == SecurityThreatLevel.critical;

        if (!isCriticalBlocked) {
          final tags = <String>{...opts.defaultTags};
          if (opts.autoCategorize) {
            tags.addAll(_computeSmartTags(payload, assessment, isTrustQr, rawContent));
          }

          final computedTitle = title ?? _computeDefaultTitle(payload, rawContent, trustQrEnvelope);

          vaultItem = await vault!.recordItem(
            rawContent: rawContent,
            payloadType: payload.type,
            threatLevel: assessment.threatLevel,
            safetyScore: assessment.safetyScore,
            origin: QrItemOrigin.scanned,
            title: computedTitle,
            notes: notes,
            collectionId: opts.targetCollectionId,
            tags: tags.toList()..sort(),
            isTrustQr: isTrustQr,
            trustQrIssuer: trustQrIssuer,
          );

          if (opts.purgeOnScan) {
            await vault!.purgeHistory();
          }
        }
      }
    }

    stopwatch.stop();
    final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;

    return PipelineScanResult(
      rawContent: rawContent,
      payload: payload,
      threatAssessment: assessment,
      vaultItem: vaultItem,
      isDeduplicated: isDeduplicated,
      latencyMs: latencyMs,
      timestamp: DateTime.now(),
    );
  }

  /// Automatically computes smart classification tags based on payload content and security findings.
  List<String> _computeSmartTags(
    QrPayload payload,
    ThreatAssessment assessment,
    bool isTrustQr,
    String rawContent,
  ) {
    final tags = <String>[];

    // Payload type tags
    switch (payload.type) {
      case QrPayloadType.url:
        tags.add('#url');
        if (rawContent.toLowerCase().startsWith('https://')) {
          tags.add('#https');
        } else {
          tags.add('#http');
        }
        break;
      case QrPayloadType.wifi:
        tags.add('#wifi');
        break;
      case QrPayloadType.vcard:
      case QrPayloadType.mecard:
        tags.add('#contact');
        break;
      case QrPayloadType.event:
        tags.add('#event');
        break;
      case QrPayloadType.geo:
        tags.add('#location');
        break;
      case QrPayloadType.email:
        tags.add('#email');
        break;
      case QrPayloadType.sms:
        tags.add('#sms');
        break;
      case QrPayloadType.tel:
        tags.add('#phone');
        break;
      case QrPayloadType.crypto:
        tags.add('#crypto');
        break;
      case QrPayloadType.otpauth:
        tags.add('#2fa');
        break;
      case QrPayloadType.upi:
      case QrPayloadType.epc:
        tags.add('#payment');
        break;
      default:
        tags.add('#text');
        break;
    }

    // TrustQR tags
    if (isTrustQr) {
      tags.add('#trustqr');
      if (assessment.threatLevel == SecurityThreatLevel.safe) {
        tags.add('#verified');
      } else {
        tags.add('#tampered');
      }
    }

    // Security & Threat status tags
    if (assessment.threatLevel != SecurityThreatLevel.safe) {
      tags.add('#threat-${assessment.threatLevel.name}');
    }

    return tags;
  }

  /// Automatically formats a human-readable title based on payload details.
  String _computeDefaultTitle(QrPayload payload, String rawContent, TrustQrEnvelope? trustQr) {
    if (trustQr != null) {
      return 'TrustQR: ${trustQr.issuer}';
    }

    switch (payload.type) {
      case QrPayloadType.url:
        if (payload is UrlPayload) {
          return payload.host.isNotEmpty ? payload.host : rawContent;
        }
        return rawContent;
      case QrPayloadType.wifi:
        if (payload is WifiPayload) {
          return 'Wi-Fi: ${payload.ssid}';
        }
        return 'Wi-Fi Network';
      case QrPayloadType.vcard:
        if (payload is VCardPayload) {
          return 'Contact: ${payload.formattedName}';
        }
        return 'Contact Card';
      case QrPayloadType.mecard:
        if (payload is MeCardPayload) {
          return 'Contact: ${payload.name}';
        }
        return 'MeCard Contact';
      case QrPayloadType.event:
        if (payload is EventPayload) {
          return 'Event: ${payload.summary}';
        }
        return 'Calendar Event';
      case QrPayloadType.geo:
        if (payload is GeoPayload) {
          return 'Geo: ${payload.latitude.toStringAsFixed(4)}, ${payload.longitude.toStringAsFixed(4)}';
        }
        return 'Geographic Coordinates';
      case QrPayloadType.email:
        if (payload is EmailPayload) {
          return 'Email to: ${payload.to}';
        }
        return 'Email Message';
      case QrPayloadType.sms:
        if (payload is SmsPayload) {
          return 'SMS to: ${payload.phoneNumber}';
        }
        return 'SMS Message';
      case QrPayloadType.tel:
        if (payload is TelPayload) {
          return 'Call: ${payload.phoneNumber}';
        }
        return 'Telephone Call';
      default:
        final preview = rawContent.trim();
        return preview.length > 32 ? '${preview.substring(0, 29)}...' : preview;
    }
  }
}
