import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:user_app/src/state/vault_controller.dart';

void main() {
  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late VaultController controller;

  setUp(() async {
    integrityKey = CryptoKeyPair.generateHmacKey().privateKey;
    vault = QrVault.inMemory(integrityKey: integrityKey);
    await vault.init();
    controller = VaultController(vault: vault);
    await controller.init();
  });

  tearDown(() {
    controller.dispose();
  });

  group('VaultController - Lifecycle & CRUD', () {
    test('initializes empty state correctly', () {
      expect(controller.items, isEmpty);
      expect(controller.collections, isEmpty);
      expect(controller.tags, isEmpty);
      expect(controller.selectedItemIds, isEmpty);
      expect(controller.selectedCount, 0);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.tamperedCount, 0);
    });

    test('records item, refreshes, and reads metrics', () async {
      final item = await vault.recordItem(
        rawContent: 'https://example.com/vault1',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.safe,
        safetyScore: 95,
        title: 'Example Vault Item',
        tags: ['work', 'web'],
      );

      await controller.refresh();

      expect(controller.items.length, 1);
      expect(controller.items.first.id, item.id);
      expect(controller.tags, containsAll(['web', 'work']));
      expect(controller.metrics?.totalItems, 1);
      expect(controller.verifyIntegrity(item), isTrue);
    });

    test('toggles favorite and reflects in state', () async {
      final item = await vault.recordItem(
        rawContent: 'https://example.com/fav',
        payloadType: QrPayloadType.url,
        title: 'Fav Test',
      );
      await controller.refresh();

      final updated = await controller.toggleFavorite(item.id);
      expect(updated?.isFavorite, isTrue);
      expect(controller.items.first.isFavorite, isTrue);

      final unFav = await controller.toggleFavorite(item.id);
      expect(unFav?.isFavorite, isFalse);
      expect(controller.items.first.isFavorite, isFalse);
    });

    test('updates title and notes', () async {
      final item = await vault.recordItem(
        rawContent: 'note test',
        payloadType: QrPayloadType.plainText,
      );
      await controller.refresh();

      final withTitle = await controller.updateTitle(item.id, 'New Title');
      expect(withTitle?.title, 'New Title');
      expect(controller.items.first.title, 'New Title');

      final withNotes = await controller.updateNotes(item.id, 'Encrypted secret note');
      expect(withNotes?.notes, 'Encrypted secret note');
      expect(controller.items.first.notes, 'Encrypted secret note');
    });

    test('sets tags and assigns collection', () async {
      final col = await controller.createCollection(
        name: 'Work',
        description: 'Work items',
        colorHex: '#00F0FF',
      );
      final item = await vault.recordItem(
        rawContent: 'WIFI:S:MyNetwork;T:WPA;P:pass;;',
        payloadType: QrPayloadType.wifi,
      );
      await controller.refresh();

      final withTags = await controller.setTags(item.id, ['office', 'wifi']);
      expect(withTags?.tags, ['office', 'wifi']);
      expect(controller.tags, containsAll(['office', 'wifi']));

      final withCol = await controller.assignCollection(item.id, col.id);
      expect(withCol?.collectionId, col.id);
      expect(controller.items.first.collectionId, col.id);
    });

    test('deletes single item', () async {
      final item = await vault.recordItem(
        rawContent: 'delete me',
        payloadType: QrPayloadType.plainText,
      );
      await controller.refresh();
      expect(controller.items.length, 1);

      controller.toggleSelection(item.id);
      expect(controller.isSelected(item.id), isTrue);

      await controller.deleteItem(item.id);
      expect(controller.items, isEmpty);
      expect(controller.isSelected(item.id), isFalse);
    });

    test('selection and batch deletion', () async {
      final i1 = await vault.recordItem(rawContent: 'item 1', payloadType: QrPayloadType.plainText);
      final i2 = await vault.recordItem(rawContent: 'item 2', payloadType: QrPayloadType.plainText);
      final i3 = await vault.recordItem(rawContent: 'item 3', payloadType: QrPayloadType.plainText);
      await controller.refresh();

      controller.toggleSelection(i1.id);
      controller.toggleSelection(i2.id);
      expect(controller.selectedCount, 2);

      controller.selectAll();
      expect(controller.selectedCount, 3);

      controller.clearSelection();
      expect(controller.selectedCount, 0);

      controller.toggleSelection(i1.id);
      controller.toggleSelection(i3.id);
      await controller.deleteSelected();

      expect(controller.items.length, 1);
      expect(controller.items.first.id, i2.id);
      expect(controller.selectedCount, 0);
    });
  });

  group('VaultController - Filtering & Searching', () {
    late QrVaultItem safeItem;
    late QrVaultItem cautionItem;
    late QrVaultItem favItem;

    setUp(() async {
      safeItem = await vault.recordItem(
        rawContent: 'https://bank.com/safe',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.safe,
        safetyScore: 98,
        title: 'Safe Bank Portal',
        tags: ['finance'],
      );
      cautionItem = await vault.recordItem(
        rawContent: 'http://insecure-domain.xyz/login',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.caution,
        safetyScore: 40,
        title: 'Insecure Login',
        tags: ['risk'],
      );
      favItem = await vault.recordItem(
        rawContent: 'WIFI:S:GuestNet;T:WPA;P:welcome;;',
        payloadType: QrPayloadType.wifi,
        threatLevel: SecurityThreatLevel.safe,
        safetyScore: 90,
        title: 'Guest Wi-Fi',
        isFavorite: true,
        tags: ['office'],
      );
      await controller.refresh();
    });

    test('filters by search query', () async {
      await controller.updateSearchQuery('Bank');
      expect(controller.items.length, 1);
      expect(controller.items.first.id, safeItem.id);

      await controller.updateSearchQuery('GuestNet');
      expect(controller.items.length, 1);
      expect(controller.items.first.id, favItem.id);

      await controller.updateSearchQuery('nonexistent query token');
      expect(controller.items, isEmpty);

      await controller.updateSearchQuery(null);
      expect(controller.items.length, 3);
    });

    test('filters by favorite status', () async {
      await controller.setFavoriteFilter(true);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, favItem.id);

      await controller.setFavoriteFilter(null);
      expect(controller.items.length, 3);
    });

    test('filters by threat levels', () async {
      await controller.setThreatLevelsFilter({SecurityThreatLevel.caution});
      expect(controller.items.length, 1);
      expect(controller.items.first.id, cautionItem.id);

      await controller.setThreatLevelsFilter({SecurityThreatLevel.safe});
      expect(controller.items.length, 2);

      await controller.setThreatLevelsFilter(null);
      expect(controller.items.length, 3);
    });

    test('filters by payload types', () async {
      await controller.setPayloadTypesFilter({QrPayloadType.wifi});
      expect(controller.items.length, 1);
      expect(controller.items.first.id, favItem.id);

      await controller.setPayloadTypesFilter(null);
      expect(controller.items.length, 3);
    });

    test('filters by tags', () async {
      await controller.setTagsFilter({'finance'});
      expect(controller.items.length, 1);
      expect(controller.items.first.id, safeItem.id);

      await controller.setTagsFilter(null);
      expect(controller.items.length, 3);
    });

    test('filters by collection', () async {
      final col = await controller.createCollection(name: 'Financials');
      await controller.assignCollection(safeItem.id, col.id);

      await controller.setCollectionFilter(col.id);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, safeItem.id);

      await controller.setCollectionFilter(null);
      expect(controller.items.length, 3);
    });

    test('sorts items', () async {
      await controller.setSortBy(QrVaultSortBy.safetyScoreDesc);
      expect(controller.items.first.safetyScore, 98);

      await controller.setSortBy(QrVaultSortBy.safetyScoreAsc);
      expect(controller.items.first.safetyScore, 40);

      await controller.setSortBy(QrVaultSortBy.titleAsc);
      expect(controller.items.first.title, 'Guest Wi-Fi');
    });

    test('clears all filters', () async {
      await controller.setFavoriteFilter(true);
      await controller.updateSearchQuery('Bank');
      expect(controller.items, isEmpty);

      await controller.clearFilters();
      expect(controller.items.length, 3);
      expect(controller.filter.searchQuery, isNull);
      expect(controller.filter.isFavorite, isNull);
    });
  });

  group('VaultController - Collections, Privacy, Import & Export', () {
    test('creates and deletes collections with contained item options', () async {
      final col = await controller.createCollection(name: 'Travel', colorHex: '#FFB800');
      final item = await vault.recordItem(
        rawContent: 'https://airline.com/boarding',
        payloadType: QrPayloadType.url,
        collectionId: col.id,
      );
      await controller.refresh();
      expect(controller.collections.length, 1);

      // Delete without deleting items (unlinks items)
      await controller.deleteCollection(col.id, deleteContainedItems: false);
      expect(controller.collections, isEmpty);
      expect(controller.items.length, 1);
      expect(controller.items.first.collectionId, isNull);

      // Create another and delete with contained items
      final col2 = await controller.createCollection(name: 'Temp');
      await controller.assignCollection(item.id, col2.id);
      await controller.deleteCollection(col2.id, deleteContainedItems: true);
      expect(controller.items, isEmpty);
    });

    test('privacy policy updates, auto-purge, and clear all history', () async {
      await vault.recordItem(
        rawContent: 'old scan',
        payloadType: QrPayloadType.plainText,
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 45)),
      );
      final recentFav = await vault.recordItem(
        rawContent: 'recent fav',
        payloadType: QrPayloadType.plainText,
        isFavorite: true,
      );
      await controller.refresh();
      expect(controller.items.length, 2);

      controller.updatePrivacyPolicy(
        const VaultPrivacyPolicy(autoPurgeHistoryDays: 30, keepFavoritesOnPurge: true),
      );
      expect(controller.privacyPolicy.autoPurgeHistoryDays, 30);

      final purged = await controller.purgeHistory(olderThanDays: 30);
      expect(purged, 1);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, recentFav.id);

      final cleared = await controller.clearAllHistory(keepFavorites: true);
      expect(cleared, 0); // recentFav was preserved
      expect(controller.items.length, 1);

      final clearedAll = await controller.clearAllHistory(keepFavorites: false);
      expect(clearedAll, 1);
      expect(controller.items, isEmpty);
    });

    test('exports selected or all items to JSON and imports back', () async {
      final item1 = await vault.recordItem(
        rawContent: 'export-payload-1',
        payloadType: QrPayloadType.plainText,
        title: 'Export 1',
      );
      await vault.recordItem(
        rawContent: 'export-payload-2',
        payloadType: QrPayloadType.plainText,
        title: 'Export 2',
      );
      await controller.refresh();

      // Export all
      final allJson = await controller.exportSelectedOrAllToJson();
      final allDecoded = jsonDecode(allJson) as Map<String, dynamic>;
      expect(allDecoded['format'], 'trustqr-vault-export');
      expect((allDecoded['items'] as List).length, 2);

      // Export selected
      controller.toggleSelection(item1.id);
      final selectedJson = await controller.exportSelectedOrAllToJson();
      final selectedDecoded = jsonDecode(selectedJson) as Map<String, dynamic>;
      expect((selectedDecoded['items'] as List).length, 1);
      expect((selectedDecoded['items'] as List).first['id'], item1.id);

      // Clear vault and import back
      await controller.clearAllHistory(keepFavorites: false);
      expect(controller.items, isEmpty);

      final importRes = await controller.importFromJson(allJson, overwrite: true);
      expect(importRes.importedItems, 2);
      expect(importRes.tamperedItems, 0);
      expect(controller.items.length, 2);
    });
  });
}
