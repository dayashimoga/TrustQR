import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Supported cryptographic signature algorithms.
enum CryptoAlgorithm {
  ed25519,
  hmacSha256,
}

/// Public verification key container.
class CryptoPublicKey {
  final Uint8List bytes;
  final CryptoAlgorithm algorithm;
  final String keyId;

  const CryptoPublicKey({
    required this.bytes,
    required this.algorithm,
    required this.keyId,
  });

  String toBase64Url() => base64UrlEncode(bytes);

  factory CryptoPublicKey.fromBase64Url({
    required String base64Url,
    required CryptoAlgorithm algorithm,
    required String keyId,
  }) {
    return CryptoPublicKey(
      bytes: Uint8List.fromList(base64Url.contains('=') ? base64Decode(base64Url) : base64Url.length % 4 == 0 ? base64Url.decode() : _decodeUnpadded(base64Url)),
      algorithm: algorithm,
      keyId: keyId,
    );
  }

  static Uint8List _decodeUnpadded(String src) {
    var s = src.replaceAll('-', '+').replaceAll('_', '/');
    while (s.length % 4 != 0) {
      s += '=';
    }
    return Uint8List.fromList(base64Decode(s));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CryptoPublicKey &&
          other.algorithm == algorithm &&
          other.keyId == keyId &&
          _bytesEqual(other.bytes, bytes));

  @override
  int get hashCode => Object.hash(algorithm, keyId, bytes.length);

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Private signing key container.
class CryptoPrivateKey {
  final Uint8List bytes;
  final CryptoAlgorithm algorithm;
  final String keyId;

  const CryptoPrivateKey({
    required this.bytes,
    required this.algorithm,
    required this.keyId,
  });

  String toBase64Url() => base64UrlEncode(bytes);

  factory CryptoPrivateKey.fromBase64Url({
    required String base64Url,
    required CryptoAlgorithm algorithm,
    required String keyId,
  }) {
    return CryptoPrivateKey(
      bytes: Uint8List.fromList(CryptoPublicKey._decodeUnpadded(base64Url)),
      algorithm: algorithm,
      keyId: keyId,
    );
  }
}

/// Asymmetric or symmetric cryptographic keypair.
class CryptoKeyPair {
  final CryptoPrivateKey privateKey;
  final CryptoPublicKey publicKey;

  const CryptoKeyPair({
    required this.privateKey,
    required this.publicKey,
  });

  String get keyId => publicKey.keyId;
  CryptoAlgorithm get algorithm => publicKey.algorithm;

  /// Generates a random cryptographic seed / keypair.
  static CryptoKeyPair generateHmacKey({String keyId = 'hmac-default', int byteLength = 32}) {
    final rng = Random.secure();
    final bytes = Uint8List(byteLength);
    for (var i = 0; i < byteLength; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return CryptoKeyPair(
      privateKey: CryptoPrivateKey(bytes: bytes, algorithm: CryptoAlgorithm.hmacSha256, keyId: keyId),
      publicKey: CryptoPublicKey(bytes: bytes, algorithm: CryptoAlgorithm.hmacSha256, keyId: keyId),
    );
  }
}

extension on String {
  List<int> decode() => base64Url.decode(this);
}
