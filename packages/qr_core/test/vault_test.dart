import 'dart:io';
import 'dart:typed_data';
import 'package:qr_core/qr_core.dart';
import 'package:test/test.dart';

void main() {
  group('Offline-First Encrypted Vault Test Suite', () {
    late CryptoPrivateKey testHmacKey;
    late Directory tempDir;

    setUp(() {
      final seed = Uint8List.fromList(List.generate(32, (i) => (i * 29 + 11) % 256));
      testHmacKey = CryptoPrivateKey(
        bytes: seed,
        algorithm: CryptoAlgorithm.hmacSha256,
        keyId: 'vault-test-key-01',
      );
      tempDir = Directory.systemTemp.createTempSync('vault_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // 1. QrVaultItem Model & Cryptographic Integrity Tests
    // =========================================================================
    group('QrVaultItem Model & HMAC Integrity', () {
      test('Creates, serializes toJson, and deserializes fromJson correctly', () {
        final now = DateTime.now().toUtc();
        final hash = QrVaultItem.computeIntegrityHash(
          id: 'item-001',
          rawContent: 'https://antigravity.dev',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
          safetyScore: 100,
          origin: QrItemOrigin.scanned,
          createdAt: now,
          isFavorite: true,
          collectionId: 'col-work',
          tags: ['work', 'web'],
          isTrustQr: true,
          trustQrIssuer: 'org.google',
          hmacKey: testHmacKey,
        );

        final item = QrVaultItem(
          id: 'item-001',
          rawContent: 'https://antigravity.dev',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
          safetyScore: 100,
          origin: QrItemOrigin.scanned,
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 5)),
          isFavorite: true,
          title: 'Antigravity Portal',
          notes: 'Developer documentation',
          collectionId: 'col-work',
          tags: ['work', 'web'],
          isTrustQr: true,
          trustQrIssuer: 'org.google',
          integrityHash: hash,
        );

        expect(item.verifyIntegrity(testHmacKey), isTrue);

        final json = item.toJson();
        expect(json['id'], equals('item-001'));
        expect(json['rawContent'], equals('https://antigravity.dev'));
        expect(json['payloadType'], equals('url'));
        expect(json['threatLevel'], equals('safe'));
        expect(json['safetyScore'], equals(100));
        expect(json['origin'], equals('scanned'));
        expect(json['isFavorite'], isTrue);
        expect(json['title'], equals('Antigravity Portal'));
        expect(json['notes'], equals('Developer documentation'));
        expect(json['collectionId'], equals('col-work'));
        expect(json['tags'], equals(['work', 'web']));
        expect(json['isTrustQr'], isTrue);
        expect(json['trustQrIssuer'], equals('org.google'));

        final parsed = QrVaultItem.fromJson(json);
        expect(parsed.id, equals(item.id));
        expect(parsed.rawContent, equals(item.rawContent));
        expect(parsed.payloadType, equals(item.payloadType));
        expect(parsed.threatLevel, equals(item.threatLevel));
        expect(parsed.safetyScore, equals(item.safetyScore));
        expect(parsed.origin, equals(item.origin));
        expect(parsed.isFavorite, equals(item.isFavorite));
        expect(parsed.title, equals(item.title));
        expect(parsed.notes, equals(item.notes));
        expect(parsed.collectionId, equals(item.collectionId));
        expect(parsed.tags, equals(item.tags));
        expect(parsed.isTrustQr, equals(item.isTrustQr));
        expect(parsed.trustQrIssuer, equals(item.trustQrIssuer));
        expect(parsed.integrityHash, equals(item.integrityHash));
        expect(parsed.verifyIntegrity(testHmacKey), isTrue);
      });

      test('Detects tampering if any protected field is altered', () {
        final now = DateTime.now().toUtc();
        final hash = QrVaultItem.computeIntegrityHash(
          id: 'item-secure-01',
          rawContent: 'https://bank.com',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.critical,
          safetyScore: 10,
          origin: QrItemOrigin.scanned,
          createdAt: now,
          isFavorite: false,
          hmacKey: testHmacKey,
        );

        final item = QrVaultItem(
          id: 'item-secure-01',
          rawContent: 'https://bank.com',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.critical,
          safetyScore: 10,
          origin: QrItemOrigin.scanned,
          createdAt: now,
          integrityHash: hash,
        );

        expect(item.verifyIntegrity(testHmacKey), isTrue);

        // 1. Tamper threatLevel (adversary attempts to downgrade threat from critical to safe)
        final tamperedThreat = item.copyWith(threatLevel: SecurityThreatLevel.safe);
        expect(tamperedThreat.verifyIntegrity(testHmacKey), isFalse);

        // 2. Tamper rawContent (adversary switches destination URL)
        final tamperedContent = item.copyWith(rawContent: 'https://evil.com');
        expect(tamperedContent.verifyIntegrity(testHmacKey), isFalse);

        // 3. Tamper safety score
        final tamperedScore = item.copyWith(safetyScore: 100);
        expect(tamperedScore.verifyIntegrity(testHmacKey), isFalse);

        // 4. Tamper origin
        final tamperedOrigin = item.copyWith(origin: QrItemOrigin.generated);
        expect(tamperedOrigin.verifyIntegrity(testHmacKey), isFalse);

        // 5. Tamper empty integrity hash or corrupted base64
        final emptyHash = item.copyWith(integrityHash: '');
        expect(emptyHash.verifyIntegrity(testHmacKey), isFalse);

        final corruptedHash = item.copyWith(integrityHash: '!!!not-base64???');
        expect(corruptedHash.verifyIntegrity(testHmacKey), isFalse);
      });
    });

    // =========================================================================
    // 2. QrCollection & VaultPrivacyPolicy Models
    // =========================================================================
    group('QrCollection & VaultPrivacyPolicy Models', () {
      test('QrCollection serializes and deserializes cleanly', () {
        final now = DateTime.now().toUtc();
        final col = QrCollection(
          id: 'col-finance',
          name: 'Finance & Payments',
          description: 'Payment QR codes and bank tokens',
          colorHex: '#00E5FF',
          createdAt: now,
          itemCount: 5,
        );

        final json = col.toJson();
        expect(json['id'], equals('col-finance'));
        expect(json['name'], equals('Finance & Payments'));
        expect(json['description'], equals('Payment QR codes and bank tokens'));
        expect(json['colorHex'], equals('#00E5FF'));
        expect(json['itemCount'], equals(5));

        final parsed = QrCollection.fromJson(json);
        expect(parsed.id, equals(col.id));
        expect(parsed.name, equals(col.name));
        expect(parsed.description, equals(col.description));
        expect(parsed.colorHex, equals(col.colorHex));
        expect(parsed.itemCount, equals(5));

        final updated = parsed.copyWith(name: 'Updated Name', itemCount: 10);
        expect(updated.name, equals('Updated Name'));
        expect(updated.itemCount, equals(10));
      });

      test('VaultPrivacyPolicy serializes and supports copyWith', () {
        const policy = VaultPrivacyPolicy(
          autoPurgeHistoryDays: 30,
          isIncognitoMode: true,
          keepFavoritesOnPurge: true,
        );

        final json = policy.toJson();
        expect(json['autoPurgeHistoryDays'], equals(30));
        expect(json['isIncognitoMode'], isTrue);
        expect(json['keepFavoritesOnPurge'], isTrue);

        final parsed = VaultPrivacyPolicy.fromJson(json);
        expect(parsed.autoPurgeHistoryDays, equals(30));
        expect(parsed.isIncognitoMode, isTrue);

        final updated = parsed.copyWith(autoPurgeHistoryDays: 60, isIncognitoMode: false);
        expect(updated.autoPurgeHistoryDays, equals(60));
        expect(updated.isIncognitoMode, isFalse);
      });
    });

    // =========================================================================
    // 3. QrVaultFilter & Full-Text Search (FTS)
    // =========================================================================
    group('QrVaultFilter & FTS Matching', () {
      final now = DateTime.utc(2026, 11, 22, 10, 0, 0);

      final itemA = QrVaultItem(
        id: 'A',
        rawContent: 'https://flutter.dev/docs',
        payloadType: QrPayloadType.url,
        threatLevel: SecurityThreatLevel.safe,
        safetyScore: 100,
        origin: QrItemOrigin.scanned,
        createdAt: now,
        isFavorite: true,
        title: 'Flutter Documentation',
        notes: 'UI toolkit for cross-platform apps',
        collectionId: 'col-dev',
        tags: const ['flutter', 'mobile'],
        integrityHash: 'hashA',
      );

      final itemB = QrVaultItem(
        id: 'B',
        rawContent: 'WIFI:S:GuestNet;T:WPA;P:secret123;;',
        payloadType: QrPayloadType.wifi,
        threatLevel: SecurityThreatLevel.caution,
        safetyScore: 75,
        origin: QrItemOrigin.scanned,
        createdAt: now.add(const Duration(hours: 1)),
        isFavorite: false,
        title: 'Guest Wi-Fi Office',
        notes: 'Reception desk password',
        collectionId: 'col-office',
        tags: const ['wifi', 'network'],
        integrityHash: 'hashB',
      );

      final itemC = QrVaultItem(
        id: 'C',
        rawContent: 'upi://pay?pa=store@upi&pn=Grocery&am=500.00&cu=INR',
        payloadType: QrPayloadType.upi,
        threatLevel: SecurityThreatLevel.safe,
        safetyScore: 100,
        origin: QrItemOrigin.generated,
        createdAt: now.add(const Duration(hours: 2)),
        isFavorite: true,
        title: 'Grocery Store Payment',
        collectionId: 'col-finance',
        tags: const ['upi', 'finance'],
        integrityHash: 'hashC',
      );

      test('Filters by origin, isFavorite, collectionId, payloadType, threatLevel', () {
        // Origin
        expect(const QrVaultFilter(origin: QrItemOrigin.scanned).matches(itemA), isTrue);
        expect(const QrVaultFilter(origin: QrItemOrigin.scanned).matches(itemC), isFalse);

        // Favorite
        expect(const QrVaultFilter(isFavorite: true).matches(itemA), isTrue);
        expect(const QrVaultFilter(isFavorite: true).matches(itemB), isFalse);

        // CollectionId
        expect(const QrVaultFilter(collectionId: 'col-dev').matches(itemA), isTrue);
        expect(const QrVaultFilter(collectionId: 'col-dev').matches(itemB), isFalse);

        // Payload types
        expect(const QrVaultFilter(payloadTypes: {QrPayloadType.url}).matches(itemA), isTrue);
        expect(const QrVaultFilter(payloadTypes: {QrPayloadType.wifi}).matches(itemA), isFalse);

        // Threat levels
        expect(const QrVaultFilter(threatLevels: {SecurityThreatLevel.safe}).matches(itemA), isTrue);
        expect(const QrVaultFilter(threatLevels: {SecurityThreatLevel.safe}).matches(itemB), isFalse);
      });

      test('Filters by tags and date range', () {
        expect(const QrVaultFilter(tags: {'flutter'}).matches(itemA), isTrue);
        expect(const QrVaultFilter(tags: {'unknown'}).matches(itemA), isFalse);

        // Date range
        final filterDate = QrVaultFilter(
          fromDate: now.add(const Duration(minutes: 30)),
          toDate: now.add(const Duration(hours: 3)),
        );
        expect(filterDate.matches(itemA), isFalse);
        expect(filterDate.matches(itemB), isTrue);
        expect(filterDate.matches(itemC), isTrue);
      });

      test('FTS token search matches across title, content, notes, tags', () {
        // Multi-word search
        expect(const QrVaultFilter(searchQuery: 'flutter documentation').matches(itemA), isTrue);
        expect(const QrVaultFilter(searchQuery: 'cross-platform ui').matches(itemA), isTrue);
        expect(const QrVaultFilter(searchQuery: 'wifi reception').matches(itemB), isTrue);
        expect(const QrVaultFilter(searchQuery: 'grocery inr').matches(itemC), isTrue);
        expect(const QrVaultFilter(searchQuery: 'nonexistent keyword').matches(itemA), isFalse);
      });

      test('Sort comparator orders items accurately', () {
        final list = [itemA, itemB, itemC];

        // 1. CreatedAt Desc
        list.sort(const QrVaultFilter(sortBy: QrVaultSortBy.createdAtDesc).compare);
        expect(list.map((i) => i.id).toList(), equals(['C', 'B', 'A']));

        // 2. CreatedAt Asc
        list.sort(const QrVaultFilter(sortBy: QrVaultSortBy.createdAtAsc).compare);
        expect(list.map((i) => i.id).toList(), equals(['A', 'B', 'C']));

        // 3. Title Asc
        list.sort(const QrVaultFilter(sortBy: QrVaultSortBy.titleAsc).compare);
        expect(list.map((i) => i.id).toList(), equals(['A', 'C', 'B']));

        // 4. SafetyScore Asc
        list.sort(const QrVaultFilter(sortBy: QrVaultSortBy.safetyScoreAsc).compare);
        expect(list.first.id, equals('B')); // Score 75 first

        // 5. SafetyScore Desc
        list.sort(const QrVaultFilter(sortBy: QrVaultSortBy.safetyScoreDesc).compare);
        expect(list.last.id, equals('B')); // Score 75 last
      });

      test('Filter copyWith updates properties', () {
        const initial = QrVaultFilter(searchQuery: 'test');
        final updated = initial.copyWith(
          searchQuery: 'newQuery',
          origin: QrItemOrigin.generated,
          isFavorite: true,
          sortBy: QrVaultSortBy.titleAsc,
        );
        expect(updated.searchQuery, equals('newQuery'));
        expect(updated.origin, equals(QrItemOrigin.generated));
        expect(updated.isFavorite, isTrue);
        expect(updated.sortBy, equals(QrVaultSortBy.titleAsc));
      });
    });

    // =========================================================================
    // 4. Storage Adapters (InMemory & FileJson)
    // =========================================================================
    group('Storage Adapters', () {
      test('InMemoryVaultStorageAdapter throws if used without init()', () async {
        final adapter = InMemoryVaultStorageAdapter();
        expect(() => adapter.getAllItems(), throwsStateError);
      });

      test('FileJsonVaultStorageAdapter provides durable atomic persistence', () async {
        final filePath = '${tempDir.path}/vault_data.json';
        final adapter = FileJsonVaultStorageAdapter(filePath: filePath);

        await adapter.init();
        expect(await adapter.getAllItems(), isEmpty);
        expect(await adapter.getAllCollections(), isEmpty);

        final now = DateTime.now().toUtc();
        final item = QrVaultItem(
          id: 'file-item-01',
          rawContent: 'https://dart.dev',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
          safetyScore: 100,
          origin: QrItemOrigin.scanned,
          createdAt: now,
          integrityHash: 'testHash',
        );

        final col = QrCollection(
          id: 'col-01',
          name: 'Test Collection',
          createdAt: now,
        );

        await adapter.saveItem(item);
        await adapter.saveCollection(col);

        expect(File(filePath).existsSync(), isTrue);

        // Re-read with fresh adapter to confirm physical file persistence
        final freshAdapter = FileJsonVaultStorageAdapter(filePath: filePath);
        await freshAdapter.init();

        final loadedItem = await freshAdapter.getItem('file-item-01');
        expect(loadedItem, isNotNull);
        expect(loadedItem!.rawContent, equals('https://dart.dev'));

        final loadedCol = await freshAdapter.getCollection('col-01');
        expect(loadedCol, isNotNull);
        expect(loadedCol!.name, equals('Test Collection'));

        // Batch delete and clear
        await freshAdapter.deleteItem('file-item-01');
        expect(await freshAdapter.getItem('file-item-01'), isNull);

        await freshAdapter.clearAll();
        expect(await freshAdapter.getAllCollections(), isEmpty);

        await freshAdapter.close();
      });
    });

    // =========================================================================
    // 5. QrVault Engine Integration Tests
    // =========================================================================
    group('QrVault Engine Integration Tests', () {
      test('Complete item recording, querying, pagination, and favorites workflow', () async {
        final vault = QrVault.inMemory(integrityKey: testHmacKey);
        await vault.init();

        // 1. Record items
        final item1 = await vault.recordItem(
          rawContent: 'https://github.com',
          payloadType: QrPayloadType.url,
          title: 'GitHub',
          tags: ['git', 'code'],
          isFavorite: false,
        );
        expect(item1.integrityHash.isNotEmpty, isTrue);
        expect(vault.verifyItemIntegrity(item1), isTrue);

        final item2 = await vault.recordItem(
          rawContent: 'tel:+15551234567',
          payloadType: QrPayloadType.tel,
          title: 'Office Phone',
          tags: ['contact'],
          isFavorite: true,
        );

        // 2. Query and Pagination
        final all = await vault.query(const QrVaultFilter());
        expect(all.length, equals(2));

        final paged = await vault.query(const QrVaultFilter(), limit: 1, offset: 0);
        expect(paged.length, equals(1));

        final paged2 = await vault.query(const QrVaultFilter(), limit: 1, offset: 1);
        expect(paged2.length, equals(1));
        expect(paged.first.id, isNot(equals(paged2.first.id)));

        // Offset out of bounds
        final emptyPage = await vault.query(const QrVaultFilter(), offset: 10);
        expect(emptyPage, isEmpty);

        // Count
        final countAll = await vault.count(const QrVaultFilter());
        expect(countAll, equals(2));

        // 3. Toggle favorite
        final favUpdated = await vault.toggleFavorite(item1.id);
        expect(favUpdated!.isFavorite, isTrue);
        expect(vault.verifyItemIntegrity(favUpdated), isTrue);

        // 4. Update title and notes
        final titled = await vault.updateTitle(item1.id, 'GitHub Portal');
        expect(titled!.title, equals('GitHub Portal'));
        expect(vault.verifyItemIntegrity(titled), isTrue);

        final noted = await vault.updateNotes(item1.id, 'My repos');
        expect(noted!.notes, equals('My repos'));
        expect(vault.verifyItemIntegrity(noted), isTrue);

        // 5. Set tags
        final tagged = await vault.setTags(item1.id, ['dev', 'oss', 'git']);
        expect(tagged!.tags, equals(['dev', 'oss', 'git']));
        expect(vault.verifyItemIntegrity(tagged), isTrue);

        // 6. Non-existent updates return null
        expect(await vault.toggleFavorite('non-existent'), isNull);
        expect(await vault.assignCollection('non-existent', 'col'), isNull);
        expect(await vault.setTags('non-existent', []), isNull);
        expect(await vault.updateTitle('non-existent', 'x'), isNull);
        expect(await vault.updateNotes('non-existent', 'x'), isNull);

        // 7. Delete
        await vault.deleteItem(item2.id);
        expect(await vault.getItem(item2.id), isNull);

        await vault.close();
      });

      test('Incognito mode skips persisting scanned items but retains generated ones', () async {
        final vault = QrVault.inMemory(
          integrityKey: testHmacKey,
          privacyPolicy: const VaultPrivacyPolicy(isIncognitoMode: true),
        );
        await vault.init();

        final scannedItem = await vault.recordItem(
          rawContent: 'https://incognito-scan.org',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.scanned,
        );
        expect(await vault.getItem(scannedItem.id), isNull);

        final generatedItem = await vault.recordItem(
          rawContent: 'https://incognito-gen.org',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.generated,
        );
        expect(await vault.getItem(generatedItem.id), isNotNull);
      });

      test('Collection lifecycle: create, compute item counts, unlink vs delete contained items', () async {
        final vault = QrVault.inMemory(integrityKey: testHmacKey);
        await vault.init();

        final col = await vault.createCollection(
          name: 'Travel',
          description: 'Boarding passes and hotels',
          colorHex: '#FF5722',
        );

        final item1 = await vault.recordItem(
          rawContent: 'https://airline.com/pass/123',
          payloadType: QrPayloadType.url,
          collectionId: col.id,
        );
        final item2 = await vault.recordItem(
          rawContent: 'geo:48.8584,2.2945',
          payloadType: QrPayloadType.geo,
          collectionId: col.id,
        );

        // Verify computed item counts
        final collections = await vault.getCollections();
        expect(collections.first.itemCount, equals(2));

        // Delete collection without deleting contained items (unlinks items)
        await vault.deleteCollection(col.id, deleteContainedItems: false);
        expect(await vault.getCollections(), isEmpty);

        final item1Reloaded = await vault.getItem(item1.id);
        expect(item1Reloaded!.collectionId, isNull);
        expect(vault.verifyItemIntegrity(item1Reloaded), isTrue);

        // Recreate and delete with deleteContainedItems = true
        final col2 = await vault.createCollection(name: 'Temporary');
        await vault.assignCollection(item1.id, col2.id);
        await vault.assignCollection(item2.id, col2.id);

        await vault.deleteCollection(col2.id, deleteContainedItems: true);
        expect(await vault.getItem(item1.id), isNull);
        expect(await vault.getItem(item2.id), isNull);
      });

      test('Tag management and aggregation', () async {
        final vault = QrVault.inMemory(integrityKey: testHmacKey);
        await vault.init();

        await vault.recordItem(rawContent: 'A', payloadType: QrPayloadType.plainText, tags: ['work', 'urgent']);
        await vault.recordItem(rawContent: 'B', payloadType: QrPayloadType.plainText, tags: ['work', 'review']);
        await vault.recordItem(rawContent: 'C', payloadType: QrPayloadType.plainText, tags: ['personal']);

        final allTags = await vault.getAllTags();
        expect(allTags, equals(['personal', 'review', 'urgent', 'work']));

        final tagCounts = await vault.getTagCounts();
        expect(tagCounts['work'], equals(2));
        expect(tagCounts['personal'], equals(1));
        expect(tagCounts['review'], equals(1));
      });

      test('Integrity Audit: detects tampered records in storage', () async {
        final adapter = InMemoryVaultStorageAdapter();
        await adapter.init();
        final vault = QrVault(storage: adapter, integrityKey: testHmacKey);

        final item1 = await vault.recordItem(
          rawContent: 'https://clean-site.org',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
        );
        expect(vault.verifyItemIntegrity(item1), isTrue);
        final item2 = await vault.recordItem(
          rawContent: 'https://malicious-site.org',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.critical,
          safetyScore: 10,
        );

        // Before tampering: 0 tampered items
        expect(await vault.getTamperedItems(), isEmpty);

        // Adversary tampers with item2 in storage (alters threatLevel to bypass security warnings)
        final maliciousTamper = item2.copyWith(threatLevel: SecurityThreatLevel.safe, safetyScore: 100);
        await adapter.saveItem(maliciousTamper);

        final tampered = await vault.getTamperedItems();
        expect(tampered.length, equals(1));
        expect(tampered.first.id, equals(item2.id));
      });

      test('Privacy auto-purge deletes old scanned records while preserving favorites', () async {
        final vault = QrVault.inMemory(
          integrityKey: testHmacKey,
          privacyPolicy: const VaultPrivacyPolicy(autoPurgeHistoryDays: 30, keepFavoritesOnPurge: true),
        );
        await vault.init();

        final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 45));

        // 1. Old scanned item (not favorite) -> should be purged
        final oldScan = await vault.recordItem(
          rawContent: 'https://old-scan.com',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.scanned,
          createdAt: oldDate,
          isFavorite: false,
        );

        // 2. Old scanned item (favorite) -> should be preserved
        final oldFav = await vault.recordItem(
          rawContent: 'https://old-fav.com',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.scanned,
          createdAt: oldDate,
          isFavorite: true,
        );

        // 3. Old generated item -> should be preserved (purge applies to scans only)
        final oldGen = await vault.recordItem(
          rawContent: 'https://old-gen.com',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.generated,
          createdAt: oldDate,
        );

        // 4. Recent scanned item -> should be preserved
        final recentScan = await vault.recordItem(
          rawContent: 'https://recent-scan.com',
          payloadType: QrPayloadType.url,
          origin: QrItemOrigin.scanned,
        );

        final purgedCount = await vault.purgeHistory(olderThanDays: 30);
        expect(purgedCount, equals(1));

        expect(await vault.getItem(oldScan.id), isNull);
        expect(await vault.getItem(oldFav.id), isNotNull);
        expect(await vault.getItem(oldGen.id), isNotNull);
        expect(await vault.getItem(recentScan.id), isNotNull);

        // Clear all history keeping favorites
        final cleared = await vault.clearAllHistory(keepFavorites: true);
        expect(cleared, equals(1)); // recentScan deleted
        expect(await vault.getItem(oldFav.id), isNotNull); // oldFav still kept
      });

      test('Export to JSON and import from JSON with validation and duplicate handling', () async {
        final vaultA = QrVault.inMemory(integrityKey: testHmacKey);
        await vaultA.init();

        final col = await vaultA.createCollection(name: 'Work');
        final itemA = await vaultA.recordItem(
          rawContent: 'https://dart.dev',
          payloadType: QrPayloadType.url,
          title: 'Dart Dev',
          collectionId: col.id,
          tags: ['dart'],
        );

        final jsonExport = await vaultA.exportToJson();
        expect(jsonExport.contains('trustqr-vault-export'), isTrue);
        expect(jsonExport.contains('Work'), isTrue);
        expect(jsonExport.contains('https://dart.dev'), isTrue);

        // Import into fresh vaultB
        final vaultB = QrVault.inMemory(integrityKey: testHmacKey);
        await vaultB.init();

        final result = await vaultB.importFromJson(jsonExport);
        expect(result.importedCollections, equals(1));
        expect(result.importedItems, equals(1));
        expect(result.skippedItems, equals(0));
        expect(result.tamperedItems, equals(0));

        final importedItem = await vaultB.getItem(itemA.id);
        expect(importedItem, isNotNull);
        expect(importedItem!.title, equals('Dart Dev'));
        expect(vaultB.verifyItemIntegrity(importedItem), isTrue);

        // Duplicate import without overwrite -> skipped
        final dupeResult = await vaultB.importFromJson(jsonExport, overwrite: false);
        expect(dupeResult.skippedItems, equals(1));
        expect(dupeResult.importedItems, equals(0));

        // Duplicate import with overwrite -> imported
        final overwriteResult = await vaultB.importFromJson(jsonExport, overwrite: true);
        expect(overwriteResult.importedItems, equals(1));

        // Result JSON serialization
        final resultJson = result.toJson();
        expect(resultJson['importedItems'], equals(1));
        expect(resultJson['importedCollections'], equals(1));
        expect(resultJson['skippedItems'], equals(0));
        expect(resultJson['tamperedItems'], equals(0));

        // Import with tampered item
        final tamperedExport = jsonExport.replaceFirst('"https://dart.dev"', '"https://tampered-url.com"');
        final tamperedResult = await vaultB.importFromJson(tamperedExport, overwrite: true, verifyIntegritySignatures: true);
        expect(tamperedResult.tamperedItems, equals(1));
      });

      test('Batch storage adapter operations and helper constructors', () async {
        // InMemory batch
        final memAdapter = InMemoryVaultStorageAdapter();
        await memAdapter.init();
        final itemA = QrVaultItem(
          id: 'memA',
          rawContent: 'testA',
          payloadType: QrPayloadType.plainText,
          threatLevel: SecurityThreatLevel.safe,
          safetyScore: 100,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now().toUtc(),
          integrityHash: 'hashA',
        );
        final itemB = QrVaultItem(
          id: 'memB',
          rawContent: 'testB',
          payloadType: QrPayloadType.plainText,
          threatLevel: SecurityThreatLevel.safe,
          safetyScore: 100,
          origin: QrItemOrigin.scanned,
          createdAt: DateTime.now().toUtc(),
          integrityHash: 'hashB',
        );

        await memAdapter.saveItems([itemA, itemB]);
        expect((await memAdapter.getAllItems()).length, equals(2));
        await memAdapter.deleteItems(['memA', 'memB']);
        expect(await memAdapter.getAllItems(), isEmpty);

        // FileJson fromFile constructor and batch operations
        final file = File('${tempDir.path}/batch_vault.json');
        final fileAdapter = FileJsonVaultStorageAdapter.fromFile(file);
        await fileAdapter.init();

        final col = QrCollection(id: 'col1', name: 'Col 1', createdAt: DateTime.now().toUtc());
        await fileAdapter.saveCollection(col);
        expect(await fileAdapter.getCollection('col1'), isNotNull);
        await fileAdapter.deleteCollection('col1');
        expect(await fileAdapter.getCollection('col1'), isNull);

        await fileAdapter.saveItems([itemA, itemB]);
        expect((await fileAdapter.getAllItems()).length, equals(2));
        await fileAdapter.deleteItems(['memA', 'memB']);
        expect(await fileAdapter.getAllItems(), isEmpty);

        await fileAdapter.close();
      });

      test('Search with origin and deleteItems on QrVault', () async {
        final vault = QrVault.inMemory(integrityKey: testHmacKey);
        await vault.init();

        final item1 = await vault.recordItem(
          rawContent: 'https://scan-origin.org',
          payloadType: QrPayloadType.url,
          title: 'Scanned Search Item',
          origin: QrItemOrigin.scanned,
        );
        final item2 = await vault.recordItem(
          rawContent: 'https://gen-origin.org',
          payloadType: QrPayloadType.url,
          title: 'Generated Search Item',
          origin: QrItemOrigin.generated,
        );

        // Search with origin filter
        final scannedResults = await vault.search('search', origin: QrItemOrigin.scanned);
        expect(scannedResults.length, equals(1));
        expect(scannedResults.first.id, equals(item1.id));

        final genResults = await vault.search('search', origin: QrItemOrigin.generated);
        expect(genResults.length, equals(1));
        expect(genResults.first.id, equals(item2.id));

        // Query with negative offset clamps cleanly to 0
        final negativeOffsetQuery = await vault.query(const QrVaultFilter(), offset: -5);
        expect(negativeOffsetQuery.length, equals(2));

        // Batch deleteItems
        await vault.deleteItems([item1.id, item2.id]);
        expect(await vault.query(const QrVaultFilter()), isEmpty);
      });

      test('VaultMetrics computes real summary over stored dataset', () async {
        final vault = QrVault.inMemory(integrityKey: testHmacKey);
        await vault.init();

        await vault.createCollection(name: 'Col1');
        await vault.recordItem(
          rawContent: 'https://site1.com',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.safe,
          origin: QrItemOrigin.scanned,
          isFavorite: true,
          tags: ['tag1'],
        );
        await vault.recordItem(
          rawContent: 'https://site2.com',
          payloadType: QrPayloadType.url,
          threatLevel: SecurityThreatLevel.critical,
          origin: QrItemOrigin.generated,
          isFavorite: false,
          tags: ['tag1', 'tag2'],
        );

        final metrics = await vault.getMetrics();
        expect(metrics.totalItems, equals(2));
        expect(metrics.scannedCount, equals(1));
        expect(metrics.generatedCount, equals(1));
        expect(metrics.favoritesCount, equals(1));
        expect(metrics.collectionsCount, equals(1));
        expect(metrics.tagsCount, equals(2));
        expect(metrics.threatLevelCounts[SecurityThreatLevel.safe], equals(1));
        expect(metrics.threatLevelCounts[SecurityThreatLevel.critical], equals(1));

        final metricsJson = metrics.toJson();
        expect(metricsJson['totalItems'], equals(2));
        expect((metricsJson['threatLevelCounts'] as Map)['safe'], equals(1));
      });
    });
  });
}
