import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:qr_core/qr_core.dart';

/// State coordinator for the offline-first encrypted vault, collections, and privacy policies.
class VaultController extends ChangeNotifier {
  final QrVault vault;

  List<QrVaultItem> _items = const [];
  List<QrCollection> _collections = const [];
  List<String> _tags = const [];
  final Set<String> _selectedItemIds = {};
  QrVaultFilter _filter = const QrVaultFilter();
  bool _isLoading = false;
  String? _errorMessage;
  VaultMetrics? _metrics;
  int _tamperedCount = 0;

  VaultController({required this.vault});

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<QrVaultItem> get items => _items;
  List<QrCollection> get collections => _collections;
  List<String> get tags => _tags;
  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  int get selectedCount => _selectedItemIds.length;
  QrVaultFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VaultMetrics? get metrics => _metrics;
  int get tamperedCount => _tamperedCount;
  VaultPrivacyPolicy get privacyPolicy => vault.privacyPolicy;

  // ---------------------------------------------------------------------------
  // Lifecycle & Querying
  // ---------------------------------------------------------------------------

  /// Initializes the vault engine and loads the initial item list and collections.
  Future<void> init() async {
    await vault.init();
    await refresh();
  }

  /// Refreshes items, collections, tags, and metrics from storage matching the current filter.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedItems = await vault.query(_filter);
      final fetchedCollections = await vault.getCollections();
      final fetchedTags = await vault.getAllTags();
      final fetchedMetrics = await vault.getMetrics();
      final tampered = await vault.getTamperedItems();

      _items = fetchedItems;
      _collections = fetchedCollections;
      _tags = fetchedTags;
      _metrics = fetchedMetrics;
      _tamperedCount = tampered.length;

      // Clean up selected IDs that no longer exist
      final existingIds = _items.map((i) => i.id).toSet();
      _selectedItemIds.removeWhere((id) => !existingIds.contains(id));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Filters & Search
  // ---------------------------------------------------------------------------

  /// Updates the active filter and refreshes the items list.
  Future<void> setFilter(QrVaultFilter newFilter) async {
    _filter = newFilter;
    await refresh();
  }

  /// Updates the full-text search query token.
  Future<void> updateSearchQuery(String? query) async {
    final trimmed = query?.trim();
    _filter = _filter.copyWith(
      searchQuery: trimmed?.isNotEmpty == true ? trimmed : null,
      clearSearchQuery: trimmed?.isEmpty ?? true,
    );
    await refresh();
  }

  /// Sets or clears favorite-only filtering.
  Future<void> setFavoriteFilter(bool? isFavorite) async {
    _filter = _filter.copyWith(
      isFavorite: isFavorite,
      clearFavorite: isFavorite == null,
    );
    await refresh();
  }

  /// Sets threat level filter criteria.
  Future<void> setThreatLevelsFilter(Set<SecurityThreatLevel>? levels) async {
    _filter = _filter.copyWith(
      threatLevels: levels,
      clearThreatLevels: levels == null || levels.isEmpty,
    );
    await refresh();
  }

  /// Sets payload format filter criteria.
  Future<void> setPayloadTypesFilter(Set<QrPayloadType>? types) async {
    _filter = _filter.copyWith(
      payloadTypes: types,
      clearPayloadTypes: types == null || types.isEmpty,
    );
    await refresh();
  }

  /// Sets collection folder filter.
  Future<void> setCollectionFilter(String? collectionId) async {
    _filter = _filter.copyWith(
      collectionId: collectionId,
      clearCollectionId: collectionId == null,
    );
    await refresh();
  }

  /// Sets tag filter criteria.
  Future<void> setTagsFilter(Set<String>? tags) async {
    _filter = _filter.copyWith(
      tags: tags,
      clearTags: tags == null || tags.isEmpty,
    );
    await refresh();
  }

  /// Sets sorting order.
  Future<void> setSortBy(QrVaultSortBy sortBy) async {
    _filter = _filter.copyWith(sortBy: sortBy);
    await refresh();
  }

