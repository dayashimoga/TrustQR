/// A discrete time-series data point capturing volume and security telemetry.
class TimeSeriesPoint {
  final DateTime timestamp;
  final int scanCount;
  final int generationCount;
  final int threatCount;
  final double? movingAverage;
  final bool isAnomaly;

  const TimeSeriesPoint({
    required this.timestamp,
    required this.scanCount,
    required this.generationCount,
    required this.threatCount,
    this.movingAverage,
    this.isAnomaly = false,
  });

  /// Total QR transaction volume for this bucket.
  int get totalVolume => scanCount + generationCount;

  /// Alias for [scanCount].
  int get scans => scanCount;

  /// Alias for [generationCount].
  int get generations => generationCount;

  /// Alias for [threatCount].
  int get threats => threatCount;

  /// Percentage of scans classified as security threats.
  double get threatRatePercentage =>
      scanCount > 0 ? (threatCount / scanCount) * 100.0 : 0.0;

  TimeSeriesPoint copyWith({
    DateTime? timestamp,
    int? scanCount,
    int? generationCount,
    int? threatCount,
    double? movingAverage,
    bool? isAnomaly,
  }) {
    return TimeSeriesPoint(
      timestamp: timestamp ?? this.timestamp,
      scanCount: scanCount ?? this.scanCount,
      generationCount: generationCount ?? this.generationCount,
      threatCount: threatCount ?? this.threatCount,
      movingAverage: movingAverage ?? this.movingAverage,
      isAnomaly: isAnomaly ?? this.isAnomaly,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'scanCount': scanCount,
    'generationCount': generationCount,
    'threatCount': threatCount,
    'totalVolume': totalVolume,
    'movingAverage': movingAverage,
    'isAnomaly': isAnomaly,
  };

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
      scanCount: (json['scanCount'] as num).toInt(),
      generationCount: (json['generationCount'] as num).toInt(),
      threatCount: (json['threatCount'] as num).toInt(),
      movingAverage: (json['movingAverage'] as num?)?.toDouble(),
      isAnomaly: (json['isAnomaly'] as bool?) ?? false,
    );
  }
}
