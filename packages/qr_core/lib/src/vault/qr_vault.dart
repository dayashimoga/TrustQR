import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../crypto/crypto_keys.dart';
import '../models/qr_enums.dart';
import 'in_memory_vault_storage_adapter.dart';
import 'qr_collection.dart';
import 'qr_vault_filter.dart';
import 'qr_vault_item.dart';
import 'vault_privacy_policy.dart';
import 'vault_storage_adapter.dart';

/// Aggregated metrics for the offline vault.
class VaultMetrics {
  final int totalItems;
  final int scannedCount;
  final int generatedCount;
  final int favoritesCount;
  final int collectionsCount;
  final int tagsCount;
  final Map<SecurityThreatLevel, int> threatLevelCounts;

  const VaultMetrics({
    required this.totalItems,
    required this.scannedCount,
    required this.generatedCount,
    required this.favoritesCount,
    required this.collectionsCount,
    required this.tagsCount,
    required this.threatLevelCounts,
  });

  Map<String, dynamic> toJson() => {
    'totalItems': totalItems,
    'scannedCount': scannedCount,
    'generatedCount': generatedCount,
    'favoritesCount': favoritesCount,
    'collectionsCount': collectionsCount,
    'tagsCount': tagsCount,
    'threatLevelCounts': threatLevelCounts.map((k, v) => MapEntry(k.name, v)),
  };
}

/// Result of a vault import operation.
class VaultImportResult {
  final int importedItems;
  final int importedCollections;
  final int skippedItems;
  final int tamperedItems;

  const VaultImportResult({
    required this.importedItems,
    required this.importedCollections,
    required this.skippedItems,
    required this.tamperedItems,
  });

  Map<String, dynamic> toJson() => {
    'importedItems': importedItems,
    'importedCollections': importedCollections,
    'skippedItems': skippedItems,
    'tamperedItems': tamperedItems,
  };
}

/// High-performance, offline-first Vault Engine with HMAC cryptographic integrity guard.
class QrVault {
  final QrVaultStorageAdapter storage;
  final CryptoPrivateKey integrityKey;
  VaultPrivacyPolicy privacyPolicy;
  final Random _rng = Random.secure();

  QrVault({
    required this.storage,
    required this.integrityKey,
    this.privacyPolicy = const VaultPrivacyPolicy(),
  });

  /// Factory creating an in-memory ephemeral vault (ideal for testing and incognito sessions).
  factory QrVault.inMemory({
    required CryptoPrivateKey integrityKey,
    VaultPrivacyPolicy privacyPolicy = const VaultPrivacyPolicy(),
  }) {
    return QrVault(
      storage: InMemoryVaultStorageAdapter(),
      integrityKey: integrityKey,
      privacyPolicy: privacyPolicy,
    );
  }

  /// Initializes the vault storage and enforces auto-purge retention policies if configured.
  Future<void> init() async {
    await storage.init();
    if (privacyPolicy.autoPurgeHistoryDays != null) {
      await purgeHistory();
    }
  }

  /// Closes the vault storage.
  Future<void> close() async {
    await storage.close();
  }

  // ===========================================================================
  // ITEM CRUD OPERATIONS
  // ===========================================================================

  /// Records a new QR code into the vault with cryptographic integrity hash.
  Future<QrVaultItem> recordItem({
    required String rawContent,
    required QrPayloadType payloadType,
    SecurityThreatLevel threatLevel = SecurityThreatLevel.safe,
    int safetyScore = 100,
    QrItemOrigin origin = QrItemOrigin.scanned,
    String? title,
    String? notes,
    String? collectionId,
    List<String> tags = const [],
    bool isFavorite = false,
    bool isTrustQr = false,
    String? trustQrIssuer,
    String? customId,
    DateTime? createdAt,
  }) async {
    final id = customId ?? _generateUniqueId();
    final created = (createdAt ?? DateTime.now()).toUtc();

    final hash = QrVaultItem.computeIntegrityHash(
      id: id,
      rawContent: rawContent,
      payloadType: payloadType,
      threatLevel: threatLevel,
      safetyScore: safetyScore,
      origin: origin,
      createdAt: created,
      isFavorite: isFavorite,
      collectionId: collectionId,
      tags: tags,
      isTrustQr: isTrustQr,
      trustQrIssuer: trustQrIssuer,
      hmacKey: integrityKey,
    );

    final item = QrVaultItem(
      id: id,
      rawContent: rawContent,
      payloadType: payloadType,
      threatLevel: threatLevel,
      safetyScore: safetyScore,
      origin: origin,
      createdAt: created,
      isFavorite: isFavorite,
      title: title,
      notes: notes,
      collectionId: collectionId,
      tags: tags,
      isTrustQr: isTrustQr,
      trustQrIssuer: trustQrIssuer,
      integrityHash: hash,
    );

    // If incognito mode is active and origin is scanned, do not persist to storage
    if (privacyPolicy.isIncognitoMode && origin == QrItemOrigin.scanned) {
      return item;
    }

    await storage.saveItem(item);
    return item;
  }

