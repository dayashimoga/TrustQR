import 'dart:convert';
import 'dart:typed_data';
import '../crypto/crypto_keys.dart';
import '../crypto/hmac_engine.dart';
import '../models/qr_enums.dart';

/// Stored QR item within the offline-first vault with HMAC cryptographic integrity guard.
class QrVaultItem {
  final String id;
  final String rawContent;
  final QrPayloadType payloadType;
  final SecurityThreatLevel threatLevel;
  final int safetyScore;
  final QrItemOrigin origin;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final String? title;
  final String? notes;
  final String? collectionId;
  final List<String> tags;
  final bool isTrustQr;
  final String? trustQrIssuer;
  final String integrityHash;

  const QrVaultItem({
    required this.id,
    required this.rawContent,
    required this.payloadType,
    required this.threatLevel,
    required this.safetyScore,
    required this.origin,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.title,
    this.notes,
    this.collectionId,
    this.tags = const [],
    this.isTrustQr = false,
    this.trustQrIssuer,
    required this.integrityHash,
  });

  /// Canonical byte representation for HMAC integrity verification.
  String computeCanonicalData() {
    final sortedTags = List<String>.from(tags)..sort();
    return '$id|${origin.name}|$rawContent|${payloadType.name}|${threatLevel.name}|$safetyScore|'
        '${createdAt.toUtc().toIso8601String()}|$isFavorite|${collectionId ?? ''}|'
        '${sortedTags.join(',')}|${isTrustQr ? (trustQrIssuer ?? 'trustqr') : ''}';
  }

  /// Computes the HMAC-SHA256 integrity hash for the given item.
  static String computeIntegrityHash({
    required String id,
    required String rawContent,
    required QrPayloadType payloadType,
    required SecurityThreatLevel threatLevel,
    required int safetyScore,
    required QrItemOrigin origin,
    required DateTime createdAt,
    required bool isFavorite,
    String? collectionId,
    List<String> tags = const [],
    bool isTrustQr = false,
    String? trustQrIssuer,
    required CryptoPrivateKey hmacKey,
  }) {
    final sortedTags = List<String>.from(tags)..sort();
    final canonical = '$id|${origin.name}|$rawContent|${payloadType.name}|${threatLevel.name}|$safetyScore|'
        '${createdAt.toUtc().toIso8601String()}|$isFavorite|${collectionId ?? ''}|'
        '${sortedTags.join(',')}|${isTrustQr ? (trustQrIssuer ?? 'trustqr') : ''}';
    final sig = HmacEngine.sign(
      message: Uint8List.fromList(utf8.encode(canonical)),
      privateKey: hmacKey,
    );
    return base64UrlEncode(sig);
  }

  /// Verifies whether this item has been tampered with since creation/signing.
  bool verifyIntegrity(CryptoPrivateKey hmacKey) {
    if (integrityHash.isEmpty) return false;
    final canonical = computeCanonicalData();
    Uint8List expectedSig;
    try {
      var normalized = integrityHash.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      expectedSig = Uint8List.fromList(base64Decode(normalized));
    } catch (_) {
      return false;
    }

    return HmacEngine.verify(
      message: Uint8List.fromList(utf8.encode(canonical)),
      signature: expectedSig,
      publicKey: CryptoPublicKey(
        bytes: hmacKey.bytes,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: hmacKey.keyId,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rawContent': rawContent,
    'payloadType': payloadType.name,
    'threatLevel': threatLevel.name,
    'safetyScore': safetyScore,
    'origin': origin.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'isFavorite': isFavorite,
    'title': title,
    'notes': notes,
    'collectionId': collectionId,
    'tags': tags,
    'isTrustQr': isTrustQr,
    'trustQrIssuer': trustQrIssuer,
    'integrityHash': integrityHash,
  };

  factory QrVaultItem.fromJson(Map<String, dynamic> json) {
    return QrVaultItem(
      id: json['id'] as String,
      rawContent: json['rawContent'] as String,
      payloadType: QrPayloadType.values.byName(json['payloadType'] as String),
      threatLevel: SecurityThreatLevel.values.byName(json['threatLevel'] as String),
      safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 100,
      origin: QrItemOrigin.values.byName((json['origin'] as String?) ?? 'scanned'),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String).toUtc() : null,
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      collectionId: json['collectionId'] as String?,
      tags: List<String>.from((json['tags'] as List?) ?? []),
      isTrustQr: (json['isTrustQr'] as bool?) ?? false,
      trustQrIssuer: json['trustQrIssuer'] as String?,
      integrityHash: (json['integrityHash'] as String?) ?? '',
    );
  }

  QrVaultItem copyWith({
    String? id,
    String? rawContent,
    QrPayloadType? payloadType,
    SecurityThreatLevel? threatLevel,
    int? safetyScore,
    QrItemOrigin? origin,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? title,
    bool clearTitle = false,
    String? notes,
    bool clearNotes = false,
    String? collectionId,
    bool clearCollectionId = false,
    List<String>? tags,
    bool? isTrustQr,
    String? trustQrIssuer,
    String? integrityHash,
  }) {
    return QrVaultItem(
      id: id ?? this.id,
      rawContent: rawContent ?? this.rawContent,
      payloadType: payloadType ?? this.payloadType,
      threatLevel: threatLevel ?? this.threatLevel,
      safetyScore: safetyScore ?? this.safetyScore,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      title: clearTitle ? null : (title ?? this.title),
      notes: clearNotes ? null : (notes ?? this.notes),
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
      tags: tags ?? this.tags,
      isTrustQr: isTrustQr ?? this.isTrustQr,
      trustQrIssuer: trustQrIssuer ?? this.trustQrIssuer,
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }
}
