import 'package:flutter/material.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/studio_controller.dart';
import '../widgets/payload_forms/payload_form_dispatcher.dart';
import '../widgets/artistic_customization_panel.dart';
import '../widgets/scannability_simulator_card.dart';
import '../widgets/trust_qr_signer_card.dart';
import '../widgets/qr_studio_preview_canvas.dart';

/// Main responsive QR Studio workspace view for the Admin App.
class StudioWorkspaceView extends StatefulWidget {
  final StudioController controller;
  final AdminAnalyticsService analyticsService;

  const StudioWorkspaceView({
    super.key,
    required this.controller,
    this.analyticsService = const AdminAnalyticsService(),
  });

  @override
  State<StudioWorkspaceView> createState() => _StudioWorkspaceViewState();
}

class _StudioWorkspaceViewState extends State<StudioWorkspaceView> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Universal QR Studio & Fleet Analytics [Admin]'),
            backgroundColor: CyberTokens.obsidianBackground,
            actions: [
              IconButton(
                key: const Key('fleet_telemetry_appbar_button'),
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'View Fleet Telemetry',
                onPressed: () {
                  final summary = widget.analyticsService.aggregateMetrics(items: [], generationCount: 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generations: ${summary.totalGenerations}, Threats: ${summary.threatsDetected}')),
                  );
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle Header
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const Text(
                          'Artistic QR Generator Studio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CyberTokens.neonCyan,
                          ),
                        ),
                        CyberBadge(
                          text: widget.controller.payloadType.name.toUpperCase(),
                          type: CyberBadgeType.info,
                        ),
                        if (widget.controller.isTrustQrEnabled)
                          const CyberBadge(
                            text: 'ED25519 VERIFIED',
                            type: CyberBadgeType.safe,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isWide) ...[
                      // Multi-column layout for desktop/tablets
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                PayloadFormDispatcher(controller: widget.controller),
                                const SizedBox(height: 16),
                                TrustQrSignerCard(controller: widget.controller),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                QrStudioPreviewCanvas(controller: widget.controller),
                                const SizedBox(height: 16),
                                ArtisticCustomizationPanel(controller: widget.controller),
                                const SizedBox(height: 16),
                                ScannabilitySimulatorCard(controller: widget.controller),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Single-column layout for mobile
                      QrStudioPreviewCanvas(controller: widget.controller),
                      const SizedBox(height: 16),
                      ScannabilitySimulatorCard(controller: widget.controller),
                      const SizedBox(height: 16),
                      PayloadFormDispatcher(controller: widget.controller),
                      const SizedBox(height: 16),
                      ArtisticCustomizationPanel(controller: widget.controller),
                      const SizedBox(height: 16),
                      TrustQrSignerCard(controller: widget.controller),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
