import 'dart:convert';
import 'dart:typed_data';
import 'crypto_keys.dart';
import 'ed25519_engine.dart';
import 'hmac_engine.dart';

/// Result of a TrustQR verification operation.
class TrustQrVerificationResult {
  final bool isValid;
  final String? payload;
  final String? issuer;
  final String? keyId;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const TrustQrVerificationResult({
    required this.isValid,
    this.payload,
    this.issuer,
    this.keyId,
    this.reason,
    this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'payload': payload,
    'issuer': issuer,
    'keyId': keyId,
    'reason': reason,
    'createdAt': createdAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };
}

/// Cryptographically signed QR envelope preventing physical sticker tampering.
///
/// URI format: `trustqr://v1?issuer=...&payload=...&created=...&keyId=...&alg=...&sig=...`
class TrustQrEnvelope {
  final String version;
  final String issuer;
  final String payload;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String keyId;
  final CryptoAlgorithm algorithm;
  final String signature;

  const TrustQrEnvelope({
    this.version = 'v1',
    required this.issuer,
    required this.payload,
    required this.createdAt,
    this.expiresAt,
    required this.keyId,
    required this.algorithm,
    required this.signature,
  });

  /// Canonical bytes to be signed or verified.
  static Uint8List computeCanonicalBytes({
    required String version,
    required String issuer,
    required String payload,
    required DateTime createdAt,
    DateTime? expiresAt,
    required String keyId,
    required CryptoAlgorithm algorithm,
  }) {
    final expStr = expiresAt?.toUtc().toIso8601String() ?? '';
    final raw = '$version|$issuer|$payload|${createdAt.toUtc().toIso8601String()}|$expStr|$keyId|${algorithm.name}';
    return Uint8List.fromList(utf8.encode(raw));
  }

  /// Create and sign a new [TrustQrEnvelope].
  static TrustQrEnvelope sign({
    required String issuer,
    required String payload,
    required CryptoPrivateKey privateKey,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    final created = (createdAt ?? DateTime.now()).toUtc();
    final canonical = computeCanonicalBytes(
      version: 'v1',
      issuer: issuer,
      payload: payload,
      createdAt: created,
      expiresAt: expiresAt,
      keyId: privateKey.keyId,
      algorithm: privateKey.algorithm,
    );

    Uint8List sigBytes;
    if (privateKey.algorithm == CryptoAlgorithm.ed25519) {
      sigBytes = Ed25519Engine.sign(message: canonical, privateKey: privateKey);
    } else {
      sigBytes = HmacEngine.sign(message: canonical, privateKey: privateKey);
    }

    return TrustQrEnvelope(
      version: 'v1',
      issuer: issuer,
      payload: payload,
      createdAt: created,
      expiresAt: expiresAt?.toUtc(),
      keyId: privateKey.keyId,
      algorithm: privateKey.algorithm,
      signature: base64UrlEncode(sigBytes),
    );
  }

  /// Serializes the envelope to a `trustqr://` URI.
  String toUriString() {
    final params = <String, String>{
      'issuer': issuer,
      'payload': base64UrlEncode(utf8.encode(payload)),
      'created': createdAt.toIso8601String(),
      'keyId': keyId,
      'alg': algorithm.name,
      'sig': signature,
    };
    if (expiresAt != null) {
      params['expires'] = expiresAt!.toIso8601String();
    }
    return Uri(scheme: 'trustqr', host: version, queryParameters: params).toString();
  }

  /// Parses a `trustqr://` URI string into a [TrustQrEnvelope].
  static TrustQrEnvelope? tryParse(String raw) {
    try {
      final trimmed = raw.trim();
      if (!trimmed.toLowerCase().startsWith('trustqr://')) return null;
      final uri = Uri.parse(trimmed);
      final version = uri.host.isEmpty ? 'v1' : uri.host;
      final params = uri.queryParameters;

      final issuer = params['issuer'];
      final encodedPayload = params['payload'];
      final createdStr = params['created'];
      final keyId = params['keyId'];
      final algStr = params['alg'];
      final sig = params['sig'];

      if (issuer == null || encodedPayload == null || createdStr == null || keyId == null || algStr == null || sig == null) {
        return null;
      }

      final payload = utf8.decode(base64Url.decode(encodedPayload));
      final createdAt = DateTime.parse(createdStr);
      final expiresAt = params['expires'] != null ? DateTime.parse(params['expires']!) : null;
      final algorithm = CryptoAlgorithm.values.byName(algStr);

      return TrustQrEnvelope(
        version: version,
        issuer: issuer,
        payload: payload,
        createdAt: createdAt,
        expiresAt: expiresAt,
        keyId: keyId,
        algorithm: algorithm,
        signature: sig,
      );
    } catch (_) {
      return null;
    }
  }

  /// Verifies the envelope against the trusted [publicKey].
  TrustQrVerificationResult verify({required CryptoPublicKey publicKey, DateTime? currentTime}) {
    if (publicKey.keyId != keyId) {
      return TrustQrVerificationResult(
        isValid: false,
        reason: 'Key ID mismatch (expected $keyId, provided ${publicKey.keyId})',
      );
    }
    if (publicKey.algorithm != algorithm) {
      return TrustQrVerificationResult(
        isValid: false,
        reason: 'Algorithm mismatch (envelope uses ${algorithm.name}, key is ${publicKey.algorithm.name})',
      );
    }

    final now = currentTime ?? DateTime.now();
    if (expiresAt != null && now.isAfter(expiresAt!)) {
      return TrustQrVerificationResult(
        isValid: false,
        payload: payload,
        issuer: issuer,
        keyId: keyId,
        reason: 'TrustQR payload has expired',
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
    }

    final canonical = computeCanonicalBytes(
      version: version,
      issuer: issuer,
      payload: payload,
      createdAt: createdAt,
      expiresAt: expiresAt,
      keyId: keyId,
      algorithm: algorithm,
    );

    try {
      final sigBytes = Uint8List.fromList(base64Url.decode(signature));
      bool isSigValid = false;

      if (algorithm == CryptoAlgorithm.ed25519) {
        isSigValid = Ed25519Engine.verify(message: canonical, signature: sigBytes, publicKey: publicKey);
      } else {
        isSigValid = HmacEngine.verify(message: canonical, signature: sigBytes, publicKey: publicKey);
      }

      if (!isSigValid) {
        return TrustQrVerificationResult(
          isValid: false,
          payload: payload,
          issuer: issuer,
          keyId: keyId,
          reason: 'Cryptographic signature verification failed (tampered payload or invalid key)',
        );
      }

      return TrustQrVerificationResult(
        isValid: true,
        payload: payload,
        issuer: issuer,
        keyId: keyId,
        reason: 'Authentic TrustQR signature verified successfully',
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
    } catch (e) {
      return TrustQrVerificationResult(
        isValid: false,
        reason: 'Signature decoding error: $e',
      );
    }
  }
}
