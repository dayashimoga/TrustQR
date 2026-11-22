import 'package:flutter/material.dart';
import '../tokens/cyber_colors.dart';
import '../tokens/cyber_tokens.dart';
import '../tokens/cyber_typography.dart';

/// Cryptographic TrustQR authenticity verification badge.
class TrustQrBadge extends StatelessWidget {
  final bool isAuthentic;
  final String? institutionName;
  final String? keyId;
  final DateTime? issuedAt;
  final bool isCompact;

  const TrustQrBadge({
    super.key,
    required this.isAuthentic,
    this.institutionName,
    this.keyId,
    this.issuedAt,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAuthentic ? CyberColors.neonEmerald : CyberColors.neonCrimson;
    final statusText = isAuthentic ? 'TRUSTQR VERIFIED' : 'SIGNATURE INVALID';
    final icon = isAuthentic ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(CyberTokens.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
          boxShadow: isAuthentic ? CyberTokens.neonGlow(color, blur: 6.0) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: CyberTypography.monospace(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      decoration: BoxDecoration(
        color: CyberColors.slateCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.0),
        boxShadow: isAuthentic ? CyberTokens.neonGlow(color, blur: 10.0) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: CyberTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: CyberTypography.monospace(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: CyberTokens.neonGlow(color, blur: 4.0),
                      ),
                    ),
                  ],
                ),
                if (institutionName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    institutionName!,
                    style: const TextStyle(
                      color: CyberColors.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (keyId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'KEY: $keyId',
                    style: CyberTypography.monospace(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: CyberColors.textMutedDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
