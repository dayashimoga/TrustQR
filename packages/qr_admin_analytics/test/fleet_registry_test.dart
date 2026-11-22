import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('FleetDevice Tests', () {
    test('Calculates active/inactive status and updates heartbeats correctly', () {
      final now = DateTime.utc(2026, 11, 22, 12, 0);
      final device = FleetDevice(
        deviceId: 'dev_01',
        deviceName: 'Pixel 8 Pro',
        os: 'Android 14',
        appVersion: '1.0.0',
        registeredAt: now.subtract(const Duration(days: 5)),
        lastActiveAt: now.subtract(const Duration(minutes: 2)),
      );

      expect(device.isRevoked, isFalse);
      expect(device.isActive(now: now), isTrue);
      expect(device.lastSeenAt, equals(device.lastActiveAt));

      // Device not seen for > 15 minutes is inactive
      final oldDevice = device.copyWith(
        lastActiveAt: now.subtract(const Duration(minutes: 20)),
      );
      expect(oldDevice.isActive(now: now), isFalse);

      // Revoked device is not active
      final revokedDevice = device.copyWith(isRevoked: true);
      expect(revokedDevice.isActive(now: now), isFalse);

      // Serialization
      final json = device.toJson();
      final restored = FleetDevice.fromJson(json);
      expect(restored.deviceId, equals(device.deviceId));
      expect(restored.deviceName, equals(device.deviceName));
      expect(restored.os, equals(device.os));
      expect(restored.appVersion, equals(device.appVersion));
    });
  });

  group('TrustQrTokenRecord Tests', () {
    test('Calculates active/expired/revoked status and serializes correctly', () {
      final now = DateTime.utc(2026, 11, 22, 12, 0);
      final token = TrustQrTokenRecord(
        tokenId: 'tok_01',
        subject: 'admin@institution.corp',
        role: UserRole.admin,
        issuer: 'auth_authority',
        issuedAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 23)),
      );

      expect(token.isRevoked, isFalse);
      expect(token.isExpired(now), isFalse);
      expect(token.isActive(now), isTrue);
      expect(token.status(now), equals('active'));

      // Expired token
      final expiredToken = token.copyWith(
        expiresAt: now.subtract(const Duration(minutes: 10)),
      );
      expect(expiredToken.isExpired(now), isTrue);
      expect(expiredToken.isActive(now), isFalse);
      expect(expiredToken.status(now), equals('expired'));

      // Revoked token
      final revokedToken = token.copyWith(isRevoked: true);
      expect(revokedToken.status(now), equals('revoked'));

      // Serialization
      final json = token.toJson();
      final restored = TrustQrTokenRecord.fromJson(json);
      expect(restored.tokenId, equals(token.tokenId));
      expect(restored.subject, equals(token.subject));
      expect(restored.role, equals(token.role));
      expect(restored.issuer, equals(token.issuer));
    });
  });

  group('FleetRegistry Tests', () {
    test('Manages devices and token lifecycle and aggregates summary correctly', () {
      final registry = FleetRegistry();
      final now = DateTime.utc(2026, 11, 22, 12, 0);

      // Register devices
      registry.registerDevice(
        deviceId: 'dev_android',
        deviceName: 'Galaxy S24',
        os: 'Android',
        appVersion: '1.0.0',
        registeredAt: now,
      );
      registry.registerDevice(
        deviceId: 'dev_ios',
        deviceName: 'iPhone 15 Pro',
        os: 'iOS',
        appVersion: '1.0.0',
        registeredAt: now,
      );
      registry.registerDevice(
        deviceId: 'dev_win',
        deviceName: 'Dell XPS 15',
        os: 'Windows',
        appVersion: '1.0.0',
        registeredAt: now,
      );

      expect(registry.deviceCount, equals(3));
      expect(registry.devices.length, equals(3));
      expect(registry.getDevice('dev_android'), isNotNull);

      // Update existing dev_android registration
      final updatedAndroid = registry.registerDevice(
        deviceId: 'dev_android',
        deviceName: 'Galaxy S24 Ultra',
        os: 'Android',
        appVersion: '1.0.1',
      );
      expect(updatedAndroid.deviceName, equals('Galaxy S24 Ultra'));
      expect(updatedAndroid.appVersion, equals('1.0.1'));

      // Heartbeat dev_android
      final updatedHb = registry.recordHeartbeat('dev_android', seenAt: now, scans: 5, threats: 1);
      expect(updatedHb, isNotNull);
      expect(updatedHb?.scansRecorded, equals(5));
      expect(updatedHb?.threatsEncountered, equals(1));
      // Non-existent device heartbeat returns null
      expect(registry.recordHeartbeat('unknown_id'), isNull);

      // Revoke dev_win
      final revokedDev = registry.revokeDevice('dev_win', reason: 'Hardware lost');
      expect(revokedDev?.isRevoked, isTrue);
      expect(revokedDev?.revocationReason, equals('Hardware lost'));

      // Unrevoke dev_win
      final unrevoked = registry.unrevokeDevice('dev_win');
      expect(unrevoked?.isRevoked, isFalse);

      // Revoke dev_win again
      registry.revokeDevice('dev_win', reason: 'Decommissioned');

      // Query devices with filters
      final activeDevices = registry.listDevices(isRevoked: false);
      expect(activeDevices.length, equals(2));
      final revokedDevices = registry.listDevices(isRevoked: true);
      expect(revokedDevices.length, equals(1));
      expect(revokedDevices.first.deviceId, equals('dev_win'));
      final androidDevices = registry.listDevices(os: 'android');
      expect(androidDevices.length, equals(1));

      // Register tokens
      registry.registerToken(
        TrustQrTokenRecord(
          tokenId: 'tok_01',
          subject: 'daya@admin.corp',
          role: UserRole.admin,
          issuer: 'master_auth',
          issuedAt: now,
          expiresAt: now.add(const Duration(hours: 12)),
        ),
      );
      registry.registerToken(
        TrustQrTokenRecord(
          tokenId: 'tok_02',
          subject: 'daya@admin.corp',
          role: UserRole.admin,
          issuer: 'master_auth',
          issuedAt: now,
          expiresAt: now.add(const Duration(hours: 12)),
        ),
      );
      registry.registerToken(
        TrustQrTokenRecord(
          tokenId: 'tok_03',
          subject: 'scanner_guest@user.corp',
          role: UserRole.user,
          issuer: 'guest_auth',
          issuedAt: now.subtract(const Duration(days: 2)),
          expiresAt: now.subtract(const Duration(days: 1)), // Expired
        ),
      );

      expect(registry.tokenCount, equals(3));
      expect(registry.tokens.length, equals(3));
      expect(registry.getToken('tok_01'), isNotNull);
      expect(registry.isTokenValid('tok_01', now), isTrue);
      expect(registry.isTokenRevoked('tok_01'), isFalse);
      expect(registry.isTokenValid('unknown_tok'), isFalse);

      // Revoke single token
      final revToken = registry.revokeToken('tok_01', reason: 'Key rotation');
      expect(revToken?.isRevoked, isTrue);
      expect(registry.isTokenRevoked('tok_01'), isTrue);

      // Batch revoke by issuer
      final batchCount = registry.batchRevoke(
        issuer: 'master_auth',
        role: UserRole.admin,
        expiredBefore: now.add(const Duration(days: 1)),
        reason: 'Issuer key rollover',
      );
      expect(batchCount, equals(1)); // tok_02

      // List tokens with filters
      final validTokens = registry.listTokens(isValid: true);
      expect(validTokens, isEmpty); // tok_01 revoked, tok_02 revoked, tok_03 expired

      final adminTokens = registry.listTokens(role: UserRole.admin, issuer: 'master_auth');
      expect(adminTokens.length, equals(2));

      // Summarize
      final summary = registry.summarize(now);
      expect(summary.totalDevices, equals(3));
      expect(summary.activeDevices, equals(2));
      expect(summary.revokedDevices, equals(1));
      expect(summary.totalTokens, equals(3));
      expect(summary.activeTokens, equals(0));
      expect(summary.revokedTokens, equals(2));
      expect(summary.expiredTokens, equals(1));
      expect(summary.devicesByOs['Android'], equals(1));
      expect(summary.devicesByOs['iOS'], equals(1));
      expect(summary.devicesByOs['Windows'], equals(1));

      // Serialization round-trip
      final json = summary.toJson();
      final restored = FleetSummary.fromJson(json);
      expect(restored.totalDevices, equals(3));
      expect(restored.revokedDevices, equals(1));
      expect(restored.devicesByOs['Android'], equals(1));

      // Clear
      registry.clear();
      expect(registry.deviceCount, equals(0));
      expect(registry.tokenCount, equals(0));
    });
  });
}
