// Universal QR Platform — User App End-to-End (E2E) Journey Test
// Exercises the complete user workflow:
// Camera/File Scanning -> Zero-Trust Threat Firewall -> Ed25519 TrustQR Verification ->
// Encrypted Vault Persistence -> FTS Querying, Tags, Collections & Favorites.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/src/state/scanner_controller.dart';
import 'package:user_app/src/state/vault_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QrVault vault;
  late CryptoPrivateKey integrityKey;
  late VaultController vaultController;
  late ScanToVaultPipeline pipeline;
  late ScannerController scannerController;

  setUp(() async {
    integrityKey = CryptoKeyPair.generateHmacKey().privateKey;
    vault = QrVault.inMemory(integrityKey: integrityKey);
    await vault.init();

    vaultController = VaultController(vault: vault);
    await vaultController.init();

    pipeline = ScanToVaultPipeline(
      scanner: UniversalQrScannerEngine(),
      firewall: QrThreatFirewall(),
      vault: vault,
    );
    scannerController = ScannerController(pipeline: pipeline);
  });

  tearDown(() {
    scannerController.dispose();
    vaultController.dispose();
  });

  group('User App E2E Journey Tests', () {
    test('E2E Journey 1: Malicious Phishing QR Interception & Firewall Mitigation', () async {
      // 1. Ingest suspicious QR payload (punycode + raw IP + high entropy)
      const maliciousUrl = 'http://192.168.1.1/secure-bank-login?token=x938fn29dk30sl20fmk';

      final pipelineResult = await scannerController.scanRawString(maliciousUrl);

      // 2. Verify scan result payload parsing
      expect(pipelineResult, isNotNull);
      expect(pipelineResult!.payloadType, equals(QrPayloadType.url));

      // 3. Inspect Threat Firewall evaluation
      expect(pipelineResult.threatLevel, isIn([
        SecurityThreatLevel.caution,
        SecurityThreatLevel.suspicious,
        SecurityThreatLevel.critical,
      ]));
      expect(pipelineResult.safetyScore, lessThanOrEqualTo(80));

      // 4. Verify HUD alert state transitions
      expect(
        scannerController.hudState,
        isIn([ScannerHudState.threat, ScannerHudState.warning, ScannerHudState.scanning]),
      );
    });

    test('E2E Journey 2: Legitimate Ed25519 TrustQR Verification & Encrypted Vault Lifecycle', () async {
      // 1. Setup institutional Ed25519 authority keypair
      final seed = Uint8List.fromList(List.generate(32, (i) => (i * 17 + 5) % 256));
      final edKeyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'trust-key-2026-e2e');
      const rawPayload = 'https://portal.universalqr.corp/credentials/emp-98214';

      final signedEnvelope = TrustQrEnvelope.sign(
        issuer: 'authority.universalqr.corp',
        payload: rawPayload,
        privateKey: edKeyPair.privateKey,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );

      final trustQrUri = signedEnvelope.toUriString();
      expect(trustQrUri.startsWith('trustqr://v1?'), isTrue);

      // 2. Decode TrustQR URI via Scanner Pipeline
      final pipelineResult = await scannerController.scanRawString(trustQrUri);
      expect(pipelineResult, isNotNull);
      expect(pipelineResult!.isSavedToVault, isTrue);

      // 3. Verify cryptographic envelope
      final parsed = TrustQrEnvelope.tryParse(trustQrUri);
      expect(parsed, isNotNull);
      final verification = parsed!.verify(publicKey: edKeyPair.publicKey);
      expect(verification.isValid, isTrue);

      // 4. Inspect Auto-Persisted Item in Offline-First Vault
      await vaultController.refresh();
      expect(vaultController.items.length, equals(1));
      final recordedItem = vaultController.items.first;
      expect(recordedItem.rawContent, equals(trustQrUri));

      // Update title and tags
      await vaultController.updateTitle(recordedItem.id, 'Executive Corporate Credential');
      await vaultController.setTags(recordedItem.id, ['corporate', 'security', 'verified']);
      expect(vaultController.tags, containsAll(['corporate', 'security', 'verified']));

      // 5. Create a Collection and assign the record
      final collection = await vaultController.createCollection(
        name: 'Executive Access Badges',
        description: 'Verified Ed25519 corporate credentials',
        colorHex: '#00E5FF',
      );

      await vaultController.assignCollection(recordedItem.id, collection.id);
      expect(vaultController.items.first.collectionId, equals(collection.id));

      // 6. Toggle Favorite Status
      await vaultController.toggleFavorite(recordedItem.id);
      expect(vaultController.items.first.isFavorite, isTrue);

      // 7. Full-Text Search (FTS) Querying
      await vaultController.updateSearchQuery('Executive');
      expect(vaultController.items.length, equals(1));
      expect(vaultController.items.first.id, equals(recordedItem.id));

      // Clear search filter
      await vaultController.updateSearchQuery(null);
      expect(vaultController.items.length, equals(1));

      // 8. Cryptographic HMAC-SHA256 Item Integrity Verification
      final isIntegrityValid = vaultController.verifyIntegrity(vaultController.items.first);
      expect(isIntegrityValid, isTrue);
    });

    test('E2E Journey 3: Multi-Source Batch QR Ingestion & Tag Filtering', () async {
      const sampleQr1 = 'WIFI:T:WPA;S:BranchOfficeGuest;P:CyberSecret2026;;';
      const sampleQr2 = 'geo:37.7749,-122.4194?u=35';

      final res1 = await scannerController.scanRawString(sampleQr1);
      final res2 = await scannerController.scanRawString(sampleQr2);

      expect(res1, isNotNull);
      expect(res2, isNotNull);

      await vaultController.refresh();
      expect(vaultController.items.length, equals(2));

      final item1 = vaultController.items.firstWhere((i) => i.rawContent == sampleQr1);
      final item2 = vaultController.items.firstWhere((i) => i.rawContent == sampleQr2);

      await vaultController.updateTitle(item1.id, 'Branch Office Wi-Fi');
      await vaultController.setTags(item1.id, ['infrastructure', 'wifi']);

      await vaultController.updateTitle(item2.id, 'HQ Coordinates');
      await vaultController.setTags(item2.id, ['navigation', 'hq']);

      // Filter by tag
      await vaultController.setTagsFilter({'wifi'});
      expect(vaultController.items.length, equals(1));
      expect(vaultController.items.first.title, equals('Branch Office Wi-Fi'));

      // Clear filter
      await vaultController.clearFilters();
      expect(vaultController.items.length, equals(2));
    });
  });
}
