import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  group('TimeSeries Anomaly & Timeline Stress Tests', () {
    test('Simulates 365-day timeline with zero-padded gaps and flags statistical spikes', () {
      const aggregator = TimeSeriesAggregator();
      final baseDate = DateTime.utc(2025, 1, 1);
      final items = <QrVaultItem>[];
      final gens = <DateTime>[];

      // Simulate steady baseline: Days 1 to 50 have 10 scans and 2 generations per day
      for (var day = 0; day < 50; day++) {
        final dayTime = baseDate.add(Duration(days: day, hours: 12));
        for (var s = 0; s < 10; s++) {
          items.add(QrVaultItem(
            id: 'item_${day}_$s',
            rawContent: 'https://steady.org/$s',
            payloadType: QrPayloadType.url,
            safetyScore: 95,
            threatLevel: SecurityThreatLevel.safe,
            origin: QrItemOrigin.scanned,
            createdAt: dayTime.add(Duration(minutes: s)),
            integrityHash: '',
          ));
        }
        for (var g = 0; g < 2; g++) {
          gens.add(dayTime.add(Duration(minutes: 30 + g)));
        }
      }

      // Gap: Days 51 to 150 have ZERO transactions (100 days silence)

      // Day 151: Massive anomalous spike (500 scans, 100 threats, 150 generations)
      final spikeDay = baseDate.add(const Duration(days: 151, hours: 12));
      for (var s = 0; s < 500; s++) {
        items.add(QrVaultItem(
          id: 'spike_item_$s',
          rawContent: s < 100 ? 'javascript:evil($s)' : 'https://spike.org',
          payloadType: QrPayloadType.url,
          safetyScore: s < 100 ? 5 : 90,
          threatLevel: s < 100 ? SecurityThreatLevel.critical : SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          createdAt: spikeDay.add(Duration(seconds: s)),
          integrityHash: '',
        ));
      }
      for (var g = 0; g < 150; g++) {
        gens.add(spikeDay.add(Duration(seconds: g * 2)));
      }

      // Days 152 to 200: Return to baseline (10 scans per day)
      for (var day = 152; day <= 200; day++) {
        final dayTime = baseDate.add(Duration(days: day, hours: 12));
        for (var s = 0; s < 10; s++) {
          items.add(QrVaultItem(
            id: 'post_item_${day}_$s',
            rawContent: 'https://steady.org',
            payloadType: QrPayloadType.url,
            safetyScore: 95,
            threatLevel: SecurityThreatLevel.safe,
            origin: QrItemOrigin.scanned,
            createdAt: dayTime.add(Duration(minutes: s)),
            integrityHash: '',
          ));
        }
      }

      // Aggregate daily metrics
      final dailyMetrics = aggregator.aggregate(
        scannedItems: items,
        generationTimestamps: gens,
        interval: TimeSeriesBucketInterval.daily,
        anomalyZScoreThreshold: 2.5,
      );

      // Verify continuous zero-padded buckets: Days 0 through 200 = 201 days
      expect(dailyMetrics.points.length, equals(201));

      // Verify that Days 51 to 150 (indices 51 to 150) are all zero-padded
      for (var i = 51; i <= 150; i++) {
        expect(dailyMetrics.points[i].totalVolume, equals(0));
        expect(dailyMetrics.points[i].scans, equals(0));
        expect(dailyMetrics.points[i].generations, equals(0));
        expect(dailyMetrics.points[i].threats, equals(0));
        expect(dailyMetrics.points[i].isAnomaly, isFalse);
      }

      // Verify anomalous spike at index 151
      final spikePoint = dailyMetrics.points[151];
      expect(spikePoint.scans, equals(500));
      expect(spikePoint.generations, equals(150));
      expect(spikePoint.threats, equals(100));
      expect(spikePoint.totalVolume, equals(650));
      expect(spikePoint.isAnomaly, isTrue);

      // Peak tracking
      expect(dailyMetrics.peakVolume, equals(650));
      expect(dailyMetrics.peakTimestamp, equals(spikeDay.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)));

      // Anomalies list contains the spike
      expect(dailyMetrics.anomalies.any((p) => p.totalVolume == 650), isTrue);

      // Aggregate weekly metrics over the same timeline
      final weeklyMetrics = aggregator.aggregate(
        scannedItems: items,
        generationTimestamps: gens,
        interval: TimeSeriesBucketInterval.weekly,
        anomalyZScoreThreshold: 2.0,
      );
      expect(weeklyMetrics.points.length, greaterThan(25));
      expect(weeklyMetrics.peakVolume, greaterThanOrEqualTo(650));

      // Aggregate monthly metrics over the same timeline
      final monthlyMetrics = aggregator.aggregate(
        scannedItems: items,
        generationTimestamps: gens,
        interval: TimeSeriesBucketInterval.monthly,
      );
      expect(monthlyMetrics.points.length, greaterThanOrEqualTo(7));
      expect(monthlyMetrics.totalScans, equals(dailyMetrics.totalScans));
      expect(monthlyMetrics.totalGenerations, equals(dailyMetrics.totalGenerations));
    });

    test('Computes ratios and rates under extreme boundary conditions', () {
      const aggregator = TimeSeriesAggregator();
      final now = DateTime.utc(2026, 11, 22);

      // Boundary 1: Zero generations
      final scanOnly = aggregator.aggregate(
        scannedItems: [
          QrVaultItem(
            id: 's1',
            rawContent: 'https://test.com',
            payloadType: QrPayloadType.url,
            safetyScore: 90,
            threatLevel: SecurityThreatLevel.safe,
            origin: QrItemOrigin.scanned,
            createdAt: now,
            integrityHash: '',
          ),
        ],
        interval: TimeSeriesBucketInterval.daily,
      );
      expect(scanOnly.totalGenerations, equals(0));
      expect(scanOnly.scanToGenerationRatio, equals(1.0));
      expect(scanOnly.threatRatePercentage, equals(0.0));

      // Boundary 2: Zero scans, generations only
      final genOnly = aggregator.aggregate(
        generationTimestamps: [now, now.add(const Duration(hours: 1))],
        interval: TimeSeriesBucketInterval.daily,
      );
      expect(genOnly.totalScans, equals(0));
      expect(genOnly.totalGenerations, equals(2));
      expect(genOnly.scanToGenerationRatio, equals(0.0));
      expect(genOnly.threatRatePercentage, equals(0.0));

      // Boundary 3: 100% threats
      final allThreats = aggregator.aggregate(
        scannedItems: [
          QrVaultItem(
            id: 't1',
            rawContent: 'javascript:evil()',
            payloadType: QrPayloadType.plainText,
            safetyScore: 10,
            threatLevel: SecurityThreatLevel.critical,
            origin: QrItemOrigin.scanned,
            createdAt: now,
            integrityHash: '',
          ),
        ],
        interval: TimeSeriesBucketInterval.daily,
      );
      expect(allThreats.threatRatePercentage, equals(100.0));
    });
  });
}
