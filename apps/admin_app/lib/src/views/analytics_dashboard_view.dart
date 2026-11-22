import 'package:flutter/material.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../state/analytics_controller.dart';
import '../theme/admin_typography.dart';

/// Interactive Fleet Telemetry, Usage Insights & Threat Intelligence Dashboard.
class AnalyticsDashboardView extends StatelessWidget {
  final AnalyticsController analyticsController;

  const AnalyticsDashboardView({
    super.key,
    required this.analyticsController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: analyticsController,
      builder: (context, _) {
        final controller = analyticsController;
        final timeSeries = controller.timeSeriesMetrics;
        final distribution = controller.payloadDistribution;
        final threats = controller.threatSummary;
        final devices = controller.fleetDevices;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 16),
              if (controller.lastExportResult != null) _buildExportBanner(controller),
              _buildKpiGrid(controller),
              const SizedBox(height: 16),
              _buildTimeSeriesChart(controller, timeSeries),
              const SizedBox(height: 16),
              _buildPayloadDistributionCard(distribution),
              const SizedBox(height: 16),
              _buildThreatIntelligenceCard(threats),
              const SizedBox(height: 16),
              _buildFleetDevicesCard(controller, devices),
              const SizedBox(height: 16),
              _buildExportActionsCard(controller),
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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, color: CyberColors.neonCyan, size: 28),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLEET TELEMETRY & THREAT INTELLIGENCE',
                      style: AdminTypography.headerMedium.copyWith(
                        color: CyberColors.neonCyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Real-time aggregation, time-series anomaly detection, and fleet lifecycle management.',
                      style: AdminTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Interval selector chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'INTERVAL:',
                style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                key: const Key('interval_chip_hourly'),
                label: const Text('Hourly'),
                selected: controller.interval == TimeSeriesBucketInterval.hourly,
                onSelected: (_) => controller.setInterval(TimeSeriesBucketInterval.hourly),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const Key('interval_chip_daily'),
                label: const Text('Daily'),
                selected: controller.interval == TimeSeriesBucketInterval.daily,
                onSelected: (_) => controller.setInterval(TimeSeriesBucketInterval.daily),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const Key('interval_chip_weekly'),
                label: const Text('Weekly'),
                selected: controller.interval == TimeSeriesBucketInterval.weekly,
                onSelected: (_) => controller.setInterval(TimeSeriesBucketInterval.weekly),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const Key('interval_chip_monthly'),
                label: const Text('Monthly'),
                selected: controller.interval == TimeSeriesBucketInterval.monthly,
                onSelected: (_) => controller.setInterval(TimeSeriesBucketInterval.monthly),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KPI Metrics Grid
  // ---------------------------------------------------------------------------

  Widget _buildKpiGrid(AnalyticsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'TOTAL FLEET SCANS',
              value: '${controller.totalScans}',
              icon: Icons.qr_code_scanner,
              accentColor: CyberColors.neonCyan,
              subtitle: 'Across all client devices',
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'QR GENERATIONS',
              value: '${controller.totalGenerations}',
              icon: Icons.brush_outlined,
              accentColor: CyberColors.neonAmber,
              subtitle: 'Studio & Batch exports',
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'SECURITY THREATS',
              value: '${controller.totalThreats}',
              icon: Icons.gpp_bad_outlined,
              accentColor: CyberColors.neonCrimson,
              subtitle: '${controller.threatRate.toStringAsFixed(1)}% threat rate',
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'ACTIVE DEVICES',
              value: '${controller.activeDevices}',
              icon: Icons.devices_outlined,
              accentColor: CyberColors.neonEmerald,
              subtitle: 'Heartbeat online',
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: CyberGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
                  ),
                ),
                Icon(icon, color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AdminTypography.headerLarge.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AdminTypography.bodySmall.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Time-Series Activity Chart
  // ---------------------------------------------------------------------------

  Widget _buildTimeSeriesChart(AnalyticsController controller, TimeSeriesMetrics metrics) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME-SERIES ACTIVITY & ANOMALY DETECTION',
                style: AdminTypography.bodySmall.copyWith(
                  color: CyberColors.neonCyan,
                  letterSpacing: 1.0,
                ),
              ),
              if (metrics.anomalies.isNotEmpty)
                CyberBadge(
                  text: '${metrics.anomalies.length} ANOMALIES DETECTED',
                  type: CyberBadgeType.warning,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (metrics.points.isEmpty)
            const Center(child: Text('No telemetry points available'))
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: metrics.points.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final pt = metrics.points[index];
                  final maxVol = metrics.peakVolume > 0 ? metrics.peakVolume : 1;
                  final scanRatio = (pt.scanCount / maxVol).clamp(0.05, 1.0);
                  final genRatio = (pt.generationCount / maxVol).clamp(0.05, 1.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pt.isAnomaly)
                        const Icon(Icons.warning, color: CyberColors.neonCrimson, size: 14),
                      Text(
                        '${pt.totalVolume}',
                        style: AdminTypography.codeSmall.copyWith(
                          color: pt.isAnomaly ? CyberColors.neonCrimson : Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 12,
                            height: 100 * scanRatio,
                            decoration: BoxDecoration(
                              color: CyberColors.neonCyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 12,
                            height: 100 * genRatio,
                            decoration: BoxDecoration(
                              color: CyberColors.neonAmber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${pt.timestamp.month}/${pt.timestamp.day}',
                        style: AdminTypography.codeSmall.copyWith(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _buildLegendItem('Scans', CyberColors.neonCyan),
              _buildLegendItem('Generations', CyberColors.neonAmber),
              _buildLegendItem('Anomalies', CyberColors.neonCrimson),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: AdminTypography.codeSmall.copyWith(color: Colors.white70)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 15-Format Distribution Breakdown
  // ---------------------------------------------------------------------------

  Widget _buildPayloadDistributionCard(PayloadDistribution distribution) {
    final topFormats = distribution.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '15-FORMAT PAYLOAD DISTRIBUTION BREAKDOWN',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonCyan,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topFormats.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = topFormats[index];
              final pct = distribution.percentages[entry.key] ?? 0.0;
              final share = (pct / 100.0).clamp(0.01, 1.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.name.toUpperCase(),
                        style: AdminTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.value} items (${pct.toStringAsFixed(1)}%)',
                        style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonCyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: share,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(CyberColors.neonCyan),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Security Threat Intelligence
  // ---------------------------------------------------------------------------

  Widget _buildThreatIntelligenceCard(ThreatAnalyticsSummary threats) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECURITY THREAT INTELLIGENCE',
                style: AdminTypography.bodySmall.copyWith(
                  color: CyberColors.neonCrimson,
                  letterSpacing: 1.0,
                ),
              ),
              CyberBadge(
                text: '${threats.totalAudited} INSPECTED',
                type: CyberBadgeType.info,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Risk Histogram Buckets
          Text(
            'RISK SCORE DISTRIBUTION HISTOGRAM:',
            style: AdminTypography.codeSmall.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: threats.scoreHistogram.entries.map((b) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '${b.key}: ${b.value}',
                  style: AdminTypography.codeSmall.copyWith(
                    color: b.key.startsWith('0-') ? CyberColors.neonCrimson : CyberColors.neonEmerald,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Top Malicious Domains Table
          Text(
            'TOP MALICIOUS DOMAINS DETECTED:',
            style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonCrimson),
          ),
          const SizedBox(height: 8),
          if (threats.topMaliciousDomains.isEmpty)
            Text('No malicious domains detected.',
                style: AdminTypography.bodySmall.copyWith(color: Colors.white38))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: threats.topMaliciousDomains.entries.take(4).length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final entry = threats.topMaliciousDomains.entries.toList()[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: CyberColors.neonCrimson, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: AdminTypography.codeSmall.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${entry.value} BLOCKED',
                      style: AdminTypography.codeSmall.copyWith(color: CyberColors.neonCrimson),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fleet Devices & Token Management
  // ---------------------------------------------------------------------------

  Widget _buildFleetDevicesCard(AnalyticsController controller, List<FleetDevice> devices) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FLEET HARDWARE & CREDENTIAL LIFECYCLE',
                style: AdminTypography.bodySmall.copyWith(
                  color: CyberColors.neonCyan,
                  letterSpacing: 1.0,
                ),
              ),
              CyberBadge(
                text: '${devices.length} REGISTERED',
                type: CyberBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 16),
            itemBuilder: (context, index) {
              final dev = devices[index];

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dev.os.toUpperCase(),
                      style: AdminTypography.codeSmall.copyWith(
                        color: CyberColors.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dev.deviceName,
                          style: AdminTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                        Text(
                          'ID: ${dev.deviceId} • Scans: ${dev.scansRecorded} • Threats: ${dev.threatsEncountered}',
                          style: AdminTypography.codeSmall.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  CyberBadge(
                    text: dev.isRevoked ? 'REVOKED' : 'ACTIVE',
                    type: dev.isRevoked ? CyberBadgeType.threat : CyberBadgeType.safe,
                  ),
                  const SizedBox(width: 12),
                  if (dev.isRevoked)
                    IconButton(
                      key: Key('restore_device_${dev.deviceId}'),
                      icon: const Icon(Icons.restart_alt, color: CyberColors.neonEmerald, size: 20),
                      tooltip: 'Restore Device',
                      onPressed: () => controller.restoreDevice(dev.deviceId),
                    )
                  else
                    IconButton(
                      key: Key('revoke_device_${dev.deviceId}'),
                      icon: const Icon(Icons.block, color: CyberColors.neonCrimson, size: 20),
                      tooltip: 'Revoke Device',
                      onPressed: () => controller.revokeDevice(dev.deviceId),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export Actions Card
  // ---------------------------------------------------------------------------

  Widget _buildExportActionsCard(AnalyticsController controller) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CANONICAL REPORT EXPORTERS',
            style: AdminTypography.bodySmall.copyWith(
              color: CyberColors.neonAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              CyberButton(
                key: const Key('export_json_report_btn'),
                label: 'Export JSON Report',
                icon: Icons.data_object,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.exportCanonicalJson,
              ),
              CyberButton(
                key: const Key('export_time_series_csv_btn'),
                label: 'Export Time-Series CSV',
                icon: Icons.timeline,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.exportTimeSeriesCsv,
              ),
              CyberButton(
                key: const Key('export_payload_csv_btn'),
                label: 'Export Payload Breakdown CSV',
                icon: Icons.pie_chart_outline,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.exportPayloadBreakdownCsv,
              ),
              CyberButton(
                key: const Key('export_threats_csv_btn'),
                label: 'Export Threats CSV',
                icon: Icons.security,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.exportThreatsCsv,
              ),
              CyberButton(
                key: const Key('export_fleet_csv_btn'),
                label: 'Export Fleet CSV',
                icon: Icons.devices,
                variant: CyberButtonVariant.secondary,
                onPressed: controller.exportFleetInventoryCsv,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export Notification Banner
  // ---------------------------------------------------------------------------

  Widget _buildExportBanner(AnalyticsController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.neonEmerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CyberColors.neonEmerald),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: CyberColors.neonEmerald, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${controller.lastExportType} generated successfully (${controller.lastExportResult?.length ?? 0} characters).',
              key: const Key('export_banner_text'),
              style: AdminTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