  /// Retrieves an item by its unique identifier.
  Future<QrVaultItem?> getItem(String id) async {
    return storage.getItem(id);
  }

  /// Queries vault items matching [filter] criteria, with optional pagination.
  Future<List<QrVaultItem>> query(
    QrVaultFilter filter, {
    int? limit,
    int? offset,
  }) async {
    final all = await storage.getAllItems();
    final matched = all.where(filter.matches).toList();

    matched.sort(filter.compare);

    var start = offset ?? 0;
    if (start < 0) start = 0;
    if (start >= matched.length) return [];

    if (limit != null && limit > 0) {
      final end = (start + limit).clamp(0, matched.length);
      return matched.sublist(start, end);
    }

    return matched.sublist(start);
  }

  /// Counts total items matching the [filter].
  Future<int> count(QrVaultFilter filter) async {
    final all = await storage.getAllItems();
    return all.where(filter.matches).length;
  }

  /// Full-Text Search (FTS) shortcut querying title, raw payload, notes, and tags.
  Future<List<QrVaultItem>> search(
    String queryStr, {
    int? limit,
    int? offset,
    QrItemOrigin? origin,
  }) async {
    return query(
      QrVaultFilter(searchQuery: queryStr, origin: origin),
      limit: limit,
      offset: offset,
    );
  }

  /// Toggles favorite status of an item, re-signing the integrity hash.
  Future<QrVaultItem?> toggleFavorite(String id) async {
    final item = await storage.getItem(id);
    if (item == null) return null;

    final updated = _updateAndSignItem(
      item,
      isFavorite: !item.isFavorite,
      updatedAt: DateTime.now().toUtc(),
    );

    await storage.saveItem(updated);
    return updated;
  }

  /// Assigns an item to a collection, re-signing the integrity hash.
  Future<QrVaultItem?> assignCollection(String itemId, String? collectionId) async {
    final item = await storage.getItem(itemId);
    if (item == null) return null;

    final updated = _updateAndSignItem(
      item,
      collectionId: collectionId,
      clearCollectionId: collectionId == null,
      updatedAt: DateTime.now().toUtc(),
    );

    await storage.saveItem(updated);
    return updated;
  }

  /// Updates tags assigned to an item, re-signing the integrity hash.
  Future<QrVaultItem?> setTags(String itemId, List<String> tags) async {
    final item = await storage.getItem(itemId);
    if (item == null) return null;

    final updated = _updateAndSignItem(
      item,
      tags: tags,
      updatedAt: DateTime.now().toUtc(),
    );

    await storage.saveItem(updated);
    return updated;
  }

  /// Updates title of an item, re-signing the integrity hash.
  Future<QrVaultItem?> updateTitle(String itemId, String? title) async {
    final item = await storage.getItem(itemId);
    if (item == null) return null;

    final updated = _updateAndSignItem(
      item,
      title: title,
      updatedAt: DateTime.now().toUtc(),
    );

    await storage.saveItem(updated);
    return updated;
  }

  /// Updates user notes on an item, re-signing the integrity hash.
  Future<QrVaultItem?> updateNotes(String itemId, String? notes) async {
    final item = await storage.getItem(itemId);
    if (item == null) return null;

    final updated = _updateAndSignItem(
      item,
      notes: notes,
      updatedAt: DateTime.now().toUtc(),
    );

    await storage.saveItem(updated);
    return updated;
  }

  /// Deletes an item by ID.
  Future<void> deleteItem(String id) async {
    await storage.deleteItem(id);
  }

  /// Deletes multiple items by ID.
  Future<void> deleteItems(List<String> ids) async {
    await storage.deleteItems(ids);
  }

  // ===========================================================================
  // COLLECTION MANAGEMENT
  // ===========================================================================

  /// Creates a new collection folder.
  Future<QrCollection> createCollection({
    required String name,
    String? description,
    String? colorHex,
    String? customId,
  }) async {
    final id = customId ?? _generateUniqueId();
    final collection = QrCollection(
      id: id,
      name: name,
      description: description,
      colorHex: colorHex,
      createdAt: DateTime.now().toUtc(),
    );

    await storage.saveCollection(collection);
    return collection;
  }

