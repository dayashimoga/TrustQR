import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/analytics_controller.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';

void main() {
  group('AnalyticsController Unit Tests', () {
    late AnalyticsController controller;

    setUp(() {
      controller = AnalyticsController();
    });

    test('initializes with populated fleet telemetry and verified audit trail', () {
      expect(controller.totalScans, greaterThan(0));
      expect(controller.totalGenerations, greaterThan(0));
      expect(controller.totalThreats, greaterThan(0));
      expect(controller.activeDevices, greaterThan(0));
      expect(controller.threatRate, greaterThan(0.0));
      expect(controller.fleetDevices.length, greaterThanOrEqualTo(5));
      expect(controller.fleetTokens.length, greaterThanOrEqualTo(3));
      expect(controller.auditLogs.length, greaterThanOrEqualTo(3));
      expect(controller.isAuditVerified, isTrue);
      expect(controller.interval, equals(TimeSeriesBucketInterval.daily));
    });

    test('setInterval updates time-series bucket interval and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setInterval(TimeSeriesBucketInterval.hourly);
      expect(controller.interval, equals(TimeSeriesBucketInterval.hourly));
      expect(notified, isTrue);

      controller.setInterval(TimeSeriesBucketInterval.weekly);
      expect(controller.interval, equals(TimeSeriesBucketInterval.weekly));

      controller.setInterval(TimeSeriesBucketInterval.monthly);
      expect(controller.interval, equals(TimeSeriesBucketInterval.monthly));
    });

    test('revokeDevice and restoreDevice modify device status and log audit entries', () {
      final initialLogCount = controller.auditLogs.length;

      // Revoke
      controller.revokeDevice('dev_android_pixel8_01');
      final revokedDevice = controller.fleetDevices.firstWhere((d) => d.deviceId == 'dev_android_pixel8_01');
      expect(revokedDevice.isRevoked, isTrue);
      expect(controller.auditLogs.length, equals(initialLogCount + 1));
      expect(controller.auditLogs.last.action, equals('REVOKE_DEVICE'));

      // Restore
      controller.restoreDevice('dev_android_pixel8_01');
      final restoredDevice = controller.fleetDevices.firstWhere((d) => d.deviceId == 'dev_android_pixel8_01');
      expect(restoredDevice.isRevoked, isFalse);
      expect(controller.auditLogs.length, equals(initialLogCount + 2));
      expect(controller.auditLogs.last.action, equals('RESTORE_DEVICE'));
    });

    test('revokeToken updates token status and records audit action', () {
      final initialCount = controller.auditLogs.length;

      controller.revokeToken('tok_auth_001');
      final token = controller.fleetTokens.firstWhere((t) => t.tokenId == 'tok_auth_001');
      expect(token.isRevoked, isTrue);
      expect(controller.auditLogs.length, equals(initialCount + 1));
      expect(controller.auditLogs.last.action, equals('REVOKE_TOKEN'));
    });

    test('verifyAuditLedger verifies all HMAC-SHA256 signatures', () {
      final isValid = controller.verifyAuditLedger();
      expect(isValid, isTrue);
      expect(controller.isAuditVerified, isTrue);
      expect(controller.auditVerifiedCount, equals(controller.auditLogs.length));
    });

    test('exports canonical reports across JSON and all 4 CSV formats', () {
      // 1. JSON Report
      final json = controller.exportCanonicalJson();
      expect(json, contains('reportId'));
      expect(json, contains('sha256Fingerprint'));
      expect(controller.lastExportType, equals('JSON Report'));

      // 2. Time-Series CSV
      final tsCsv = controller.exportTimeSeriesCsv();
      expect(tsCsv, contains('bucket_timestamp,interval,scans,generations'));
      expect(controller.lastExportType, equals('Time Series CSV'));

      // 3. Payload Breakdown CSV
      final payloadCsv = controller.exportPayloadBreakdownCsv();
      expect(payloadCsv, contains('payload_type,count,percentage'));
      expect(controller.lastExportType, equals('Payload Breakdown CSV'));

      // 4. Threats CSV
      final threatsCsv = controller.exportThreatsCsv();
      expect(threatsCsv, contains('total_audited'));
      expect(controller.lastExportType, equals('Threat Firewall CSV'));

      // 5. Fleet Inventory CSV
      final fleetCsv = controller.exportFleetInventoryCsv();
      expect(fleetCsv, contains('device_id,device_name'));
      expect(controller.lastExportType, equals('Fleet Inventory CSV'));
    });
  });
}