  /// Resets all filters back to default.
  Future<void> clearFilters() async {
    _filter = const QrVaultFilter();
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Multi-Selection
  // ---------------------------------------------------------------------------

  bool isSelected(String id) => _selectedItemIds.contains(id);

  void toggleSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedItemIds.addAll(_items.map((i) => i.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Item Mutations
  // ---------------------------------------------------------------------------

  /// Toggles favorite status of an item and refreshes state.
  Future<QrVaultItem?> toggleFavorite(String id) async {
    final updated = await vault.toggleFavorite(id);
    await refresh();
    return updated;
  }

  /// Deletes a single item by ID.
  Future<void> deleteItem(String id) async {
    await vault.deleteItem(id);
    _selectedItemIds.remove(id);
    await refresh();
  }

  /// Deletes all currently selected items.
  Future<void> deleteSelected() async {
    if (_selectedItemIds.isEmpty) return;
    await vault.deleteItems(_selectedItemIds.toList());
    _selectedItemIds.clear();
    await refresh();
  }

  /// Updates user notes on an item.
  Future<QrVaultItem?> updateNotes(String id, String? notes) async {
    final updated = await vault.updateNotes(id, notes);
    await refresh();
    return updated;
  }

  /// Updates title of an item.
  Future<QrVaultItem?> updateTitle(String id, String? title) async {
    final updated = await vault.updateTitle(id, title);
    await refresh();
    return updated;
  }

  /// Updates tags assigned to an item.
  Future<QrVaultItem?> setTags(String id, List<String> tags) async {
    final updated = await vault.setTags(id, tags);
    await refresh();
    return updated;
  }

  /// Assigns an item to a collection.
  Future<QrVaultItem?> assignCollection(String id, String? collectionId) async {
    final updated = await vault.assignCollection(id, collectionId);
    await refresh();
    return updated;
  }

  /// Cryptographically verifies the HMAC-SHA256 signature of an item.
  bool verifyIntegrity(QrVaultItem item) {
    return vault.verifyItemIntegrity(item);
  }

  // ---------------------------------------------------------------------------
  // Collection Management
  // ---------------------------------------------------------------------------

  /// Creates a new named collection folder.
  Future<QrCollection> createCollection({
    required String name,
    String? description,
    String? colorHex,
  }) async {
    final collection = await vault.createCollection(
      name: name,
      description: description,
      colorHex: colorHex,
    );
    await refresh();
    return collection;
  }

  /// Deletes a collection folder, optionally purging contained items.
  Future<void> deleteCollection(String id, {bool deleteContainedItems = false}) async {
    await vault.deleteCollection(id, deleteContainedItems: deleteContainedItems);
    if (_filter.collectionId == id) {
      _filter = _filter.copyWith(clearCollectionId: true);
    }
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Privacy, Purge & Data Export/Import
  // ---------------------------------------------------------------------------

  /// Purges scanned items older than configured retention policy.
  Future<int> purgeHistory({int? olderThanDays}) async {
    final count = await vault.purgeHistory(olderThanDays: olderThanDays);
    await refresh();
    return count;
  }

  /// Clears all scanned items in the vault.
  Future<int> clearAllHistory({bool keepFavorites = true}) async {
    final count = await vault.clearAllHistory(keepFavorites: keepFavorites);
    await refresh();
    return count;
  }

  /// Updates the local vault privacy policy.
  void updatePrivacyPolicy(VaultPrivacyPolicy policy) {
    vault.privacyPolicy = policy;
    notifyListeners();
  }

  /// Exports selected items (or all filtered items if none selected) to JSON format.
  Future<String> exportSelectedOrAllToJson() async {
    if (_selectedItemIds.isNotEmpty) {
      final selectedItems = _items.where((i) => _selectedItemIds.contains(i.id)).toList();
      final collections = await vault.getCollections();
      final map = {
        'format': 'trustqr-vault-export',
        'version': '1.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'itemCount': selectedItems.length,
        'collectionCount': collections.length,
        'items': selectedItems.map((i) => i.toJson()).toList(),
        'collections': collections.map((c) => c.toJson()).toList(),
      };
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return vault.exportToJson(filter: _filter);
  }

  /// Imports vault records and collections from a JSON export string.
  Future<VaultImportResult> importFromJson(String jsonString, {bool overwrite = false}) async {
    final result = await vault.importFromJson(jsonString, overwrite: overwrite);
    await refresh();
    return result;
  }
}
