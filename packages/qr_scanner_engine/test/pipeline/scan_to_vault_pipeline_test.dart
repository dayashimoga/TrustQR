import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('ScanToVaultPipeline End-to-End Tests', () {
    late CryptoPrivateKey testIntegrityKey;
    late QrVault vault;
    late ScanToVaultPipeline pipeline;
    late CryptoKeyPair testTrustQrKeyPair;

    setUp(() async {
      testIntegrityKey = CryptoPrivateKey(
        keyId: 'vault-key-01',
        bytes: Uint8List.fromList(List<int>.generate(32, (i) => (i * 7) % 256)),
        algorithm: CryptoAlgorithm.hmacSha256,
      );

      vault = QrVault.inMemory(integrityKey: testIntegrityKey);
      await vault.init();

      final seed = Uint8List.fromList(List<int>.generate(32, (i) => (i + 42) % 256));
      testTrustQrKeyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'inst-01');

      pipeline = ScanToVaultPipeline(
        vault: vault,
        defaultOptions: PipelineOptions(
          enableThreatFirewall: true,
          saveToVault: true,
          autoDeduplicate: true,
          deduplicationWindow: const Duration(seconds: 5),
          trustedInstitutionalKeys: {
            'inst-01': testTrustQrKeyPair.publicKey,
          },
        ),
      );
    });

    tearDown(() async {
      await vault.close();
    });

    test('Processes benign HTTPS URL, runs firewall, and persists to vault with smart tags', () async {
      const url = 'https://example.com/portal/login';
      final result = await pipeline.processRawString(url);

      expect(result.rawContent, equals(url));
      expect(result.payloadType, equals(QrPayloadType.url));
      expect(result.threatLevel, equals(SecurityThreatLevel.safe));
      expect(result.safetyScore, equals(100));
      expect(result.isAllowed, isTrue);
      expect(result.isDeduplicated, isFalse);
      expect(result.isSavedToVault, isTrue);
      expect(result.vaultItem, isNotNull);

      // Verify vault item integrity
      final storedItem = result.vaultItem!;
      expect(storedItem.rawContent, equals(url));
      expect(storedItem.verifyIntegrity(testIntegrityKey), isTrue);
      expect(storedItem.tags, contains('#url'));
      expect(storedItem.tags, contains('#https'));
      expect(storedItem.title, equals('example.com'));

      // Check item retrievable from vault
      final retrieved = await vault.getItem(storedItem.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.rawContent, equals(url));
    });

    test('Deduplicates identical scans within deduplicationWindow', () async {
      const content = 'WIFI:S:MyHomeNetwork;T:WPA;P:SecretPass123;;';

      // First scan
      final res1 = await pipeline.processRawString(content);
      expect(res1.isDeduplicated, isFalse);
      expect(res1.isSavedToVault, isTrue);
      final firstItemId = res1.vaultItem!.id;

      // Immediate second scan of identical content
      final res2 = await pipeline.processRawString(content);
      expect(res2.isDeduplicated, isTrue);
      expect(res2.vaultItem, isNotNull);
      expect(res2.vaultItem!.id, equals(firstItemId));

      // Vault should contain exactly 1 item
      final allItems = await vault.query(const QrVaultFilter());
      expect(allItems.length, equals(1));
    });

    test('Blocks vault recording when blockVaultOnCriticalThreat is enabled (quarantine)', () async {
      const xssPayload = 'javascript:alert(document.cookie)';

      final quarantinePipeline = ScanToVaultPipeline(
        vault: vault,
        defaultOptions: const PipelineOptions(
          blockVaultOnCriticalThreat: true,
          saveToVault: true,
        ),
      );

      final result = await quarantinePipeline.processRawString(xssPayload);
      expect(result.threatLevel, equals(SecurityThreatLevel.critical));
      expect(result.isAllowed, isFalse);
      expect(result.safetyScore, equals(0));
      expect(result.isSavedToVault, isFalse);
      expect(result.vaultItem, isNull);

      final vaultItems = await vault.query(const QrVaultFilter());
      expect(vaultItems, isEmpty);
    });

    test('Processes TrustQR signed payload with authenticity verification', () async {
      final envelope = TrustQrEnvelope.sign(
        issuer: 'Global Bank AG',
        payload: 'https://bank.example/secure-auth?session=123',
        privateKey: testTrustQrKeyPair.privateKey,
      );

      final trustQrUri = envelope.toUriString();
      final result = await pipeline.processRawString(trustQrUri);

      expect(result.payloadType, equals(QrPayloadType.url));
      expect(result.threatLevel, equals(SecurityThreatLevel.safe));
      expect(result.safetyScore, equals(100));
      expect(result.vaultItem, isNotNull);
      expect(result.vaultItem!.isTrustQr, isTrue);
      expect(result.vaultItem!.trustQrIssuer, equals('Global Bank AG'));
      expect(result.vaultItem!.tags, contains('#trustqr'));
      expect(result.vaultItem!.tags, contains('#verified'));
      expect(result.vaultItem!.title, equals('TrustQR: Global Bank AG'));
    });

    test('Detects tampered TrustQR envelope, flags threat and attaches #tampered tag', () async {
      final envelope = TrustQrEnvelope.sign(
        issuer: 'Global Bank AG',
        payload: 'https://bank.example/legit',
        privateKey: testTrustQrKeyPair.privateKey,
      );

      // Create tampered envelope with altered payload but original signature
      final tamperedEnvelope = TrustQrEnvelope(
        version: envelope.version,
        issuer: envelope.issuer,
        payload: 'https://bank.example/evil',
        createdAt: envelope.createdAt,
        expiresAt: envelope.expiresAt,
        keyId: envelope.keyId,
        algorithm: envelope.algorithm,
        signature: envelope.signature,
      );
      final tamperedUri = tamperedEnvelope.toUriString();

      final result = await pipeline.processRawString(tamperedUri);

      expect(result.threatLevel, equals(SecurityThreatLevel.critical));
      expect(result.safetyScore, lessThanOrEqualTo(20));
      expect(result.isAllowed, isFalse);
      expect(result.vaultItem, isNotNull);
      expect(result.vaultItem!.tags, contains('#tampered'));
      expect(result.vaultItem!.tags, contains('#threat-critical'));
    });

    test('Auto-categorizes various QR format types (vCard, MeCard, Event, Geo, Email, SMS, Tel)', () async {
      final formats = <String, ({String expectedTag, String titlePrefix})>{
        'BEGIN:VCARD\nVERSION:3.0\nFN:Alice Smith\nTEL:555-0199\nEND:VCARD':
            (expectedTag: '#contact', titlePrefix: 'Contact: Alice Smith'),
        'MECARD:N:Bob Jones;TEL:555-0188;;':
            (expectedTag: '#contact', titlePrefix: 'Contact: Bob Jones'),
        'BEGIN:VEVENT\nSUMMARY:Cyber Conference\nDTSTART:20261201T100000Z\nEND:VEVENT':
            (expectedTag: '#event', titlePrefix: 'Event: Cyber Conference'),
        'geo:37.7749,-122.4194?q=San+Francisco':
            (expectedTag: '#location', titlePrefix: 'Geo: 37.7749, -122.4194'),
        'mailto:support@example.com?subject=Help':
            (expectedTag: '#email', titlePrefix: 'Email to: support@example.com'),
        'smsto:+15550100:Hello there':
            (expectedTag: '#sms', titlePrefix: 'SMS to: +15550100'),
        'tel:+15550155':
            (expectedTag: '#phone', titlePrefix: 'Call: +15550155'),
        'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.5':
            (expectedTag: '#crypto', titlePrefix: 'bitcoin:1A1zP1eP5QGefi2DMPTfT'),
        'otpauth://totp/Acme:user@example.com?secret=JBSWY3DPEHPK3PXP':
            (expectedTag: '#2fa', titlePrefix: 'otpauth://totp/Acme:user@exam...'),
        'PLAIN TEXT NOTE':
            (expectedTag: '#text', titlePrefix: 'PLAIN TEXT NOTE'),
      };

      for (final entry in formats.entries) {
        final res = await pipeline.processRawString(entry.key);
        expect(res.vaultItem, isNotNull);
        expect(res.vaultItem!.tags, contains(entry.value.expectedTag));
        expect(res.vaultItem!.title, startsWith(entry.value.titlePrefix));
      }
    });

    test('Decodes and processes an ImageBuffer through full pipeline', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('PIPELINE-IMG');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 5);

      final result = await pipeline.processImageBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('PIPELINE-IMG'));
      expect(result.payloadType, equals(QrPayloadType.plainText));
      expect(result.isSavedToVault, isTrue);
      expect(result.vaultItem!.title, equals('PIPELINE-IMG'));
    });

    test('Decodes and processes raw BMP file bytes through full pipeline', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('FILE-BYTES');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 4);
      final bmpBytes = ImageFileDecoder.encodeBmp(buffer);

      final result = await pipeline.processFileBytes(bmpBytes);
      expect(result, isNotNull);
      expect(result!.rawContent, equals('FILE-BYTES'));
      expect(result.isSavedToVault, isTrue);
    });

    test('Detects and processes all QR codes in a multi-QR composite image', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('MULTI-P1');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('MULTI-P2');
      final composite = QrTestPatternGenerator.createMultiQrComposite([m1, m2], scale: 4);

      final results = await pipeline.processMultiQrImage(composite);
      expect(results.length, equals(2));
      final contents = results.map((r) => r.rawContent).toList();
      expect(contents, contains('MULTI-P1'));
      expect(contents, contains('MULTI-P2'));
      expect(results.every((r) => r.isSavedToVault), isTrue);
    });

    test('Streams and processes batch of images concurrently', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('BATCH-S1');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('BATCH-S2');
      final b1 = QrTestPatternGenerator.matrixToImageBuffer(m1, scale: 4);
      final b2 = QrTestPatternGenerator.matrixToImageBuffer(m2, scale: 4);

      // Stream
      final streamed = <PipelineScanResult>[];
      await for (final res in pipeline.processBatchImagesStream([b1, b2])) {
        streamed.add(res);
      }
      expect(streamed.length, equals(2));

      // Future list
      final list = await pipeline.processBatchImages([b1, b2]);
      expect(list.length, equals(2));
    });

    test('Streams and processes batch of file bytes concurrently', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('FILE-B1');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('FILE-B2');
      final f1 = ImageFileDecoder.encodeBmp(QrTestPatternGenerator.matrixToImageBuffer(m1, scale: 4));
      final f2 = ImageFileDecoder.encodeBmp(QrTestPatternGenerator.matrixToImageBuffer(m2, scale: 4));

      // Stream
      final streamed = <PipelineScanResult>[];
      await for (final res in pipeline.processBatchFilesStream([f1, f2])) {
        streamed.add(res);
      }
      expect(streamed.length, equals(2));

      // Future list
      final list = await pipeline.processBatchFiles([f1, f2]);
      expect(list.length, equals(2));
    });

    test('Handles pipeline without vault gracefully (vault: null)', () async {
      final noVaultPipeline = ScanToVaultPipeline(vault: null);
      final result = await noVaultPipeline.processRawString('https://novault.example');

      expect(result.rawContent, equals('https://novault.example'));
      expect(result.isSavedToVault, isFalse);
      expect(result.vaultItem, isNull);
    });

    test('Supports disabled firewall option (enableThreatFirewall: false)', () async {
      final result = await pipeline.processRawString(
        'https://example.com',
        options: const PipelineOptions(enableThreatFirewall: false),
      );

      expect(result.threatLevel, equals(SecurityThreatLevel.safe));
      expect(result.safetyScore, equals(100));
      expect(result.threatAssessment.summary, contains('disabled by pipeline options'));
    });

    test('Supports purgeOnScan with custom privacy retention policy', () async {
      final privacyVault = QrVault.inMemory(
        integrityKey: testIntegrityKey,
        privacyPolicy: const VaultPrivacyPolicy(
          autoPurgeHistoryDays: 0, // Purge everything older than 0 days
        ),
      );
      await privacyVault.init();

      final purgePipeline = ScanToVaultPipeline(
        vault: privacyVault,
        defaultOptions: const PipelineOptions(
          purgeOnScan: true,
          autoDeduplicate: false,
        ),
      );

      final res = await purgePipeline.processRawString('PURGE-ME');
      expect(res.vaultItem, isNotNull);
      await privacyVault.close();
    });

    test('Serializes PipelineOptions and PipelineScanResult to JSON and supports copyWith', () {
      const options = PipelineOptions(
        enableThreatFirewall: true,
        saveToVault: true,
        autoDeduplicate: false,
        deduplicationWindow: Duration(minutes: 1),
        blockVaultOnCriticalThreat: true,
        autoCategorize: false,
        defaultTags: ['#custom'],
        targetCollectionId: 'coll-1',
        useIsolate: false,
        purgeOnScan: true,
      );

      final json = options.toJson();
      expect(json['enableThreatFirewall'], isTrue);
      expect(json['autoDeduplicate'], isFalse);
      expect(json['deduplicationWindowMs'], equals(60000));
      expect(json['blockVaultOnCriticalThreat'], isTrue);
      expect(json['defaultTags'], contains('#custom'));

      final copied = options.copyWith(saveToVault: false);
      expect(copied.saveToVault, isFalse);
      expect(copied.blockVaultOnCriticalThreat, isTrue);

      final result = PipelineScanResult(
        rawContent: 'https://test.com',
        payload: QrPayloadParser.parse('https://test.com'),
        threatAssessment: const ThreatAssessment(
          safetyScore: 90,
          threatLevel: SecurityThreatLevel.safe,
          findings: [],
          isActionAllowed: true,
          summary: 'Safe test payload',
        ),
        latencyMs: 12.5,
        timestamp: DateTime.now(),
      );

      final resJson = result.toJson();
      expect(resJson['rawContent'], equals('https://test.com'));
      expect(resJson['payloadType'], equals('url'));
      expect(resJson['isAllowed'], isTrue);
      expect(resJson['latencyMs'], equals(12.5));
    });
  });
}
