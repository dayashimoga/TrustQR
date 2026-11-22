import 'package:flutter/material.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'src/state/studio_controller.dart';
import 'src/views/studio_workspace_view.dart';

void main() {
  runApp(const AdminApp());
}

/// Root widget for the Full-Featured Admin Application.
class AdminApp extends StatelessWidget {
  final StudioController? controller;
  final AdminAnalyticsService? analyticsService;

  const AdminApp({
    super.key,
    this.controller,
    this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal QR Studio [Admin App]',
      debugShowCheckedModeBanner: false,
      theme: CyberTokens.createDarkCyberTheme(),
      home: AdminStudioHomePage(
        controller: controller,
        analyticsService: analyticsService,
      ),
    );
  }
}

/// Primary Admin QR Studio home screen.
class AdminStudioHomePage extends StatefulWidget {
  final StudioController? controller;
  final AdminAnalyticsService? analyticsService;

  const AdminStudioHomePage({
    super.key,
    this.controller,
    this.analyticsService,
  });

  @override
  State<AdminStudioHomePage> createState() => _AdminStudioHomePageState();
}

class _AdminStudioHomePageState extends State<AdminStudioHomePage> {
  late final StudioController _controller;
  late final AdminAnalyticsService _analytics;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = StudioController();
      _ownsController = true;
    }
    _analytics = widget.analyticsService ?? const AdminAnalyticsService();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudioWorkspaceView(
      controller: _controller,
      analyticsService: _analytics,
    );
  }
}
