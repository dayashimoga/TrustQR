import 'package:qr_core/qr_core.dart';

/// Aggregated breakdown of all 15 supported QR payload formats with counts and percentages.
class PayloadDistribution {
  final Map<QrPayloadType, int> counts;
  final Map<QrPayloadType, double> percentages;
  final int totalCount;
  final QrPayloadType? topFormat;
  final QrPayloadType? topNonUrlFormat;

  const PayloadDistribution({
    required this.counts,
    required this.percentages,
    required this.totalCount,
    this.topFormat,
    this.topNonUrlFormat,
  });

  /// Factory constructing distribution from raw counts.
  factory PayloadDistribution.fromCounts(Map<QrPayloadType, int> rawCounts) {
    final cleanCounts = <QrPayloadType, int>{};
    for (final type in QrPayloadType.values) {
      cleanCounts[type] = rawCounts[type] ?? 0;
    }

    final total = cleanCounts.values.fold<int>(0, (sum, count) => sum + count);
    final cleanPercentages = <QrPayloadType, double>{};

    QrPayloadType? top;
    int topCount = -1;

    QrPayloadType? topNonUrl;
    int topNonUrlCount = -1;

    for (final entry in cleanCounts.entries) {
      final type = entry.key;
      final count = entry.value;

      final pct = total > 0 ? (count / total) * 100.0 : 0.0;
      cleanPercentages[type] = double.parse(pct.toStringAsFixed(2));

      if (count > topCount) {
        topCount = count;
        top = type;
      }

      if (type != QrPayloadType.url && count > topNonUrlCount) {
        topNonUrlCount = count;
        topNonUrl = type;
      }
    }

    return PayloadDistribution(
      counts: cleanCounts,
      percentages: cleanPercentages,
      totalCount: total,
      topFormat: topCount > 0 ? top : null,
      topNonUrlFormat: topNonUrlCount > 0 ? topNonUrl : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalCount': totalCount,
    'topFormat': topFormat?.name,
    'topNonUrlFormat': topNonUrlFormat?.name,
    'counts': counts.map((k, v) => MapEntry(k.name, v)),
    'percentages': percentages.map((k, v) => MapEntry(k.name, v)),
  };

  factory PayloadDistribution.fromJson(Map<String, dynamic> json) {
    final rawCounts = <QrPayloadType, int>{};
    final jsonCounts = json['counts'] as Map<String, dynamic>? ?? {};
    for (final entry in jsonCounts.entries) {
      try {
        final type = QrPayloadType.values.byName(entry.key);
        rawCounts[type] = (entry.value as num).toInt();
      } catch (_) {}
    }
    return PayloadDistribution.fromCounts(rawCounts);
  }
}
