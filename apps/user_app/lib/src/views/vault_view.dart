import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/vault_controller.dart';
import '../widgets/vault_item_detail_modal.dart';

/// Full-featured Offline Encrypted Vault View supporting search, multi-criteria filtering,
/// tag navigation, multi-selection batch deletion/export, and record inspection.
class VaultView extends StatefulWidget {
  final VaultController controller;
  final VoidCallback? onNavigateToScanner;

  const VaultView({
    super.key,
    required this.controller,
    this.onNavigateToScanner,
  });

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.controller.filter.searchQuery ?? '');
    widget.controller.addListener(_onControllerChanged);
    // Refresh if not loaded yet
    if (widget.controller.items.isEmpty && !widget.controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.controller.refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSearch(String query) {
    widget.controller.updateSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.controller.updateSearchQuery(null);
  }

  Future<void> _handleExportBatch() async {
    final jsonStr = await widget.controller.exportSelectedOrAllToJson();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.slateCard,
        title: Text(
          'VAULT EXPORT // JSON',
          style: CyberTypography.monospace(fontSize: 14, color: CyberColors.neonCyan),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exported ${widget.controller.selectedCount > 0 ? widget.controller.selectedCount : widget.controller.items.length} records with HMAC integrity hashes.',
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
            key: const Key('copy_export_json_btn'),
            label: 'Copy JSON',
            icon: Icons.copy_rounded,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
            },
          ),
          CyberButton(
            key: const Key('close_export_dialog_btn'),
            label: 'Close',
            variant: CyberButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Container(
      color: CyberColors.obsidianBackground,
      child: Column(
        children: [
          // Top Search & Filter Bar
          _buildTopSearchBar(ctrl),

          // Tag Carousel & Sort Bar
          _buildFilterAndSortBar(ctrl),

          // Multi-Select Batch Actions Bar
          if (ctrl.selectedCount > 0) _buildBatchActionBar(ctrl),

          // Main Vault List / Empty State
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator(color: CyberColors.neonCyan))
                : ctrl.items.isEmpty
                    ? _buildEmptyState(ctrl)
                    : _buildItemsList(ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar(VaultController ctrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: CyberColors.slateCard.withValues(alpha: 0.60),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('vault_search_field'),
              controller: _searchController,
              onChanged: _handleSearch,
              style: const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Search vault by title, payload content, notes, or tags...',
                hintStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: CyberColors.neonCyan, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const Key('clear_search_btn'),
                        icon: const Icon(Icons.clear_rounded, size: 18, color: CyberColors.textMutedDark),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: CyberColors.obsidianBackground,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
                  borderSide: const BorderSide(color: CyberColors.slateBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('refresh_vault_btn'),
            icon: const Icon(Icons.refresh_rounded, color: CyberColors.neonCyan),
            tooltip: 'Refresh Vault',
            onPressed: () => ctrl.refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortBar(VaultController ctrl) {
    final filter = ctrl.filter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CyberColors.slateCard.withValues(alpha: 0.40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilterChip(
                  label: 'All (${ctrl.metrics?.totalItems ?? ctrl.items.length})',
                  isSelected: filter.isFavorite == null &&
                      (filter.threatLevels == null || filter.threatLevels!.isEmpty) &&
                      filter.collectionId == null,
                  onSelected: () => ctrl.clearFilters(),
                ),
                const SizedBox(width: 6),
                _buildQuickFilterChip(
                  label: 'Favorites (${ctrl.metrics?.favoritesCount ?? 0})',
                  isSelected: filter.isFavorite == true,
                  icon: Icons.favorite_rounded,
                  iconColor: CyberColors.neonCrimson,
                  onSelected: () {
                    ctrl.setThreatLevelsFilter(null);
                    ctrl.setFavoriteFilter(filter.isFavorite == true ? null : true);
                  },
                ),
                const SizedBox(width: 6),
                _buildQuickFilterChip(
                  label: 'Safe',
                  isSelected: filter.threatLevels?.contains(SecurityThreatLevel.safe) == true,
                  icon: Icons.verified_user_rounded,
                  iconColor: CyberColors.neonEmerald,
                  onSelected: () {
                    final isSafe = filter.threatLevels?.contains(SecurityThreatLevel.safe) == true;
                    ctrl.setFavoriteFilter(null);
                    ctrl.setThreatLevelsFilter(isSafe ? null : {SecurityThreatLevel.safe});
                  },
                ),
                const SizedBox(width: 6),
                _buildQuickFilterChip(
                  label: 'Caution / Threat',
                  isSelected: filter.threatLevels?.contains(SecurityThreatLevel.caution) == true ||
                      filter.threatLevels?.contains(SecurityThreatLevel.critical) == true,
                  icon: Icons.warning_rounded,
                  iconColor: CyberColors.neonAmber,
                  onSelected: () {
                    final active = filter.threatLevels?.contains(SecurityThreatLevel.caution) == true;
                    ctrl.setFavoriteFilter(null);
                    ctrl.setThreatLevelsFilter(
                      active ? null : {SecurityThreatLevel.caution, SecurityThreatLevel.suspicious, SecurityThreatLevel.critical},
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Sort Dropdown
                _buildSortDropdown(ctrl),
              ],
            ),
          ),
          // Tag Carousel if tags exist
          if (ctrl.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'TAGS:',
                    style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
                  ),
                  const SizedBox(width: 6),
                  ...ctrl.tags.map((tag) {
                    final isTagSelected = filter.tags?.contains(tag) == true;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 10, color: isTagSelected ? Colors.black : CyberColors.neonCyan)),
                        selected: isTagSelected,
                        backgroundColor: CyberColors.obsidianBackground,
                        selectedColor: CyberColors.neonCyan,
                        side: const BorderSide(color: CyberColors.slateBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        onSelected: (_) {
                          final currentTags = Set<String>.from(filter.tags ?? {});
                          if (currentTags.contains(tag)) {
                            currentTags.remove(tag);
                          } else {
                            currentTags.add(tag);
                          }
                          ctrl.setTagsFilter(currentTags.isNotEmpty ? currentTags : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.black : (iconColor ?? CyberColors.neonCyan)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : CyberColors.textPrimaryDark,
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: CyberColors.neonCyan,
      backgroundColor: CyberColors.obsidianBackground,
      side: const BorderSide(color: CyberColors.slateBorder),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildSortDropdown(VaultController ctrl) {
    return DropdownButton<QrVaultSortBy>(
      key: const Key('vault_sort_dropdown'),
      value: ctrl.filter.sortBy,
      dropdownColor: CyberColors.slateCard,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.sort_rounded, size: 16, color: CyberColors.neonCyan),
      items: const [
        DropdownMenuItem(
          value: QrVaultSortBy.createdAtDesc,
          child: Text('Newest First', style: TextStyle(fontSize: 11, color: CyberColors.textPrimaryDark)),
        ),
        DropdownMenuItem(
          value: QrVaultSortBy.createdAtAsc,
          child: Text('Oldest First', style: TextStyle(fontSize: 11, color: CyberColors.textPrimaryDark)),
        ),
        DropdownMenuItem(
          value: QrVaultSortBy.titleAsc,
          child: Text('Title (A-Z)', style: TextStyle(fontSize: 11, color: CyberColors.textPrimaryDark)),
        ),
        DropdownMenuItem(
          value: QrVaultSortBy.safetyScoreDesc,
          child: Text('Safety Score (High)', style: TextStyle(fontSize: 11, color: CyberColors.textPrimaryDark)),
        ),
      ],
      onChanged: (val) {
        if (val != null) ctrl.setSortBy(val);
      },
    );
  }

  Widget _buildBatchActionBar(VaultController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CyberColors.neonCyan.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: CyberColors.neonCyan),
          const SizedBox(width: 8),
          Text(
            '${ctrl.selectedCount} RECORD(S) SELECTED',
            style: CyberTypography.monospace(fontSize: 11, fontWeight: FontWeight.w800, color: CyberColors.neonCyan),
          ),
          const Spacer(),
          TextButton(
            key: const Key('batch_select_all_btn'),
            onPressed: () => ctrl.selectAll(),
            child: const Text('Select All', style: TextStyle(color: CyberColors.textPrimaryDark, fontSize: 11)),
          ),
          TextButton(
            key: const Key('batch_clear_selection_btn'),
            onPressed: () => ctrl.clearSelection(),
            child: const Text('Deselect', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 11)),
          ),
          IconButton(
            key: const Key('batch_export_btn'),
            icon: const Icon(Icons.download_rounded, color: CyberColors.neonCyan, size: 18),
            tooltip: 'Export Selected to JSON',
            onPressed: _handleExportBatch,
          ),
          IconButton(
            key: const Key('batch_delete_btn'),
            icon: const Icon(Icons.delete_outline_rounded, color: CyberColors.neonCrimson, size: 18),
            tooltip: 'Delete Selected',
            onPressed: () => ctrl.deleteSelected(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(VaultController ctrl) {
    return ListView.separated(
      key: const Key('vault_items_list'),
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = ctrl.items[index];
        final isSelected = ctrl.isSelected(item.id);

        return _buildItemCard(item, isSelected, ctrl);
      },
    );
  }

  Widget _buildItemCard(QrVaultItem item, bool isSelected, VaultController ctrl) {
    final formatIcon = _resolvePayloadIcon(item.payloadType);

    return InkWell(
      key: Key('vault_item_${item.id}'),
      onTap: () => VaultItemDetailModal.show(
        context: context,
        item: item,
        controller: ctrl,
      ),
      borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? CyberColors.neonCyan.withValues(alpha: 0.10)
              : CyberColors.slateCardSecondary,
          borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
          border: Border.all(
            color: isSelected ? CyberColors.neonCyan : CyberColors.slateBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Checkbox for selection
            Checkbox(
              key: Key('checkbox_${item.id}'),
              value: isSelected,
              activeColor: CyberColors.neonCyan,
              checkColor: Colors.black,
              onChanged: (_) => ctrl.toggleSelection(item.id),
            ),
            // Format icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: CyberColors.obsidianBackground,
                shape: BoxShape.circle,
                border: Border.all(color: CyberColors.slateBorder),
              ),
              child: Icon(formatIcon, size: 18, color: CyberColors.neonCyan),
            ),
            const SizedBox(width: 12),
            // Title & Content preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title ?? item.rawContent,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CyberColors.textPrimaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isTrustQr) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 14, color: CyberColors.neonEmerald),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        item.payloadType.name.toUpperCase(),
                        style: CyberTypography.monospace(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CyberColors.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.createdAt.toLocal().toString().split('.').first,
                        style: const TextStyle(fontSize: 10, color: CyberColors.textMutedDark),
                      ),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '#${item.tags.first}',
                            style: const TextStyle(fontSize: 10, color: CyberColors.neonAmber),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Threat Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _resolveScoreColor(item.safetyScore).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                border: Border.all(color: _resolveScoreColor(item.safetyScore)),
              ),
              child: Text(
                '${item.safetyScore}',
                style: CyberTypography.monospace(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _resolveScoreColor(item.safetyScore),
                ),
              ),
            ),
            // Favorite Button
            IconButton(
              key: Key('item_fav_${item.id}'),
              icon: Icon(
                item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: item.isFavorite ? CyberColors.neonCrimson : CyberColors.textMutedDark,
                size: 20,
              ),
              onPressed: () => ctrl.toggleFavorite(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveScoreColor(int score) {
    if (score >= 80) return CyberColors.neonEmerald;
    if (score >= 50) return CyberColors.neonAmber;
    return CyberColors.neonCrimson;
  }

  IconData _resolvePayloadIcon(QrPayloadType type) {
    switch (type) {
      case QrPayloadType.url:
        return Icons.link_rounded;
      case QrPayloadType.wifi:
        return Icons.wifi_rounded;
      case QrPayloadType.vcard:
      case QrPayloadType.mecard:
        return Icons.contact_page_rounded;
      case QrPayloadType.otpauth:
        return Icons.password_rounded;
      case QrPayloadType.upi:
      case QrPayloadType.epc:
        return Icons.payment_rounded;
      case QrPayloadType.crypto:
        return Icons.currency_bitcoin_rounded;
      case QrPayloadType.geo:
        return Icons.location_on_rounded;
      case QrPayloadType.email:
        return Icons.email_rounded;
      case QrPayloadType.sms:
        return Icons.sms_rounded;
      case QrPayloadType.tel:
        return Icons.phone_rounded;
      case QrPayloadType.event:
        return Icons.event_rounded;
      case QrPayloadType.gs1:
        return Icons.qr_code_2_rounded;
      case QrPayloadType.plainText:
        return Icons.text_snippet_rounded;
    }
  }

  Widget _buildEmptyState(VaultController ctrl) {
    final hasFilters = ctrl.filter.searchQuery != null ||
        ctrl.filter.isFavorite != null ||
        (ctrl.filter.threatLevels != null && ctrl.filter.threatLevels!.isNotEmpty) ||
        ctrl.filter.collectionId != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: CyberGlassCard(
          padding: const EdgeInsets.all(CyberTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: CyberColors.neonCyan),
              const SizedBox(height: 12),
              Text(
                hasFilters ? 'NO MATCHING RECORDS' : 'VAULT IS EMPTY',
                style: CyberTypography.monospace(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CyberColors.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters
                    ? 'No QR codes match the current search query or filter tags.'
                    : 'Scanned codes will be cryptographically signed and stored in this offline vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
              ),
              const SizedBox(height: 16),
              if (hasFilters)
                CyberButton(
                  key: const Key('empty_clear_filters_btn'),
                  label: 'Clear Filters',
                  icon: Icons.filter_alt_off_rounded,
                  onPressed: () {
                    _clearSearch();
                    ctrl.clearFilters();
                  },
                )
              else if (widget.onNavigateToScanner != null)
                CyberButton(
                  key: const Key('empty_open_scanner_btn'),
                  label: 'Open Scanner',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: widget.onNavigateToScanner!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
