import 'package:flutter/material.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/vault_controller.dart';

/// Collections & Smart Folders view for organizing QR vault records.
class CollectionsView extends StatefulWidget {
  final VaultController controller;
  final ValueChanged<String>? onSelectCollection;

  const CollectionsView({
    super.key,
    required this.controller,
    this.onSelectCollection,
  });

  @override
  State<CollectionsView> createState() => _CollectionsViewState();
}

class _CollectionsViewState extends State<CollectionsView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.collections.isEmpty && !widget.controller.isLoading) {
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
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showCreateCollectionDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedColor = '#00F0FF'; // Neon Cyan default

    final colors = [
      {'name': 'Cyan', 'hex': '#00F0FF', 'color': CyberColors.neonCyan},
      {'name': 'Emerald', 'hex': '#00FF9D', 'color': CyberColors.neonEmerald},
      {'name': 'Amber', 'hex': '#FFB800', 'color': CyberColors.neonAmber},
      {'name': 'Crimson', 'hex': '#FF0055', 'color': CyberColors.neonCrimson},
      {'name': 'Purple', 'hex': '#B026FF', 'color': CyberColors.neonPurple},
      {'name': 'Blue', 'hex': '#0070F3', 'color': CyberColors.electricBlue},
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberColors.slateCard,
          title: Text(
            'NEW COLLECTION',
            style: CyberTypography.monospace(fontSize: 14, color: CyberColors.neonCyan),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('create_collection_name_field'),
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Collection Name',
                    labelStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 12),
                    filled: true,
                    fillColor: CyberColors.obsidianBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.slateBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('create_collection_desc_field'),
                  controller: descCtrl,
                  style: const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 12),
                    filled: true,
                    fillColor: CyberColors.obsidianBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.slateBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'COLOR ACCENT',
                  style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((c) {
                    final hex = c['hex'] as String;
                    final isSel = selectedColor == hex;
                    return InkWell(
                      key: Key('color_choice_$hex'),
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            CyberButton(
              key: const Key('confirm_create_collection_btn'),
              label: 'Create',
              icon: Icons.add_rounded,
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  widget.controller.createCollection(
                    name: name,
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    colorHex: selectedColor,
                  );
                  Navigator.of(ctx).pop();
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

  Future<void> _showDeleteCollectionDialog(QrCollection collection) async {
    bool deleteItemsToo = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberColors.slateCard,
          title: Text(
            'DELETE COLLECTION // ${collection.name.toUpperCase()}',
            style: CyberTypography.monospace(fontSize: 13, color: CyberColors.neonCrimson),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete the "${collection.name}" collection?',
                style: const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const Key('delete_items_too_checkbox'),
                value: deleteItemsToo,
                activeColor: CyberColors.neonCrimson,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Delete contained records too',
                  style: TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark),
                ),
                subtitle: const Text(
                  'If unchecked, records will be unassigned but preserved in the vault.',
                  style: TextStyle(fontSize: 10, color: CyberColors.textMutedDark),
                ),
                onChanged: (val) => setDialogState(() => deleteItemsToo = val ?? false),
              ),
            ],
          ),
          actions: [
            CyberButton(
              key: const Key('confirm_delete_collection_btn'),
              label: 'Delete Collection',
              variant: CyberButtonVariant.danger,
              onPressed: () {
                widget.controller.deleteCollection(
                  collection.id,
                  deleteContainedItems: deleteItemsToo,
                );
                Navigator.of(ctx).pop();
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

  Color _parseHex(String? hex) {
    if (hex == null || !hex.startsWith('#')) return CyberColors.neonCyan;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return CyberColors.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Container(
      color: CyberColors.obsidianBackground,
      child: Column(
        children: [
          // Header Bar
          _buildHeaderBar(),

          // Collections Content
          Expanded(
            child: ctrl.collections.isEmpty
                ? _buildEmptyState()
                : _buildCollectionsList(ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CyberColors.slateCard.withValues(alpha: 0.60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.folder_special_rounded, color: CyberColors.neonCyan, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'COLLECTIONS // SMART FOLDERS',
                    style: CyberTypography.monospace(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CyberColors.neonCyan,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CyberButton(
            key: const Key('new_collection_btn'),
            label: 'New Collection',
            icon: Icons.create_new_folder_rounded,
            onPressed: _showCreateCollectionDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsList(VaultController ctrl) {
    return ListView.separated(
      key: const Key('collections_list'),
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final col = ctrl.collections[index];
        final colColor = _parseHex(col.colorHex);

        return Container(
          key: Key('collection_card_${col.id}'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CyberColors.slateCardSecondary,
            borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
            border: Border.all(color: CyberColors.slateBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: colColor),
                ),
                child: Icon(Icons.folder_rounded, color: colColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CyberColors.textPrimaryDark,
                      ),
                    ),
                    if (col.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        col.description!,
                        style: const TextStyle(fontSize: 11, color: CyberColors.textSecondaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${col.itemCount} RECORD(S)',
                      style: CyberTypography.monospace(fontSize: 10, color: colColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              CyberButton(
                key: Key('view_collection_${col.id}_btn'),
                label: 'View',
                icon: Icons.arrow_forward_rounded,
                variant: CyberButtonVariant.secondary,
                onPressed: () {
                  ctrl.setCollectionFilter(col.id);
                  widget.onSelectCollection?.call(col.id);
                },
              ),
              const SizedBox(width: 6),
              IconButton(
                key: Key('delete_collection_${col.id}_btn'),
                icon: const Icon(Icons.delete_outline_rounded, color: CyberColors.neonCrimson, size: 20),
                tooltip: 'Delete Collection',
                onPressed: () => _showDeleteCollectionDialog(col),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: CyberGlassCard(
          padding: const EdgeInsets.all(CyberTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded, size: 48, color: CyberColors.neonCyan),
              const SizedBox(height: 12),
              Text(
                'NO COLLECTIONS CREATED',
                style: CyberTypography.monospace(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CyberColors.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Organize your vault by creating smart collections (e.g., Work, Travel, Security, Personal).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: CyberColors.textSecondaryDark),
              ),
              const SizedBox(height: 16),
              CyberButton(
                key: const Key('empty_create_collection_btn'),
                label: 'Create First Collection',
                icon: Icons.add_rounded,
                onPressed: _showCreateCollectionDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
