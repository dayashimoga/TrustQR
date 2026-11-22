import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/admin_nav_controller.dart';
import '../state/analytics_controller.dart';
import '../state/auth_controller.dart';
import '../state/batch_controller.dart';
import '../state/studio_controller.dart';
import '../theme/admin_typography.dart';
import 'admin_settings_view.dart';
import 'analytics_dashboard_view.dart';
import 'audit_trail_view.dart';
import 'batch_generator_view.dart';
import 'studio_workspace_view.dart';

/// Root multi-pane administrative shell coordinating all 5 functional workspaces.
class AdminShellView extends StatelessWidget {
  final AuthController authController;
  final AdminNavController navController;
  final StudioController studioController;
  final BatchController batchController;
  final AnalyticsController analyticsController;

  const AdminShellView({
    super.key,
    required this.authController,
    required this.navController,
    required this.studioController,
    required this.batchController,
    required this.analyticsController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([navController, authController]),
      builder: (context, _) {
        final currentPane = navController.currentPane;

        Widget currentBody;
        switch (currentPane) {
          case AdminPane.studio:
            currentBody = StudioWorkspaceView(controller: studioController);
            break;
          case AdminPane.batch:
            currentBody = BatchGeneratorView(batchController: batchController);
            break;
          case AdminPane.analytics:
            currentBody = AnalyticsDashboardView(analyticsController: analyticsController);
            break;
          case AdminPane.audit:
            currentBody = AuditTrailView(analyticsController: analyticsController);
            break;
          case AdminPane.settings:
            currentBody = AdminSettingsView(authController: authController);
            break;
        }

        return AdaptiveWorkspaceShell(
          title: 'UNIVERSAL QR // ADMIN SUITE',
          currentIndex: navController.currentIndex,
          onIndexChanged: navController.selectIndex,
          items: const [
            WorkspaceNavItem(
              id: 'nav_studio',
              label: 'QR Studio',
              icon: Icons.qr_code_2_outlined,
              selectedIcon: Icons.qr_code_2,
            ),
            WorkspaceNavItem(
              id: 'nav_batch',
              label: 'Batch Generator',
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers,
            ),
            WorkspaceNavItem(
              id: 'nav_analytics',
              label: 'Fleet Analytics',
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics,
            ),
            WorkspaceNavItem(
              id: 'nav_audit',
              label: 'Audit Trail',
              icon: Icons.security_outlined,
              selectedIcon: Icons.security,
            ),
            WorkspaceNavItem(
              id: 'nav_settings',
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CyberBadge(
                key: const Key('shell_role_badge'),
                text: authController.role.name.toUpperCase(),
                type: CyberBadgeType.safe,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  authController.subject,
                  key: const Key('shell_subject_text'),
                  style: AdminTypography.codeSmall.copyWith(color: Colors.white70),
                ),
              ),
            ),
            IconButton(
              key: const Key('shell_sign_out_btn'),
              icon: const Icon(Icons.logout, color: Colors.white60, size: 20),
              tooltip: 'Sign Out',
              onPressed: authController.signOut,
            ),
            const SizedBox(width: 8),
          ],
          body: currentBody,
        );
      },
    );
  }
}
