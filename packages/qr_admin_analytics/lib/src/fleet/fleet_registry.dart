import 'package:qr_core/qr_core.dart';
import 'fleet_device.dart';
import 'trust_qr_token_record.dart';

/// Aggregated fleet summary metrics.
class FleetSummary {
  final int totalDevices;
  final int activeDevices;
  final int revokedDevices;
  final int totalTokens;
  final int activeTokens;
  final int revokedTokens;
  final int expiredTokens;
  final Map<String, int> devicesByOs;

  const FleetSummary({
    required this.totalDevices,
    required this.activeDevices,
    required this.revokedDevices,
    required this.totalTokens,
    required this.activeTokens,
    required this.revokedTokens,
    required this.expiredTokens,
    required this.devicesByOs,
  });

  Map<String, dynamic> toJson() => {
    'totalDevices': totalDevices,
    'activeDevices': activeDevices,
    'revokedDevices': revokedDevices,
    'totalTokens': totalTokens,
    'activeTokens': activeTokens,
    'revokedTokens': revokedTokens,
    'expiredTokens': expiredTokens,
    'devicesByOs': devicesByOs,
  };

  factory FleetSummary.fromJson(Map<String, dynamic> json) => FleetSummary(
        totalDevices: (json['totalDevices'] as num?)?.toInt() ?? 0,
        activeDevices: (json['activeDevices'] as num?)?.toInt() ?? 0,
        revokedDevices: (json['revokedDevices'] as num?)?.toInt() ?? 0,
        totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
        activeTokens: (json['activeTokens'] as num?)?.toInt() ?? 0,
        revokedTokens: (json['revokedTokens'] as num?)?.toInt() ?? 0,
        expiredTokens: (json['expiredTokens'] as num?)?.toInt() ?? 0,
        devicesByOs: (json['devicesByOs'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            const {},
      );
}

/// Registry managing active fleet hardware devices, TrustQR tokens, and cryptographic revocations.
class FleetRegistry {
  final Map<String, FleetDevice> _devices = {};
  final Map<String, TrustQrTokenRecord> _tokens = {};

  FleetRegistry();

  List<FleetDevice> get devices => _devices.values.toList();
  List<TrustQrTokenRecord> get tokens => _tokens.values.toList();
  int get deviceCount => _devices.length;
  int get tokenCount => _tokens.length;

  void clear() {
    _devices.clear();
    _tokens.clear();
  }

  // ---------------------------------------------------------------------------
  // Device Management
  // ---------------------------------------------------------------------------

  /// Registers or updates a device in the fleet registry.
  FleetDevice registerDevice({
    required String deviceId,
    required String deviceName,
    required String os,
    required String appVersion,
    DateTime? registeredAt,
  }) {
    final now = DateTime.now().toUtc();
    final existing = _devices[deviceId];
    final device = FleetDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      os: os,
      appVersion: appVersion,
      registeredAt: existing?.registeredAt ?? registeredAt?.toUtc() ?? now,
      lastActiveAt: now,
      isRevoked: existing?.isRevoked ?? false,
      revocationReason: existing?.revocationReason,
      scansRecorded: existing?.scansRecorded ?? 0,
      threatsEncountered: existing?.threatsEncountered ?? 0,
    );

    _devices[deviceId] = device;
    return device;
  }

  /// Records heartbeat and scan activity telemetry from a fleet device.
  FleetDevice? recordDeviceHeartbeat(
    String deviceId, {
    int scans = 0,
    int threats = 0,
    DateTime? seenAt,
  }) {
    final device = _devices[deviceId];
    if (device != null) {
      final updated = device.copyWith(
        lastActiveAt: (seenAt ?? DateTime.now()).toUtc(),
        scansRecorded: device.scansRecorded + scans,
        threatsEncountered: device.threatsEncountered + threats,
      );
      _devices[deviceId] = updated;
      return updated;
    }
    return null;
  }

  /// Alias for [recordDeviceHeartbeat].
  FleetDevice? recordHeartbeat(
    String deviceId, {
    DateTime? seenAt,
    int scans = 0,
    int threats = 0,
  }) =>
      recordDeviceHeartbeat(deviceId, scans: scans, threats: threats, seenAt: seenAt);

  /// Revokes a device's access to the institutional fleet.
  FleetDevice? revokeDevice(String deviceId, {String reason = 'Administrative revocation'}) {
    final device = _devices[deviceId];
    if (device == null) return null;

    final updated = device.copyWith(
      isRevoked: true,
      revocationReason: reason,
      lastActiveAt: DateTime.now().toUtc(),
    );
    _devices[deviceId] = updated;
    return updated;
  }

  /// Unrevokes/restores a revoked device's access to the fleet.
  FleetDevice? unrevokeDevice(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) return null;

    final updated = device.copyWith(
      isRevoked: false,
      revocationReason: null,
      lastActiveAt: DateTime.now().toUtc(),
    );
    _devices[deviceId] = updated;
    return updated;
  }

