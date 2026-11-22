import '../models/qr_enums.dart';
import 'qr_vault_item.dart';

/// Multi-criteria search and filter descriptor for vault items.
class QrVaultFilter {
  final String? searchQuery;
  final QrItemOrigin? origin;
  final Set<QrPayloadType>? payloadTypes;
  final Set<SecurityThreatLevel>? threatLevels;
  final bool? isFavorite;
  final String? collectionId;
  final Set<String>? tags;
  final DateTime? fromDate;
  final DateTime? toDate;
  final QrVaultSortBy sortBy;

  const QrVaultFilter({
    this.searchQuery,
    this.origin,
    this.payloadTypes,
    this.threatLevels,
    this.isFavorite,
    this.collectionId,
    this.tags,
    this.fromDate,
    this.toDate,
    this.sortBy = QrVaultSortBy.createdAtDesc,
  });

  /// Evaluates whether an item matches all specified filter criteria.
  bool matches(QrVaultItem item) {
    // 1. Origin filter
    if (origin != null && item.origin != origin) {
      return false;
    }

    // 2. Favorite filter
    if (isFavorite != null && item.isFavorite != isFavorite) {
      return false;
    }

    // 3. Collection filter
    if (collectionId != null && item.collectionId != collectionId) {
      return false;
    }

    // 4. Payload format filter
    if (payloadTypes != null && payloadTypes!.isNotEmpty) {
      if (!payloadTypes!.contains(item.payloadType)) {
        return false;
      }
    }

    // 5. Threat level filter
    if (threatLevels != null && threatLevels!.isNotEmpty) {
      if (!threatLevels!.contains(item.threatLevel)) {
        return false;
      }
    }

    // 6. Tags filter (item must match at least one of the queried tags)
    if (tags != null && tags!.isNotEmpty) {
      final itemTagsLower = item.tags.map((t) => t.toLowerCase()).toSet();
      final hasMatchingTag = tags!.any((t) => itemTagsLower.contains(t.toLowerCase()));
      if (!hasMatchingTag) {
        return false;
      }
    }

    // 7. Date range filter
    if (fromDate != null && item.createdAt.isBefore(fromDate!)) {
      return false;
    }
    if (toDate != null && item.createdAt.isAfter(toDate!)) {
      return false;
    }

    // 8. Full-Text Search (FTS) query matching
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final tokens = searchQuery!.trim().toLowerCase().split(RegExp(r'\s+'));
      final targetContent = [
        item.title ?? '',
        item.rawContent,
        item.notes ?? '',
        item.trustQrIssuer ?? '',
        ...item.tags,
      ].join(' ').toLowerCase();

      // All search tokens must match the target content
      for (final token in tokens) {
        if (!targetContent.contains(token)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Compares two items according to the filter's sort order.
  int compare(QrVaultItem a, QrVaultItem b) {
    switch (sortBy) {
      case QrVaultSortBy.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
      case QrVaultSortBy.createdAtAsc:
        return a.createdAt.compareTo(b.createdAt);
      case QrVaultSortBy.titleAsc:
        final titleA = (a.title?.isNotEmpty == true ? a.title! : a.rawContent).toLowerCase();
        final titleB = (b.title?.isNotEmpty == true ? b.title! : b.rawContent).toLowerCase();
        return titleA.compareTo(titleB);
      case QrVaultSortBy.safetyScoreAsc:
        return a.safetyScore.compareTo(b.safetyScore);
      case QrVaultSortBy.safetyScoreDesc:
        return b.safetyScore.compareTo(a.safetyScore);
    }
  }

  QrVaultFilter copyWith({
    String? searchQuery,
    QrItemOrigin? origin,
    Set<QrPayloadType>? payloadTypes,
    Set<SecurityThreatLevel>? threatLevels,
    bool? isFavorite,
    String? collectionId,
    Set<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
    QrVaultSortBy? sortBy,
  }) {
    return QrVaultFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      origin: origin ?? this.origin,
      payloadTypes: payloadTypes ?? this.payloadTypes,
      threatLevels: threatLevels ?? this.threatLevels,
      isFavorite: isFavorite ?? this.isFavorite,
      collectionId: collectionId ?? this.collectionId,
      tags: tags ?? this.tags,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
