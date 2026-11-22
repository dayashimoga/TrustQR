import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/src/widgets/threat_hud_modal.dart';

void main() {
  group('ThreatHudModal Visual & Interaction Tests', () {
    testWidgets('Renders safe payload with score gauge, unsigned badge, and save action', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool dismissed = false;
      bool saved = false;

      const assessment = ThreatAssessment(
        safetyScore: 95,
        threatLevel: SecurityThreatLevel.safe,
        findings: [],
        isActionAllowed: true,
        summary: 'Payload is safe',
      );

      final result = PipelineScanResult(
        rawContent: 'https://apex-security.org',
        payload: UrlPayload(uri: Uri.parse('https://apex-security.org')),
        threatAssessment: assessment,
        vaultItem: null,
        isDeduplicated: false,
        latencyMs: 5.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            CyberLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          home: Scaffold(
            body: ThreatHudModal(
              result: result,
              onDismiss: () => dismissed = true,
              onSaveToVault: () => saved = true,
            ),
          ),
        ),
      );

      expect(find.text('THREAT FIREWALL INSPECTION'), findsOneWidget);
      expect(find.text('THREAT STATUS: SAFE'), findsOneWidget);
      expect(find.text('95/100'), findsOneWidget);
      expect(find.text('Unsigned Standard QR'), findsOneWidget);

      await tester.ensureVisible(find.text('Save to Vault'));
      expect(find.text('Save to Vault'), findsOneWidget);

      // Save to Vault
      await tester.tap(find.text('Save to Vault'));
      await tester.pump();
      expect(saved, isTrue);
      expect(find.text('Saved in Vault'), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('Dismiss'));
      expect(dismissed, isTrue);
    });

    testWidgets('Renders quarantined critical payload with override unlock checkbox', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const assessment = ThreatAssessment(
        safetyScore: 15,
        threatLevel: SecurityThreatLevel.critical,
        findings: [
          ThreatFinding(
            code: 'MALICIOUS_SCHEME',
            severity: SecurityThreatLevel.critical,
            title: 'MALICIOUS_SCHEME',
            description: 'Dangerous script execution scheme',
            remediationRecommendation: 'Do not execute',
          ),
          ThreatFinding(
            code: 'PHISHING_PATTERN',
            severity: SecurityThreatLevel.critical,
            title: 'PHISHING_PATTERN',
            description: 'Known phishing threat pattern',
            remediationRecommendation: 'Do not visit',
          ),
        ],
        isActionAllowed: false,
        summary: 'Critical threat detected',
      );

      final result = PipelineScanResult(
        rawContent: 'javascript:alert(1)',
        payload: const PlainTextPayload(text: 'javascript:alert(1)'),
        threatAssessment: assessment,
        vaultItem: null,
        isDeduplicated: false,
        latencyMs: 5.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            CyberLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          home: Scaffold(
            body: ThreatHudModal(result: result),
          ),
        ),
      );

      expect(find.text('CRITICAL THREAT // ACCESS QUARANTINED'), findsOneWidget);
      expect(find.text('QUARANTINE PROTECTION ACTIVE'), findsOneWidget);
      expect(find.text('MALICIOUS_SCHEME'), findsOneWidget);
      expect(find.text('PHISHING_PATTERN'), findsOneWidget);

      // Override checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pump();
      // Checkbox is toggled
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
    });

    testWidgets('Renders authentic TrustQR envelope badge with issuer and key ID', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final envelope = TrustQrEnvelope(
        payload: 'https://authority.gov/badge/001',
        issuer: 'Federal Transit Administration',
        keyId: 'ed25519:transit:key1',
        createdAt: DateTime(2026, 11, 22),
        algorithm: CryptoAlgorithm.ed25519,
        signature: 'mockSigBase64==',
      );

      const assessment = ThreatAssessment(
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        findings: [],
        isActionAllowed: true,
        summary: 'TrustQR Verified',
      );

      final rawEnvelopeString = envelope.toUriString();

      final result = PipelineScanResult(
        rawContent: rawEnvelopeString,
        payload: UrlPayload(uri: Uri.parse('https://authority.gov/badge/001')),
        threatAssessment: assessment,
        vaultItem: null,
        isDeduplicated: false,
        latencyMs: 5.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            CyberLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          home: Scaffold(
            body: ThreatHudModal(result: result),
          ),
        ),
      );

      expect(find.text('Federal Transit Administration'), findsOneWidget);
      expect(find.text('TRUSTQR VERIFIED'), findsOneWidget);
    });
  });
}
