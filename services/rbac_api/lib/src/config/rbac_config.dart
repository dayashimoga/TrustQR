import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:qr_core/qr_core.dart';

/// Configuration for the RBAC Authority and Entitlement Server.
class RbacConfig {
  final InternetAddress address;
  final int port;
  final String issuer;
  final CryptoKeyPair institutionalKeyPair;
  final Duration tokenValidity;
  final Map<String, ({String password, UserRole role, List<String> scopes})> credentials;

  const RbacConfig({
    required this.address,
    required this.port,
    required this.issuer,
    required this.institutionalKeyPair,
    this.tokenValidity = const Duration(hours: 24),
    required this.credentials,
  });

  CryptoPrivateKey get privateKey => institutionalKeyPair.privateKey;
  CryptoPublicKey get publicKey => institutionalKeyPair.publicKey;

  /// Creates a standard production/testing configuration with deterministic institutional Ed25519 keys.
  factory RbacConfig.defaultConfig({
    InternetAddress? address,
    int port = 8089,
    String issuer = 'universal-qr-authority',
    Duration tokenValidity = const Duration(hours: 24),
  }) {
    // Deterministic 32-byte seed for institutional root key
    final seedHash = sha256.convert(utf8.encode('universal-qr-authority-institutional-root-2026')).bytes;
    final seed = Uint8List.fromList(seedHash);
    final keyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'trustqr-root-2026');

    final credentials = <String, ({String password, UserRole role, List<String> scopes})>{
      'admin': (
        password: 'admin-password-secure',
        role: UserRole.admin,
        scopes: const [
          'qr:scan',
          'qr:verify',
          'qr:history:own',
          'qr:generate',
          'qr:customize',
          'qr:batch',
          'qr:sign',
          'qr:templates',
          'qr:analytics',
          'qr:admin',
        ],
      ),
      'user': (
        password: 'user-password-secure',
        role: UserRole.user,
        scopes: const [
          'qr:scan',
          'qr:verify',
          'qr:history:own',
        ],
      ),
    };

    return RbacConfig(
      address: address ?? InternetAddress.loopbackIPv4,
      port: port,
      issuer: issuer,
      institutionalKeyPair: keyPair,
      tokenValidity: tokenValidity,
      credentials: credentials,
    );
  }
}
