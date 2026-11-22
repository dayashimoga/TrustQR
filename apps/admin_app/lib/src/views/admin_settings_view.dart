import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/auth_controller.dart';
import '../theme/admin_typography.dart';

/// Administrative operator profile, cryptographic trust anchors, and security controls.
class AdminSettingsView extends StatelessWidget {
  final AuthController authController;

  const AdminSettingsView({
    super.key,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildOperatorProfileCard(),
              const SizedBox(height: 16),
              _buildTrustAnchorsCard(),
              const SizedBox(height: 16),
              _buildSecurityPostureCard(),
              const SizedBox(height: 16),
              _buildPenTestControlsCard(),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, color: CyberColors.neonCyan, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SETTINGS & SECURITY GOVERNANCE',
                  style: AdminTypography.headerMedium.copyWith(
                    color: CyberColors.neonCyan,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Active cryptographic identity, institutional trust anchors, and adversarial RBAC simulation.',
                  style: AdminTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Operator Profile Card
  // ---------------------------------------------------------------------------

  Widget _buildOperatorProfileCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE OPERATOR ENTITLEMENT',
                style: AdminTypography.bodySmall.copyWith(
                  color: CyberColors.neonCyan,
                  letterSpacing: 1.0,
                ),
              ),
              CyberBadge(
                text: authController.role.name.toUpperCase(),
                type: authController.isAdmin ? CyberBadgeType.safe : CyberBadgeType.threat,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Subject:', authController.subject),
          _buildInfoRow('Role:', authController.role.name),
          _buildInfoRow('Issuer Authority:', AuthController.defaultIssuer),
          _buildInfoRow('Key ID:', authController.keyId),
          _buildInfoRow('Granted Scopes:', authController.scopes.join(', ')),
          if (authController.rawTokenString != null) ...[
            const SizedBox(height: 12),
            Text(
              'COMPACT ENTITLEMENT TOKEN:',
              style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                authController.rawTokenString!,
                key: const Key('active_token_text'),
                style: AdminTypography.codeSmall.copyWith(
                  color: CyberColors.neonCyan,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Trust Anchors Card
  // ---------------------------------------------------------------------------

  Widget _buildTrustAnchorsCard() {
    final pubKey = authController.authorityPublicKey;

    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTITUTIONAL TRUST ANCHORS',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Algorithm:', pubKey.algorithm.name.toUpperCase()),
          _buildInfoRow('Key ID:', pubKey.keyId),
          _buildInfoRow('Key Length:', '${pubKey.bytes.length} bytes (256-bit)'),
          const SizedBox(height: 8),
          Text(
            'Public Key Fingerprint:',
            style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pubKey.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':'),
              style: AdminTypography.codeSmall.copyWith(
                color: CyberColors.neonAmber,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Security Posture Card
  // ---------------------------------------------------------------------------

  Widget _buildSecurityPostureCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONOREPO SECURITY & ISOLATION POSTURE',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonEmerald,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildPostureRow(
            'Compile-Time Binary Isolation',
            'apps/user_app is 100% physically isolated from generator & analytics packages.',
            true,
          ),
          const SizedBox(height: 10),
          _buildPostureRow(
            'Zero-Trust QR Threat Firewall',
            'Heuristic inspection engine, IDN homograph checks, and anti-phishing filters active.',
            true,
          ),
          const SizedBox(height: 10),
          _buildPostureRow(
            'Server-Side RBAC Guard',
            'services/rbac_api enforces signed Ed25519 tokens on all generator/analytics endpoints.',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildPostureRow(String title, String description, bool isEnforced) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isEnforced ? Icons.check_circle : Icons.warning,
          color: isEnforced ? CyberColors.neonEmerald : CyberColors.neonCrimson,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdminTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: AdminTypography.bodySmall.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pen-Test & Simulation Controls
  // ---------------------------------------------------------------------------

  Widget _buildPenTestControlsCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADVERSARIAL SIMULATION & PEN-TEST CONTROLS',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonCrimson,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simulate unauthorized access, privilege escalation, or expired credentials to test the RBAC Guard.',
            style: AdminTypography.bodySmall.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              CyberButton(
                key: const Key('simulate_user_role_btn'),
                label: 'Simulate User Role (Privilege Breach)',
                icon: Icons.person_off_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: authController.signInAsUser,
              ),
              CyberButton(
                key: const Key('simulate_expired_token_btn'),
                label: 'Simulate Expired Token',
                icon: Icons.timer_off_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: authController.simulateExpiredToken,
              ),
              CyberButton(
                key: const Key('sign_out_btn'),
                label: 'Sign Out (Guest State)',
                icon: Icons.logout,
                variant: CyberButtonVariant.secondary,
                onPressed: authController.signOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AdminTypography.bodySmall.copyWith(color: Colors.white60),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AdminTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
