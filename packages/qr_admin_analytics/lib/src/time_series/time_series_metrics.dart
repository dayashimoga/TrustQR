import 'time_series_interval.dart';
import 'time_series_point.dart';

/// Aggregated time-series summary metrics, moving averages, and anomaly detections.
class TimeSeriesMetrics {
  final List<TimeSeriesPoint> points;
  final TimeSeriesBucketInterval interval;
  final int totalScans;
  final int totalGenerations;
  final int totalThreats;
  final double averageVolumePerBucket;
  final double volumeStandardDeviation;
  final int peakVolume;
  final DateTime? peakTimestamp;

  const TimeSeriesMetrics({
    required this.points,
    required this.interval,
    required this.totalScans,
    required this.totalGenerations,
    required this.totalThreats,
    required this.averageVolumePerBucket,
    required this.volumeStandardDeviation,
    required this.peakVolume,
    this.peakTimestamp,
  });

  /// Total aggregated QR transactions.
  int get totalVolume => totalScans + totalGenerations;

  /// Ratio of scans to generations (e.g. 3.5 means 3.5 scans per generated code).
  double get scanToGenerationRatio =>
      totalGenerations > 0 ? (totalScans / totalGenerations) : totalScans.toDouble();

  /// Overall threat detection rate across scanned codes.
  double get threatRatePercentage =>
      totalScans > 0 ? ((totalThreats / totalScans) * 100.0) : 0.0;

  /// Anomalous buckets flagged by the detection algorithm.
  List<TimeSeriesPoint> get anomalies =>
      points.where((p) => p.isAnomaly).toList();

  Map<String, dynamic> toJson() => {
    'interval': interval.name,
    'totalScans': totalScans,
    'totalGenerations': totalGenerations,
    'totalThreats': totalThreats,
    'totalVolume': totalVolume,
    'scanToGenerationRatio': scanToGenerationRatio,
    'threatRatePercentage': threatRatePercentage,
    'averageVolumePerBucket': averageVolumePerBucket,
    'volumeStandardDeviation': volumeStandardDeviation,
    'peakVolume': peakVolume,
    'peakTimestamp': peakTimestamp?.toUtc().toIso8601String(),
    'pointCount': points.length,
    'anomalyCount': anomalies.length,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory TimeSeriesMetrics.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List<dynamic>?)
            ?.map((p) => TimeSeriesPoint.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [];

    return TimeSeriesMetrics(
      points: pointsList,
      interval: TimeSeriesBucketInterval.values.byName(
        json['interval'] as String? ?? 'daily',
      ),
      totalScans: (json['totalScans'] as num?)?.toInt() ?? 0,
      totalGenerations: (json['totalGenerations'] as num?)?.toInt() ?? 0,
      totalThreats: (json['totalThreats'] as num?)?.toInt() ?? 0,
      averageVolumePerBucket: (json['averageVolumePerBucket'] as num?)?.toDouble() ?? 0.0,
      volumeStandardDeviation: (json['volumeStandardDeviation'] as num?)?.toDouble() ?? 0.0,
      peakVolume: (json['peakVolume'] as num?)?.toInt() ?? 0,
      peakTimestamp: json['peakTimestamp'] != null
          ? DateTime.parse(json['peakTimestamp'] as String).toUtc()
          : null,
    );
  }
}
