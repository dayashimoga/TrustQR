import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  final testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i + 1));
  final privateKey = CryptoPrivateKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'test_key_01',
  );
  final publicKey = CryptoPublicKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'test_key_01',
  );
  final wrongPublicKey = CryptoPublicKey(
    bytes: Uint8List.fromList(List.generate(32, (i) => i + 2)),
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'wrong_key',
  );

  group('AuditLogEntry Tests', () {
    test('Creates, cryptographically signs, and verifies entry integrity', () {
      final now = DateTime.utc(2026, 11, 22, 10, 0);
      final entry = AuditLogEntry.create(
        id: 'log_01',
        timestamp: now,
        action: 'TOKEN_REVOKED',
        actorId: 'admin@corp.io',
        actorRole: 'admin',
        targetId: 'tok_99',
        details: {'reason': 'security_breach', 'code': 403},
        ipAddress: '10.0.0.1',
        privateKey: privateKey,
      );

      // Verification succeeds with correct public key
      expect(entry.verifyIntegrity(publicKey), isTrue);

      // Verification fails with wrong public key
      expect(entry.verifyIntegrity(wrongPublicKey), isFalse);

      // JSON serialization round-trip
      final json = entry.toJson();
      final restored = AuditLogEntry.fromJson(json);
      expect(restored.id, equals(entry.id));
      expect(restored.action, equals(entry.action));
      expect(restored.actorId, equals(entry.actorId));
      expect(restored.integrityHash, equals(entry.integrityHash));
      expect(restored.verifyIntegrity(publicKey), isTrue);

      // Equals and hashcode
      expect(restored == entry, isTrue);
      expect(restored.hashCode, equals(entry.hashCode));
      expect(entry.toString(), contains('TOKEN_REVOKED'));
    });

    test('Fails verification when data is tampered with', () {
      final now = DateTime.utc(2026, 11, 22, 10, 0);
      final entry = AuditLogEntry.create(
        id: 'log_02',
        timestamp: now,
        action: 'DEVICE_REGISTERED',
        actorId: 'admin@corp.io',
        actorRole: 'admin',
        targetId: 'dev_01',
        privateKey: privateKey,
      );

      // Tampered action
      final tamperedAction = AuditLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        action: 'UNAUTHORIZED_ACCESS',
        actorId: entry.actorId,
        actorRole: entry.actorRole,
        targetId: entry.targetId,
        details: entry.details,
        ipAddress: entry.ipAddress,
        integrityHash: entry.integrityHash,
      );
      expect(tamperedAction.verifyIntegrity(publicKey), isFalse);

      // Tampered details
      final tamperedDetails = AuditLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        action: entry.action,
        actorId: entry.actorId,
        actorRole: entry.actorRole,
        targetId: entry.targetId,
        details: {'tampered': true},
        ipAddress: entry.ipAddress,
        integrityHash: entry.integrityHash,
      );
      expect(tamperedDetails.verifyIntegrity(publicKey), isFalse);

      // Malformed hex hash
      final malformedHash = AuditLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        action: entry.action,
        actorId: entry.actorId,
        actorRole: entry.actorRole,
        targetId: entry.targetId,
        details: entry.details,
        ipAddress: entry.ipAddress,
        integrityHash: 'invalid_hex',
      );
      expect(malformedHash.verifyIntegrity(publicKey), isFalse);
    });
  });

  group('AuditLogFilter Tests', () {
    final now = DateTime.utc(2026, 11, 22, 10, 0);
    final entry = AuditLogEntry.create(
      id: 'log_filter_01',
      timestamp: now,
      action: 'EXPORT_REPORT',
      actorId: 'admin_1',
      actorRole: 'admin',
      targetId: 'rep_001',
      details: {'format': 'csv'},
      ipAddress: '192.168.1.50',
      privateKey: privateKey,
    );

    test('Matches specific criteria correctly', () {
      final f1 = AuditLogFilter(action: 'EXPORT_REPORT');
      expect(f1.matches(entry), isTrue);

      final f2 = AuditLogFilter(action: 'DELETE');
      expect(f2.matches(entry), isFalse);

      final fRole = AuditLogFilter(actorRole: 'admin');
      expect(fRole.matches(entry), isTrue);

      final fActor = AuditLogFilter(actorId: 'admin_1');
      expect(fActor.matches(entry), isTrue);

      final fTarget = AuditLogFilter(targetId: 'rep_001');
      expect(fTarget.matches(entry), isTrue);

      final fDateIn = AuditLogFilter(
        fromDate: now.subtract(const Duration(minutes: 5)),
        toDate: now.add(const Duration(minutes: 5)),
      );
      expect(fDateIn.matches(entry), isTrue);

      final fDateOut = AuditLogFilter(
        fromDate: now.add(const Duration(minutes: 5)),
      );
      expect(fDateOut.matches(entry), isFalse);

      final fDatePast = AuditLogFilter(
        toDate: now.subtract(const Duration(minutes: 5)),
      );
      expect(fDatePast.matches(entry), isFalse);

      final fSearch = AuditLogFilter(searchQuery: 'rep_001');
      expect(fSearch.matches(entry), isTrue);

      final fSearchFail = AuditLogFilter(searchQuery: 'non_existent');
      expect(fSearchFail.matches(entry), isFalse);
    });

    test('copyWith and JSON serialization work correctly', () {
      final filter = AuditLogFilter(
        action: 'TEST',
        actorId: 'id1',
        targetId: 't1',
        fromDate: now,
        toDate: now,
        searchQuery: 'query',
      );
      final updated = filter.copyWith(
        actorRole: 'admin',
        clearAction: true,
        clearTargetId: false,
        clearFromDate: false,
        clearToDate: false,
        clearSearchQuery: false,
      );
      expect(updated.action, isNull);
      expect(updated.actorRole, equals('admin'));
      expect(updated.actorId, equals('id1'));
      expect(updated.targetId, equals('t1'));
      expect(updated.fromDate, equals(now));
      expect(updated.toDate, equals(now));

      final json = updated.toJson();
      final restored = AuditLogFilter.fromJson(json);
      expect(restored.actorRole, equals('admin'));
      expect(restored.actorId, equals('id1'));
      expect(restored.targetId, equals('t1'));
      expect(restored.fromDate, equals(now));
      expect(restored.toDate, equals(now));
      expect(restored.searchQuery, equals('query'));
    });
  });

  group('AuditLogEngine Tests', () {
    test('Logs actions, queries with pagination, and verifies cryptographic integrity', () {
      final engine = AuditLogEngine(privateKey: privateKey, publicKey: publicKey);
      final t1 = DateTime.utc(2026, 11, 22, 10, 0);
      final t2 = DateTime.utc(2026, 11, 22, 10, 5);
      final t3 = DateTime.utc(2026, 11, 22, 10, 10);

      engine.logAction(
        action: 'TOKEN_ISSUED',
        actorId: 'admin_master',
        actorRole: 'admin',
        targetId: 'tok_01',
        timestamp: t1,
      );

      engine.logAction(
        action: 'CONFIG_CHANGED',
        actorId: 'admin_master',
        actorRole: 'admin',
        targetId: 'firewall',
        timestamp: t2,
      );

      engine.logAction(
        action: 'DEVICE_REVOKED',
        actorId: 'admin_master',
        actorRole: 'admin',
        targetId: 'dev_compromised',
        timestamp: t3,
      );

      expect(engine.count, equals(3));
      expect(engine.entries.length, equals(3));

      // Query with pagination
      final page1 = engine.query(limit: 2, offset: 0);
      expect(page1.length, equals(2));
      expect(page1.first.action, equals('TOKEN_ISSUED'));

      final page2 = engine.query(limit: 2, offset: 2);
      expect(page2.length, equals(1));
      expect(page2.first.action, equals('DEVICE_REVOKED'));

      final outOfBounds = engine.query(limit: 2, offset: 10);
      expect(outOfBounds, isEmpty);

      // Verify audit integrity (all valid and chronological)
      final auditResult = engine.verifyAll();
      expect(auditResult.isValid, isTrue);
      expect(auditResult.totalChecked, equals(3));
      expect(auditResult.tamperedEntries, isEmpty);
      expect(auditResult.isChronological, isTrue);

      final auditJson = auditResult.toJson();
      expect(auditJson['isValid'], isTrue);
      expect(auditJson['totalChecked'], equals(3));
    });

    test('Detects tampered entries and chronological violations', () {
      final engine = AuditLogEngine(privateKey: privateKey, publicKey: publicKey);

      final e1 = AuditLogEntry.create(
        id: 'log_a',
        timestamp: DateTime.utc(2026, 11, 22, 10, 10),
        action: 'A',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't1',
        privateKey: privateKey,
      );

      // Chronological violation: e2 is earlier than e1
      final e2 = AuditLogEntry.create(
        id: 'log_b',
        timestamp: DateTime.utc(2026, 11, 22, 10, 5),
        action: 'B',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't2',
        privateKey: privateKey,
      );

      // Tampered hash
      final e3 = AuditLogEntry(
        id: 'log_c',
        timestamp: DateTime.utc(2026, 11, 22, 10, 15),
        action: 'C',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't3',
        details: const {},
        ipAddress: '127.0.0.1',
        integrityHash: 'deadbeef1234',
      );

      engine.loadEntries([e1, e2, e3]);

      final auditResult = engine.verifyAll();
      expect(auditResult.isValid, isFalse);
      expect(auditResult.isChronological, isFalse);
      expect(auditResult.tamperedEntries.length, equals(1));
      expect(auditResult.tamperedEntries.first.id, equals('log_c'));

      engine.clear();
      expect(engine.count, equals(0));
    });
  });
}
