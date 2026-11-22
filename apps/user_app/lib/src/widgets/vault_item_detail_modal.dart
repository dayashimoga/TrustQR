import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/vault_controller.dart';

/// Modal dialog / sheet inspecting a vault item with cryptographic HMAC verification,
/// threat assessment scores, tags management, and notes editing.
class VaultItemDetailModal extends StatefulWidget {
  final QrVaultItem item;
  final VaultController controller;
  final VoidCallback? onDismiss;

  const VaultItemDetailModal({
    super.key,
    required this.item,
    required this.controller,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required QrVaultItem item,
    required VaultController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VaultItemDetailModal(
        item: item,
        controller: controller,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<VaultItemDetailModal> createState() => _VaultItemDetailModalState();
}

class _VaultItemDetailModalState extends State<VaultItemDetailModal> {
  late QrVaultItem _item;
  late final TextEditingController _notesController;
  late final TextEditingController _tagInputController;
  bool _isCopied = false;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _notesController = TextEditingController(text: _item.notes ?? '');
    _tagInputController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFavorite() async {
    final updated = await widget.controller.toggleFavorite(_item.id);
    if (updated != null && mounted) {
      setState(() => _item = updated);
    }
  }

  Future<void> _handleSaveNotes() async {
    setState(() => _isSavingNotes = true);
    final text = _notesController.text.trim();
    final updated = await widget.controller.updateNotes(_item.id, text.isNotEmpty ? text : null);
    if (mounted) {
      setState(() {
        if (updated != null) _item = updated;
        _isSavingNotes = false;
      });
    }
  }

  Future<void> _handleAddTag() async {
    final tag = _tagInputController.text.trim().toLowerCase();
    if (tag.isEmpty || _item.tags.contains(tag)) return;

    final updatedTags = List<String>.from(_item.tags)..add(tag);
    final updated = await widget.controller.setTags(_item.id, updatedTags);
    if (mounted) {
      _tagInputController.clear();
      if (updated != null) {
        setState(() => _item = updated);
      }
    }
  }

  Future<void> _handleRemoveTag(String tag) async {
    final updatedTags = List<String>.from(_item.tags)..remove(tag);
    final updated = await widget.controller.setTags(_item.id, updatedTags);
    if (mounted && updated != null) {
      setState(() => _item = updated);
    }
  }

  Future<void> _handleAssignCollection(String? collectionId) async {
    final updated = await widget.controller.assignCollection(_item.id, collectionId);
    if (mounted && updated != null) {
      setState(() => _item = updated);
    }
  }

  Future<void> _handleDeleteItem() async {
    await widget.controller.deleteItem(_item.id);
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _item.rawContent));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIntact = widget.controller.verifyIntegrity(_item);
    final collections = widget.controller.collections;

    return CyberGlassSheet(
      title: 'RECORD INSPECTOR // ${_item.id.substring(0, _item.id.length.clamp(0, 8)).toUpperCase()}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('favorite_toggle_btn'),
            icon: Icon(
              _item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _item.isFavorite ? CyberColors.neonCrimson : CyberColors.textMutedDark,
            ),
            onPressed: _handleToggleFavorite,
            tooltip: 'Toggle Favorite',
          ),
          IconButton(
            key: const Key('sheet_close_btn'),
            icon: const Icon(Icons.close_rounded, color: CyberColors.textMutedDark),
            onPressed: () => widget.onDismiss?.call(),
            tooltip: 'Close',
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cryptographic Integrity Verification Banner
            _buildIntegrityBanner(isIntact),
            const SizedBox(height: 12),

            // Threat & Score Overview
            _buildThreatOverview(),
            const SizedBox(height: 12),

            // Raw Payload Box
            _buildRawPayloadBox(),
            const SizedBox(height: 12),

            // Metadata Grid
            _buildMetadataGrid(),
            const SizedBox(height: 12),

            // Collection Assignment
            _buildCollectionSelector(collections),
            const SizedBox(height: 12),

            // Tag Manager
            _buildTagManager(),
            const SizedBox(height: 12),

            // Notes Editor
            _buildNotesEditor(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityBanner(bool isIntact) {
    final bgColor = isIntact
        ? CyberColors.neonEmerald.withValues(alpha: 0.12)
        : CyberColors.neonCrimson.withValues(alpha: 0.15);
    final borderColor = isIntact ? CyberColors.neonEmerald : CyberColors.neonCrimson;
    final iconColor = isIntact ? CyberColors.neonEmerald : CyberColors.neonCrimson;
    final text = isIntact
        ? 'HMAC-SHA256 INTEGRITY INTACT // UNTAMPERED'
        : 'SECURITY ALERT: TAMPERED RECORD // INVALID SIGNATURE';

    return Container(
      key: const Key('integrity_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isIntact ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: CyberTypography.monospace(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatOverview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.slateCardSecondary,
        borderRadius: BorderRadius.circular(CyberTokens.radiusMd),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Row(
        children: [
          ThreatScoreGauge(
            score: _item.safetyScore.toDouble(),
            size: 72,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CyberBadge(
                      text: _item.threatLevel.name.toUpperCase(),
                      type: _resolveBadgeType(_item.threatLevel),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'FORMAT: ${_item.payloadType.name.toUpperCase()}',
                        style: CyberTypography.monospace(
                          fontSize: 10,
                          color: CyberColors.neonCyan,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_item.isTrustQr)
                  TrustQrBadge(
                    isAuthentic: true,
                    institutionName: _item.trustQrIssuer,
                    isCompact: false,
                  )
                else
                  const Text(
                    'Standard Unsigned QR Code',
                    style: TextStyle(
                      fontSize: 11,
                      color: CyberColors.textMutedDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CyberBadgeType _resolveBadgeType(SecurityThreatLevel level) {
    switch (level) {
      case SecurityThreatLevel.safe:
        return CyberBadgeType.safe;
      case SecurityThreatLevel.caution:
        return CyberBadgeType.warning;
      case SecurityThreatLevel.suspicious:
      case SecurityThreatLevel.critical:
        return CyberBadgeType.threat;
    }
  }

  Widget _buildRawPayloadBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.obsidianBackground,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RAW PAYLOAD',
                style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
              ),
              InkWell(
                key: const Key('copy_payload_btn'),
                onTap: _handleCopy,
                borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 14,
                        color: _isCopied ? CyberColors.neonEmerald : CyberColors.neonCyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCopied ? 'COPIED' : 'COPY',
                        style: CyberTypography.monospace(
                          fontSize: 10,
                          color: _isCopied ? CyberColors.neonEmerald : CyberColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            _item.rawContent,
            style: CyberTypography.monospace(
              fontSize: 12,
              color: CyberColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.slateCardSecondary,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Column(
        children: [
          _buildMetaRow('RECORD ID', _item.id),
          const Divider(color: CyberColors.slateBorder, height: 12),
          _buildMetaRow('ORIGIN', _item.origin.name.toUpperCase()),
          const Divider(color: CyberColors.slateBorder, height: 12),
          _buildMetaRow('CREATED', _item.createdAt.toLocal().toString().split('.').first),
          if (_item.updatedAt != null) ...[
            const Divider(color: CyberColors.slateBorder, height: 12),
            _buildMetaRow('UPDATED', _item.updatedAt!.toLocal().toString().split('.').first),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
        ),
        Flexible(
          child: Text(
            value,
            style: CyberTypography.monospace(fontSize: 11, color: CyberColors.textPrimaryDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionSelector(List<QrCollection> collections) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.slateCardSecondary,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLLECTION ASSIGNMENT',
            style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            key: const Key('collection_dropdown'),
            initialValue: _item.collectionId,
            dropdownColor: CyberColors.slateCard,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: CyberColors.obsidianBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                borderSide: const BorderSide(color: CyberColors.slateBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None (Unassigned)', style: TextStyle(color: CyberColors.textMutedDark, fontSize: 12)),
              ),
              ...collections.map(
                (c) => DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name, style: const TextStyle(color: CyberColors.textPrimaryDark, fontSize: 12)),
                ),
              ),
            ],
            onChanged: _handleAssignCollection,
          ),
        ],
      ),
    );
  }

  Widget _buildTagManager() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.slateCardSecondary,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAGS',
            style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._item.tags.map(
                (t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 11, color: CyberColors.neonCyan)),
                  backgroundColor: CyberColors.obsidianBackground,
                  side: const BorderSide(color: CyberColors.slateBorder),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: CyberColors.textMutedDark),
                  onDeleted: () => _handleRemoveTag(t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('add_tag_input'),
                  controller: _tagInputController,
                  style: const TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark),
                  decoration: InputDecoration(
                    hintText: 'New tag...',
                    hintStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: CyberColors.obsidianBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                      borderSide: const BorderSide(color: CyberColors.slateBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onSubmitted: (_) => _handleAddTag(),
                ),
              ),
              const SizedBox(width: 8),
              CyberButton(
                key: const Key('add_tag_btn'),
                label: 'Add',
                icon: Icons.add_rounded,
                variant: CyberButtonVariant.secondary,
                onPressed: _handleAddTag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.slateCardSecondary,
        borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
        border: Border.all(color: CyberColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USER NOTES',
            style: CyberTypography.monospace(fontSize: 10, color: CyberColors.textMutedDark),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('notes_input'),
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12, color: CyberColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'Add persistent encrypted notes...',
              hintStyle: const TextStyle(color: CyberColors.textMutedDark, fontSize: 12),
              filled: true,
              fillColor: CyberColors.obsidianBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CyberTokens.radiusSm),
                borderSide: const BorderSide(color: CyberColors.slateBorder),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CyberButton(
              key: const Key('save_notes_btn'),
              label: 'Save Notes',
              icon: Icons.save_rounded,
              isLoading: _isSavingNotes,
              onPressed: _handleSaveNotes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CyberButton(
          key: const Key('delete_record_btn'),
          label: 'Delete Record',
          icon: Icons.delete_outline_rounded,
          variant: CyberButtonVariant.danger,
          onPressed: _handleDeleteItem,
        ),
        const SizedBox(width: 8),
        CyberButton(
          key: const Key('close_detail_btn'),
          label: 'Close',
          variant: CyberButtonVariant.secondary,
          onPressed: () => widget.onDismiss?.call(),
        ),
      ],
    );
  }
}
