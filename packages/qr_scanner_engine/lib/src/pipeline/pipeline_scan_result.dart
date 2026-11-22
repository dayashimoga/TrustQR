import 'package:qr_core/qr_core.dart';
import '../security/threat_assessment.dart';

/// Comprehensive result of an end-to-end scan, security inspection, and vault recording operation.
class PipelineScanResult {
  /// The decoded raw text string extracted from the QR code.
  final String rawContent;

  /// The parsed structured QR payload model (1 of 15 supported formats).
  final QrPayload payload;

  /// The Zero-Trust security threat assessment and safety findings.
  final ThreatAssessment threatAssessment;

  /// The persisted vault record with cryptographic integrity hash, or null if not saved.
  final QrVaultItem? vaultItem;

  /// Whether this scan was deduplicated against an identical recent vault entry.
  final bool isDeduplicated;

  /// Total end-to-end processing latency in milliseconds.
  final double latencyMs;

  /// Timestamp of when the pipeline operation was completed.
  final DateTime timestamp;

  const PipelineScanResult({
    required this.rawContent,
    required this.payload,
    required this.threatAssessment,
    this.vaultItem,
    this.isDeduplicated = false,
    required this.latencyMs,
    required this.timestamp,
  });

  /// Whether the payload is safe to open or execute.
  bool get isAllowed => threatAssessment.isActionAllowed;

  /// Threat severity classification (safe, caution, suspicious, critical).
  SecurityThreatLevel get threatLevel => threatAssessment.threatLevel;

  /// Normalized safety score from 0 (malicious) to 100 (safe).
  int get safetyScore => threatAssessment.safetyScore;

  /// Structured payload format type.
  QrPayloadType get payloadType => payload.type;

  /// Whether this item was successfully committed to the encrypted vault.
  bool get isSavedToVault => vaultItem != null;

  Map<String, dynamic> toJson() => {
    'rawContent': rawContent,
    'payloadType': payloadType.name,
    'threatLevel': threatLevel.name,
    'safetyScore': safetyScore,
    'isAllowed': isAllowed,
    'isDeduplicated': isDeduplicated,
    'isSavedToVault': isSavedToVault,
    'vaultItemId': vaultItem?.id,
    'latencyMs': latencyMs,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'threatAssessment': threatAssessment.toJson(),
  };
}
