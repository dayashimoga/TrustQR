import 'dart:convert';
import 'dart:typed_data';
import '../models/qr_enums.dart';
import 'crypto_keys.dart';
import 'ed25519_engine.dart';
import 'hmac_engine.dart';

/// Result of an entitlement token verification check.
class EntitlementVerificationResult {
  final bool isValid;
  final String? tokenId;
  final String? subject;
  final UserRole? role;
  final List<String> scopes;
  final DateTime? expiresAt;
  final String? reason;

  const EntitlementVerificationResult({
    required this.isValid,
    this.tokenId,
    this.subject,
    this.role,
    this.scopes = const [],
    this.expiresAt,
    this.reason,
  });

  bool get isAdmin => isValid && role == UserRole.admin;

  bool hasScope(String requiredScope) => isValid && (isAdmin || scopes.contains(requiredScope));

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'tokenId': tokenId,
    'subject': subject,
    'role': role?.name,
    'scopes': scopes,
    'expiresAt': expiresAt?.toIso8601String(),
    'reason': reason,
  };
}

/// Asymmetric or HMAC-signed Entitlement Token issued by the server.
///
/// Prevents local data tampering from elevating user privileges.
class EntitlementToken {
  final String tokenId;
  final String subject;
  final UserRole role;
  final List<String> scopes;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String issuer;
  final CryptoAlgorithm algorithm;
  final String keyId;
  final String signature;

  const EntitlementToken({
    required this.tokenId,
    required this.subject,
    required this.role,
    required this.scopes,
    required this.issuedAt,
    required this.expiresAt,
    required this.issuer,
    required this.algorithm,
    required this.keyId,
    required this.signature,
  });

  /// Canonical bytes over token claims.
  static Uint8List computeCanonicalBytes({
    required String tokenId,
    required String subject,
    required UserRole role,
    required List<String> scopes,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required String issuer,
    required CryptoAlgorithm algorithm,
    required String keyId,
  }) {
    final claimsMap = {
      'jti': tokenId,
      'sub': subject,
      'role': role.name,
      'scopes': scopes,
      'iat': issuedAt.toUtc().toIso8601String(),
      'exp': expiresAt.toUtc().toIso8601String(),
      'iss': issuer,
      'alg': algorithm.name,
      'kid': keyId,
    };
    final serialized = jsonEncode(claimsMap);
    return Uint8List.fromList(utf8.encode(serialized));
  }

  /// Issues a new signed [EntitlementToken].
  static EntitlementToken issue({
    required String tokenId,
    required String subject,
    required UserRole role,
    required List<String> scopes,
    required CryptoPrivateKey privateKey,
    String issuer = 'universal-qr-authority',
    Duration validity = const Duration(hours: 24),
    DateTime? issuedAt,
  }) {
    final iat = (issuedAt ?? DateTime.now()).toUtc();
    final exp = iat.add(validity);

    final canonical = computeCanonicalBytes(
      tokenId: tokenId,
      subject: subject,
      role: role,
      scopes: scopes,
      issuedAt: iat,
      expiresAt: exp,
      issuer: issuer,
      algorithm: privateKey.algorithm,
      keyId: privateKey.keyId,
    );

    Uint8List sigBytes;
    if (privateKey.algorithm == CryptoAlgorithm.ed25519) {
      sigBytes = Ed25519Engine.sign(message: canonical, privateKey: privateKey);
    } else {
      sigBytes = HmacEngine.sign(message: canonical, privateKey: privateKey);
    }

    return EntitlementToken(
      tokenId: tokenId,
      subject: subject,
      role: role,
      scopes: scopes,
      issuedAt: iat,
      expiresAt: exp,
      issuer: issuer,
      algorithm: privateKey.algorithm,
      keyId: privateKey.keyId,
      signature: base64UrlEncode(sigBytes),
    );
  }

  /// Serializes into a compact 3-part token: `<header>.<claims>.<signature>`
  String toCompactToken() {
    final header = base64UrlEncode(utf8.encode(jsonEncode({'alg': algorithm.name, 'kid': keyId})));
    final claims = base64UrlEncode(computeCanonicalBytes(
      tokenId: tokenId,
      subject: subject,
      role: role,
      scopes: scopes,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      issuer: issuer,
      algorithm: algorithm,
      keyId: keyId,
    ));
    return '$header.$claims.$signature';
  }

  /// Parses a compact 3-part token string.
  static EntitlementToken? tryParse(String compactToken) {
    try {
      final parts = compactToken.trim().split('.');
      if (parts.length != 3) return null;

      final claimsJson = jsonDecode(utf8.decode(base64Url.decode(parts[1]))) as Map<String, dynamic>;
      return EntitlementToken(
        tokenId: claimsJson['jti'] as String,
        subject: claimsJson['sub'] as String,
        role: UserRole.values.byName(claimsJson['role'] as String),
        scopes: List<String>.from(claimsJson['scopes'] as List),
        issuedAt: DateTime.parse(claimsJson['iat'] as String),
        expiresAt: DateTime.parse(claimsJson['exp'] as String),
        issuer: claimsJson['iss'] as String,
        algorithm: CryptoAlgorithm.values.byName(claimsJson['alg'] as String),
        keyId: claimsJson['kid'] as String,
        signature: parts[2],
      );
    } catch (_) {
      return null;
    }
  }

  /// Verifies token integrity and expiration against public key.
  EntitlementVerificationResult verify({required CryptoPublicKey publicKey, DateTime? currentTime}) {
    if (publicKey.keyId != keyId) {
      return EntitlementVerificationResult(
        isValid: false,
        reason: 'Key ID mismatch (token=$keyId, key=${publicKey.keyId})',
      );
    }
    if (publicKey.algorithm != algorithm) {
      return EntitlementVerificationResult(
        isValid: false,
        reason: 'Algorithm mismatch',
      );
    }

    final now = currentTime ?? DateTime.now();
    if (now.isAfter(expiresAt)) {
      return EntitlementVerificationResult(
        isValid: false,
        tokenId: tokenId,
        subject: subject,
        role: role,
        scopes: scopes,
        expiresAt: expiresAt,
        reason: 'Entitlement token has expired',
      );
    }

    final canonical = computeCanonicalBytes(
      tokenId: tokenId,
      subject: subject,
      role: role,
      scopes: scopes,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      issuer: issuer,
      algorithm: algorithm,
      keyId: keyId,
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
        return const EntitlementVerificationResult(
          isValid: false,
          reason: 'Cryptographic signature invalid (token has been tampered with)',
        );
      }

      return EntitlementVerificationResult(
        isValid: true,
        tokenId: tokenId,
        subject: subject,
        role: role,
        scopes: scopes,
        expiresAt: expiresAt,
        reason: 'Token authentic and valid',
      );
    } catch (e) {
      return EntitlementVerificationResult(
        isValid: false,
        reason: 'Signature verification error: $e',
      );
    }
  }
}
