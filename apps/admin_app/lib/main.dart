import 'package:flutter/material.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'src/state/admin_nav_controller.dart';
import 'src/state/analytics_controller.dart';
import 'src/state/auth_controller.dart';
import 'src/state/batch_controller.dart';
import 'src/state/studio_controller.dart';
import 'src/views/admin_shell_view.dart';
import 'src/views/rbac_guard_view.dart';

void main() {
  runApp(const AdminApp());
}

/// Root widget for the Full-Featured Admin Application.
class AdminApp extends StatelessWidget {
  final AuthController? authController;
  final AdminNavController? navController;
  final StudioController? controller;
  final BatchController? batchController;
  final AnalyticsController? analyticsController;
  final AdminAnalyticsService? analyticsService;

  const AdminApp({
    super.key,
    this.authController,
    this.navController,
    this.controller,
    this.batchController,
    this.analyticsController,
    this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal QR Studio [Admin Suite]',
      debugShowCheckedModeBanner: false,
      theme: CyberTokens.createDarkCyberTheme(),
      home: AdminStudioHomePage(
        authController: authController,
        navController: navController,
        controller: controller,
        batchController: batchController,
        analyticsController: analyticsController,
        analyticsService: analyticsService,
      ),
    );
  }
}

/// Primary Admin QR Studio & Multi-Pane Suite home screen.
class AdminStudioHomePage extends StatefulWidget {
  final AuthController? authController;
  final AdminNavController? navController;
  final StudioController? controller;
  final BatchController? batchController;
  final AnalyticsController? analyticsController;
  final AdminAnalyticsService? analyticsService;

  const AdminStudioHomePage({
    super.key,
    this.authController,
    this.navController,
    this.controller,
    this.batchController,
    this.analyticsController,
    this.analyticsService,
  });

  @override
  State<AdminStudioHomePage> createState() => _AdminStudioHomePageState();
}

class _AdminStudioHomePageState extends State<AdminStudioHomePage> {
  late final AuthController _authController;
  late final AdminNavController _navController;
  late final StudioController _studioController;
  late final BatchController _batchController;
  late final AnalyticsController _analyticsController;

  bool _ownsAuth = false;
  bool _ownsNav = false;
  bool _ownsStudio = false;
  bool _ownsBatch = false;
  bool _ownsAnalytics = false;

  @override
  void initState() {
    super.initState();
    if (widget.authController != null) {
      _authController = widget.authController!;
    } else {
      _authController = AuthController();
      _ownsAuth = true;
    }

    if (widget.navController != null) {
      _navController = widget.navController!;
    } else {
      _navController = AdminNavController();
      _ownsNav = true;
    }

    if (widget.controller != null) {
      _studioController = widget.controller!;
    } else {
      _studioController = StudioController();
      _ownsStudio = true;
    }

    if (widget.batchController != null) {
      _batchController = widget.batchController!;
    } else {
      _batchController = BatchController();
      _ownsBatch = true;
    }

    if (widget.analyticsController != null) {
      _analyticsController = widget.analyticsController!;
    } else {
      _analyticsController = AnalyticsController();
      _ownsAnalytics = true;
    }
  }

  @override
  void dispose() {
    if (_ownsAuth) _authController.dispose();
    if (_ownsNav) _navController.dispose();
    if (_ownsStudio) _studioController.dispose();
    if (_ownsBatch) _batchController.dispose();
    if (_ownsAnalytics) _analyticsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RbacGuardView(
      authController: _authController,
      child: AdminShellView(
        authController: _authController,
        navController: _navController,
        studioController: _studioController,
        batchController: _batchController,
        analyticsController: _analyticsController,
      ),
    );
  }
}
