import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import '../state/batch_controller.dart';
import '../theme/admin_typography.dart';

/// Interactive high-throughput batch QR generator and pure-Dart ZIP exporter view.
class BatchGeneratorView extends StatefulWidget {
  final BatchController batchController;

  const BatchGeneratorView({
    super.key,
    required this.batchController,
  });

  @override
  State<BatchGeneratorView> createState() => _BatchGeneratorViewState();
}

class _BatchGeneratorViewState extends State<BatchGeneratorView> {
  final TextEditingController _rawTextController = TextEditingController();

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.batchController,
      builder: (context, _) {
        final controller = widget.batchController;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 16),
              if (controller.isProcessing) _buildProgressCard(controller),
              if (controller.lastZipBytes != null) _buildExportResultCard(controller),
              const SizedBox(height: 16),
              _buildInputAndControlsCard(controller),
              const SizedBox(height: 16),
              _buildItemsListCard(controller),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BatchController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers_outlined, color: CyberColors.neonCyan, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'BATCH GENERATOR // ZIP EXPORTER',
                    style: AdminTypography.headerMedium.copyWith(
                      color: CyberColors.neonCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              CyberBadge(
                key: const Key('batch_count_badge'),
                text: '${controller.itemCount} ITEMS LOADED',
                type: controller.itemCount > 0 ? CyberBadgeType.safe : CyberBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'High-throughput multi-format QR generation with batch scannability scoring and pure-Dart ZIP bundling.',
            style: AdminTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CyberButton(
                key: const Key('preset_asset_tags_btn'),
                label: 'Load Asset Tags',
                icon: Icons.inventory_2_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.loadAssetTagsPreset,
              ),
              CyberButton(
                key: const Key('preset_employee_btn'),
                label: 'Load Employee Badges',
                icon: Icons.badge_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.loadEmployeeBadgesPreset,
              ),
              CyberButton(
                key: const Key('preset_wifi_btn'),
                label: 'Load Wi-Fi Stations',
                icon: Icons.wifi_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.loadWifiHotspotsPreset,
              ),
              CyberButton(
                key: const Key('batch_clear_btn'),
                label: 'Clear All',
                icon: Icons.delete_sweep_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.clearItems,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input & Generation Controls Card
  // ---------------------------------------------------------------------------

  Widget _buildInputAndControlsCard(BatchController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMPORT CSV OR JSON DEFINITIONS',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('batch_raw_input_field'),
            controller: _rawTextController,
            maxLines: 4,
            style: AdminTypography.codeSmall.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'id,content,title,subtitle,templateId\nTAG-01,https://corp.local/1,Machine A,Rack 1,corporateNavy',
              hintStyle: AdminTypography.codeSmall.copyWith(color: Colors.white24),
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              CyberButton(
                key: const Key('batch_parse_csv_btn'),
                label: 'Parse CSV',
                icon: Icons.table_chart_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: () {
                  if (_rawTextController.text.isNotEmpty) {
                    controller.parseCsv(_rawTextController.text);
                    _rawTextController.clear();
                  }
                },
              ),
              CyberButton(
                key: const Key('batch_parse_json_btn'),
                label: 'Parse JSON',
                icon: Icons.data_object_outlined,
                variant: CyberButtonVariant.secondary,
                onPressed: () {
                  if (_rawTextController.text.isNotEmpty) {
                    controller.parseJson(_rawTextController.text);
                    _rawTextController.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Format selection and Batch Generate
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXPORT FORMAT:',
                    style: AdminTypography.codeSmall.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    key: const Key('format_chip_png'),
                    label: const Text('PNG 300 DPI'),
                    selected: controller.selectedFormat == ExportFormat.png,
                    onSelected: (_) => controller.setSelectedFormat(ExportFormat.png),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('format_chip_svg'),
                    label: const Text('Vector SVG'),
                    selected: controller.selectedFormat == ExportFormat.svg,
                    onSelected: (_) => controller.setSelectedFormat(ExportFormat.svg),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('format_chip_pdf'),
                    label: const Text('Print PDF'),
                    selected: controller.selectedFormat == ExportFormat.pdf,
                    onSelected: (_) => controller.setSelectedFormat(ExportFormat.pdf),
                  ),
                ],
              ),
              CyberButton(
                key: const Key('batch_generate_zip_btn'),
                label: 'Generate Batch & Download ZIP',
                icon: Icons.archive_outlined,
                variant: CyberButtonVariant.primary,
                onPressed: controller.itemCount > 0 && !controller.isProcessing
                    ? () => controller.generateBatch()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress Card
  // ---------------------------------------------------------------------------

  Widget _buildProgressCard(BatchController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.neonCyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GENERATING QR MATRIX BUNDLE...',
                style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonCyan),
              ),
              Text(
                '${(controller.progress * 100).toInt()}%',
                style: AdminTypography.codeSmall.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: controller.progress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(CyberColors.neonCyan),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export Result Card
  // ---------------------------------------------------------------------------

  Widget _buildExportResultCard(BatchController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.neonEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.neonEmerald.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: CyberColors.neonEmerald, size: 22),
              const SizedBox(width: 8),
              Text(
                'BATCH ZIP ARCHIVE COMPILED SUCCESSFULLY',
                style: AdminTypography.bodyMedium.copyWith(
                  color: CyberColors.neonEmerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                'Archive: ${controller.lastZipName}',
                style: AdminTypography.codeSmall.copyWith(color: Colors.white),
              ),
              Text(
                'Size: ${controller.lastZipSize} bytes',
                style: AdminTypography.codeSmall.copyWith(color: Colors.white70),
              ),
              Text(
                'Items: ${controller.successCount} generated',
                style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonEmerald),
              ),
            ],
          ),
          if (controller.lastZipSha256 != null) ...[
            const SizedBox(height: 6),
            Text(
              'SHA-256: ${controller.lastZipSha256}',
              key: const Key('batch_zip_hash_text'),
              style: AdminTypography.codeSmall.copyWith(
                color: CyberColors.neonCyan,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Items List Card
  // ---------------------------------------------------------------------------

  Widget _buildItemsListCard(BatchController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUEUE ITEMS (${controller.itemCount})',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonCyan,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (controller.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No items in batch queue. Load a preset or parse CSV above.',
                  style: AdminTypography.bodyMedium.copyWith(color: Colors.white38),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 16),
              itemBuilder: (context, index) {
                final item = controller.items[index];
                final report = controller.getScannability(item.id);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: AdminTypography.codeSmall.copyWith(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.id,
                                style: AdminTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.title != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${item.title}',
                                  style: AdminTypography.bodySmall.copyWith(color: Colors.white70),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminTypography.codeSmall.copyWith(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                    if (report != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: report.isScannable
                              ? CyberColors.neonEmerald.withValues(alpha: 0.15)
                              : CyberColors.neonCrimson.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: report.isScannable
                                ? CyberColors.neonEmerald
                                : CyberColors.neonCrimson,
                          ),
                        ),
                        child: Text(
                          '${report.overallScore}% SCAN',
                          style: AdminTypography.codeSmall.copyWith(
                            color: report.isScannable
                                ? CyberColors.neonEmerald
                                : CyberColors.neonCrimson,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    IconButton(
                      key: Key('batch_remove_${item.id}'),
                      icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                      tooltip: 'Remove Item',
                      onPressed: () => controller.removeItem(item.id),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
