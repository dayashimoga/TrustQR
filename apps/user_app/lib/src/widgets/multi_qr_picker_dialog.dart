import 'package:flutter/material.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

/// Modal dialog presented when a multi-QR image contains multiple detected codes,
/// allowing the user to select and inspect each QR individually.
class MultiQrPickerDialog extends StatelessWidget {
  final List<PipelineScanResult> candidates;
  final ValueChanged<PipelineScanResult> onCandidateSelected;
  final VoidCallback onDismiss;

  const MultiQrPickerDialog({
    super.key,
    required this.candidates,
    required this.onCandidateSelected,
    required this.onDismiss,
  });

  CyberBadgeType _getThreatBadgeType(SecurityThreatLevel level) {
    switch (level) {
      case SecurityThreatLevel.critical:
        return CyberBadgeType.threat;
      case SecurityThreatLevel.suspicious:
        return CyberBadgeType.warning;
      case SecurityThreatLevel.caution:
        return CyberBadgeType.info;
      case SecurityThreatLevel.safe:
        return CyberBadgeType.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberGlassSheet(
      title: 'MULTI-QR DETECTED (${candidates.length} CODES)',
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, color: CyberColors.textMutedDark),
        tooltip: 'Close Picker',
        onPressed: onDismiss,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Multiple QR matrices were detected in this image. Select a code below to inspect its Threat Firewall assessment:',
            style: TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
          ),
          const SizedBox(height: CyberTokens.spacingMd),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: candidates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final item = candidates[idx];
              final assessment = item.threatAssessment;
              final badgeType = _getThreatBadgeType(assessment.threatLevel);

              return CyberGlassCard(
                onTap: () => onCandidateSelected(item),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CyberColors.neonCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: CyberColors.neonCyan.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '#${idx + 1}',
                          style: CyberTypography.monospace(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: CyberColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CyberBadge(
                                text: item.payload.type.name.toUpperCase(),
                                type: CyberBadgeType.info,
                                isPill: true,
                              ),
                              const SizedBox(width: 8),
                              CyberBadge(
                                text: '${assessment.safetyScore}/100 ${assessment.threatLevel.name.toUpperCase()}',
                                type: badgeType,
                                isPill: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.rawContent,
                            style: CyberTypography.monospace(
                              fontSize: 11,
                              color: CyberColors.textPrimaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: CyberColors.neonCyan),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: CyberTokens.spacingLg),
          CyberButton(
            label: 'Cancel',
            variant: CyberButtonVariant.outline,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
