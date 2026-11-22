import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/studio_controller.dart';

/// Institutional TrustQR Ed25519 cryptographic signing controls card.
class TrustQrSignerCard extends StatelessWidget {
  final StudioController controller;

  const TrustQrSignerCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final envelope = controller.signedEnvelope;
        final verification = controller.envelopeVerification;

        return CyberGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: CyberTokens.neonEmerald, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TrustQR Cryptographic Signer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: CyberTokens.neonEmerald,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    key: const Key('trust_qr_toggle_switch'),
                    value: controller.isTrustQrEnabled,
                    activeThumbColor: CyberTokens.neonEmerald,
                    onChanged: (val) => controller.setTrustQrEnabled(val),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Signs QR payload with Ed25519 institutional authority keys, rendering physical sticker replacement attacks provably detectable.',
                style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted),
              ),
              const SizedBox(height: 12),

              if (controller.isTrustQrEnabled) ...[
                TextFormField(
                  key: const Key('trust_qr_issuer_field'),
                  initialValue: controller.authorityIssuer,
                  decoration: const InputDecoration(
                    labelText: 'Institutional Authority (Issuer)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => controller.setAuthorityDetails(issuer: val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('trust_qr_key_id_field'),
                        initialValue: controller.keyId,
                        decoration: const InputDecoration(
                          labelText: 'Signing Key ID',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) => controller.setAuthorityDetails(keyId: val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Regenerate Ed25519 Keypair',
                      icon: const Icon(Icons.refresh, color: CyberTokens.neonCyan),
                      onPressed: () => controller.setAuthorityDetails(keyId: controller.keyId),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (envelope != null && verification != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CyberTokens.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: verification.isValid ? CyberTokens.neonEmerald : CyberTokens.neonCrimson,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Algorithm: ${envelope.algorithm.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTokens.neonCyan),
                            ),
                            CyberBadge(
                              text: verification.isValid ? 'VALID ED25519 SIGNATURE' : 'SIGNATURE REJECTED',
                              type: verification.isValid ? CyberBadgeType.safe : CyberBadgeType.threat,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Signed URI: ${envelope.toUriString()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: CyberTokens.cyberTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
