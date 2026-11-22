import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/widgets/scannability_simulator_card.dart';

class _NullReportEngine extends DefaultQrGeneratorEngine {
  const _NullReportEngine();

  @override
  ScannabilityReport simulateScannability(
    String payload, {
    QrTemplate? template,
    QrModuleShape? moduleShape,
    QrColorConfig? colorConfig,
    QrEyeStyle? eyeStyle,
    QrLogoConfig? logoConfig,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int quietZone = 4,
    double roundTripConfidence = 1.0,
  }) {
    throw Exception('Simulated null report');
  }
}

void main() {
  group('ScannabilitySimulatorCard Widget Tests', () {
    late StudioController controller;

    setUp(() {
      controller = StudioController();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );
    }

    testWidgets('renders scannability score and environmental simulation bars', (tester) async {
      await tester.pumpWidget(createTestApp(ScannabilitySimulatorCard(controller: controller)));

      expect(find.text('Scannability Simulator'), findsOneWidget);
      expect(find.text('Scannability Score:'), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
      expect(find.text('WCAG Contrast'), findsOneWidget);
      expect(find.text('Michelson Index'), findsOneWidget);
      expect(find.text('Logo Occlusion'), findsOneWidget);
      expect(find.text('Quiet Zone'), findsOneWidget);

      expect(find.text('Environmental Stress Simulation'), findsOneWidget);
      expect(find.text('Studio Diffuse Light'), findsOneWidget);
      expect(find.text('Surface Glare Washout'), findsOneWidget);
      expect(find.text('Dim Ambient Lighting'), findsOneWidget);
      expect(find.text('30° Perspective Tilt'), findsOneWidget);
      expect(find.text('Defocus Distance Blur'), findsOneWidget);
    });

    testWidgets('renders fallback when scannability report is null', (tester) async {
      final nullCtrl = StudioController(generator: const _NullReportEngine());
      await tester.pumpWidget(createTestApp(ScannabilitySimulatorCard(controller: nullCtrl)));

      expect(find.text('Calculating scannability metrics...'), findsOneWidget);
    });

    testWidgets('displays active warnings and recommendations under poor contrast', (tester) async {
      // Set foreground and background to near-identical dark colors
      controller.setColors(foreground: 0xFF101010, background: 0xFF090D14);
      await tester.pumpWidget(createTestApp(ScannabilitySimulatorCard(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Active Warnings:'), findsOneWidget);
      expect(find.text('Recommendations:'), findsOneWidget);
    });
  });
}
