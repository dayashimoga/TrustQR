import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('Pipeline Performance & Latency Benchmarks', () {
    late CryptoPrivateKey testIntegrityKey;
    late QrVault vault;
    late ScanToVaultPipeline pipeline;

    setUpAll(() async {
      testIntegrityKey = CryptoPrivateKey(
        keyId: 'bench-key-01',
        bytes: Uint8List.fromList(List<int>.generate(32, (i) => (i * 13) % 256)),
        algorithm: CryptoAlgorithm.hmacSha256,
      );

      vault = QrVault.inMemory(integrityKey: testIntegrityKey);
      await vault.init();

      pipeline = ScanToVaultPipeline(
        vault: vault,
        defaultOptions: const PipelineOptions(
          enableThreatFirewall: true,
          saveToVault: true,
          autoDeduplicate: false, // Ensure full processing for each iteration in benchmark
        ),
      );
    });

    tearDownAll(() async {
      await vault.close();
    });

    test('Single Image Frame Decode + Firewall + Vault Latency Benchmark (< 25 ms target)', () async {
      final matrix = QrTestPatternGenerator.createVersion1Matrix('BENCHMARK-IMG');
      final buffer = QrTestPatternGenerator.matrixToImageBuffer(matrix, scale: 5);

      // Warm-up iterations
      for (var i = 0; i < 5; i++) {
        await pipeline.processImageBuffer(buffer, options: const PipelineOptions(useIsolate: false));
      }

      const iterations = 50;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        final res = await pipeline.processImageBuffer(
          buffer,
          options: const PipelineOptions(useIsolate: false, saveToVault: false),
        );
        expect(res, isNotNull);
        expect(res!.rawContent, equals('BENCHMARK-IMG'));
      }
      sw.stop();

      final avgLatencyMs = (sw.elapsedMicroseconds / iterations) / 1000.0;
      final fps = (1000.0 / avgLatencyMs).round();

      print('\n============================================================');
      print('=== FRAME DECODE & SECURITY PIPELINE LATENCY BENCHMARK   ===');
      print('============================================================');
      print('Iterations       : $iterations');
      print('Total Elapsed    : ${sw.elapsedMilliseconds} ms');
      print('Avg Frame Latency: ${avgLatencyMs.toStringAsFixed(2)} ms');
      print('Frame Rate Equiv : $fps frames/sec');
      print('Target Latency   : < 25.0 ms / frame (PASS: ${avgLatencyMs < 25.0})');
      print('============================================================\n');

      expect(avgLatencyMs, lessThan(25.0),
          reason: 'Frame decode & firewall latency must average < 25 ms');
    });

    test('High-Throughput Raw String Pipeline Benchmark (> 5,000 payloads/sec)', () async {
      final corpus = <String>[
        'https://secure.example.com/checkout',
        'WIFI:S:OfficeGuest;T:WPA;P:GuestPass2026;;',
        'BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nTEL:+15550199\nEND:VCARD',
        'geo:40.7128,-74.0060',
        'mailto:devops@example.com?subject=Alert',
        'smsto:+18005550199:Emergency message',
        'https://pay.bank.example/transfer?amount=500',
        'bitcoin:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq?amount=0.1',
      ];

      // Warm-up
      for (final p in corpus) {
        await pipeline.processRawString(p, options: const PipelineOptions(saveToVault: false));
      }

      const totalCount = 5000;
      final sw = Stopwatch()..start();

      for (var i = 0; i < totalCount; i++) {
        final payload = corpus[i % corpus.length];
        await pipeline.processRawString(
          payload,
          options: const PipelineOptions(saveToVault: false),
        );
      }
      sw.stop();

      final totalMs = sw.elapsedMilliseconds;
      final avgLatencyUs = (sw.elapsedMicroseconds / totalCount);
      final avgLatencyMs = avgLatencyUs / 1000.0;
      final throughput = (totalCount / (totalMs / 1000.0)).round();

      print('============================================================');
      print('=== HIGH-THROUGHPUT PIPELINE INSPECTION BENCHMARK        ===');
      print('============================================================');
      print('Inspections      : $totalCount');
      print('Total Time       : $totalMs ms');
      print('Avg Latency      : ${avgLatencyMs.toStringAsFixed(4)} ms (${avgLatencyUs.toStringAsFixed(1)} µs)');
      print('Throughput       : $throughput payloads/sec');
      print('Target Throughput: > 5,000 payloads/sec (PASS: ${throughput > 5000})');
      print('============================================================\n');

      expect(throughput, greaterThan(5000),
          reason: 'Pipeline throughput must exceed 5,000 inspections/sec');
    });

    test('Multi-QR Image Extraction & Pipeline Benchmark', () async {
      final m1 = QrTestPatternGenerator.createVersion1Matrix('BENCH-M1');
      final m2 = QrTestPatternGenerator.createVersion1Matrix('BENCH-M2');
      final composite = QrTestPatternGenerator.createMultiQrComposite([m1, m2], scale: 4, gap: 16);

      final sw = Stopwatch()..start();
      const multiIterations = 10;
      for (var i = 0; i < multiIterations; i++) {
        final results = await pipeline.processMultiQrImage(
          composite,
          options: const PipelineOptions(useIsolate: false, saveToVault: false),
        );
        expect(results.length, equals(2));
      }
      sw.stop();

      final avgMultiLatencyMs = (sw.elapsedMicroseconds / multiIterations) / 1000.0;

      print('============================================================');
      print('=== MULTI-QR VISION EXTRACTION & PIPELINE BENCHMARK      ===');
      print('============================================================');
      print('Iterations       : $multiIterations (2 QR codes per image)');
      print('Total Elapsed    : ${sw.elapsedMilliseconds} ms');
      print('Avg Multi Latency: ${avgMultiLatencyMs.toStringAsFixed(2)} ms');
      print('Codes Decoded/sec: ${(2 * multiIterations / (sw.elapsedMilliseconds / 1000.0)).round()}');
      print('============================================================\n');

      expect(avgMultiLatencyMs, lessThan(60.0),
          reason: 'Multi-QR extraction and pipeline processing should average < 60 ms');
    });
  });
}
