import 'qr_collection.dart';
import 'qr_vault_item.dart';
import 'vault_storage_adapter.dart';

/// In-memory storage adapter for fast ephemeral tests, memory caches, and incognito sessions.
class InMemoryVaultStorageAdapter implements QrVaultStorageAdapter {
  final Map<String, QrVaultItem> _items = {};
  final Map<String, QrCollection> _collections = {};
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<void> saveItem(QrVaultItem item) async {
    _checkInit();
    _items[item.id] = item;
  }

  @override
  Future<void> saveItems(List<QrVaultItem> items) async {
    _checkInit();
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  @override
  Future<QrVaultItem?> getItem(String id) async {
    _checkInit();
    return _items[id];
  }

  @override
  Future<List<QrVaultItem>> getAllItems() async {
    _checkInit();
    return _items.values.toList();
  }

  @override
  Future<void> deleteItem(String id) async {
    _checkInit();
    _items.remove(id);
  }

  @override
  Future<void> deleteItems(List<String> ids) async {
    _checkInit();
    for (final id in ids) {
      _items.remove(id);
    }
  }

  @override
  Future<void> saveCollection(QrCollection collection) async {
    _checkInit();
    _collections[collection.id] = collection;
  }

  @override
  Future<QrCollection?> getCollection(String id) async {
    _checkInit();
    return _collections[id];
  }

  @override
  Future<List<QrCollection>> getAllCollections() async {
    _checkInit();
    return _collections.values.toList();
  }

  @override
  Future<void> deleteCollection(String id) async {
    _checkInit();
    _collections.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _checkInit();
    _items.clear();
    _collections.clear();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  void _checkInit() {
    if (!_isInitialized) {
      throw StateError('InMemoryVaultStorageAdapter must be initialized via init() before use.');
    }
  }
}
