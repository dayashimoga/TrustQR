import 'package:qr_core/qr_core.dart';
import 'payload_distribution.dart';

/// Calculator generating accurate percentage distributions over any collection of QR vault items
/// or incrementally recorded payload events.
class PayloadDistributionCalculator {
  final Map<QrPayloadType, int> _counts = {};

  PayloadDistributionCalculator();

  /// Records a single payload format event.
  void recordPayload(QrPayloadType type) {
    _counts[type] = (_counts[type] ?? 0) + 1;
  }

  /// Records a batch of payload format events.
  void recordPayloads(Iterable<QrPayloadType> types) {
    for (final t in types) {
      recordPayload(t);
    }
  }

  /// Resets internal recorded counts.
  void reset() {
    _counts.clear();
  }

  /// Computes the payload distribution from a list of vault items (or internal counts if items is omitted/empty).
  PayloadDistribution calculate([List<QrVaultItem>? items]) {
    if (items != null && items.isNotEmpty) {
      final counts = <QrPayloadType, int>{};
      for (final item in items) {
        counts[item.payloadType] = (counts[item.payloadType] ?? 0) + 1;
      }
      return PayloadDistribution.fromCounts(counts);
    }

    return PayloadDistribution.fromCounts(_counts);
  }
}
