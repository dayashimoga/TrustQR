import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'crypto_keys.dart';

/// Pure-Dart Ed25519 (RFC 8032) Cryptographic Engine
///
/// Implements Edwards25519 curve arithmetic over prime field 2^255 - 19.
/// Provides Ed25519 signing and verification with zero native C/C++ dependencies.
class Ed25519Engine {
  // Prime field: q = 2^255 - 19
  static final BigInt _q = (BigInt.one << 255) - BigInt.from(19);

  // Group order: l = 2^252 + 27742317777372353535851937790883648493
  static final BigInt _l = (BigInt.one << 252) + BigInt.parse('27742317777372353535851937790883648493');

  // Curve parameter d = -121665 / 121666 mod q
  static final BigInt _d = _mod(
    -BigInt.from(121665) * _inv(BigInt.from(121666), _q),
    _q,
  );

  // Base point By = 4 / 5 mod q
  static final BigInt _by = _mod(
    BigInt.from(4) * _inv(BigInt.from(5), _q),
    _q,
  );

  // Base point Bx
  static late final BigInt _bx = _recoverX(_by);

  static final _EdwardsPoint _basePoint = _EdwardsPoint(_bx, _by);

  /// Generates an Ed25519 keypair from a 32-byte seed.
  static CryptoKeyPair generateKeyPairFromSeed(Uint8List seed, {String keyId = 'ed25519-key'}) {
    if (seed.length != 32) {
      throw ArgumentError('Seed must be exactly 32 bytes for Ed25519');
    }
    final hash = sha512.convert(seed).bytes;
    final clamped = Uint8List.fromList(hash.sublist(0, 32));
    clamped[0] &= 248;
    clamped[31] &= 127;
    clamped[31] |= 64;

    final aScalar = _decodeLittleEndian(clamped);
    final aPoint = _scalarMultiply(_basePoint, aScalar);
    final pubBytes = _encodePoint(aPoint);

    return CryptoKeyPair(
      privateKey: CryptoPrivateKey(bytes: seed, algorithm: CryptoAlgorithm.ed25519, keyId: keyId),
      publicKey: CryptoPublicKey(bytes: pubBytes, algorithm: CryptoAlgorithm.ed25519, keyId: keyId),
    );
  }

  /// Signs a message using Ed25519 private key seed (32 bytes).
  static Uint8List sign({required Uint8List message, required CryptoPrivateKey privateKey}) {
    if (privateKey.bytes.length != 32) {
      throw ArgumentError('Ed25519 private key seed must be exactly 32 bytes');
    }

    final h = sha512.convert(privateKey.bytes).bytes;
    final aBytes = Uint8List.fromList(h.sublist(0, 32));
    aBytes[0] &= 248;
    aBytes[31] &= 127;
    aBytes[31] |= 64;
    final aScalar = _decodeLittleEndian(aBytes);
    final aPoint = _scalarMultiply(_basePoint, aScalar);
    final pubBytes = _encodePoint(aPoint);

    // r = SHA-512(h[32..64] || message) mod l
    final rInput = Uint8List(32 + message.length);
    rInput.setRange(0, 32, h.sublist(32, 64));
    rInput.setRange(32, rInput.length, message);
    final rHash = sha512.convert(rInput).bytes;
    final rScalar = _decodeLittleEndian(Uint8List.fromList(rHash)) % _l;

    // R = r * B
    final rPoint = _scalarMultiply(_basePoint, rScalar);
    final rBytes = _encodePoint(rPoint);

    // k = SHA-512(R || pubKey || message) mod l
    final kInput = Uint8List(32 + 32 + message.length);
    kInput.setRange(0, 32, rBytes);
    kInput.setRange(32, 64, pubBytes);
    kInput.setRange(64, kInput.length, message);
    final kHash = sha512.convert(kInput).bytes;
    final kScalar = _decodeLittleEndian(Uint8List.fromList(kHash)) % _l;

    // S = (r + k * a) mod l
    final sScalar = (rScalar + (kScalar * aScalar)) % _l;
    final sBytes = _encodeLittleEndian(sScalar, 32);

    final signature = Uint8List(64);
    signature.setRange(0, 32, rBytes);
    signature.setRange(32, 64, sBytes);
    return signature;
  }

