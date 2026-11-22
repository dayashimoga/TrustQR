import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/analytics_controller.dart';
import 'package:admin_app/src/views/analytics_dashboard_view.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('AnalyticsDashboardView Widget Tests', () {
    late AnalyticsController controller;

    setUp(() {
      controller = AnalyticsController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: CyberTokens.createDarkCyberTheme(),
        home: Scaffold(
          body: AnalyticsDashboardView(analyticsController: controller),
        ),
      );
    }

    testWidgets('renders KPI cards, header, and interval chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('FLEET TELEMETRY & THREAT INTELLIGENCE'), findsOneWidget);
      expect(find.text('TOTAL FLEET SCANS'), findsOneWidget);
      expect(find.text('QR GENERATIONS'), findsOneWidget);
      expect(find.text('SECURITY THREATS'), findsOneWidget);
      expect(find.text('ACTIVE DEVICES'), findsOneWidget);

      // Change intervals
      await tester.tap(find.byKey(const Key('interval_chip_hourly')));
      await tester.pumpAndSettle();
      expect(controller.interval, equals(TimeSeriesBucketInterval.hourly));

      await tester.tap(find.byKey(const Key('interval_chip_weekly')));
      await tester.pumpAndSettle();
      expect(controller.interval, equals(TimeSeriesBucketInterval.weekly));

      await tester.tap(find.byKey(const Key('interval_chip_monthly')));
      await tester.pumpAndSettle();
      expect(controller.interval, equals(TimeSeriesBucketInterval.monthly));

      await tester.tap(find.byKey(const Key('interval_chip_daily')));
      await tester.pumpAndSettle();
      expect(controller.interval, equals(TimeSeriesBucketInterval.daily));
    });

    testWidgets('renders distribution and threat intelligence sections', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('15-FORMAT PAYLOAD DISTRIBUTION BREAKDOWN'), findsOneWidget);
      expect(find.text('SECURITY THREAT INTELLIGENCE'), findsOneWidget);
      expect(find.text('RISK SCORE DISTRIBUTION HISTOGRAM:'), findsOneWidget);
    });

    testWidgets('revokes and restores fleet devices via action buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Revoke Pixel 8
      expect(find.byKey(const Key('revoke_device_dev_android_pixel8_01')), findsOneWidget);
      await tester.tap(find.byKey(const Key('revoke_device_dev_android_pixel8_01')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('restore_device_dev_android_pixel8_01')), findsOneWidget);

      // Restore Pixel 8
      await tester.tap(find.byKey(const Key('restore_device_dev_android_pixel8_01')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('revoke_device_dev_android_pixel8_01')), findsOneWidget);
    });

    testWidgets('triggers canonical report exports and shows notification banner', (tester) async {
      tester.view.physicalSize = const Size(1280, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. JSON Report
      await tester.tap(find.byKey(const Key('export_json_report_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export_banner_text')), findsOneWidget);
      expect(find.textContaining('JSON Report generated successfully'), findsOneWidget);

      // 2. Time-Series CSV
      await tester.tap(find.byKey(const Key('export_time_series_csv_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Time Series CSV generated successfully'), findsOneWidget);

      // 3. Payload CSV
      await tester.tap(find.byKey(const Key('export_payload_csv_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Payload Breakdown CSV generated successfully'), findsOneWidget);

      // 4. Threats CSV
      await tester.tap(find.byKey(const Key('export_threats_csv_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Threat Firewall CSV generated successfully'), findsOneWidget);

      // 5. Fleet CSV
      await tester.tap(find.byKey(const Key('export_fleet_csv_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fleet Inventory CSV generated successfully'), findsOneWidget);
    });
  });
}
