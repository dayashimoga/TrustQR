/// Comprehensive security metrics summarizing threat firewall classifications and risk distributions.
class ThreatAnalyticsSummary {
  final int totalAudited;
  final int safeCount;
  final int cautionCount;
  final int suspiciousCount;
  final int criticalCount;
  final double averageSafetyScore;
  final Map<String, int> attackCategoryCounts;
  final Map<String, int> topMaliciousDomains;
  final Map<String, int> scoreHistogram;

  const ThreatAnalyticsSummary({
    required this.totalAudited,
    required this.safeCount,
    required this.cautionCount,
    required this.suspiciousCount,
    required this.criticalCount,
    required this.averageSafetyScore,
    required this.attackCategoryCounts,
    required this.topMaliciousDomains,
    required this.scoreHistogram,
  });

  /// Total count of items classified as non-safe threats.
  int get totalThreats => cautionCount + suspiciousCount + criticalCount;

  /// Overall threat percentage of audited items.
  double get threatRatePercentage =>
      totalAudited > 0 ? double.parse(((totalThreats / totalAudited) * 100.0).toStringAsFixed(2)) : 0.0;

  Map<String, dynamic> toJson() => {
    'totalAudited': totalAudited,
    'safeCount': safeCount,
    'cautionCount': cautionCount,
    'suspiciousCount': suspiciousCount,
    'criticalCount': criticalCount,
    'totalThreats': totalThreats,
    'threatRatePercentage': threatRatePercentage,
    'averageSafetyScore': averageSafetyScore,
    'attackCategoryCounts': attackCategoryCounts,
    'topMaliciousDomains': topMaliciousDomains,
    'scoreHistogram': scoreHistogram,
  };

  factory ThreatAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return ThreatAnalyticsSummary(
      totalAudited: (json['totalAudited'] as num?)?.toInt() ?? 0,
      safeCount: (json['safeCount'] as num?)?.toInt() ?? 0,
      cautionCount: (json['cautionCount'] as num?)?.toInt() ?? 0,
      suspiciousCount: (json['suspiciousCount'] as num?)?.toInt() ?? 0,
      criticalCount: (json['criticalCount'] as num?)?.toInt() ?? 0,
      averageSafetyScore: (json['averageSafetyScore'] as num?)?.toDouble() ?? 100.0,
      attackCategoryCounts: (json['attackCategoryCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      topMaliciousDomains: (json['topMaliciousDomains'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      scoreHistogram: (json['scoreHistogram'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
    );
  }
}
