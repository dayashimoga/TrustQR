import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('TimeSeriesBucketInterval Tests', () {
    final testDate = DateTime.utc(2026, 11, 22, 14, 35, 45);

    test('Hourly interval truncates, steps, and formats correctly', () {
      const interval = TimeSeriesBucketInterval.hourly;
      final truncated = interval.truncate(testDate);
      expect(truncated, equals(DateTime.utc(2026, 11, 22, 14, 0, 0)));

      final next = interval.nextBucket(truncated);
      expect(next, equals(DateTime.utc(2026, 11, 22, 15, 0, 0)));

      final label = interval.formatLabel(testDate);
      expect(label, contains('14:00'));
    });

    test('Daily interval truncates, steps, and formats correctly', () {
      const interval = TimeSeriesBucketInterval.daily;
      final truncated = interval.truncate(testDate);
      expect(truncated, equals(DateTime.utc(2026, 11, 22, 0, 0, 0)));

      final next = interval.nextBucket(truncated);
      expect(next, equals(DateTime.utc(2026, 11, 23, 0, 0, 0)));

      final label = interval.formatLabel(testDate);
      expect(label, equals('2026-11-22'));
    });

    test('Weekly interval truncates, steps, and formats correctly', () {
      const interval = TimeSeriesBucketInterval.weekly;
      final truncated = interval.truncate(testDate);
      // 2026-11-22 is Sunday (weekday 7), Monday of this week is 2026-11-16
      expect(truncated.weekday, equals(DateTime.monday));
      expect(truncated.hour, equals(0));

      final next = interval.nextBucket(truncated);
      expect(next.difference(truncated).inDays, equals(7));

      final label = interval.formatLabel(testDate);
      expect(label, startsWith('Wk '));
    });

    test('Monthly interval truncates, steps, and formats correctly', () {
      const interval = TimeSeriesBucketInterval.monthly;
      final truncated = interval.truncate(testDate);
      expect(truncated, equals(DateTime.utc(2026, 11, 1, 0, 0, 0)));

      final next = interval.nextBucket(truncated);
      expect(next, equals(DateTime.utc(2026, 12, 1, 0, 0, 0)));

      // Next of December wraps to January of next year
      final dec = DateTime.utc(2026, 12, 15);
      final nextYear = interval.nextBucket(interval.truncate(dec));
      expect(nextYear, equals(DateTime.utc(2027, 1, 1, 0, 0, 0)));

      final label = interval.formatLabel(testDate);
      expect(label, equals('2026-11'));
    });
  });

  group('TimeSeriesPoint Tests', () {
    test('Calculates metrics and serializes to/from JSON correctly', () {
      final point = TimeSeriesPoint(
        timestamp: DateTime.utc(2026, 11, 22, 10, 0),
        scanCount: 10,
        generationCount: 5,
        threatCount: 2,
        movingAverage: 12.5,
        isAnomaly: true,
      );

      expect(point.totalVolume, equals(15));
      expect(point.scans, equals(10));
      expect(point.generations, equals(5));
      expect(point.threats, equals(2));
      expect(point.threatRatePercentage, equals(20.0));

      final json = point.toJson();
      final restored = TimeSeriesPoint.fromJson(json);

      expect(restored.timestamp, equals(point.timestamp));
      expect(restored.scanCount, equals(10));
      expect(restored.generationCount, equals(5));
      expect(restored.threatCount, equals(2));
      expect(restored.movingAverage, equals(12.5));
      expect(restored.isAnomaly, isTrue);

      final modified = restored.copyWith(scanCount: 20, isAnomaly: false);
      expect(modified.scanCount, equals(20));
      expect(modified.isAnomaly, isFalse);
    });

    test('Calculates zero threat rate when scans are zero', () {
      final point = TimeSeriesPoint(
        timestamp: DateTime.utc(2026, 11, 22),
        scanCount: 0,
        generationCount: 4,
        threatCount: 0,
      );
      expect(point.threatRatePercentage, equals(0.0));
      expect(point.totalVolume, equals(4));
    });
  });

  group('TimeSeriesAggregator Tests', () {
    test('Returns empty metrics when no events have been recorded', () {
      const aggregator = TimeSeriesAggregator();
      final metrics = aggregator.aggregate(interval: TimeSeriesBucketInterval.daily);

      expect(metrics.points, isEmpty);
      expect(metrics.totalScans, equals(0));
      expect(metrics.totalGenerations, equals(0));
      expect(metrics.totalThreats, equals(0));
      expect(metrics.totalVolume, equals(0));
      expect(metrics.averageVolumePerBucket, equals(0.0));
      expect(metrics.volumeStandardDeviation, equals(0.0));
      expect(metrics.peakVolume, equals(0));
      expect(metrics.peakTimestamp, isNull);
      expect(metrics.scanToGenerationRatio, equals(0.0));
      expect(metrics.threatRatePercentage, equals(0.0));
    });

    test('Aggregates single event correctly', () {
      const aggregator = TimeSeriesAggregator();
      final ts = DateTime.utc(2026, 11, 22, 10, 0);

      final scannedItem = QrVaultItem(
        id: 'scan_01',
        rawContent: 'https://test.com',
        payloadType: QrPayloadType.url,
        safetyScore: 25,
        threatLevel: SecurityThreatLevel.critical,
        origin: QrItemOrigin.scanned,
        createdAt: ts,
        integrityHash: '',
      );

      final metrics = aggregator.aggregate(
        scannedItems: [scannedItem],
        interval: TimeSeriesBucketInterval.daily,
      );

      expect(metrics.points.length, equals(1));
      expect(metrics.totalScans, equals(1));
      expect(metrics.totalGenerations, equals(0));
      expect(metrics.totalThreats, equals(1));
      expect(metrics.peakVolume, equals(1));
      expect(metrics.peakTimestamp, equals(DateTime.utc(2026, 11, 22)));
      expect(metrics.scanToGenerationRatio, equals(1.0));
      expect(metrics.threatRatePercentage, equals(100.0));
    });

    test('Pads continuous buckets and computes SMA and anomalies', () {
      const aggregator = TimeSeriesAggregator();
      final items = <QrVaultItem>[];
      final gens = <DateTime>[];

      // Day 1: normal volume (10 scans)
      for (var i = 0; i < 10; i++) {
        items.add(QrVaultItem(
          id: 'day1_$i',
          rawContent: 'https://day1.com',
          payloadType: QrPayloadType.url,
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.utc(2026, 11, 10, 12, i),
          integrityHash: '',
        ));
      }

      // Day 2: normal volume (10 scans)
      for (var i = 0; i < 10; i++) {
        items.add(QrVaultItem(
          id: 'day2_$i',
          rawContent: 'https://day2.com',
          payloadType: QrPayloadType.url,
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.utc(2026, 11, 11, 12, i),
          integrityHash: '',
        ));
      }

      // Day 3: normal volume (10 scans)
      for (var i = 0; i < 10; i++) {
        items.add(QrVaultItem(
          id: 'day3_$i',
          rawContent: 'https://day3.com',
          payloadType: QrPayloadType.url,
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.utc(2026, 11, 12, 12, i),
          integrityHash: '',
        ));
      }

      // Day 4: gap (no items)

      // Day 5: massive anomalous spike (100 scans, 10 threats, 20 generations)
      for (var i = 0; i < 100; i++) {
        items.add(QrVaultItem(
          id: 'day5_$i',
          rawContent: i < 10 ? 'javascript:alert(1)' : 'https://day5.com',
          payloadType: QrPayloadType.url,
          safetyScore: i < 10 ? 10 : 95,
          threatLevel: i < 10 ? SecurityThreatLevel.critical : SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.utc(2026, 11, 14, 12, i % 60),
          integrityHash: '',
        ));
      }

      for (var i = 0; i < 20; i++) {
        gens.add(DateTime.utc(2026, 11, 14, 13, i % 60));
      }

      final metrics = aggregator.aggregate(
        scannedItems: items,
        generationTimestamps: gens,
        interval: TimeSeriesBucketInterval.daily,
        movingAveragePeriod: 3,
        anomalyZScoreThreshold: 1.5,
      );

      // Days: 10, 11, 12, 13 (padded 0), 14 -> 5 points
      expect(metrics.points.length, equals(5));

      // Day 4 (index 3) should be zero-padded
      expect(metrics.points[3].totalVolume, equals(0));
      expect(metrics.points[3].scans, equals(0));

      // Day 5 (index 4) should be detected as anomaly
      expect(metrics.points[4].totalVolume, equals(120));
      expect(metrics.points[4].isAnomaly, isTrue);
      expect(metrics.anomalies.length, greaterThanOrEqualTo(1));
      expect(metrics.peakVolume, equals(120));

      // Metrics getters
      expect(metrics.totalScans, equals(130));
      expect(metrics.totalGenerations, equals(20));
      expect(metrics.totalThreats, equals(10));
      expect(metrics.scanToGenerationRatio, equals(130 / 20));
      expect(metrics.threatRatePercentage, closeTo(7.69, 0.05));

      // Serialization round-trip
      final json = metrics.toJson();
      final restored = TimeSeriesMetrics.fromJson(json);
      expect(restored.totalVolume, equals(metrics.totalVolume));
      expect(restored.totalThreats, equals(metrics.totalThreats));
      expect(restored.points.length, equals(metrics.points.length));
    });
  });
}
