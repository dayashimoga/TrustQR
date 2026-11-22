import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/studio_controller.dart';

/// Real-time Scannability & Environmental Simulator dashboard card.
class ScannabilitySimulatorCard extends StatelessWidget {
  final StudioController controller;

  const ScannabilitySimulatorCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final report = controller.scannabilityReport;

        return CyberGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Scannability Simulator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberTokens.neonCyan,
                    ),
                  ),
                  if (report != null)
                    CyberBadge(
                      text: report.isScannable ? 'OPTIMAL' : 'DEGRADED',
                      type: report.isScannable ? CyberBadgeType.safe : CyberBadgeType.threat,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (report == null) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Calculating scannability metrics...', style: TextStyle(color: CyberTokens.cyberTextMuted)),
                  ),
                ),
              ] else ...[
                // Main score gauge & contrast readouts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CyberTokens.obsidianBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: report.isScannable ? CyberTokens.neonEmerald : CyberTokens.neonCrimson,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Scannability Score:',
                              style: TextStyle(fontSize: 11, color: CyberTokens.cyberTextMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${report.overallScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: report.overallScore >= 80
                                    ? CyberTokens.neonEmerald
                                    : report.overallScore >= 60
                                        ? CyberTokens.neonAmber
                                        : CyberTokens.neonCrimson,
                              ),
                            ),
                            Text(
                              report.isScannable ? 'High Reliability' : 'Low Readability',
                              style: const TextStyle(fontSize: 9, color: CyberTokens.cyberTextPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricRow('WCAG Contrast', '${report.contrastRatio.toStringAsFixed(2)}:1',
                              report.contrastRatio >= 4.5 ? CyberTokens.neonEmerald : CyberTokens.neonCrimson),
                          const SizedBox(height: 3),
                          _buildMetricRow('Michelson Index', report.michelsonContrast.toStringAsFixed(2),
                              report.michelsonContrast >= 0.70 ? CyberTokens.neonEmerald : CyberTokens.neonAmber),
                          const SizedBox(height: 3),
                          _buildMetricRow('Logo Occlusion', '${(report.logoOcclusionPercentage * 100).toStringAsFixed(1)}%',
                              report.logoOcclusionPercentage <= report.maxSafeOcclusionPercentage ? CyberTokens.neonEmerald : CyberTokens.neonCrimson),
                          const SizedBox(height: 3),
                          _buildMetricRow('Quiet Zone', '${report.quietZoneModules} mod',
                              report.quietZoneSufficient ? CyberTokens.neonEmerald : CyberTokens.neonCrimson),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5 Simulated Environmental Stress Conditions
                const Text(
                  'Environmental Stress Simulation',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTokens.cyberTextPrimary),
                ),
                const SizedBox(height: 6),
                _buildStressBar('Studio Diffuse Light', report.simulationScores.standardLightScore),
                const SizedBox(height: 5),
                _buildStressBar('Surface Glare Washout', report.simulationScores.glareLightingScore),
                const SizedBox(height: 5),
                _buildStressBar('Dim Ambient Lighting', report.simulationScores.lowLightingScore),
                const SizedBox(height: 5),
                _buildStressBar('30° Perspective Tilt', report.simulationScores.angleTiltScore),
                const SizedBox(height: 5),
                _buildStressBar('Defocus Distance Blur', report.simulationScores.distanceBlurScore),
                const SizedBox(height: 10),

                // Warnings and Recommendations
                if (report.warningFlags.isNotEmpty) ...[
                  const Text('Active Warnings:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTokens.neonCrimson)),
                  const SizedBox(height: 2),
                  ...report.warningFlags.map((w) => Text('• $w', style: const TextStyle(fontSize: 10, color: CyberTokens.neonCrimson))),
                  const SizedBox(height: 6),
                ],
                if (report.recommendations.isNotEmpty) ...[
                  const Text('Recommendations:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTokens.neonCyan)),
                  const SizedBox(height: 2),
                  ...report.recommendations.map((r) => Text('• $r', style: const TextStyle(fontSize: 10, color: CyberTokens.cyberTextMuted))),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: CyberTokens.cyberTextMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStressBar(String label, double score) {
    final color = score >= 80
        ? CyberTokens.neonEmerald
        : score >= 60
            ? CyberTokens.neonAmber
            : CyberTokens.neonCrimson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: CyberTokens.cyberTextPrimary)),
            Text('${score.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            backgroundColor: CyberTokens.slateCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