  /// Lists all registered devices matching optional criteria.
  List<FleetDevice> listDevices({bool? isRevoked, String? os}) {
    return _devices.values.where((d) {
      if (isRevoked != null && d.isRevoked != isRevoked) return false;
      if (os != null && d.os.toLowerCase() != os.toLowerCase()) return false;
      return true;
    }).toList();
  }

  FleetDevice? getDevice(String deviceId) => _devices[deviceId];

  // ---------------------------------------------------------------------------
  // Token Management & Cryptographic Revocation
  // ---------------------------------------------------------------------------

  /// Enrolls a new or issued TrustQR token record.
  TrustQrTokenRecord registerToken(TrustQrTokenRecord token) {
    _tokens[token.tokenId] = token;
    return token;
  }

  /// Checks whether a token has been revoked.
  bool isTokenRevoked(String tokenId) {
    final token = _tokens[tokenId];
    return token?.isRevoked ?? false;
  }

  /// Checks whether a token is valid (exists, not revoked, not expired).
  bool isTokenValid(String tokenId, [DateTime? now]) {
    final token = _tokens[tokenId];
    if (token == null) return false;
    return token.isValid(now);
  }

  /// Revokes a single token by ID with a mandatory audit reason.
  TrustQrTokenRecord? revokeToken(String tokenId, {String reason = 'Administrative revocation'}) {
    final token = _tokens[tokenId];
    if (token == null) return null;

    final updated = token.copyWith(
      isRevoked: true,
      revokedAt: DateTime.now().toUtc(),
      revocationReason: reason,
    );
    _tokens[tokenId] = updated;
    return updated;
  }

  /// Batch revokes tokens matching specified criteria (e.g., all tokens issued by a compromised authority).
  int batchRevoke({
    String? issuer,
    UserRole? role,
    DateTime? expiredBefore,
    required String reason,
  }) {
    int count = 0;
    final now = DateTime.now().toUtc();

    for (final entry in _tokens.entries) {
      final token = entry.value;
      if (token.isRevoked) continue;

      bool match = true;
      if (issuer != null && token.issuer != issuer) match = false;
      if (role != null && token.role != role) match = false;
      if (expiredBefore != null && token.expiresAt.isAfter(expiredBefore)) match = false;

      if (match) {
        _tokens[entry.key] = token.copyWith(
          isRevoked: true,
          revokedAt: now,
          revocationReason: reason,
        );
        count++;
      }
    }

    return count;
  }

  /// Lists all registered tokens matching optional criteria.
  List<TrustQrTokenRecord> listTokens({
    bool? isValid,
    UserRole? role,
    String? issuer,
  }) {
    final now = DateTime.now().toUtc();
    return _tokens.values.where((t) {
      if (isValid != null && t.isValid(now) != isValid) return false;
      if (role != null && t.role != role) return false;
      if (issuer != null && t.issuer != issuer) return false;
      return true;
    }).toList();
  }

  TrustQrTokenRecord? getToken(String tokenId) => _tokens[tokenId];

  // ---------------------------------------------------------------------------
  // Summary Metrics
  // ---------------------------------------------------------------------------

  /// Generates real-time fleet aggregated summary metrics.
  FleetSummary getSummary([DateTime? now]) {
    final current = now ?? DateTime.now().toUtc();
    int activeDevs = 0;
    int revokedDevs = 0;
    final osCounts = <String, int>{};

    for (final d in _devices.values) {
      if (d.isRevoked) {
        revokedDevs++;
      } else {
        activeDevs++;
      }
      osCounts[d.os] = (osCounts[d.os] ?? 0) + 1;
    }

    int activeToks = 0;
    int revokedToks = 0;
    int expiredToks = 0;

    for (final t in _tokens.values) {
      if (t.isRevoked) {
        revokedToks++;
      } else if (t.isExpired(current)) {
        expiredToks++;
      } else {
        activeToks++;
      }
    }

    return FleetSummary(
      totalDevices: _devices.length,
      activeDevices: activeDevs,
      revokedDevices: revokedDevs,
      totalTokens: _tokens.length,
      activeTokens: activeToks,
      revokedTokens: revokedToks,
      expiredTokens: expiredToks,
      devicesByOs: osCounts,
    );
  }

  /// Alias for [getSummary].
  FleetSummary summarize([DateTime? now]) => getSummary(now);
}
