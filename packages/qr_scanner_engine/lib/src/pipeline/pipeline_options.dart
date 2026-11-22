import 'package:qr_core/qr_core.dart';

/// Configuration options controlling the end-to-end Scan-to-Firewall-to-Vault pipeline.
class PipelineOptions {
  /// Whether to run Zero-Trust security inspection through the threat firewall.
  final bool enableThreatFirewall;

  /// Whether to automatically record decoded QR items into the offline vault.
  final bool saveToVault;

  /// Whether to suppress duplicate records scanned within the deduplication window.
  final bool autoDeduplicate;

  /// Time window within which an identical raw QR payload is considered a duplicate.
  final Duration deduplicationWindow;

  /// If true, prevents saving to the vault when threat level is critical (quarantine).
  final bool blockVaultOnCriticalThreat;

  /// Whether to automatically assign default smart tags and categories based on payload type.
  final bool autoCategorize;

  /// User-defined tags to attach to recorded vault items.
  final List<String> defaultTags;

  /// Explicit target collection ID in the vault. If null, collection assignment follows defaults.
  final String? targetCollectionId;

  /// Custom institutional Ed25519 public keys for TrustQR authenticity verification.
  final Map<String, CryptoPublicKey>? trustedInstitutionalKeys;

  /// Whether to offload pixel binarization and matrix decoding to background Dart isolates.
  final bool useIsolate;

  /// Whether to enforce privacy retention policy auto-purge immediately after recording.
  final bool purgeOnScan;

  const PipelineOptions({
    this.enableThreatFirewall = true,
    this.saveToVault = true,
    this.autoDeduplicate = true,
    this.deduplicationWindow = const Duration(seconds: 10),
    this.blockVaultOnCriticalThreat = false,
    this.autoCategorize = true,
    this.defaultTags = const [],
    this.targetCollectionId,
    this.trustedInstitutionalKeys,
    this.useIsolate = true,
    this.purgeOnScan = false,
  });

  PipelineOptions copyWith({
    bool? enableThreatFirewall,
    bool? saveToVault,
    bool? autoDeduplicate,
    Duration? deduplicationWindow,
    bool? blockVaultOnCriticalThreat,
    bool? autoCategorize,
    List<String>? defaultTags,
    String? targetCollectionId,
    Map<String, CryptoPublicKey>? trustedInstitutionalKeys,
    bool? useIsolate,
    bool? purgeOnScan,
  }) {
    return PipelineOptions(
      enableThreatFirewall: enableThreatFirewall ?? this.enableThreatFirewall,
      saveToVault: saveToVault ?? this.saveToVault,
      autoDeduplicate: autoDeduplicate ?? this.autoDeduplicate,
      deduplicationWindow: deduplicationWindow ?? this.deduplicationWindow,
      blockVaultOnCriticalThreat: blockVaultOnCriticalThreat ?? this.blockVaultOnCriticalThreat,
      autoCategorize: autoCategorize ?? this.autoCategorize,
      defaultTags: defaultTags ?? this.defaultTags,
      targetCollectionId: targetCollectionId ?? this.targetCollectionId,
      trustedInstitutionalKeys: trustedInstitutionalKeys ?? this.trustedInstitutionalKeys,
      useIsolate: useIsolate ?? this.useIsolate,
      purgeOnScan: purgeOnScan ?? this.purgeOnScan,
    );
  }

  Map<String, dynamic> toJson() => {
    'enableThreatFirewall': enableThreatFirewall,
    'saveToVault': saveToVault,
    'autoDeduplicate': autoDeduplicate,
    'deduplicationWindowMs': deduplicationWindow.inMilliseconds,
    'blockVaultOnCriticalThreat': blockVaultOnCriticalThreat,
    'autoCategorize': autoCategorize,
    'defaultTags': defaultTags,
    'targetCollectionId': targetCollectionId,
    'useIsolate': useIsolate,
    'purgeOnScan': purgeOnScan,
  };
}