  /// Verifies an Ed25519 signature (64 bytes) against public key (32 bytes) and message.
  static bool verify({
    required Uint8List message,
    required Uint8List signature,
    required CryptoPublicKey publicKey,
  }) {
    if (signature.length != 64) return false;
    if (publicKey.bytes.length != 32) return false;

    try {
      final rBytes = signature.sublist(0, 32);
      final sBytes = signature.sublist(32, 64);
      final sScalar = _decodeLittleEndian(sBytes);
      if (sScalar >= _l) return false;

      final aPoint = _decodePoint(publicKey.bytes);
      if (aPoint == null) return false;

      final rPoint = _decodePoint(rBytes);
      if (rPoint == null) return false;

      // k = SHA-512(R || pubKey || message) mod l
      final kInput = Uint8List(32 + 32 + message.length);
      kInput.setRange(0, 32, rBytes);
      kInput.setRange(32, 64, publicKey.bytes);
      kInput.setRange(64, kInput.length, message);
      final kHash = sha512.convert(kInput).bytes;
      final kScalar = _decodeLittleEndian(Uint8List.fromList(kHash)) % _l;

      // Verification equation: S * B == R + k * A
      final sbPoint = _scalarMultiply(_basePoint, sScalar);
      final kaPoint = _scalarMultiply(aPoint, kScalar);
      final rkaPoint = _pointAdd(rPoint, kaPoint);

      return sbPoint.x == rkaPoint.x && sbPoint.y == rkaPoint.y;
    } catch (_) {
      return false;
    }
  }

  // Helper arithmetic
  static BigInt _mod(BigInt a, BigInt n) => ((a % n) + n) % n;

  static BigInt _inv(BigInt a, BigInt m) => a.modInverse(m);

  static BigInt _recoverX(BigInt y) {
    final u = _mod(y * y - BigInt.one, _q);
    final v = _mod(_d * y * y + BigInt.one, _q);
    var x = _mod(u * _inv(v, _q), _q);
    // Square root modulo q via x = u * v^3 * (u * v^7)^((q-5)/8)
    final root = x.modPow((_q + BigInt.from(3)) ~/ BigInt.from(8), _q);
    if (_mod(root * root - x, _q) != BigInt.zero) {
      final sqrtMinusOne = BigInt.from(2).modPow((_q - BigInt.one) ~/ BigInt.from(4), _q);
      x = _mod(root * sqrtMinusOne, _q);
    } else {
      x = root;
    }
    if (x.isOdd) x = _q - x;
    return x;
  }

  static _EdwardsPoint _pointAdd(_EdwardsPoint p1, _EdwardsPoint p2) {
    final x1 = p1.x, y1 = p1.y, x2 = p2.x, y2 = p2.y;
    final dX1X2Y1Y2 = _mod(_d * x1 * x2 * y1 * y2, _q);
    final x3 = _mod((x1 * y2 + y1 * x2) * _inv(_mod(BigInt.one + dX1X2Y1Y2, _q), _q), _q);
    final y3 = _mod((y1 * y2 + x1 * x2) * _inv(_mod(BigInt.one - dX1X2Y1Y2, _q), _q), _q);
    return _EdwardsPoint(x3, y3);
  }

  static _EdwardsPoint _scalarMultiply(_EdwardsPoint p, BigInt scalar) {
    var r = _EdwardsPoint(BigInt.zero, BigInt.one);
    var base = p;
    var s = scalar;
    while (s > BigInt.zero) {
      if (s.isOdd) r = _pointAdd(r, base);
      base = _pointAdd(base, base);
      s >>= 1;
    }
    return r;
  }

  static Uint8List _encodePoint(_EdwardsPoint p) {
    final bytes = _encodeLittleEndian(p.y, 32);
    if (p.x.isOdd) bytes[31] |= 128;
    return bytes;
  }

  static _EdwardsPoint? _decodePoint(Uint8List bytes) {
    if (bytes.length != 32) return null;
    final yBytes = Uint8List.fromList(bytes);
    final sign = (yBytes[31] & 128) != 0;
    yBytes[31] &= 127;
    final y = _decodeLittleEndian(yBytes);
    if (y >= _q) return null;
    var x = _recoverX(y);
    if (x.isOdd != sign) x = _q - x;
    return _EdwardsPoint(x, y);
  }

  static BigInt _decodeLittleEndian(Uint8List b) {
    var res = BigInt.zero;
    for (var i = b.length - 1; i >= 0; i--) {
      res = (res << 8) | BigInt.from(b[i]);
    }
    return res;
  }

  static Uint8List _encodeLittleEndian(BigInt val, int length) {
    final res = Uint8List(length);
    var v = val;
    for (var i = 0; i < length; i++) {
      res[i] = (v & BigInt.from(0xFF)).toInt();
      v >>= 8;
    }
    return res;
  }
}

class _EdwardsPoint {
  final BigInt x;
  final BigInt y;
  const _EdwardsPoint(this.x, this.y);
}
