import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/src/state/scanner_controller.dart';
import 'package:user_app/src/views/scanner_workspace_view.dart';
import 'package:user_app/src/widgets/threat_hud_modal.dart';

void main() {
  group('ScannerWorkspaceView Visual & Viewport Tests', () {
    late QrVault vault;
    late ScannerController controller;

    setUp(() async {
      vault = QrVault.inMemory(
        integrityKey: CryptoKeyPair.generateHmacKey().privateKey,
      );
      await vault.init();
      final pipeline = ScanToVaultPipeline(
        scanner: UniversalQrScannerEngine(),
        firewall: QrThreatFirewall(),
        vault: vault,
      );
      controller = ScannerController(pipeline: pipeline);
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          CyberLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      );
    }

    testWidgets('Renders HUD reticle, telemetry header, torch, and incognito controls', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(ScannerWorkspaceView(controller: controller)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HudScannerReticle), findsOneWidget);
      expect(find.text('FIREWALL // ZERO-TRUST'), findsOneWidget);
      expect(find.text('VIEWFINDER READY'), findsOneWidget);
      expect(find.text('Decode Image File'), findsOneWidget);
      expect(find.text('Batch Multi-QR'), findsOneWidget);

      // Toggle torch
      final torchButton = find.byTooltip('Toggle Flashlight / Torch');
      expect(torchButton, findsOneWidget);
      await tester.tap(torchButton);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isTorchOn, isTrue);
      expect(find.text('LIGHT SOURCE ACTIVE'), findsOneWidget);

      // Toggle incognito
      final incognitoButton = find.byTooltip('Toggle Incognito Mode (Bypass Vault Save)');
      expect(incognitoButton, findsOneWidget);
      await tester.tap(incognitoButton);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isIncognito, isTrue);
    });

    testWidgets('Executes manual payload scan and displays ThreatHudModal', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(ScannerWorkspaceView(controller: controller)));
      await tester.pump(const Duration(milliseconds: 100));

      // Enter manual URL
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'https://test-cyber.dev');
      await tester.tap(find.text('Inspect'));
      await tester.pump(const Duration(milliseconds: 200));

      // ThreatHudModal should appear
      expect(find.byType(ThreatHudModal), findsOneWidget);
      expect(find.text('THREAT FIREWALL INSPECTION'), findsOneWidget);
      expect(find.text('https://test-cyber.dev'), findsOneWidget);

      // Dismiss modal
      await tester.ensureVisible(find.text('Dismiss'));
      await tester.tap(find.text('Dismiss'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ThreatHudModal), findsNothing);
      expect(controller.activeScanResult, isNull);
    });

    testWidgets('Triggers file decode and multi-QR scan buttons', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(ScannerWorkspaceView(controller: controller)));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap decode image file
      await tester.tap(find.text('Decode Image File'));
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && controller.isProcessing; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.lastErrorMessage, isNotNull);

      // Tap batch multi-QR
      await tester.tap(find.text('Batch Multi-QR'));
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && controller.isProcessing; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.lastErrorMessage, isNotNull);
    });

    testWidgets('Manual input textfield onSubmitted triggers scan', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(ScannerWorkspaceView(controller: controller)));
      await tester.pump(const Duration(milliseconds: 100));

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'https://submit-test.dev');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ThreatHudModal), findsOneWidget);
    });

    testWidgets('Renders MultiQrPickerDialog and allows candidate selection and dismiss', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(ScannerWorkspaceView(controller: controller)));
      await tester.pump(const Duration(milliseconds: 100));

      final candidates = [
        PipelineScanResult(
          rawContent: 'https://site-a.org',
          payload: UrlPayload(uri: Uri.parse('https://site-a.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 90,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          latencyMs: 1.0,
          timestamp: DateTime.now(),
        ),
        PipelineScanResult(
          rawContent: 'https://site-b.org',
          payload: UrlPayload(uri: Uri.parse('https://site-b.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 85,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          latencyMs: 1.0,
          timestamp: DateTime.now(),
        ),
      ];

      controller.setCandidatesForTesting(candidates);
      await tester.pump(const Duration(milliseconds: 100));

      // MultiQrPickerDialog is visible
      expect(find.text('MULTI-QR DETECTED (2 CODES)'), findsOneWidget);

      // Select candidate #1
      await tester.tap(find.text('https://site-a.org'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.activeScanResult?.rawContent, equals('https://site-a.org'));
      expect(find.byType(ThreatHudModal), findsOneWidget);
    });
  });
}
