import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:qr_core/qr_core.dart';

/// State coordinator managing administrative authentication, entitlement tokens,
/// cryptographic validation, and role-based access control.
class AuthController extends ChangeNotifier {
  static const String defaultIssuer = 'universal-qr-authority';
  static const String defaultAdminKeyId = 'admin-ed25519-auth-key';

  late final CryptoKeyPair _authorityKeyPair;
  EntitlementToken? _activeToken;
  String? _rawTokenString;
  bool _isAuthenticated = false;
  String? _denialReason;
  String _subject = 'admin@enterprise.corp';
  UserRole _role = UserRole.admin;
  List<String> _scopes = const ['generate', 'batch', 'analytics', 'audit', 'templates'];

  AuthController({CryptoKeyPair? authorityKeyPair}) {
    if (authorityKeyPair != null) {
      _authorityKeyPair = authorityKeyPair;
    } else {
      // Deterministic keypair for reproducible local testing and offline operation
      final seed = Uint8List(32);
      final random = math.Random(1337);
      for (var i = 0; i < 32; i++) {
        seed[i] = random.nextInt(256);
      }
      _authorityKeyPair = Ed25519Engine.generateKeyPairFromSeed(
        seed,
        keyId: defaultAdminKeyId,
      );
    }
    // Default to signed admin session on startup
    signInAsAdmin();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAuthenticated && _role == UserRole.admin;
  EntitlementToken? get activeToken => _activeToken;
  String? get rawTokenString => _rawTokenString;
  String? get denialReason => _denialReason;
  String get subject => _subject;
  UserRole get role => _role;
  List<String> get scopes => List.unmodifiable(_scopes);
  CryptoPublicKey get authorityPublicKey => _authorityKeyPair.publicKey;
  String get keyId => _authorityKeyPair.publicKey.keyId;

  // ---------------------------------------------------------------------------
  // Authentication Actions
  // ---------------------------------------------------------------------------

  /// Signs in as a fully privileged administrator using a signed Ed25519 token.
  void signInAsAdmin({String subject = 'admin@enterprise.corp'}) {
    final token = EntitlementToken.issue(
      tokenId: 'tok_admin_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      role: UserRole.admin,
      scopes: const ['generate', 'batch', 'analytics', 'audit', 'templates'],
      privateKey: _authorityKeyPair.privateKey,
      issuer: defaultIssuer,
      validity: const Duration(hours: 24),
    );

    _activeToken = token;
    _rawTokenString = token.toCompactToken();
    _subject = subject;
    _role = UserRole.admin;
    _scopes = token.scopes;
    _isAuthenticated = true;
    _denialReason = null;
    notifyListeners();
  }

  /// Signs in as a restricted non-admin user (for negative RBAC access testing).
  void signInAsUser({String subject = 'user@restricted.corp'}) {
    final token = EntitlementToken.issue(
      tokenId: 'tok_user_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      role: UserRole.user,
      scopes: const ['scan', 'vault'],
      privateKey: _authorityKeyPair.privateKey,
      issuer: defaultIssuer,
      validity: const Duration(hours: 24),
    );

    _activeToken = token;
    _rawTokenString = token.toCompactToken();
    _subject = subject;
    _role = UserRole.user;
    _scopes = token.scopes;
    _isAuthenticated = false;
    _denialReason = "Access Denied: Subject '$subject' holds role 'user'. Administrator privileges required.";
    notifyListeners();
  }

  /// Validates and authenticates using a compact 3-part entitlement token string.
  bool authenticateWithToken(String rawToken) {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) {
      _isAuthenticated = false;
      _denialReason = 'Token cannot be empty';
      notifyListeners();
      return false;
    }

    final parsed = EntitlementToken.tryParse(trimmed);
    if (parsed == null) {
      _isAuthenticated = false;
      _denialReason = 'Invalid token format. Expected compact 3-part JWT.';
      notifyListeners();
      return false;
    }

    final verification = parsed.verify(publicKey: _authorityKeyPair.publicKey);
    if (!verification.isValid) {
      _isAuthenticated = false;
      _denialReason = verification.reason ?? 'Cryptographic verification failed.';
      notifyListeners();
      return false;
    }

    if (verification.role != UserRole.admin) {
      _isAuthenticated = false;
      _denialReason = "Access Denied: Role '${verification.role?.name}' lacks administrator privileges.";
      notifyListeners();
      return false;
    }

    _activeToken = parsed;
    _rawTokenString = trimmed;
    _subject = verification.subject ?? 'admin@enterprise.corp';
    _role = verification.role!;
    _scopes = verification.scopes;
    _isAuthenticated = true;
    _denialReason = null;
    notifyListeners();
    return true;
  }

  /// Clears credentials and signs out to unauthenticated state.
  void signOut() {
    _activeToken = null;
    _rawTokenString = null;
    _isAuthenticated = false;
    _denialReason = 'Signed out. Operator authentication required.';
    _subject = 'anonymous';
    _role = UserRole.user;
    _scopes = const [];
    notifyListeners();
  }

  /// Simulates an expired token for security verification.
  void simulateExpiredToken() {
    final expiredToken = EntitlementToken.issue(
      tokenId: 'tok_exp_${DateTime.now().millisecondsSinceEpoch}',
      subject: 'admin@enterprise.corp',
      role: UserRole.admin,
      scopes: const ['generate', 'batch'],
      privateKey: _authorityKeyPair.privateKey,
      issuer: defaultIssuer,
      validity: const Duration(seconds: -10), // already expired
    );

    _activeToken = expiredToken;
    _rawTokenString = expiredToken.toCompactToken();
    _isAuthenticated = false;
    _denialReason = 'Entitlement token has expired. Re-authentication required.';
    notifyListeners();
  }
}
