import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'adversarial_corpus.dart';

void main() {
  group('Threat Firewall Adversarial Benchmark & Verification Suite', () {
    late final QrThreatFirewall firewall;
    late final List<AdversarialVector> vectors;

    setUpAll(() {
      firewall = QrThreatFirewall(
        trustedInstitutionalKeys: {
          TrustQrVectorFactory.institutionalKeyPair.publicKey.keyId:
              TrustQrVectorFactory.institutionalKeyPair.publicKey,
        },
      );
      vectors = AdversarialCorpus.getVectors();
    });

    test('Corpus Integrity: contains at least 120 uniquely identified test vectors', () {
      expect(vectors.length, greaterThanOrEqualTo(120));
      expect(vectors.length, equals(150));

      final idSet = <String>{};
      for (final v in vectors) {
        expect(idSet.contains(v.id), isFalse, reason: 'Duplicate vector ID found: ${v.id}');
        idSet.add(v.id);
        expect(v.description.isNotEmpty, isTrue);
        expect(v.payload.isNotEmpty, isTrue);
        expect(v.minScore, lessThanOrEqualTo(v.maxScore));
      }
    });

    group('Category 1: Dangerous Executable Schemes (17 vectors)', () {
      test('Blocks all executable, script, and local file schemes with score 0', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.dangerousScheme).toList();
        expect(categoryVectors.length, equals(17));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 2: Credential-in-URL Phishing Masquerades (10 vectors)', () {
      test('Flags embedded credentials in URL as critical threat blocking action', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.credentialInUrl).toList();
        expect(categoryVectors.length, equals(10));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 3: IDN Homograph & Punycode Spoofs (20 vectors)', () {
      test('Detects Cyrillic, Greek, and Punycode confusable domains with zero false negatives', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.idnHomographPunycode).toList();
        expect(categoryVectors.length, equals(20));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 4: Raw IP, Obfuscated IPs & SSRF Targets (16 vectors)', () {
      test('Correctly classifies private/SSRF targets as critical and raw IPs as suspicious', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.rawIpObfuscationSsrf).toList();
        expect(categoryVectors.length, equals(16));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 5: URL Shorteners & Redirection Masking (12 vectors)', () {
      test('Flags link shorteners with caution or suspicious ratings', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.urlShortener).toList();
        expect(categoryVectors.length, equals(12));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 6: Insecure Plaintext HTTP on Sensitive Paths (10 vectors)', () {
      test('Identifies insecure sensitive transport across auth, payment, and admin paths', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.insecureSensitiveTransport).toList();
        expect(categoryVectors.length, equals(10));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 7: Excessive Subdomains & DGA Phishing Domains (10 vectors)', () {
      test('Detects nested subdomain chains and high-entropy algorithmic domains', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.dgaExcessiveSubdomains).toList();
        expect(categoryVectors.length, equals(10));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 8: Open-Redirect & Reflected Query Injections (12 vectors)', () {
      test('Flags open-redirect destinations and blocks reflected script injections', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.openRedirectQueryInjection).toList();
        expect(categoryVectors.length, equals(12));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 9: Wi-Fi Vulnerabilities & Configurations (8 vectors)', () {
      test('Evaluates open vs WEP vs secure WPA networks and empty SSIDs', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.wifiVulnerabilities).toList();
        expect(categoryVectors.length, equals(8));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          if (v.expectedFindingCode.isNotEmpty) {
            expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
                reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
          } else {
            expect(res.findings, isEmpty);
          }
        }
      });
    });

    group('Category 10: vCard, MeCard, SMS & Tel Sanitization (10 vectors)', () {
      test('Inspects contact URLs, CRLF injection in SMS/Tel, and embedded scripts in text', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.vcardMecardInsecure).toList();
        expect(categoryVectors.length, equals(10));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          if (v.expectedFindingCode.isNotEmpty) {
            expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
                reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
          } else {
            expect(res.findings, isEmpty);
          }
        }
      });
    });

    group('Category 11: TrustQR Cryptographic Authenticity & Tampering (10 vectors)', () {
      test('Verifies authentic signatures and detects all tampering and malformed envelopes', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.trustQrCryptographic).toList();
        expect(categoryVectors.length, equals(10));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(v.expectedThreatLevel), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, equals(v.expectedActionAllowed), reason: 'Action allowed failed for ${v.id}');
          expect(res.safetyScore, inInclusiveRange(v.minScore, v.maxScore), reason: 'Score range failed for ${v.id}');
          expect(res.findings.any((f) => f.code == v.expectedFindingCode), isTrue,
              reason: 'Finding code ${v.expectedFindingCode} missing in ${v.id}');
        }
      });
    });

    group('Category 12: Benign Multi-Format QR Payloads (15 vectors)', () {
      test('Validates benign payloads across all 15 formats produce score 100 with zero false positives', () {
        final categoryVectors = vectors.where((v) => v.category == AdversarialCategory.benignMultiFormat).toList();
        expect(categoryVectors.length, equals(15));

        for (final v in categoryVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.threatLevel, equals(SecurityThreatLevel.safe), reason: 'Failed for ${v.id}: ${v.description}');
          expect(res.isActionAllowed, isTrue, reason: 'Action should be allowed for ${v.id}');
          expect(res.safetyScore, equals(100), reason: 'Score should be 100 for ${v.id}');
          expect(res.findings, isEmpty, reason: 'False positive findings detected for ${v.id}: ${res.findings.map((f) => f.code)}');
        }
      });
    });

    test('Zero False Negatives Invariant on all Critical Vectors', () {
      final criticalVectors = vectors.where((v) => v.expectedThreatLevel == SecurityThreatLevel.critical).toList();
      expect(criticalVectors.length, greaterThanOrEqualTo(50));

      for (final v in criticalVectors) {
        final res = firewall.inspectRaw(v.payload);
        expect(res.isCritical, isTrue, reason: 'CRITICAL FALSE NEGATIVE on ${v.id}: ${v.description}');
        expect(res.isActionAllowed, isFalse, reason: 'CRITICAL ACTION ALLOWED on ${v.id}: ${v.description}');
        expect(res.safetyScore, lessThan(40), reason: 'Safety score dangerously high for ${v.id}');
      }
    });

    test('High-Throughput & Low-Latency Performance Benchmark (15,000 payload inspections)', () {
      final standardVectors = vectors.where((v) => v.category != AdversarialCategory.trustQrCryptographic).toList();
      final cryptoVectors = vectors.where((v) => v.category == AdversarialCategory.trustQrCryptographic).toList();

      // 1. Warm-up
      for (var w = 0; w < 3; w++) {
        for (final v in vectors) {
          firewall.inspectRaw(v.payload);
        }
      }

      // 2. Standard heuristic firewall benchmark (100 iterations of 140 non-crypto vectors = 14,000 inspections)
      const standardIterations = 100;
      final totalStandardInspections = standardIterations * standardVectors.length;
      final standardWatch = Stopwatch()..start();

      for (var i = 0; i < standardIterations; i++) {
        for (final v in standardVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.safetyScore, greaterThanOrEqualTo(0));
        }
      }
      standardWatch.stop();

      final standardMs = standardWatch.elapsedMilliseconds;
      final standardMicros = standardWatch.elapsedMicroseconds;
      final avgStandardMs = (standardMicros / totalStandardInspections) / 1000.0;
      final standardThroughput = (totalStandardInspections / (standardMicros / 1000000.0)).round();

      // 3. Cryptographic Ed25519 TrustQR signature verification benchmark (10 iterations of 10 crypto vectors = 100 verifications)
      const cryptoIterations = 10;
      final totalCryptoInspections = cryptoIterations * cryptoVectors.length;
      final cryptoWatch = Stopwatch()..start();

      for (var i = 0; i < cryptoIterations; i++) {
        for (final v in cryptoVectors) {
          final res = firewall.inspectRaw(v.payload);
          expect(res.safetyScore, greaterThanOrEqualTo(0));
        }
      }
      cryptoWatch.stop();

      final cryptoMs = cryptoWatch.elapsedMilliseconds;
      final cryptoMicros = cryptoWatch.elapsedMicroseconds;
      final avgCryptoMs = (cryptoMicros / totalCryptoInspections) / 1000.0;

      // Output benchmark metrics
      // ignore: avoid_print
      print('\n============================================================');
      // ignore: avoid_print
      print('=== THREAT FIREWALL PERFORMANCE & THROUGHPUT BENCHMARK  ===');
      // ignore: avoid_print
      print('============================================================');
      // ignore: avoid_print
      print('Standard Heuristic Inspections: $totalStandardInspections in ${standardMs}ms');
      // ignore: avoid_print
      print('Avg Standard Inspection Latency: ${avgStandardMs.toStringAsFixed(4)} ms (${(avgStandardMs * 1000).toStringAsFixed(1)} µs)');
      // ignore: avoid_print
      print('Standard Throughput           : $standardThroughput payloads/sec');
      // ignore: avoid_print
      print('Standard Target               : < 0.50 ms / inspection (PASS: ${avgStandardMs < 0.5})');
      // ignore: avoid_print
      print('------------------------------------------------------------');
      // ignore: avoid_print
      print('Cryptographic TrustQR Verifs  : $totalCryptoInspections in ${cryptoMs}ms');
      // ignore: avoid_print
      print('Avg Ed25519 Verify Latency    : ${avgCryptoMs.toStringAsFixed(4)} ms');
      // ignore: avoid_print
      print('Crypto Target                 : < 25.0 ms / verification (PASS: ${avgCryptoMs < 25.0})');
      // ignore: avoid_print
      print('============================================================\n');

      expect(avgStandardMs, lessThan(0.50), reason: 'Standard heuristic inspection exceeds 0.50 ms');
      expect(avgCryptoMs, lessThan(25.0), reason: 'Ed25519 cryptographic verification exceeds 25.0 ms');
    });
  });
}