  /// Retrieves all collections with dynamically calculated item counts.
  Future<List<QrCollection>> getCollections({bool computeCounts = true}) async {
    final collections = await storage.getAllCollections();
    if (!computeCounts) return collections;

    final allItems = await storage.getAllItems();
    final countMap = <String, int>{};

    for (final item in allItems) {
      if (item.collectionId != null) {
        countMap[item.collectionId!] = (countMap[item.collectionId!] ?? 0) + 1;
      }
    }

    return collections.map((c) {
      final count = countMap[c.id] ?? 0;
      return c.copyWith(itemCount: count);
    }).toList();
  }

  /// Deletes a collection folder, optionally deleting contained items.
  Future<void> deleteCollection(String id, {bool deleteContainedItems = false}) async {
    if (deleteContainedItems) {
      final items = await storage.getAllItems();
      final toDelete = items.where((i) => i.collectionId == id).map((i) => i.id).toList();
      if (toDelete.isNotEmpty) {
        await storage.deleteItems(toDelete);
      }
    } else {
      // Unlink items from deleted collection
      final items = await storage.getAllItems();
      for (final item in items.where((i) => i.collectionId == id)) {
        final updated = _updateAndSignItem(item, clearCollectionId: true);
        await storage.saveItem(updated);
      }
    }

    await storage.deleteCollection(id);
  }

  // ===========================================================================
  // TAG MANAGEMENT
  // ===========================================================================

  /// Retrieves all unique tags across all stored vault items.
  Future<List<String>> getAllTags() async {
    final items = await storage.getAllItems();
    final tagSet = <String>{};
    for (final item in items) {
      tagSet.addAll(item.tags);
    }
    final list = tagSet.toList()..sort();
    return list;
  }

  /// Retrieves a map of tag names to their usage frequencies.
  Future<Map<String, int>> getTagCounts() async {
    final items = await storage.getAllItems();
    final map = <String, int>{};
    for (final item in items) {
      for (final tag in item.tags) {
        map[tag] = (map[tag] ?? 0) + 1;
      }
    }
    return map;
  }

  // ===========================================================================
  // INTEGRITY GUARD & TAMPER DETECTION
  // ===========================================================================

  /// Verifies the cryptographic HMAC integrity of a single item.
  bool verifyItemIntegrity(QrVaultItem item) {
    return item.verifyIntegrity(integrityKey);
  }

  /// Audits all vault items and returns any whose cryptographic integrity has been violated.
  Future<List<QrVaultItem>> getTamperedItems() async {
    final all = await storage.getAllItems();
    final tampered = <QrVaultItem>[];
    for (final item in all) {
      if (!item.verifyIntegrity(integrityKey)) {
        tampered.add(item);
      }
    }
    return tampered;
  }

  // ===========================================================================
  // PRIVACY & AUTO-PURGE RETENTION
  // ===========================================================================

  /// Purges scanned items older than [olderThanDays] (or policy configuration).
  Future<int> purgeHistory({int? olderThanDays}) async {
    final days = olderThanDays ?? privacyPolicy.autoPurgeHistoryDays;
    if (days == null || days <= 0) return 0;

    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    final all = await storage.getAllItems();

    final toPurge = all.where((item) {
      if (item.origin != QrItemOrigin.scanned) return false;
      if (privacyPolicy.keepFavoritesOnPurge && item.isFavorite) return false;
      return item.createdAt.isBefore(cutoff);
    }).map((i) => i.id).toList();

    if (toPurge.isNotEmpty) {
      await storage.deleteItems(toPurge);
    }

    return toPurge.length;
  }

  /// Clears all scanned history, optionally preserving favorited items.
  Future<int> clearAllHistory({bool keepFavorites = true}) async {
    final all = await storage.getAllItems();
    final toDelete = all.where((item) {
      if (item.origin != QrItemOrigin.scanned) return false;
      if (keepFavorites && item.isFavorite) return false;
      return true;
    }).map((i) => i.id).toList();

    if (toDelete.isNotEmpty) {
      await storage.deleteItems(toDelete);
    }

    return toDelete.length;
  }

  // ===========================================================================
  // IMPORT & EXPORT
  // ===========================================================================

