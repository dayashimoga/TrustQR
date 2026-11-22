import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'src/state/scanner_controller.dart';
import 'src/state/vault_controller.dart';
import 'src/views/collections_view.dart';
import 'src/views/scanner_workspace_view.dart';
import 'src/views/settings_view.dart';
import 'src/views/vault_view.dart';

void main() {
  runApp(const UserApp());
}

/// The restricted cross-platform User Application (Scanner & Security Firewall only).
///
/// QR Code generation and fleet admin tools are physically and compile-time excluded.
class UserApp extends StatefulWidget {
  final ScannerController? controller;
  final VaultController? vaultController;

  const UserApp({
    super.key,
    this.controller,
    this.vaultController,
  });

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  late final ScannerController _controller;
  late final VaultController _vaultController;
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

    _vaultController = widget.vaultController ??
        VaultController(vault: _controller.vault!);
    _vaultController.init();
    _vaultController.addListener(_onVaultChanged);
  }

  @override
  void dispose() {
    _vaultController.removeListener(_onVaultChanged);
    if (widget.vaultController == null) {
      _vaultController.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onVaultChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _handleActionExecuted(String action, String details) {
    setState(() {
      _lastActionDetails = '$action: $details';
    });
    // Refresh vault in case new items were added
    _vaultController.refresh();
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
              id: 'vault',
              label: l10n.navHistory,
              icon: Icons.lock_clock_rounded,
            ),
            WorkspaceNavItem(
              id: 'collections',
              label: 'Collections',
              icon: Icons.folder_special_rounded,
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
              // Focus Vault tab
              setState(() => _currentNavIndex = 1);
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
        return VaultView(
          controller: _vaultController,
          onNavigateToScanner: () => setState(() => _currentNavIndex = 0),
        );
      case 2:
        return CollectionsView(
          controller: _vaultController,
          onSelectCollection: (_) => setState(() => _currentNavIndex = 1),
        );
      case 3:
        return SettingsView(
          scannerController: _controller,
          vaultController: _vaultController,
          isHighContrast: _isHighContrast,
          onToggleHighContrast: (val) => setState(() => _isHighContrast = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSecondaryInspector(BuildContext context) {
    final metrics = _vaultController.metrics;
    final tamperedCount = _vaultController.tamperedCount;

    return Container(
      color: CyberColors.slateCard.withValues(alpha: 0.90),
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: SingleChildScrollView(
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
            // Vault Statistics Card
            CyberGlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENCRYPTED VAULT STATS',
                    style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
                  ),
                  const SizedBox(height: 8),
                  _buildInspectorStatRow('TOTAL RECORDS', '${metrics?.totalItems ?? _vaultController.items.length}'),
                  const SizedBox(height: 4),
                  _buildInspectorStatRow('FAVORITES', '${metrics?.favoritesCount ?? 0}'),
                  const SizedBox(height: 4),
                  _buildInspectorStatRow('COLLECTIONS', '${_vaultController.collections.length}'),
                  const SizedBox(height: 4),
                  _buildInspectorStatRow(
                    'TAMPERED AUDIT',
                    tamperedCount == 0 ? '0 (ALL INTACT)' : '$tamperedCount (ALERT)',
                    valueColor: tamperedCount == 0 ? CyberColors.neonEmerald : CyberColors.neonCrimson,
                  ),
                ],
              ),
            ),
            const SizedBox(height: CyberTokens.spacingSm),
            // Firewall Heuristic Status
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CyberColors.textPrimaryDark),
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
            // Action Dispatch Log
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
      ),
    );
  }

  Widget _buildInspectorStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: CyberTypography.monospace(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? CyberColors.neonCyan,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
