import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'src/state/scanner_controller.dart';
import 'src/views/scanner_workspace_view.dart';

void main() {
  runApp(const UserApp());
}

/// The restricted cross-platform User Application (Scanner & Security Firewall only).
///
/// QR Code generation and fleet admin tools are physically and compile-time excluded.
class UserApp extends StatefulWidget {
  final ScannerController? controller;

  const UserApp({super.key, this.controller});

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  late final ScannerController _controller;
  int _currentNavIndex = 0;
  bool _isHighContrast = false;
  String? _lastActionDetails;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ScannerController(
          pipeline: ScanToVaultPipeline(
            scanner: UniversalQrScannerEngine(),
            firewall: QrThreatFirewall(),
            vault: QrVault.inMemory(
              integrityKey: CryptoKeyPair.generateHmacKey().privateKey,
            ),
          ),
        );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleActionExecuted(String action, String details) {
    setState(() {
      _lastActionDetails = '$action: $details';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal QR Scanner [User App]',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.resolve(context, isDark: true, highContrast: _isHighContrast),
      supportedLocales: CyberLocalizations.supportedLocales,
      localizationsDelegates: const [
        CyberLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          final l10n = CyberLocalizations.of(context);

          final navItems = [
            WorkspaceNavItem(
              id: 'scan',
              label: l10n.navScanner,
              icon: Icons.qr_code_scanner_rounded,
            ),
            WorkspaceNavItem(
              id: 'history',
              label: l10n.navHistory,
              icon: Icons.history_rounded,
            ),
            WorkspaceNavItem(
              id: 'settings',
              label: l10n.navSettings,
              icon: Icons.tune_rounded,
            ),
          ];

          return AdaptiveWorkspaceShell(
            title: l10n.userAppTitle,
            items: navItems,
            currentIndex: _currentNavIndex,
            onIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
            body: _buildCurrentTab(context),
            secondaryPane: _buildSecondaryInspector(context),
            onSearchShortcut: () {
              // Focus scanner
              setState(() => _currentNavIndex = 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    switch (_currentNavIndex) {
      case 0:
        return ScannerWorkspaceView(
          controller: _controller,
          onActionExecuted: _handleActionExecuted,
        );
      case 1:
        return _buildVaultHistoryPlaceholder(context);
      case 2:
        return _buildSettingsView(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVaultHistoryPlaceholder(BuildContext context) {
    return Container(
      color: CyberColors.obsidianBackground,
      padding: const EdgeInsets.all(CyberTokens.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CyberGlassCard(
            padding: const EdgeInsets.all(CyberTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 48, color: CyberColors.neonCyan),
                const SizedBox(height: 12),
                Text(
                  'ENCRYPTED SCAN VAULT',
                  style: CyberTypography.monospace(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CyberColors.neonCyan,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Offline-first history with HMAC record tamper protection, tags, full-text search, and collections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CyberColors.textSecondaryDark, fontSize: 13),
                ),
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Return to Scanner Viewfinder',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => setState(() => _currentNavIndex = 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context) {
    return Container(
      color: CyberColors.obsidianBackground,
      padding: const EdgeInsets.all(CyberTokens.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CyberGlassCard(
            padding: const EdgeInsets.all(CyberTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY & ACCESSIBILITY SETTINGS',
                  style: CyberTypography.monospace(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CyberColors.neonCyan,
                  ),
                ),
                const SizedBox(height: CyberTokens.spacingMd),
                SwitchListTile(
                  title: const Text('High-Contrast Mode (WCAG AAA)', style: TextStyle(color: CyberColors.textPrimaryDark)),
                  subtitle: const Text('Enhanced border sheens and maximum text luminance ratio', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
                  value: _isHighContrast,
                  activeThumbColor: CyberColors.neonCyan,
                  onChanged: (val) => setState(() => _isHighContrast = val),
                ),
                SwitchListTile(
                  title: const Text('Privacy Incognito Mode', style: TextStyle(color: CyberColors.textPrimaryDark)),
                  subtitle: const Text('Bypass saving scans into the persistent local vault', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
                  value: _controller.isIncognito,
                  activeThumbColor: CyberColors.neonEmerald,
                  onChanged: (_) => _controller.toggleIncognito(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberColors.slateCardSecondary,
                    borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                    border: Border.all(color: CyberColors.slateBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: CyberColors.neonEmerald, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ROLE: RESTRICTED USER // GENERATOR DISABLED',
                          style: CyberTypography.monospace(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CyberColors.neonEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryInspector(BuildContext context) {
    return Container(
      color: CyberColors.slateCard.withValues(alpha: 0.90),
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 16, color: CyberColors.neonCyan),
              const SizedBox(width: 6),
              Text(
                'SECURITY TELEMETRY',
                style: CyberTypography.monospace(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: CyberColors.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: CyberTokens.spacingMd),
          CyberGlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIREWALL ENGINE',
                  style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Zero-Trust Heuristic Core',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CyberColors.textPrimaryDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'IDN Homographs, Scheme Protection, IP Obfuscation, and TrustQR Validation active.',
                  style: TextStyle(fontSize: 11, color: CyberColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: CyberTokens.spacingSm),
          CyberGlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH ACTION LOG',
                  style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastActionDetails ?? 'No context actions dispatched yet.',
                  style: CyberTypography.monospace(fontSize: 11, color: CyberColors.textPrimaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
