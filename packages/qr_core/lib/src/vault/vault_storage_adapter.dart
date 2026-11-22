import 'qr_collection.dart';
import 'qr_vault_item.dart';

/// Abstract storage persistence adapter for the offline-first vault.
abstract class QrVaultStorageAdapter {
  /// Initializes underlying database or storage medium.
  Future<void> init();

  /// Persists a single QR item.
  Future<void> saveItem(QrVaultItem item);

  /// Persists multiple QR items in a single batch operation.
  Future<void> saveItems(List<QrVaultItem> items);

  /// Retrieves an item by its unique ID.
  Future<QrVaultItem?> getItem(String id);

  /// Retrieves all stored QR items.
  Future<List<QrVaultItem>> getAllItems();

  /// Deletes an item by ID.
  Future<void> deleteItem(String id);

  /// Deletes multiple items by ID.
  Future<void> deleteItems(List<String> ids);

  /// Persists a collection folder.
  Future<void> saveCollection(QrCollection collection);

  /// Retrieves a collection by ID.
  Future<QrCollection?> getCollection(String id);

  /// Retrieves all collection folders.
  Future<List<QrCollection>> getAllCollections();

  /// Deletes a collection folder.
  Future<void> deleteCollection(String id);

  /// Clears all stored items and collections.
  Future<void> clearAll();

  /// Releases storage handles and closes the adapter.
  Future<void> close();
}
