import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:admin_app/src/state/studio_controller.dart';
import 'package:admin_app/src/widgets/qr_studio_preview_canvas.dart';

void main() {
  group('QrStudioPreviewCanvas Widget Tests', () {
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

    testWidgets('renders preview canvas, paints matrix, and executes all 4 export actions', (tester) async {
      await tester.pumpWidget(createTestApp(QrStudioPreviewCanvas(controller: controller)));

      expect(find.text('Live QR Matrix Preview'), findsOneWidget);
      expect(find.byKey(const Key('export_png_button')), findsOneWidget);
      expect(find.byKey(const Key('export_svg_button')), findsOneWidget);
      expect(find.byKey(const Key('export_pdf_button')), findsOneWidget);
      expect(find.byKey(const Key('export_bmp_button')), findsOneWidget);

      // Tap Export PNG
      await tester.tap(find.byKey(const Key('export_png_button')));
      await tester.pumpAndSettle();
      expect(controller.lastExportFormat, 'PNG');
      expect(find.textContaining('300DPI PNG'), findsWidgets);

      // Tap Export SVG
      await tester.tap(find.byKey(const Key('export_svg_button')));
      await tester.pumpAndSettle();
      expect(controller.lastExportFormat, 'SVG');
      expect(find.textContaining('Vector SVG'), findsWidgets);

      // Tap Export PDF
      await tester.tap(find.byKey(const Key('export_pdf_button')));
      await tester.pumpAndSettle();
      expect(controller.lastExportFormat, 'PDF');
      expect(find.textContaining('Print-Ready PDF'), findsWidgets);

      // Tap Export BMP
      await tester.tap(find.byKey(const Key('export_bmp_button')));
      await tester.pumpAndSettle();
      expect(controller.lastExportFormat, 'BMP');
      expect(find.textContaining('24-bit BMP'), findsWidgets);
    });

    testWidgets('paints custom modules across various shapes and eyes', (tester) async {
      final shapes = [
        QrModuleShape.square,
        QrModuleShape.rounded,
        QrModuleShape.dots,
        QrModuleShape.diamond,
        QrModuleShape.liquid,
        QrModuleShape.cyberGrid,
      ];

      for (final shape in shapes) {
        controller.setModuleShape(shape);
        controller.setEyeStyle(
          frameShape: QrEyeFrameShape.square,
          pupilShape: QrEyePupilShape.square,
        );
        controller.setLogoConfig(hasLogo: true, sizeRatio: 0.20);

        await tester.pumpWidget(createTestApp(QrStudioPreviewCanvas(controller: controller)));
        await tester.pumpAndSettle();
        expect(controller.currentMatrix, isNotNull);
      }

      // Circle eyes and diamond pupils
      controller.setEyeStyle(
        frameShape: QrEyeFrameShape.circle,
        pupilShape: QrEyePupilShape.diamond,
      );
      await tester.pumpWidget(createTestApp(QrStudioPreviewCanvas(controller: controller)));
      await tester.pumpAndSettle();

      // Circle pupils
      controller.setEyeStyle(
        frameShape: QrEyeFrameShape.circle,
        pupilShape: QrEyePupilShape.circle,
      );
      await tester.pumpWidget(createTestApp(QrStudioPreviewCanvas(controller: controller)));
      await tester.pumpAndSettle();
    });
  });
}
