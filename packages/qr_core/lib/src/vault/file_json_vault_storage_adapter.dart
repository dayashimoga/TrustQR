import 'dart:convert';
import 'dart:io';
import 'qr_collection.dart';
import 'qr_vault_item.dart';
import 'vault_storage_adapter.dart';

/// Durable atomic JSON file-based vault storage adapter with cross-platform persistence.
class FileJsonVaultStorageAdapter implements QrVaultStorageAdapter {
  final File _file;
  final Map<String, QrVaultItem> _items = {};
  final Map<String, QrCollection> _collections = {};
  bool _isInitialized = false;

  FileJsonVaultStorageAdapter({required String filePath}) : _file = File(filePath);

  FileJsonVaultStorageAdapter.fromFile(File file) : _file = file;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    if (await _file.exists()) {
      try {
        final content = await _file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          final rawItems = decoded['items'] as List<dynamic>? ?? [];
          final rawCollections = decoded['collections'] as List<dynamic>? ?? [];

          for (final raw in rawItems) {
            final item = QrVaultItem.fromJson(raw as Map<String, dynamic>);
            _items[item.id] = item;
          }

          for (final raw in rawCollections) {
            final col = QrCollection.fromJson(raw as Map<String, dynamic>);
            _collections[col.id] = col;
          }
        }
      } catch (e) {
        // Corrupted file will be cleanly handled / overwritten
        _items.clear();
        _collections.clear();
      }
    } else {
      // Ensure parent directory exists
      final parent = _file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
    }

    _isInitialized = true;
  }

  @override
  Future<void> saveItem(QrVaultItem item) async {
    _checkInit();
    _items[item.id] = item;
    await _flush();
  }

  @override
  Future<void> saveItems(List<QrVaultItem> items) async {
    _checkInit();
    for (final item in items) {
      _items[item.id] = item;
    }
    await _flush();
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
    await _flush();
  }

  @override
  Future<void> deleteItems(List<String> ids) async {
    _checkInit();
    for (final id in ids) {
      _items.remove(id);
    }
    await _flush();
  }

  @override
  Future<void> saveCollection(QrCollection collection) async {
    _checkInit();
    _collections[collection.id] = collection;
    await _flush();
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
    await _flush();
  }

  @override
  Future<void> clearAll() async {
    _checkInit();
    _items.clear();
    _collections.clear();
    await _flush();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  Future<void> _flush() async {
    final payload = {
      'version': '1.0',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'items': _items.values.map((i) => i.toJson()).toList(),
      'collections': _collections.values.map((c) => c.toJson()).toList(),
    };

    final jsonStr = jsonEncode(payload);

    // Atomic write to avoid data corruption on sudden interruption
    final tempFile = File('${_file.path}.tmp');
    await tempFile.writeAsString(jsonStr, flush: true);

    if (await _file.exists()) {
      await _file.delete();
    }
    await tempFile.rename(_file.path);
  }

  void _checkInit() {
    if (!_isInitialized) {
      throw StateError('FileJsonVaultStorageAdapter must be initialized via init() before use.');
    }
  }
}