  /// Exports vault items and collections to a formatted JSON string.
  Future<String> exportToJson({QrVaultFilter? filter}) async {
    final items = filter != null ? await query(filter) : await storage.getAllItems();
    final collections = await storage.getAllCollections();

    final exportMap = {
      'format': 'trustqr-vault-export',
      'version': '1.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'itemCount': items.length,
      'collectionCount': collections.length,
      'items': items.map((i) => i.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Imports items and collections from a JSON export string.
  Future<VaultImportResult> importFromJson(
    String jsonString, {
    bool overwrite = false,
    bool verifyIntegritySignatures = true,
  }) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final rawItems = decoded['items'] as List<dynamic>? ?? [];
    final rawCollections = decoded['collections'] as List<dynamic>? ?? [];

    int importedCols = 0;
    for (final raw in rawCollections) {
      final col = QrCollection.fromJson(raw as Map<String, dynamic>);
      final existing = await storage.getCollection(col.id);
      if (existing == null || overwrite) {
        await storage.saveCollection(col);
        importedCols++;
      }
    }

    int importedItems = 0;
    int skippedItems = 0;
    int tamperedItems = 0;

    for (final raw in rawItems) {
      final item = QrVaultItem.fromJson(raw as Map<String, dynamic>);

      if (verifyIntegritySignatures && !item.verifyIntegrity(integrityKey)) {
        tamperedItems++;
      }

      final existing = await storage.getItem(item.id);
      if (existing != null && !overwrite) {
        skippedItems++;
        continue;
      }

      await storage.saveItem(item);
      importedItems++;
    }

    return VaultImportResult(
      importedItems: importedItems,
      importedCollections: importedCols,
      skippedItems: skippedItems,
      tamperedItems: tamperedItems,
    );
  }

  // ===========================================================================
  // AGGREGATED METRICS & TELEMETRY
  // ===========================================================================

  /// Computes real metrics across the stored vault dataset.
  Future<VaultMetrics> getMetrics() async {
    final items = await storage.getAllItems();
    final collections = await storage.getAllCollections();

    int scanned = 0;
    int generated = 0;
    int favorites = 0;
    final tagSet = <String>{};
    final threatCounts = <SecurityThreatLevel, int>{
      SecurityThreatLevel.safe: 0,
      SecurityThreatLevel.caution: 0,
      SecurityThreatLevel.suspicious: 0,
      SecurityThreatLevel.critical: 0,
    };

    for (final item in items) {
      if (item.origin == QrItemOrigin.scanned) {
        scanned++;
      } else {
        generated++;
      }

      if (item.isFavorite) {
        favorites++;
      }

      tagSet.addAll(item.tags);
      threatCounts[item.threatLevel] = (threatCounts[item.threatLevel] ?? 0) + 1;
    }

    return VaultMetrics(
      totalItems: items.length,
      scannedCount: scanned,
      generatedCount: generated,
      favoritesCount: favorites,
      collectionsCount: collections.length,
      tagsCount: tagSet.length,
      threatLevelCounts: threatCounts,
    );
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  QrVaultItem _updateAndSignItem(
    QrVaultItem item, {
    String? title,
    bool clearTitle = false,
    String? notes,
    bool clearNotes = false,
    String? collectionId,
    bool clearCollectionId = false,
    List<String>? tags,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    final updatedCollectionId = clearCollectionId ? null : (collectionId ?? item.collectionId);
    final updatedTitle = clearTitle ? null : (title ?? item.title);
    final updatedNotes = clearNotes ? null : (notes ?? item.notes);
    final updatedTags = tags ?? item.tags;
    final updatedFavorite = isFavorite ?? item.isFavorite;

    final newHash = QrVaultItem.computeIntegrityHash(
      id: item.id,
      rawContent: item.rawContent,
      payloadType: item.payloadType,
      threatLevel: item.threatLevel,
      safetyScore: item.safetyScore,
      origin: item.origin,
      createdAt: item.createdAt,
      isFavorite: updatedFavorite,
      collectionId: updatedCollectionId,
      tags: updatedTags,
      isTrustQr: item.isTrustQr,
      trustQrIssuer: item.trustQrIssuer,
      hmacKey: integrityKey,
    );

    return item.copyWith(
      title: updatedTitle,
      clearTitle: clearTitle,
      notes: updatedNotes,
      clearNotes: clearNotes,
      collectionId: updatedCollectionId,
      clearCollectionId: clearCollectionId,
      tags: updatedTags,
      isFavorite: updatedFavorite,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      integrityHash: newHash,
    );
  }

  String _generateUniqueId() {
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    // Set UUID v4 variant & version
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
