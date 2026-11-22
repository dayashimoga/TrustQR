import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/auth_controller.dart';
import '../theme/admin_typography.dart';

/// Wraps administrative views with cryptographic role entitlement enforcement.
///
/// If the operator holds a valid [UserRole.admin] token, the [child] is rendered.
/// Otherwise, displays the cyber-precision [AccessDeniedView] with token authentication tools.
class RbacGuardView extends StatelessWidget {
  final AuthController authController;
  final Widget child;

  const RbacGuardView({
    super.key,
    required this.authController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        if (authController.isAuthenticated && authController.isAdmin) {
          return child;
        }
        return AccessDeniedView(authController: authController);
      },
    );
  }
}

/// Cyber-styled access denial and operator authentication screen.
class AccessDeniedView extends StatefulWidget {
  final AuthController authController;

  const AccessDeniedView({
    super.key,
    required this.authController,
  });

  @override
  State<AccessDeniedView> createState() => _AccessDeniedViewState();
}

class _AccessDeniedViewState extends State<AccessDeniedView> {
  final TextEditingController _tokenInputController = TextEditingController();

  @override
  void dispose() {
    _tokenInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final denialReason = widget.authController.denialReason ??
        'Cryptographic operator authorization required.';

    return Scaffold(
      backgroundColor: CyberColors.obsidianBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: CyberGlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Shield / Lock Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CyberColors.neonCrimson.withValues(alpha: 0.15),
                      border: Border.all(color: CyberColors.neonCrimson, width: 2),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: CyberColors.neonCrimson,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'SECURITY ACCESS RESTRICTED',
                    style: AdminTypography.headerMedium.copyWith(
                      color: CyberColors.neonCrimson,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'UNIVERSAL QR // ADMIN SUITE',
                    style: AdminTypography.bodySmall.copyWith(
                      color: CyberColors.neonCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Denial Reason Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CyberColors.neonCrimson.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: CyberColors.neonCrimson,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            denialReason,
                            key: const Key('rbac_denial_reason_text'),
                            style: AdminTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Quick Action Buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      CyberButton(
                        key: const Key('sign_in_admin_btn'),
                        label: 'Authenticate as Admin (Ed25519)',
                        icon: Icons.verified_user_outlined,
                        variant: CyberButtonVariant.primary,
                        onPressed: () {
                          widget.authController.signInAsAdmin();
                        },
                      ),
                      CyberButton(
                        key: const Key('sign_in_user_btn'),
                        label: 'Simulate Restricted User Role',
                        icon: Icons.person_outline,
                        variant: CyberButtonVariant.secondary,
                        onPressed: () {
                          widget.authController.signInAsUser();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),

                  // Custom Token Input Area
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'OR VALIDATE CUSTOM ENTITLEMENT TOKEN',
                      style: AdminTypography.codeSmall.copyWith(
                        color: CyberColors.neonAmber,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    key: const Key('rbac_token_input_field'),
                    controller: _tokenInputController,
                    maxLines: 2,
                    style: AdminTypography.codeSmall.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Paste compact JWT token: <header>.<claims>.<signature>',
                      hintStyle: AdminTypography.codeSmall.copyWith(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CyberColors.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: CyberButton(
                      key: const Key('validate_token_btn'),
                      label: 'Validate & Authenticate',
                      icon: Icons.check_circle_outline,
                      variant: CyberButtonVariant.secondary,
                      onPressed: () {
                        widget.authController.authenticateWithToken(
                          _tokenInputController.text,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
