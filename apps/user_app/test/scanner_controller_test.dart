import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:user_app/src/state/scanner_controller.dart';

void main() {
  group('ScannerController State & Pipeline Tests', () {
    late QrVault testVault;
    late ScanToVaultPipeline testPipeline;
    late ScannerController controller;

    setUp(() async {
      testVault = QrVault.inMemory(
        integrityKey: CryptoKeyPair.generateHmacKey().privateKey,
      );
      await testVault.init();
      testPipeline = ScanToVaultPipeline(
        scanner: UniversalQrScannerEngine(),
        firewall: QrThreatFirewall(),
        vault: testVault,
      );
      controller = ScannerController(pipeline: testPipeline);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initializes with default idle state and zero error', () {
      expect(controller.hudState, equals(ScannerHudState.idle));
      expect(controller.activeScanResult, isNull);
      expect(controller.multiQrCandidates, isEmpty);
      expect(controller.isProcessing, isFalse);
      expect(controller.isTorchOn, isFalse);
      expect(controller.isIncognito, isFalse);
      expect(controller.lastErrorMessage, isNull);
      expect(controller.vault, equals(testVault));
    });

    test('Toggles torch and incognito modes', () {
      expect(controller.isTorchOn, isFalse);
      controller.toggleTorch();
      expect(controller.isTorchOn, isTrue);
      controller.toggleTorch();
      expect(controller.isTorchOn, isFalse);

      expect(controller.isIncognito, isFalse);
      controller.toggleIncognito();
      expect(controller.isIncognito, isTrue);
      controller.toggleIncognito();
      expect(controller.isIncognito, isFalse);
    });

    test('scanRawString with safe URL updates state to safe and records in vault', () async {
      final result = await controller.scanRawString('https://secure.example.com/checkout');

      expect(result, isNotNull);
      expect(controller.hudState, equals(ScannerHudState.safe));
      expect(controller.activeScanResult, equals(result));
      expect(result!.payload.type, equals(QrPayloadType.url));
      expect(result.threatAssessment.safetyScore, greaterThanOrEqualTo(80));
      expect(result.isAllowed, isTrue);

      // Verify recorded in vault
      final items = await testVault.query(const QrVaultFilter());
      expect(items.length, equals(1));
      expect(items.first.rawContent, equals('https://secure.example.com/checkout'));
    });

    test('scanRawString in incognito mode bypasses vault recording', () async {
      controller.toggleIncognito();
      expect(controller.isIncognito, isTrue);

      final result = await controller.scanRawString('https://private-scan.org');
      expect(result, isNotNull);
      expect(controller.activeScanResult, equals(result));

      // Verify NOT recorded in vault
      final items = await testVault.query(const QrVaultFilter());
      expect(items, isEmpty);
    });

    test('scanRawString with malicious payload transitions to threat and quarantines', () async {
      // JavaScript URI is a dangerous blocked scheme
      final result = await controller.scanRawString('javascript:alert(document.cookie)');

      expect(result, isNotNull);
      expect(controller.hudState, equals(ScannerHudState.threat));
      expect(result!.isAllowed, isFalse);
      expect(result.threatAssessment.threatLevel, equals(SecurityThreatLevel.critical));
    });

    test('scanRawString with empty string returns null', () async {
      final result = await controller.scanRawString('   ');
      expect(result, isNull);
      expect(controller.activeScanResult, isNull);
    });

    test('scanImageBuffer with empty frame returns null and sets error', () async {
      final buffer = ImageBuffer(
        bytes: Uint8List(100),
        width: 10,
        height: 10,
        format: ImageColorFormat.grayscale,
      );
      final result = await controller.scanImageBuffer(buffer);

      expect(result, isNull);
      expect(controller.lastErrorMessage, isNotNull);
      expect(controller.hudState, equals(ScannerHudState.idle));
    });

    test('scanFileBytes with empty bytes returns null', () async {
      final result = await controller.scanFileBytes(Uint8List(0));
      expect(result, isNull);
    });

    test('scanFileBytes with invalid bytes returns null and sets error', () async {
      final result = await controller.scanFileBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(result, isNull);
      expect(controller.lastErrorMessage, isNotNull);
    });

    test('scanMultiQrBuffer with empty image returns empty list and sets error', () async {
      final buffer = ImageBuffer(
        bytes: Uint8List(1600),
        width: 40,
        height: 40,
        format: ImageColorFormat.grayscale,
      );
      final results = await controller.scanMultiQrBuffer(buffer);

      expect(results, isEmpty);
      expect(controller.lastErrorMessage, isNotNull);
      expect(controller.multiQrCandidates, isEmpty);
    });

    test('selectMultiQrCandidate and dismissActiveResult manage candidate states', () async {
      final result = await controller.scanRawString('WIFI:S:MyNet;T:WPA;P:secret123;;');
      expect(controller.activeScanResult, isNotNull);

      controller.dismissActiveResult();
      expect(controller.activeScanResult, isNull);
      expect(controller.hudState, equals(ScannerHudState.idle));

      // Select candidate
      controller.selectMultiQrCandidate(result!);
      expect(controller.activeScanResult, equals(result));
    });

    test('saveCurrentToVault persists active scan item explicitly', () async {
      controller.toggleIncognito(); // scan without auto-recording
      await controller.scanRawString('SMSTO:+1234567890:Hello World');

      expect(await testVault.query(const QrVaultFilter()), isEmpty);

      final savedItem = await controller.saveCurrentToVault(
        title: 'Important SMS',
        notes: 'Manual save test',
      );

      expect(savedItem, isNotNull);
      expect(savedItem!.title, equals('Important SMS'));
      expect(savedItem.notes, equals('Manual save test'));

      final items = await testVault.query(const QrVaultFilter());
      expect(items.length, equals(1));
    });

    test('saveCurrentToVault returns null if no active result', () async {
      final item = await controller.saveCurrentToVault();
      expect(item, isNull);
    });

    test('Default ScannerController instantiates cleanly without params', () {
      final ctrl = ScannerController();
      expect(ctrl.pipeline, isNotNull);
      expect(ctrl.vault, isNotNull);
      ctrl.dispose();
    });

    test('Throwing pipeline transitions state to threat and records error message', () async {
      final errorPipeline = _ThrowingPipeline();
      final errCtrl = ScannerController(pipeline: errorPipeline);

      final strRes = await errCtrl.scanRawString('bad');
      expect(strRes, isNull);
      expect(errCtrl.hudState, equals(ScannerHudState.threat));

      final imgRes = await errCtrl.scanImageBuffer(ImageBuffer(bytes: Uint8List(1), width: 1, height: 1));
      expect(imgRes, isNull);
      expect(errCtrl.hudState, equals(ScannerHudState.threat));

      final fileRes = await errCtrl.scanFileBytes(Uint8List.fromList([1, 2]));
      expect(fileRes, isNull);
      expect(errCtrl.hudState, equals(ScannerHudState.threat));

      final multiRes = await errCtrl.scanMultiQrBuffer(ImageBuffer(bytes: Uint8List(1), width: 1, height: 1));
      expect(multiRes, isEmpty);
      expect(errCtrl.hudState, equals(ScannerHudState.threat));

      errCtrl.dispose();
    });

    test('Multi-QR pipeline with single and multiple candidate branches', () async {
      final singlePipeline = _MockMultiPipeline([
        PipelineScanResult(
          rawContent: 'https://single.org',
          payload: UrlPayload(uri: Uri.parse('https://single.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 90,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          latencyMs: 1.0,
          timestamp: DateTime.now(),
        ),
      ]);

      final singleCtrl = ScannerController(pipeline: singlePipeline);
      final singleRes = await singleCtrl.scanMultiQrBuffer(ImageBuffer(bytes: Uint8List(1), width: 1, height: 1));
      expect(singleRes.length, equals(1));
      expect(singleCtrl.multiQrCandidates, isEmpty);
      expect(singleCtrl.activeScanResult, isNotNull);
      singleCtrl.dispose();

      final multiPipeline = _MockMultiPipeline([
        PipelineScanResult(
          rawContent: 'https://one.org',
          payload: UrlPayload(uri: Uri.parse('https://one.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 90,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          latencyMs: 1.0,
          timestamp: DateTime.now(),
        ),
        PipelineScanResult(
          rawContent: 'https://two.org',
          payload: UrlPayload(uri: Uri.parse('https://two.org')),
          threatAssessment: const ThreatAssessment(
            safetyScore: 85,
            threatLevel: SecurityThreatLevel.safe,
            findings: [],
            isActionAllowed: true,
            summary: 'Safe',
          ),
          latencyMs: 1.0,
          timestamp: DateTime.now(),
        ),
      ]);

      final multiCtrl = ScannerController(pipeline: multiPipeline);
      final multiRes = await multiCtrl.scanMultiQrBuffer(ImageBuffer(bytes: Uint8List(1), width: 1, height: 1));
      expect(multiRes.length, equals(2));
      expect(multiCtrl.multiQrCandidates.length, equals(2));
      expect(multiCtrl.activeScanResult, isNull);
      expect(multiCtrl.hudState, equals(ScannerHudState.scanning));
      multiCtrl.dispose();
    });
  });
}

class _ThrowingPipeline extends Fake implements ScanToVaultPipeline {
  @override
  QrVault? get vault => null;

  @override
  Future<PipelineScanResult> processRawString(String rawContent, {PipelineOptions? options, String? title, String? notes}) {
    throw Exception('Simulated pipeline error');
  }

  @override
  Future<PipelineScanResult?> processImageBuffer(ImageBuffer buffer, {PipelineOptions? options, String? title, String? notes}) {
    throw Exception('Simulated buffer error');
  }

  @override
  Future<PipelineScanResult?> processFileBytes(Uint8List fileBytes, {PipelineOptions? options, String? title, String? notes}) {
    throw Exception('Simulated file error');
  }

  @override
  Future<List<PipelineScanResult>> processMultiQrImage(ImageBuffer buffer, {PipelineOptions? options}) {
    throw Exception('Simulated multi-QR error');
  }
}

class _MockMultiPipeline extends Fake implements ScanToVaultPipeline {
  final List<PipelineScanResult> mockResults;
  _MockMultiPipeline(this.mockResults);

  @override
  QrVault? get vault => null;

  @override
  Future<List<PipelineScanResult>> processMultiQrImage(ImageBuffer buffer, {PipelineOptions? options}) async {
    return mockResults;
  }
}
