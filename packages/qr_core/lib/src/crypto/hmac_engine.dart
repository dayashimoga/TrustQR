import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'crypto_keys.dart';

/// HMAC-SHA256 Cryptographic Engine
class HmacEngine {
  /// Signs a message using an HMAC key.
  static Uint8List sign({required Uint8List message, required CryptoPrivateKey privateKey}) {
    final hmac = Hmac(sha256, privateKey.bytes);
    final digest = hmac.convert(message);
    return Uint8List.fromList(digest.bytes);
  }

  /// Verifies an HMAC signature with constant-time equality check.
  static bool verify({
    required Uint8List message,
    required Uint8List signature,
    required CryptoPublicKey publicKey,
  }) {
    final expected = sign(message: message, privateKey: CryptoPrivateKey(bytes: publicKey.bytes, algorithm: CryptoAlgorithm.hmacSha256, keyId: publicKey.keyId));
    if (expected.length != signature.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ signature[i];
    }
    return diff == 0;
  }
}
