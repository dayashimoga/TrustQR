// Universal QR Platform — Admin App End-to-End (E2E) Journey Test
// Exercises the complete administrative & studio workflow:
// Multi-Format QR Studio -> Artistic Customization -> Scannability Simulation ->
// Cryptographic Ed25519 TrustQR Signing -> Multi-Format Asset Export ->
// High-Throughput Batch Generation & ZIP Compilation ->
// Server-Side RBAC Entitlement Enforcement -> Fleet Analytics & HMAC-SHA256 Audit Trail.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/state/batch_controller.dart';
import 'package:admin_app/src/state/auth_controller.dart';
import 'package:admin_app/src/state/admin_nav_controller.dart';
import 'package:admin_app/src/state/analytics_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StudioController studioController;
  late BatchController batchController;
  late AuthController authController;
  late AdminNavController navController;
  late AnalyticsController analyticsController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('admin_e2e_workspace_');
    studioController = StudioController();
    batchController = BatchController();
    authController = AuthController();
    navController = AdminNavController();
    analyticsController = AnalyticsController();
  });

  tearDown(() {
    studioController.dispose();
    batchController.dispose();
    authController.dispose();
    navController.dispose();
    analyticsController.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Admin App E2E Journey Tests', () {
    test('E2E Journey 1: Multi-Format QR Studio, Artistic Styling & Scannability Simulator', () async {
      // 1. Verify initial format and switch through enterprise formats
      expect(studioController.payloadType, equals(QrPayloadType.url));

      studioController.setPayloadType(QrPayloadType.wifi);
      expect(studioController.payloadType, equals(QrPayloadType.wifi));

      studioController.setPayloadType(QrPayloadType.vcard);
      expect(studioController.payloadType, equals(QrPayloadType.vcard));

      studioController.setPayloadType(QrPayloadType.url);
      studioController.urlAddress = 'https://trust.universalqr.corp/enterprise-portal';
      studioController.recalculate();

      // 2. Apply artistic theme preset and styling
      studioController.applyTemplate(QrTemplate.emeraldTrust);
      expect(studioController.moduleShape, equals(QrModuleShape.rounded));

      studioController.setEyeStyle(
        frameShape: QrEyeFrameShape.rounded,
        pupilShape: QrEyePupilShape.rounded,
      );
      expect(studioController.eyeFrameShape, equals(QrEyeFrameShape.rounded));

      // 3. Inspect Live Scannability & Contrast Simulator
      final scannability = studioController.scannabilityReport;
      expect(scannability, isNotNull);
      expect(scannability!.overallScore, greaterThanOrEqualTo(70.0));
      expect(scannability.contrastRatio, greaterThan(4.5)); // Exceeds WCAG AA
      expect(scannability.isScannable, isTrue);
      expect(scannability.warningFlags, isNotNull);

      // 4. Test Multi-Format Exporters (PNG, SVG, PDF, BMP)
      final pngBytes = studioController.exportPng();
      final svgXml = studioController.exportSvg();
      final pdfBytes = studioController.exportPdf();
      final bmpBytes = studioController.exportBmp();

      expect(pngBytes, isNotNull);
      expect(pngBytes.length, greaterThan(50));
      expect(svgXml, isNotNull);
      expect(svgXml.contains('<svg'), isTrue);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(50));
      expect(bmpBytes, isNotNull);
      expect(bmpBytes.length, greaterThan(50));
    });

    test('E2E Journey 2: Institutional Ed25519 TrustQR Signing Pipeline', () async {
      // 1. Configure TrustQR authority identity
      studioController.setTrustQrEnabled(true);
      expect(studioController.isTrustQrEnabled, isTrue);

      studioController.setAuthorityDetails(
        issuer: 'identity.universalqr.corp',
        keyId: 'corp-key-prod-2026',
      );

      // 2. Check Ed25519 cryptographic keypair
      expect(studioController.activeKeyPair.keyId, equals('corp-key-prod-2026'));

      // 3. Obtain signed TrustQR container URI
      final signedUri = studioController.effectivePayload;
      expect(signedUri.startsWith('trustqr://v1?'), isTrue);

      // 4. Verify signature validity
      final envelope = studioController.signedEnvelope;
      expect(envelope, isNotNull);
      final verification = studioController.envelopeVerification;
      expect(verification, isNotNull);
      expect(verification!.isValid, isTrue);
    });

    test('E2E Journey 3: High-Throughput Batch QR Generation & PKZIP Archive Packaging', () async {
      // 1. Load Preset Assets
      batchController.loadAssetTagsPreset();
      expect(batchController.itemCount, equals(5));
      expect(batchController.items.first.title, contains('MacBook Pro M3 Max'));

      // 2. Parse custom CSV input
      batchController.clearItems();
      const customCsv = '''
id,content,title
RACK-01,https://datacenter.universalqr.corp/rack-alpha,Server Rack Alpha
BADGE-101,VISITOR-PASS-ALPHA-101,Visitor Badge 101
WIFI-HQ,WIFI:T:WPA;S:HQGuest;P:CyberSecret2026;;,Guest WiFi HQ
''';
      batchController.parseCsv(customCsv);
      expect(batchController.itemCount, equals(3));

      // 3. Select Output Format (SVG)
      batchController.setSelectedFormat(ExportFormat.svg);
      expect(batchController.selectedFormat, equals(ExportFormat.svg));

      // 4. Execute Batch Generation & PKZIP Export
      await batchController.generateBatch();
      expect(batchController.lastZipBytes, isNotNull);
      expect(batchController.lastZipBytes!.length, greaterThan(100));
      expect(batchController.lastZipSha256, isNotNull);
      expect(batchController.lastZipSha256!.length, equals(64)); // 256-bit hex hash

      // 5. Verify batch items have scannability ratings
      for (final item in batchController.items) {
        final report = batchController.getScannability(item.id);
        expect(report, isNotNull);
        expect(report!.overallScore, greaterThan(0));
      }
    });

    test('E2E Journey 4: Cryptographic RBAC Entitlements, Fleet Telemetry & HMAC-SHA256 Audit Trail', () async {
      // 1. Test authenticated admin session
      expect(authController.isAuthenticated, isTrue);
      expect(authController.isAdmin, isTrue);
      expect(authController.role, equals(UserRole.admin));

      // Simulate restricted user
      authController.signInAsUser(subject: 'contractor@external.org');
      expect(authController.isAuthenticated, isFalse);
      expect(authController.isAdmin, isFalse);
      expect(authController.role, equals(UserRole.user));

      // Re-authenticate as Administrator
      authController.signInAsAdmin(subject: 'cso@enterprise.corp');
      expect(authController.isAuthenticated, isTrue);
      expect(authController.isAdmin, isTrue);
      expect(authController.role, equals(UserRole.admin));

      // 2. Multi-Pane Navigation Workspace
      expect(navController.currentPane, equals(AdminPane.studio));
      navController.selectPane(AdminPane.analytics);
      expect(navController.currentPane, equals(AdminPane.analytics));
      navController.selectPane(AdminPane.audit);
      expect(navController.currentPane, equals(AdminPane.audit));

      // 3. Inspect Fleet Telemetry
      expect(analyticsController.totalScans, greaterThan(0));
      expect(analyticsController.totalGenerations, greaterThan(0));
      expect(analyticsController.totalThreats, greaterThan(0));
      expect(analyticsController.activeDevices, greaterThan(0));

      // Test time interval switching
      analyticsController.setInterval(TimeSeriesBucketInterval.weekly);
      expect(analyticsController.interval, equals(TimeSeriesBucketInterval.weekly));

      // 4. Test Canonical Exporters
      final jsonReport = analyticsController.exportCanonicalJson();
      expect(jsonReport.contains('reportId') || jsonReport.contains('total_scans') || jsonReport.contains('telemetry'), isTrue);

      final scansCsv = analyticsController.exportTimeSeriesCsv();
      expect(scansCsv.contains('bucket_timestamp') || scansCsv.contains('scans'), isTrue);

      final threatsCsv = analyticsController.exportThreatsCsv();
      expect(threatsCsv.contains('total_audited'), isTrue);

      // 5. Inspect Cryptographic HMAC-SHA256 Audit Trail
      final isAuditIntact = analyticsController.verifyAuditLedger();
      expect(isAuditIntact, isTrue);

      // 6. Device Quarantine & Restoration Controls
      const deviceId = 'dev_android_pixel8_01';
      analyticsController.revokeDevice(deviceId);
      expect(analyticsController.fleetDevices.firstWhere((d) => d.deviceId == deviceId).isRevoked, isTrue);

      analyticsController.restoreDevice(deviceId);
      expect(analyticsController.fleetDevices.firstWhere((d) => d.deviceId == deviceId).isRevoked, isFalse);
    });
  });
}
