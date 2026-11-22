import 'package:qr_core/qr_core.dart';

/// Aggregated usage statistics for the admin dashboard.
class FleetTelemetrySummary {
  final int totalScans;
  final int totalGenerations;
  final int threatsDetected;
  final Map<QrPayloadType, int> scansByPayloadType;

  const FleetTelemetrySummary({
    required this.totalScans,
    required this.totalGenerations,
    required this.threatsDetected,
    required this.scansByPayloadType,
  });

  Map<String, dynamic> toJson() => {
        'totalScans': totalScans,
        'totalGenerations': totalGenerations,
        'threatsDetected': threatsDetected,
        'scansByPayloadType':
            scansByPayloadType.map((k, v) => MapEntry(k.name, v)),
      };
}

/// Service for calculating and exporting fleet metrics.
class AdminAnalyticsService {
  const AdminAnalyticsService();

  FleetTelemetrySummary aggregateMetrics({
    required List<QrVaultItem> items,
    required int generationCount,
  }) {
    int totalScans = 0;
    int threats = 0;
    final payloadCounts = <QrPayloadType, int>{};

    for (final item in items) {
      totalScans++;
      if (item.threatLevel != SecurityThreatLevel.safe) {
        threats++;
      }
      payloadCounts[item.payloadType] =
          (payloadCounts[item.payloadType] ?? 0) + 1;
    }

    return FleetTelemetrySummary(
      totalScans: totalScans,
      totalGenerations: generationCount,
      threatsDetected: threats,
      scansByPayloadType: payloadCounts,
    );
  }
}
