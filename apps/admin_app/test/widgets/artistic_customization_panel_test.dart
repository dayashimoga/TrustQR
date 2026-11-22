import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/widgets/artistic_customization_panel.dart';

void main() {
  group('ArtisticCustomizationPanel Widget Tests', () {
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

    testWidgets('renders all customization controls, templates, and triggers all changes', (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(ArtisticCustomizationPanel(controller: controller)));

      expect(find.text('Artistic Customization Studio'), findsOneWidget);
      expect(find.text('Cyberpunk'), findsOneWidget);
      expect(find.text('Corporate Navy'), findsOneWidget);
      expect(find.text('Emerald Trust'), findsOneWidget);
      expect(find.text('High Contrast'), findsOneWidget);

      // Select Cyberpunk template
      await tester.tap(find.text('Cyberpunk'));
      await tester.pumpAndSettle();
      expect(controller.activeTemplate?.id, 'cyberpunk-neon');

      // Select Corporate Navy template
      await tester.tap(find.text('Corporate Navy'));
      await tester.pumpAndSettle();
      expect(controller.activeTemplate?.id, 'corporate-navy');

      // Select Emerald Trust template
      await tester.tap(find.text('Emerald Trust'));
      await tester.pumpAndSettle();
      expect(controller.activeTemplate?.id, 'emerald-trust');

      // Select High Contrast template
      await tester.tap(find.text('High Contrast'));
      await tester.pumpAndSettle();
      expect(controller.activeTemplate?.id, 'high-contrast-mono');

      // Change Module Shape Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<QrModuleShape>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('dots').last);
      await tester.pumpAndSettle();
      expect(controller.moduleShape, QrModuleShape.dots);

      // Change Error Correction Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<QrErrorCorrectionLevel>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOW').last);
      await tester.pumpAndSettle();
      expect(controller.errorCorrection, QrErrorCorrectionLevel.low);

      // Change Eye Frame Shape Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<QrEyeFrameShape>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('circle').last);
      await tester.pumpAndSettle();
      expect(controller.eyeFrameShape, QrEyeFrameShape.circle);

      // Change Eye Pupil Shape Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<QrEyePupilShape>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('diamond').last);
      await tester.pumpAndSettle();
      expect(controller.eyePupilShape, QrEyePupilShape.diamond);

      // Tap Primary Color Preset Button
      await tester.tap(find.byKey(const Key('color_button_primary_color')));
      await tester.pumpAndSettle();

      // Tap Background Color Preset Button
      await tester.tap(find.byKey(const Key('color_button_background')));
      await tester.pumpAndSettle();

      // Switch to Linear Gradient and tap Gradient Stop 2 Button
      await tester.tap(find.text('Linear'));
      await tester.pumpAndSettle();
      expect(controller.gradientType, QrGradientType.linear);
      expect(find.byKey(const Key('color_button_gradient_stop_2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('color_button_gradient_stop_2')));
      await tester.pumpAndSettle();

      // Adjust Linear Angle Slider
      expect(find.byType(Slider), findsWidgets);
      await tester.drag(find.byType(Slider).first, const Offset(30, 0));
      await tester.pumpAndSettle();

      // Toggle embedded logo switch
      await tester.tap(find.byKey(const Key('logo_toggle_switch')));
      await tester.pumpAndSettle();
      expect(controller.hasLogo, isTrue);
      expect(find.byKey(const Key('logo_size_slider')), findsOneWidget);

      // Slide logo size slider
      await tester.drag(find.byKey(const Key('logo_size_slider')), const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(controller.logoSizeRatio, greaterThan(0.10));
    });

    testWidgets('changes gradient mode using segmented button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(ArtisticCustomizationPanel(controller: controller)));

      // Switch to Radial
      await tester.tap(find.text('Radial'));
      await tester.pumpAndSettle();
      expect(controller.gradientType, QrGradientType.radial);

      // Switch to Solid
      await tester.tap(find.text('Solid'));
      await tester.pumpAndSettle();
      expect(controller.gradientType, QrGradientType.none);

      // Switch to Linear
      await tester.tap(find.text('Linear'));
      await tester.pumpAndSettle();
      expect(controller.gradientType, QrGradientType.linear);
      expect(find.text('Gradient Angle'), findsOneWidget);
    });
  });
}
