import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/src/widgets/multi_qr_picker_dialog.dart';

void main() {
  group('MultiQrPickerDialog Candidate Selection Tests', () {
    testWidgets('Renders candidates with badges and triggers candidate selection', (tester) async {
      PipelineScanResult? selected;
      bool dismissed = false;

      final candidates = [
        PipelineScanResult(
          rawContent: 'https://site1.org',
          payload: UrlPayload(uri: Uri.parse('https://site1.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 92,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          vaultItem: null,
          isDeduplicated: false,
          latencyMs: 4.0,
          timestamp: DateTime.now(),
        ),
        PipelineScanResult(
          rawContent: 'WIFI:S:GuestNet;T:WPA;P:guest123;;',
          payload: const WifiPayload(ssid: 'GuestNet', password: 'guest123'),
          threatAssessment: const ThreatAssessment(
            safetyScore: 80,
            threatLevel: SecurityThreatLevel.caution,
            findings: [],
            isActionAllowed: true,
            summary: 'Caution',
          ),
          vaultItem: null,
          isDeduplicated: false,
          latencyMs: 4.0,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiQrPickerDialog(
              candidates: candidates,
              onCandidateSelected: (cand) => selected = cand,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('MULTI-QR DETECTED (2 CODES)'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('https://site1.org'), findsOneWidget);
      expect(find.text('WIFI:S:GuestNet;T:WPA;P:guest123;;'), findsOneWidget);

      // Select candidate #2
      await tester.tap(find.text('WIFI:S:GuestNet;T:WPA;P:guest123;;'));
      expect(selected, equals(candidates[1]));

      // Test cancel dismiss
      await tester.tap(find.text('Cancel'));
      expect(dismissed, isTrue);
    });
  });
}
