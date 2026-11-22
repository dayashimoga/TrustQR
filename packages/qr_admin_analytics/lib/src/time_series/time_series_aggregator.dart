import 'dart:math' as math;
import 'package:qr_core/qr_core.dart';
import 'time_series_interval.dart';
import 'time_series_metrics.dart';
import 'time_series_point.dart';

/// Aggregator converting discrete vault and generation timestamps into continuous,
/// moving-average smoothed time-series with z-score anomaly detection.
class TimeSeriesAggregator {
  const TimeSeriesAggregator();

  /// Aggregates scan items and generation timestamps into bucketed time-series metrics.
  TimeSeriesMetrics aggregate({
    List<QrVaultItem> scannedItems = const [],
    List<DateTime> generationTimestamps = const [],
    TimeSeriesBucketInterval interval = TimeSeriesBucketInterval.daily,
    DateTime? startDate,
    DateTime? endDate,
    int movingAveragePeriod = 7,
    double anomalyZScoreThreshold = 2.0,
  }) {
    if (scannedItems.isEmpty && generationTimestamps.isEmpty) {
      return TimeSeriesMetrics(
        points: const [],
        interval: interval,
        totalScans: 0,
        totalGenerations: 0,
        totalThreats: 0,
        averageVolumePerBucket: 0.0,
        volumeStandardDeviation: 0.0,
        peakVolume: 0,
      );
    }

    // Determine temporal boundaries
    DateTime minDate = startDate?.toUtc() ?? DateTime(2099);
    DateTime maxDate = endDate?.toUtc() ?? DateTime(1970);

    for (final item in scannedItems) {
      final t = item.createdAt.toUtc();
      if (startDate == null && t.isBefore(minDate)) minDate = t;
      if (endDate == null && t.isAfter(maxDate)) maxDate = t;
    }

    for (final t in generationTimestamps) {
      final utc = t.toUtc();
      if (startDate == null && utc.isBefore(minDate)) minDate = utc;
      if (endDate == null && utc.isAfter(maxDate)) maxDate = utc;
    }

    if (minDate.isAfter(maxDate)) {
      minDate = maxDate;
    }

    final truncatedStart = interval.truncate(minDate);
    final truncatedEnd = interval.truncate(maxDate);

    // Initialize all intermediate continuous buckets with zero counts
    final bucketMap = <DateTime, _MutableBucket>{};
    var current = truncatedStart;
    while (!current.isAfter(truncatedEnd)) {
      bucketMap[current] = _MutableBucket(timestamp: current);
      current = interval.next(current);
    }

    // Map scanned items into buckets
    int totalScans = 0;
    int totalThreats = 0;
    for (final item in scannedItems) {
      final bucketTime = interval.truncate(item.createdAt);
      if (bucketMap.containsKey(bucketTime)) {
        totalScans++;
        bucketMap[bucketTime]!.scanCount++;
        if (item.threatLevel != SecurityThreatLevel.safe) {
          totalThreats++;
          bucketMap[bucketTime]!.threatCount++;
        }
      }
    }

    // Map generations into buckets
    int totalGenerations = 0;
    for (final genTime in generationTimestamps) {
      final bucketTime = interval.truncate(genTime);
      if (bucketMap.containsKey(bucketTime)) {
        totalGenerations++;
        bucketMap[bucketTime]!.generationCount++;
      }
    }

    // Sort buckets chronologically
    final sortedTimes = bucketMap.keys.toList()..sort();
    final rawPoints = sortedTimes.map((t) {
      final b = bucketMap[t]!;
      return TimeSeriesPoint(
        timestamp: t,
        scanCount: b.scanCount,
        generationCount: b.generationCount,
        threatCount: b.threatCount,
      );
    }).toList();

    // Compute basic statistics
    final totalBuckets = rawPoints.length;
    final totalVol = totalScans + totalGenerations;
    final avgVolume = totalBuckets > 0 ? (totalVol / totalBuckets) : 0.0;

    // Standard deviation
    double sumSquaredDiff = 0.0;
    int peak = 0;
    DateTime? peakTime;

    for (final p in rawPoints) {
      final diff = p.totalVolume - avgVolume;
      sumSquaredDiff += diff * diff;
      if (p.totalVolume > peak) {
        peak = p.totalVolume;
        peakTime = p.timestamp;
      }
    }

    final stdDev = totalBuckets > 1
        ? math.sqrt(sumSquaredDiff / (totalBuckets - 1))
        : 0.0;

    // Compute moving averages & z-score anomaly tags
    final finalPoints = <TimeSeriesPoint>[];
    for (var i = 0; i < rawPoints.length; i++) {
      final p = rawPoints[i];

      // Simple Moving Average (window up to movingAveragePeriod)
      final windowStart = math.max(0, i - movingAveragePeriod + 1);
      final windowPoints = rawPoints.sublist(windowStart, i + 1);
      final windowSum = windowPoints.fold<int>(0, (sum, pt) => sum + pt.totalVolume);
      final sma = windowSum / windowPoints.length;

      // Anomaly detection: z-score test
      bool isAnomaly = false;
      if (stdDev > 0) {
        final zScore = (p.totalVolume - avgVolume).abs() / stdDev;
        if (zScore >= anomalyZScoreThreshold) {
          isAnomaly = true;
        }
      }

      finalPoints.add(p.copyWith(
        movingAverage: double.parse(sma.toStringAsFixed(2)),
        isAnomaly: isAnomaly,
      ));
    }

    return TimeSeriesMetrics(
      points: finalPoints,
      interval: interval,
      totalScans: totalScans,
      totalGenerations: totalGenerations,
      totalThreats: totalThreats,
      averageVolumePerBucket: double.parse(avgVolume.toStringAsFixed(2)),
      volumeStandardDeviation: double.parse(stdDev.toStringAsFixed(2)),
      peakVolume: peak,
      peakTimestamp: peakTime,
    );
  }
}

class _MutableBucket {
  final DateTime timestamp;
  int scanCount = 0;
  int generationCount = 0;
  int threatCount = 0;

  _MutableBucket({required this.timestamp});
}
