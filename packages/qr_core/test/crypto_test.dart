import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('Ed25519 & HMAC Cryptographic Engine Tests', () {
    final seed = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));
    final keyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'gov-master-key');

    test('Ed25519 key generation produces valid 32-byte public key', () {
      expect(keyPair.publicKey.bytes.length, equals(32));
      expect(keyPair.privateKey.bytes.length, equals(32));
      expect(keyPair.publicKey.keyId, equals('gov-master-key'));
      expect(keyPair.algorithm, equals(CryptoAlgorithm.ed25519));
    });

    test('Ed25519 signing and verification succeeds on authentic message', () {
      final msg = Uint8List.fromList(utf8.encode('https://universalqr.gov/cert/12345'));
      final sig = Ed25519Engine.sign(message: msg, privateKey: keyPair.privateKey);
      expect(sig.length, equals(64));

      final isValid = Ed25519Engine.verify(message: msg, signature: sig, publicKey: keyPair.publicKey);
      expect(isValid, isTrue);
    });

    test('Ed25519 verification fails if message is tampered with by 1 byte', () {
      final msg = Uint8List.fromList(utf8.encode('https://universalqr.gov/cert/12345'));
      final sig = Ed25519Engine.sign(message: msg, privateKey: keyPair.privateKey);

      final tamperedMsg = Uint8List.fromList(utf8.encode('https://universalqr.gov/cert/12346'));
      final isValid = Ed25519Engine.verify(message: tamperedMsg, signature: sig, publicKey: keyPair.publicKey);
      expect(isValid, isFalse);
    });

    test('Ed25519 verification fails if signature byte is modified', () {
      final msg = Uint8List.fromList(utf8.encode('payload data'));
      final sig = Ed25519Engine.sign(message: msg, privateKey: keyPair.privateKey);
      sig[5] ^= 0xFF; // Flip bits

      final isValid = Ed25519Engine.verify(message: msg, signature: sig, publicKey: keyPair.publicKey);
      expect(isValid, isFalse);
    });

    test('Ed25519 rejects invalid key or signature lengths gracefully', () {
      final msg = Uint8List.fromList([1, 2, 3]);
      expect(
        () => Ed25519Engine.sign(message: msg, privateKey: CryptoPrivateKey(bytes: Uint8List(16), algorithm: CryptoAlgorithm.ed25519, keyId: 'bad')),
        throwsArgumentError,
      );
      expect(
        () => Ed25519Engine.generateKeyPairFromSeed(Uint8List(16)),
        throwsArgumentError,
      );
      expect(
        Ed25519Engine.verify(message: msg, signature: Uint8List(32), publicKey: keyPair.publicKey),
        isFalse,
      );
      expect(
        Ed25519Engine.verify(message: msg, signature: Uint8List(64), publicKey: CryptoPublicKey(bytes: Uint8List(16), algorithm: CryptoAlgorithm.ed25519, keyId: 'bad')),
        isFalse,
      );
    });

    test('HMAC signing and verification', () {
      final hmacKeyPair = CryptoKeyPair.generateHmacKey(keyId: 'hmac-key');
      final msg = Uint8List.fromList(utf8.encode('hmac-test-payload'));
      final sig = HmacEngine.sign(message: msg, privateKey: hmacKeyPair.privateKey);
      expect(sig.length, equals(32));

      final isValid = HmacEngine.verify(message: msg, signature: sig, publicKey: hmacKeyPair.publicKey);
      expect(isValid, isTrue);

      final tamperedMsg = Uint8List.fromList(utf8.encode('hmac-tampered'));
      expect(HmacEngine.verify(message: tamperedMsg, signature: sig, publicKey: hmacKeyPair.publicKey), isFalse);
    });

    test('CryptoKey serialization to and from base64url', () {
      final b64 = keyPair.publicKey.toBase64Url();
      final restored = CryptoPublicKey.fromBase64Url(
        base64Url: b64,
        algorithm: CryptoAlgorithm.ed25519,
        keyId: 'gov-master-key',
      );
      expect(restored, equals(keyPair.publicKey));
      expect(restored.hashCode, equals(keyPair.publicKey.hashCode));

      final privB64 = keyPair.privateKey.toBase64Url();
      final restoredPriv = CryptoPrivateKey.fromBase64Url(
        base64Url: privB64,
        algorithm: CryptoAlgorithm.ed25519,
        keyId: 'gov-master-key',
      );
      expect(restoredPriv.bytes, equals(keyPair.privateKey.bytes));
    });
  });

  group('TrustQR Envelope Protocol Tests', () {
    final seed = Uint8List.fromList(List.generate(32, (i) => i * 11 % 256));
    final keyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'inst-key-1');

    test('TrustQR creation, URI serialization, and verification', () {
      final envelope = TrustQrEnvelope.sign(
        issuer: 'org.health.authority',
        payload: 'https://health.gov/vaccine/verify?id=998877',
        privateKey: keyPair.privateKey,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final uriString = envelope.toUriString();
      expect(uriString, startsWith('trustqr://v1?'));
      expect(uriString, contains('issuer=org.health.authority'));

      final parsed = TrustQrEnvelope.tryParse(uriString);
      expect(parsed, isNotNull);
      expect(parsed!.issuer, equals('org.health.authority'));
      expect(parsed.payload, equals('https://health.gov/vaccine/verify?id=998877'));
      expect(parsed.keyId, equals('inst-key-1'));

      final verification = parsed.verify(publicKey: keyPair.publicKey);
      expect(verification.isValid, isTrue);
      expect(verification.reason, contains('verified successfully'));
      expect(verification.toJson()['isValid'], isTrue);
    });

    test('TrustQR detects physical tamper or modified payload URI', () {
      final envelope = TrustQrEnvelope.sign(
        issuer: 'org.health.authority',
        payload: 'https://legit-site.com/payment',
        privateKey: keyPair.privateKey,
      );

      final uriString = envelope.toUriString();
      // Attacker replaces payload with phishing link
      final tamperedUri = uriString.replaceFirst(
        base64UrlEncode(utf8.encode('https://legit-site.com/payment')),
        base64UrlEncode(utf8.encode('https://phishing-attacker.com/steal')),
      );

      final parsed = TrustQrEnvelope.tryParse(tamperedUri);
      expect(parsed, isNotNull);

      final verification = parsed!.verify(publicKey: keyPair.publicKey);
      expect(verification.isValid, isFalse);
      expect(verification.reason, contains('failed'));
    });

    test('TrustQR expiration detection', () {
      final expiredEnvelope = TrustQrEnvelope.sign(
        issuer: 'org.event.tickets',
        payload: 'TICKET-EXPIRED-123',
        privateKey: keyPair.privateKey,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final uri = expiredEnvelope.toUriString();
      final parsed = TrustQrEnvelope.tryParse(uri)!;

      final res = parsed.verify(publicKey: keyPair.publicKey);
      expect(res.isValid, isFalse);
      expect(res.reason, contains('expired'));
    });

    test('TrustQR key mismatch and algorithm mismatch detection', () {
      final envelope = TrustQrEnvelope.sign(
        issuer: 'org.test',
        payload: 'test',
        privateKey: keyPair.privateKey,
      );

      // Wrong keyId
      final wrongKey = CryptoPublicKey(bytes: keyPair.publicKey.bytes, algorithm: CryptoAlgorithm.ed25519, keyId: 'other-key');
      expect(envelope.verify(publicKey: wrongKey).isValid, isFalse);

      // Wrong algorithm
      final wrongAlgKey = CryptoPublicKey(bytes: keyPair.publicKey.bytes, algorithm: CryptoAlgorithm.hmacSha256, keyId: 'inst-key-1');
      expect(envelope.verify(publicKey: wrongAlgKey).isValid, isFalse);
    });

    test('TrustQrEnvelope.tryParse gracefully returns null on invalid inputs', () {
      expect(TrustQrEnvelope.tryParse(''), isNull);
      expect(TrustQrEnvelope.tryParse('https://not-trustqr.org'), isNull);
      expect(TrustQrEnvelope.tryParse('trustqr://v1?incomplete=params'), isNull);
    });
  });

  group('Entitlement Token & RBAC Cryptographic Protection Tests', () {
    final authSeed = Uint8List.fromList(List.generate(32, (i) => i * 13 % 256));
    final authKeyPair = Ed25519Engine.generateKeyPairFromSeed(authSeed, keyId: 'auth-server-key');

    test('Issues valid admin entitlement token with full privileges', () {
      final token = EntitlementToken.issue(
        tokenId: 'jti-admin-001',
        subject: 'admin@universalqr.org',
        role: UserRole.admin,
        scopes: ['qr:scan', 'qr:generate', 'qr:customize', 'qr:batch', 'qr:sign', 'qr:analytics', 'qr:admin'],
        privateKey: authKeyPair.privateKey,
      );

      final compact = token.toCompactToken();
      expect(compact.split('.').length, equals(3));

      final parsed = EntitlementToken.tryParse(compact);
      expect(parsed, isNotNull);
      expect(parsed!.subject, equals('admin@universalqr.org'));
      expect(parsed.role, equals(UserRole.admin));

      final res = parsed.verify(publicKey: authKeyPair.publicKey);
      expect(res.isValid, isTrue);
      expect(res.isAdmin, isTrue);
      expect(res.hasScope('qr:generate'), isTrue);
      expect(res.hasScope('qr:batch'), isTrue);
      expect(res.toJson()['role'], equals('admin'));
    });

    test('Issues restricted user entitlement token with limited scopes', () {
      final token = EntitlementToken.issue(
        tokenId: 'jti-user-002',
        subject: 'user@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan', 'qr:verify', 'qr:history:own'],
        privateKey: authKeyPair.privateKey,
      );

      final parsed = EntitlementToken.tryParse(token.toCompactToken())!;
      final res = parsed.verify(publicKey: authKeyPair.publicKey);

      expect(res.isValid, isTrue);
      expect(res.isAdmin, isFalse);
      expect(res.hasScope('qr:scan'), isTrue);
      expect(res.hasScope('qr:generate'), isFalse);
      expect(res.hasScope('qr:analytics'), isFalse);
    });

    test('Cryptographic tamper detection: Modifying local user token role fails verification', () {
      // User tries to elevate privilege by tampering with token payload locally
      final userToken = EntitlementToken.issue(
        tokenId: 'jti-user-tamper',
        subject: 'user@hack.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: authKeyPair.privateKey,
      );

      final parts = userToken.toCompactToken().split('.');
      final claimsJson = jsonDecode(utf8.decode(base64Url.decode(parts[1]))) as Map<String, dynamic>;

      // Tamper: change role from user to admin
      claimsJson['role'] = 'admin';
      claimsJson['scopes'] = ['qr:all'];

      final tamperedClaimsB64 = base64UrlEncode(utf8.encode(jsonEncode(claimsJson)));
      final tamperedTokenString = '${parts[0]}.$tamperedClaimsB64.${parts[2]}';

      final tamperedToken = EntitlementToken.tryParse(tamperedTokenString)!;
      final verification = tamperedToken.verify(publicKey: authKeyPair.publicKey);

      expect(verification.isValid, isFalse);
      expect(verification.isAdmin, isFalse);
      expect(verification.reason, contains('tampered'));
    });

    test('Expired entitlement token fails verification', () {
      final expiredToken = EntitlementToken.issue(
        tokenId: 'jti-expired',
        subject: 'user@universalqr.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: authKeyPair.privateKey,
        validity: const Duration(seconds: -10),
      );

      final parsed = EntitlementToken.tryParse(expiredToken.toCompactToken())!;
      final res = parsed.verify(publicKey: authKeyPair.publicKey);
      expect(res.isValid, isFalse);
      expect(res.reason, contains('expired'));
    });

    test('Key mismatch and malformed compact token handling', () {
      final token = EntitlementToken.issue(
        tokenId: 'jti-key-mismatch',
        subject: 'user@test.org',
        role: UserRole.user,
        scopes: ['qr:scan'],
        privateKey: authKeyPair.privateKey,
      );

      final wrongKey = CryptoPublicKey(bytes: authKeyPair.publicKey.bytes, algorithm: CryptoAlgorithm.ed25519, keyId: 'wrong-key-id');
      expect(token.verify(publicKey: wrongKey).isValid, isFalse);

      expect(EntitlementToken.tryParse('invalid.token'), isNull);
      expect(EntitlementToken.tryParse('a.b.c.d'), isNull);
    });
  });
}
