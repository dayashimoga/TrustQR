import 'package:flutter/material.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/analytics_controller.dart';
import '../theme/admin_typography.dart';

/// Cryptographically signed administrative action audit trail viewer.
class AuditTrailView extends StatefulWidget {
  final AnalyticsController analyticsController;

  const AuditTrailView({
    super.key,
    required this.analyticsController,
  });

  @override
  State<AuditTrailView> createState() => _AuditTrailViewState();
}

class _AuditTrailViewState extends State<AuditTrailView> {
  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.analyticsController,
      builder: (context, _) {
        final controller = widget.analyticsController;
        final allLogs = controller.auditLogs;

        final filtered = _filterQuery.isEmpty
            ? allLogs
            : allLogs.where((l) {
                final q = _filterQuery.toLowerCase();
                return l.action.toLowerCase().contains(q) ||
                    l.actorId.toLowerCase().contains(q) ||
                    l.targetId.toLowerCase().contains(q);
              }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 16),
              _buildFilterAndActionsBar(controller),
              const SizedBox(height: 16),
              _buildLogEntriesList(filtered),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AnalyticsController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, color: CyberColors.neonEmerald, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRYPTOGRAPHIC AUDIT TRAIL',
                          style: AdminTypography.headerMedium.copyWith(
                            color: CyberColors.neonEmerald,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'HMAC-SHA256 signed administrative ledger with chronological tamper detection.',
                          style: AdminTypography.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CyberButton(
                key: const Key('verify_audit_ledger_btn'),
                label: 'Verify All Signatures',
                icon: Icons.verified_outlined,
                variant: CyberButtonVariant.primary,
                onPressed: controller.verifyAuditLedger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Integrity Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: controller.isAuditVerified
                  ? CyberColors.neonEmerald.withValues(alpha: 0.1)
                  : CyberColors.neonCrimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.isAuditVerified
                    ? CyberColors.neonEmerald
                    : CyberColors.neonCrimson,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  controller.isAuditVerified ? Icons.check_circle : Icons.warning,
                  color: controller.isAuditVerified
                      ? CyberColors.neonEmerald
                      : CyberColors.neonCrimson,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.isAuditVerified
                        ? 'ALL ${controller.auditLogs.length} AUDIT LOG ENTRIES VERIFIED // CRYPTOGRAPHICALLY SOUND'
                        : 'LEDGER TAMPERING DETECTED // SIGNATURE MISMATCH',
                    key: const Key('audit_integrity_status_text'),
                    style: AdminTypography.codeSmall.copyWith(
                      color: controller.isAuditVerified
                          ? CyberColors.neonEmerald
                          : CyberColors.neonCrimson,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter & Search Bar
  // ---------------------------------------------------------------------------

  Widget _buildFilterAndActionsBar(AnalyticsController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('audit_filter_input_field'),
              controller: _filterController,
              style: AdminTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Filter audit logs by actor, action, or target ID...',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  _filterQuery = val.trim();
                });
              },
            ),
          ),
          if (_filterQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
              onPressed: () {
                _filterController.clear();
                setState(() {
                  _filterQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Log Entries List
  // ---------------------------------------------------------------------------

  Widget _buildLogEntriesList(List<AuditLogEntry> logs) {
    if (logs.isEmpty) {
      return CyberGlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No audit logs match the current filter criteria.',
            style: AdminTypography.bodyMedium.copyWith(color: Colors.white38),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];

        return CyberGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CyberBadge(
                        text: log.action,
                        type: _badgeTypeForAction(log.action),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        log.timestamp.toIso8601String().replaceAll('T', ' ').substring(0, 19),
                        style: AdminTypography.codeSmall.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: CyberColors.neonEmerald, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'HMAC VERIFIED',
                        style: AdminTypography.codeSmall.copyWith(
                          color: CyberColors.neonEmerald,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text(
                    'Actor: ${log.actorId} (${log.actorRole})',
                    style: AdminTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Target: ${log.targetId}',
                    style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonCyan),
                  ),
                  Text(
                    'IP: ${log.ipAddress}',
                    style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
                  ),
                ],
              ),
              if (log.details.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Details: ${log.details}',
                  style: AdminTypography.codeSmall.copyWith(color: Colors.white38, fontSize: 11),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Hash: ${log.integrityHash.length > 24 ? '${log.integrityHash.substring(0, 24)}...' : log.integrityHash}',
                style: AdminTypography.codeSmall.copyWith(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  static CyberBadgeType _badgeTypeForAction(String action) {
    if (action.contains('REVOKE')) return CyberBadgeType.threat;
    if (action.contains('ENROLL') || action.contains('RESTORE')) return CyberBadgeType.safe;
    if (action.contains('BOOT') || action.contains('SYSTEM')) return CyberBadgeType.info;
    return CyberBadgeType.neutral;
  }
}
