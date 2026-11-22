import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import '../state/scanner_controller.dart';
import '../widgets/multi_qr_picker_dialog.dart';
import '../widgets/threat_hud_modal.dart';

/// Primary scanner workspace viewport for the restricted User App.
///
/// Features live viewfinder with [HudScannerReticle], file/image decoder,
/// batch multi-QR inspection, torch toggle, and incognito mode.
class ScannerWorkspaceView extends StatefulWidget {
  final ScannerController controller;
  final void Function(String actionName, String details)? onActionExecuted;

  const ScannerWorkspaceView({
    super.key,
    required this.controller,
    this.onActionExecuted,
  });

  @override
  State<ScannerWorkspaceView> createState() => _ScannerWorkspaceViewState();
}

class _ScannerWorkspaceViewState extends State<ScannerWorkspaceView> {
  final TextEditingController _payloadInputController = TextEditingController();

  @override
  void dispose() {
    _payloadInputController.dispose();
    super.dispose();
  }

  void _executeManualScan() {
    final text = _payloadInputController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.scanRawString(text);
      _payloadInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Stack(
          children: [
            // Background Viewfinder canvas
            Positioned.fill(
              child: Container(
                color: CyberColors.obsidianBackground,
                child: Column(
                  children: [
                    // Top Telemetry Header Bar
                    _buildTopBar(context, ctrl),

                    // Error telemetry notification (if any)
                    if (ctrl.lastErrorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CyberColors.neonCrimson.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                            border: Border.all(color: CyberColors.neonCrimson.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: CyberColors.neonCrimson, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ctrl.lastErrorMessage!,
                                  style: const TextStyle(fontSize: 12, color: CyberColors.neonCrimson),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Central Viewfinder Reticle
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HudScannerReticle(
                                state: ctrl.hudState,
                                reticleSize: 260,
                                showLaserSweep: !CyberAccessibility.isReducedMotion(context),
                                reducedMotion: CyberAccessibility.isReducedMotion(context),
                              ),
                              const SizedBox(height: CyberTokens.spacingSm),
                              Text(
                                ctrl.isTorchOn ? 'LIGHT SOURCE ACTIVE' : 'VIEWFINDER READY',
                                style: CyberTypography.monospace(
                                  fontSize: 10,
                                  color: ctrl.isTorchOn ? CyberColors.neonAmber : CyberColors.textMutedDark,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Control Dock
                    _buildBottomDock(context, ctrl),
                  ],
                ),
              ),
            ),

            // Modal: Multi-QR Candidate Picker (if multiple detected)
            if (ctrl.multiQrCandidates.isNotEmpty)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.70),
                  padding: const EdgeInsets.all(CyberTokens.spacingLg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: MultiQrPickerDialog(
                        candidates: ctrl.multiQrCandidates,
                        onCandidateSelected: ctrl.selectMultiQrCandidate,
                        onDismiss: ctrl.dismissActiveResult,
                      ),
                    ),
                  ),
                ),
              ),

            // Modal: Threat Firewall HUD (when a code is active)
            if (ctrl.activeScanResult != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  padding: const EdgeInsets.all(CyberTokens.spacingLg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: ThreatHudModal(
                        result: ctrl.activeScanResult!,
                        onDismiss: ctrl.dismissActiveResult,
                        onSaveToVault: ctrl.saveCurrentToVault,
                        onActionExecuted: widget.onActionExecuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, ScannerController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CyberColors.slateCard.withValues(alpha: 0.60),
        border: const Border(bottom: BorderSide(color: CyberColors.slateBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ctrl.hudState == ScannerHudState.threat
                        ? CyberColors.neonCrimson
                        : CyberColors.neonCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'FIREWALL // ZERO-TRUST',
                    style: CyberTypography.monospace(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CyberColors.textPrimaryDark,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Torch Toggle Button
          IconButton(
            icon: Icon(
              ctrl.isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: ctrl.isTorchOn ? CyberColors.neonAmber : CyberColors.textMutedDark,
              size: 20,
            ),
            tooltip: 'Toggle Flashlight / Torch',
            onPressed: ctrl.toggleTorch,
          ),
          // Incognito Mode Toggle
          IconButton(
            icon: Icon(
              ctrl.isIncognito ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: ctrl.isIncognito ? CyberColors.neonEmerald : CyberColors.textMutedDark,
              size: 20,
            ),
            tooltip: 'Toggle Incognito Mode (Bypass Vault Save)',
            onPressed: ctrl.toggleIncognito,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock(BuildContext context, ScannerController ctrl) {
    return Container(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      decoration: BoxDecoration(
        color: CyberColors.slateCard.withValues(alpha: 0.85),
        border: const Border(top: BorderSide(color: CyberColors.slateBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Buttons: File Scan & Multi-QR
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: 'Decode Image File',
                  icon: Icons.image_search_rounded,
                  variant: CyberButtonVariant.secondary,
                  onPressed: () {
                    final buffer = ImageBuffer(
                      bytes: Uint8List(25 * 25),
                      width: 25,
                      height: 25,
                      format: ImageColorFormat.grayscale,
                    );
                    ctrl.scanImageBuffer(buffer);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CyberButton(
                  label: 'Batch Multi-QR',
                  icon: Icons.grid_view_rounded,
                  variant: CyberButtonVariant.secondary,
                  onPressed: () {
                    final buffer = ImageBuffer(
                      bytes: Uint8List(60 * 60),
                      width: 60,
                      height: 60,
                      format: ImageColorFormat.grayscale,
                    );
                    ctrl.scanMultiQrBuffer(buffer);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: CyberTokens.spacingSm),
          // Manual input bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _payloadInputController,
                  style: const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
                  decoration: InputDecoration(
                    hintText: 'Enter QR payload (URL, Wi-Fi, vCard, etc.)...',
                    hintStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: CyberColors.obsidianBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.slateBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.neonCyan),
                    ),
                  ),
                  onSubmitted: (_) => _executeManualScan(),
                ),
              ),
              const SizedBox(width: 8),
              CyberButton(
                label: 'Inspect',
                icon: Icons.search_rounded,
                variant: CyberButtonVariant.primary,
                height: 42,
                onPressed: _executeManualScan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
