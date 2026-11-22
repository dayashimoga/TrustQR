import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('Fleet Governance Stress & Lifecycle Tests', () {
    test('Simulates 1,200 devices, 3,000 tokens, and high-frequency heartbeats', () {
      final registry = FleetRegistry();
      final now = DateTime.utc(2026, 11, 22, 10, 0);
      final osList = ['Android', 'iOS', 'Windows', 'Linux', 'macOS'];

      // 1. High-density device registration (1,200 devices)
      for (var i = 0; i < 1200; i++) {
        final os = osList[i % osList.length];
        registry.registerDevice(
          deviceId: 'device_$i',
          deviceName: 'Hardware Terminal #$i',
          os: os,
          appVersion: '1.${i % 5}.0',
          registeredAt: now.subtract(Duration(days: (i % 30) + 1)),
        );
      }

      expect(registry.deviceCount, equals(1200));
      expect(registry.devices.length, equals(1200));

      // 2. High-frequency telemetry heartbeat streaming (1,200 devices updated)
      for (var i = 0; i < 1200; i++) {
        final scans = (i * 7) % 50;
        final threats = (i % 10 == 0) ? 1 : 0;
        final updated = registry.recordHeartbeat(
          'device_$i',
          seenAt: now,
          scans: scans,
          threats: threats,
        );
        expect(updated, isNotNull);
        expect(updated!.scansRecorded, equals(scans));
        expect(updated.threatsEncountered, equals(threats));
      }

      // 3. Token enrollment (3,000 tokens across 3 authorities)
      final issuers = ['auth_us_east', 'auth_eu_central', 'auth_ap_south'];
      for (var i = 0; i < 3000; i++) {
        final issuer = issuers[i % issuers.length];
        final role = (i % 4 == 0) ? UserRole.admin : UserRole.user;
        final isExpired = i % 10 == 9;
        final issuedAt = now.subtract(const Duration(days: 10));
        final expiresAt = isExpired
            ? now.subtract(const Duration(days: 1))
            : now.add(const Duration(days: 30));

        registry.registerToken(TrustQrTokenRecord(
          tokenId: 'tok_$i',
          subject: 'operator_$i@institution.org',
          role: role,
          issuer: issuer,
          issuedAt: issuedAt,
          expiresAt: expiresAt,
        ));
      }

      expect(registry.tokenCount, equals(3000));
      expect(registry.tokens.length, equals(3000));

      // Pre-revocation summary check
      final preSummary = registry.summarize(now);
      expect(preSummary.totalDevices, equals(1200));
      expect(preSummary.activeDevices, equals(1200));
      expect(preSummary.revokedDevices, equals(0));
      expect(preSummary.totalTokens, equals(3000));
      // Expired tokens: every 10th token -> 300 expired tokens
      expect(preSummary.expiredTokens, equals(300));
      expect(preSummary.activeTokens, equals(2700));
      expect(preSummary.revokedTokens, equals(0));
      expect(preSummary.devicesByOs['Android'], equals(240));
      expect(preSummary.devicesByOs['iOS'], equals(240));
      expect(preSummary.devicesByOs['Windows'], equals(240));
      expect(preSummary.devicesByOs['Linux'], equals(240));
      expect(preSummary.devicesByOs['macOS'], equals(240));

      // 4. Batch cryptographic revocation of compromised authority 'auth_eu_central'
      final stopwatch = Stopwatch()..start();
      final revokedCount = registry.batchRevoke(
        issuer: 'auth_eu_central',
        reason: 'Compromised cryptographic CA key',
      );
      stopwatch.stop();

      // Authority had 1,000 tokens (every 3rd token of 3,000)
      expect(revokedCount, equals(1000));
      // Must execute in less than 50 ms
      expect(stopwatch.elapsedMilliseconds, lessThan(50));

      // Post-revocation summary check
      final postSummary = registry.summarize(now);
      expect(postSummary.revokedTokens, equals(1000));
      // Remaining active: 2700 - (1000 - 100 expired in that authority) = 1800 active
      expect(postSummary.activeTokens, equals(1800));

      // 5. Individual hardware device revocation & unrevocation
      final revokedDev = registry.revokeDevice('device_42', reason: 'Stolen device');
      expect(revokedDev?.isRevoked, isTrue);
      expect(registry.listDevices(isRevoked: true).length, equals(1));

      final restoredDev = registry.unrevokeDevice('device_42');
      expect(restoredDev?.isRevoked, isFalse);
      expect(registry.listDevices(isRevoked: true), isEmpty);

      // 6. Query filtering verification
      final linuxDevices = registry.listDevices(os: 'linux');
      expect(linuxDevices.length, equals(240));

      final macDevices = registry.listDevices(os: 'macOS');
      expect(macDevices.length, equals(240));

      final adminTokens = registry.listTokens(role: UserRole.admin);
      expect(adminTokens.length, equals(750)); // 3000 / 4
    });

    test('Handles edge cases: non-existent devices, double-revocations, and null operations', () {
      final registry = FleetRegistry();

      // Non-existent device operations
      expect(registry.getDevice('none'), isNull);
      expect(registry.recordHeartbeat('none'), isNull);
      expect(registry.revokeDevice('none', reason: 'test'), isNull);
      expect(registry.unrevokeDevice('none'), isNull);

      // Non-existent token operations
      expect(registry.getToken('none'), isNull);
      expect(registry.isTokenRevoked('none'), isFalse);
      expect(registry.isTokenValid('none'), isFalse);
      expect(registry.revokeToken('none', reason: 'test'), isNull);

      // Double-revocation idempotency
      final now = DateTime.utc(2026, 11, 22);
      registry.registerDevice(
        deviceId: 'dev_single',
        deviceName: 'Single Unit',
        os: 'Android',
        appVersion: '1.0.0',
        registeredAt: now,
      );

      final rev1 = registry.revokeDevice('dev_single', reason: 'r1');
      expect(rev1?.isRevoked, isTrue);
      expect(rev1?.revocationReason, equals('r1'));

      final rev2 = registry.revokeDevice('dev_single', reason: 'r2');
      expect(rev2?.isRevoked, isTrue);
      expect(rev2?.revocationReason, equals('r2'));

      // Batch revoke matching zero tokens
      final zeroRevoked = registry.batchRevoke(
        issuer: 'unrelated_issuer',
        reason: 'no-op',
      );
      expect(zeroRevoked, equals(0));
    });
  });
}
