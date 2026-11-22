import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/scanner_controller.dart';
import '../state/vault_controller.dart';

/// Comprehensive Settings & Privacy view managing accessibility, incognito mode,
/// auto-purge retention policies, JSON backup/restore, and restricted entitlement verification.
class SettingsView extends StatefulWidget {
  final ScannerController scannerController;
  final VaultController vaultController;
  final bool isHighContrast;
  final ValueChanged<bool> onToggleHighContrast;

  const SettingsView({
    super.key,
    required this.scannerController,
    required this.vaultController,
    required this.isHighContrast,
    required this.onToggleHighContrast,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _showFeedback(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.black)),
          backgroundColor: CyberColors.neonCyan,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handlePurgeExpired() async {
    final count = await widget.vaultController.purgeHistory();
    _showFeedback('Purge completed: $count expired scan(s) deleted.');
  }

  Future<void> _handleClearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.slateCard,
        title: Text(
          'CLEAR ALL SCAN HISTORY',
          style: CyberTypography.monospace(fontSize: 14, color: CyberColors.neonCrimson),
        ),
        content: const Text(
          'Are you sure you want to delete all scanned records in the offline vault? Favorited items will be preserved by default.',
          style: TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
        ),
        actions: [
          CyberButton(
            key: const Key('confirm_clear_all_btn'),
            label: 'Clear All Scans',
            variant: CyberButtonVariant.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          CyberButton(
            label: 'Cancel',
            variant: CyberButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await widget.vaultController.clearAllHistory(
        keepFavorites: widget.vaultController.privacyPolicy.keepFavoritesOnPurge,
      );
      _showFeedback('Cleared $count scan record(s) from vault.');
    }
  }

  Future<void> _handleExportVault() async {
    final jsonStr = await widget.vaultController.exportSelectedOrAllToJson();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.slateCard,
        title: Text(
          'VAULT BACKUP EXPORT // JSON',
          style: CyberTypography.monospace(fontSize: 14, color: CyberColors.neonCyan),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full vault export (${widget.vaultController.items.length} records, ${widget.vaultController.collections.length} collections) with cryptographic HMAC-SHA256 signatures.',
                style: const TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                color: CyberColors.obsidianBackground,
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textPrimaryDark),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CyberButton(
            key: const Key('copy_settings_export_btn'),
            label: 'Copy Backup JSON',
            icon: Icons.copy_rounded,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              _showFeedback('Backup JSON copied to clipboard.');
            },
          ),
          CyberButton(
            label: 'Close',
            variant: CyberButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportVault() async {
    final importCtrl = TextEditingController();
    bool overwrite = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberColors.slateCard,
          title: Text(
            'RESTORE VAULT // JSON IMPORT',
            style: CyberTypography.monospace(fontSize: 14, color: CyberColors.neonCyan),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste an exported vault JSON payload. Records will be cryptographically audited against HMAC integrity keys.',
                  style: TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('import_json_input'),
                  controller: importCtrl,
                  maxLines: 6,
                  style: CyberTypography.monospace(fontSize: 11, color: CyberColors.textPrimaryDark),
                  decoration: InputDecoration(
                    hintText: '{\n  "format": "trustqr-vault-export",\n  ...\n}',
                    hintStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 11),
                    filled: true,
                    fillColor: CyberColors.obsidianBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.slateBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  key: const Key('import_overwrite_checkbox'),
                  value: overwrite,
                  activeColor: CyberColors.neonCyan,
                  checkColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Overwrite existing records with matching IDs', style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark)),
                  onChanged: (val) => setDialogState(() => overwrite = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            CyberButton(
              key: const Key('confirm_import_btn'),
              label: 'Import Records',
              icon: Icons.upload_rounded,
              onPressed: () async {
                final jsonStr = importCtrl.text.trim();
                if (jsonStr.isNotEmpty) {
                  try {
                    final res = await widget.vaultController.importFromJson(jsonStr, overwrite: overwrite);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    _showFeedback(
                      'Import complete: ${res.importedItems} items, ${res.importedCollections} collections. Tampered: ${res.tamperedItems}.',
                    );
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Import error: $e'), backgroundColor: CyberColors.neonCrimson),
                      );
                    }
                  }
                }
              },
            ),
            CyberButton(
              label: 'Cancel',
              variant: CyberButtonVariant.secondary,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.vaultController.privacyPolicy;
    final isIncognito = widget.scannerController.isIncognito;

    return Container(
      color: CyberColors.obsidianBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CyberTokens.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: CyberTokens.spacingLg),

                // Appearance & Accessibility
                _buildAppearanceCard(),
                const SizedBox(height: CyberTokens.spacingMd),

                // Privacy & Scanner Firewall
                _buildPrivacyCard(policy, isIncognito),
                const SizedBox(height: CyberTokens.spacingMd),

                // Cryptographic Backup & Portability
                _buildBackupCard(),
                const SizedBox(height: CyberTokens.spacingMd),

                // Role & Cryptographic Entitlement
                _buildEntitlementCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.tune_rounded, color: CyberColors.neonCyan, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SECURITY, PRIVACY & SYSTEM SETTINGS',
                style: CyberTypography.monospace(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CyberColors.neonCyan,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Local device vault configuration and RBAC entitlement posture',
                style: TextStyle(fontSize: 11, color: CyberColors.textSecondaryDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('ACCESSIBILITY & APPEARANCE', Icons.visibility_rounded),
          const SizedBox(height: CyberTokens.spacingSm),
          SwitchListTile(
            key: const Key('high_contrast_switch'),
            title: const Text('High-Contrast Theme (WCAG AAA)', style: TextStyle(color: CyberColors.textPrimaryDark, fontSize: 13)),
            subtitle: const Text('Ultra-high luminance ratio (21:1) and maximum border definition', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
            value: widget.isHighContrast,
            activeThumbColor: CyberColors.neonCyan,
            onChanged: widget.onToggleHighContrast,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(VaultPrivacyPolicy policy, bool isIncognito) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('PRIVACY & VAULT RETENTION', Icons.shield_rounded),
          const SizedBox(height: CyberTokens.spacingSm),
          SwitchListTile(
            key: const Key('incognito_mode_switch'),
            title: const Text('Privacy Incognito Mode', style: TextStyle(color: CyberColors.textPrimaryDark, fontSize: 13)),
            subtitle: const Text('Bypass saving decoded QR codes into persistent local storage', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
            value: isIncognito,
            activeThumbColor: CyberColors.neonEmerald,
            onChanged: (_) {
              widget.scannerController.toggleIncognito();
              setState(() {});
            },
          ),
          const Divider(color: CyberColors.slateBorder, height: 16),
          ListTile(
            title: const Text('Auto-Purge Scanned History', style: TextStyle(color: CyberColors.textPrimaryDark, fontSize: 13)),
            subtitle: const Text('Automatically delete un-favorited scans older than retention threshold', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
            trailing: DropdownButton<int?>(
              key: const Key('auto_purge_dropdown'),
              value: policy.autoPurgeHistoryDays,
              dropdownColor: CyberColors.slateCard,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: null, child: Text('Disabled', style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark))),
                DropdownMenuItem(value: 7, child: Text('7 Days', style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark))),
                DropdownMenuItem(value: 30, child: Text('30 Days', style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark))),
                DropdownMenuItem(value: 90, child: Text('90 Days', style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark))),
              ],
              onChanged: (val) {
                widget.vaultController.updatePrivacyPolicy(
                  policy.copyWith(autoPurgeHistoryDays: val),
                );
                setState(() {});
              },
            ),
          ),
          SwitchListTile(
            key: const Key('keep_favorites_switch'),
            title: const Text('Preserve Favorites on Purge', style: TextStyle(color: CyberColors.textPrimaryDark, fontSize: 13)),
            subtitle: const Text('Ensure favorited records are never deleted during automated retention purges', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
            value: policy.keepFavoritesOnPurge,
            activeThumbColor: CyberColors.neonCyan,
            onChanged: (val) {
              widget.vaultController.updatePrivacyPolicy(
                policy.copyWith(keepFavoritesOnPurge: val),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              CyberButton(
                key: const Key('purge_now_btn'),
                label: 'Purge Expired Now',
                icon: Icons.auto_delete_rounded,
                variant: CyberButtonVariant.secondary,
                onPressed: _handlePurgeExpired,
              ),
              CyberButton(
                key: const Key('clear_history_btn'),
                label: 'Clear All Scans',
                icon: Icons.delete_forever_rounded,
                variant: CyberButtonVariant.danger,
                onPressed: _handleClearAllHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('CRYPTOGRAPHIC BACKUP & PORTABILITY', Icons.cloud_sync_rounded),
          const SizedBox(height: CyberTokens.spacingSm),
          const Text(
            'Export or restore offline vault records. Exported JSON files preserve HMAC-SHA256 signatures to verify records have not been tampered with.',
            style: TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CyberButton(
                key: const Key('export_vault_btn'),
                label: 'Export Vault (JSON)',
                icon: Icons.file_download_outlined,
                onPressed: _handleExportVault,
              ),
              CyberButton(
                key: const Key('import_vault_btn'),
                label: 'Restore Vault (JSON)',
                icon: Icons.file_upload_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: _handleImportVault,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntitlementCard() {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('SECURITY POSTURE & RBAC ENTITLEMENT', Icons.security_rounded),
          const SizedBox(height: CyberTokens.spacingSm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberColors.slateCardSecondary,
              borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
              border: Border.all(color: CyberColors.neonEmerald),
            ),
            child: Column(
              children: [
                _buildEntitlementRow('ASSIGNED ROLE', 'RESTRICTED USER', CyberColors.neonEmerald),
                const Divider(color: CyberColors.slateBorder, height: 12),
                _buildEntitlementRow('BINARY ISOLATION', 'VERIFIED // ZERO GENERATOR', CyberColors.neonCyan),
                const Divider(color: CyberColors.slateBorder, height: 12),
                _buildEntitlementRow('QR SCANNER ENGINE', 'ACTIVE (15+ FORMATS // FIREWALL)', CyberColors.neonEmerald),
                const Divider(color: CyberColors.slateBorder, height: 12),
                _buildEntitlementRow('GENERATOR STUDIO', 'COMPILE-TIME EXCLUDED', CyberColors.textMutedDark),
                const Divider(color: CyberColors.slateBorder, height: 12),
                _buildEntitlementRow('ADMIN ANALYTICS', 'COMPILE-TIME EXCLUDED', CyberColors.textMutedDark),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'QR code artistic generator, custom branding, and fleet analytics are restricted to Admin App (apps/admin_app) via compile-time binary isolation and Ed25519 asymmetric token validation.',
            style: TextStyle(fontSize: 10, color: CyberColors.textMutedDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CyberColors.neonCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: CyberTypography.monospace(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: CyberColors.neonCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildEntitlementRow(String label, String value, Color valueColor) {
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: CyberTypography.monospace(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
