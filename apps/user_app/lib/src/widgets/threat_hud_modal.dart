import 'package:flutter/material.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'payload_action_card.dart';

/// Interactive modal sheet displaying Threat Firewall assessment, cryptographic
/// TrustQR verification, heuristic breakdown, and context-aware action dispatchers.
class ThreatHudModal extends StatefulWidget {
  final PipelineScanResult result;
  final VoidCallback? onDismiss;
  final VoidCallback? onSaveToVault;
  final void Function(String actionName, String details)? onActionExecuted;

  const ThreatHudModal({
    super.key,
    required this.result,
    this.onDismiss,
    this.onSaveToVault,
    this.onActionExecuted,
  });

  @override
  State<ThreatHudModal> createState() => _ThreatHudModalState();
}

class _ThreatHudModalState extends State<ThreatHudModal> {
  bool _isUnlocked = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.result.vaultItem != null;
  }

  Color _getThreatColor(SecurityThreatLevel level) {
    switch (level) {
      case SecurityThreatLevel.safe:
        return CyberColors.neonEmerald;
      case SecurityThreatLevel.caution:
        return CyberColors.neonCyan;
      case SecurityThreatLevel.suspicious:
        return CyberColors.neonAmber;
      case SecurityThreatLevel.critical:
        return CyberColors.neonCrimson;
    }
  }

  CyberBadgeType _getThreatBadgeType(SecurityThreatLevel level) {
    switch (level) {
      case SecurityThreatLevel.safe:
        return CyberBadgeType.safe;
      case SecurityThreatLevel.caution:
        return CyberBadgeType.info;
      case SecurityThreatLevel.suspicious:
        return CyberBadgeType.warning;
      case SecurityThreatLevel.critical:
        return CyberBadgeType.threat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessment = widget.result.threatAssessment;
    final threatColor = _getThreatColor(assessment.threatLevel);
    final badgeType = _getThreatBadgeType(assessment.threatLevel);
    final isQuarantined = !widget.result.isAllowed || assessment.isCritical;

    return CyberGlassSheet(
      title: 'THREAT FIREWALL INSPECTION',
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, color: CyberColors.textMutedDark),
        tooltip: 'Close Modal',
        onPressed: widget.onDismiss,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Threat Status Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: threatColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                border: Border.all(color: threatColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(
                    isQuarantined ? Icons.security_rounded : Icons.verified_user_rounded,
                    color: threatColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isQuarantined
                          ? 'CRITICAL THREAT // ACCESS QUARANTINED'
                          : 'THREAT STATUS: ${assessment.threatLevel.name.toUpperCase()}',
                      style: CyberTypography.monospace(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: threatColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  CyberBadge(
                    text: '${assessment.safetyScore}/100',
                    type: badgeType,
                    isPill: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: CyberTokens.spacingMd),

            // Top Visual Row: Gauge + TrustQR
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ThreatScoreGauge(
                      score: assessment.safetyScore.toDouble(),
                      size: 130,
                    ),
                  ),
                ),
                const SizedBox(width: CyberTokens.spacingMd),
                Expanded(
                  flex: 3,
                  child: _buildTrustQrSection(),
                ),
              ],
            ),
            const SizedBox(height: CyberTokens.spacingMd),

            // Heuristic Findings & Telemetry Cards
            _buildHeuristicSummary(assessment),
            const SizedBox(height: CyberTokens.spacingMd),

            // Quarantine Blocker Card (if quarantined)
            if (isQuarantined) ...[
              _buildQuarantineGuard(),
              const SizedBox(height: CyberTokens.spacingMd),
            ],

            // Context-Aware Payload Action Card
            PayloadActionCard(
              payload: widget.result.payload,
              isQuarantined: isQuarantined,
              isActionUnlocked: _isUnlocked,
              onActionExecuted: widget.onActionExecuted,
            ),
            const SizedBox(height: CyberTokens.spacingLg),

            // Bottom Actions
            Row(
              children: [
                if (!_isSaved)
                  Expanded(
                    child: CyberButton(
                      label: 'Save to Vault',
                      icon: Icons.archive_rounded,
                      variant: CyberButtonVariant.secondary,
                      onPressed: () {
                        widget.onSaveToVault?.call();
                        setState(() => _isSaved = true);
                      },
                    ),
                  )
                else
                  const Expanded(
                    child: CyberButton(
                      label: 'Saved in Vault',
                      icon: Icons.check_circle_rounded,
                      variant: CyberButtonVariant.secondary,
                      onPressed: null,
                    ),
                  ),
                const SizedBox(width: CyberTokens.spacingMd),
                Expanded(
                  child: CyberButton(
                    label: 'Dismiss',
                    icon: Icons.arrow_back_rounded,
                    variant: CyberButtonVariant.outline,
                    onPressed: widget.onDismiss,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustQrSection() {
    final raw = widget.result.rawContent;
    final env = TrustQrEnvelope.tryParse(raw);
    if (env != null) {
      return TrustQrBadge(
        isAuthentic: true,
        institutionName: env.issuer,
        keyId: env.keyId,
        issuedAt: env.createdAt,
        isCompact: false,
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrustQrBadge(
          isAuthentic: false,
          institutionName: 'Unsigned Standard QR',
          isCompact: false,
        ),
        SizedBox(height: 6),
        Text(
          'No cryptographic Ed25519 institutional envelope detected in this code.',
          style: TextStyle(fontSize: 11, color: CyberColors.textMutedDark),
        ),
      ],
    );
  }

  Widget _buildHeuristicSummary(ThreatAssessment assessment) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, size: 16, color: CyberColors.neonCyan),
              const SizedBox(width: 8),
              Text(
                'ZERO-TRUST FIREWALL HEURISTICS',
                style: CyberTypography.monospace(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CyberColors.neonCyan,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: CyberTokens.spacingSm),
          if (assessment.findings.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: assessment.findings.map((finding) {
                return CyberBadge(
                  text: finding.title,
                  type: finding.severity == SecurityThreatLevel.critical
                      ? CyberBadgeType.threat
                      : CyberBadgeType.warning,
                  isPill: false,
                );
              }).toList(),
            )
          else
            const Text(
              'No suspicious anomalies, phishing signatures, or URL shorteners detected.',
              style: TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
            ),
        ],
      ),
    );
  }

  Widget _buildQuarantineGuard() {
    return Container(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      decoration: BoxDecoration(
        color: CyberColors.neonCrimson.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
        border: Border.all(color: CyberColors.neonCrimson.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded, color: CyberColors.neonCrimson, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QUARANTINE PROTECTION ACTIVE',
                  style: CyberTypography.monospace(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: CyberColors.neonCrimson,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'This QR code contains high-risk or malicious payloads (e.g. deceptive phishing, dangerous scheme, or malware). Actions are locked by default.',
            style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _isUnlocked,
                activeColor: CyberColors.neonCrimson,
                onChanged: (val) {
                  setState(() => _isUnlocked = val ?? false);
                },
              ),
              const Expanded(
                child: Text(
                  'I understand the security risk and wish to override quarantine.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CyberColors.neonCrimson),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
