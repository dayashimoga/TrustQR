import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_core/qr_core.dart';

void main() {
  final testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i + 10));
  final privateKey = CryptoPrivateKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'legit_audit_key',
  );
  final publicKey = CryptoPublicKey(
    bytes: testKeyBytes,
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'legit_audit_key',
  );
  final attackerPublicKey = CryptoPublicKey(
    bytes: Uint8List.fromList(List.generate(32, (i) => i + 99)),
    algorithm: CryptoAlgorithm.hmacSha256,
    keyId: 'attacker_key',
  );

  group('Adversarial Audit Log Tampering Pen-Tests (12 Vectors)', () {
    final baseTimestamp = DateTime.utc(2026, 11, 22, 12, 0, 0);

    AuditLogEntry makeValidEntry() {
      return AuditLogEntry.create(
        id: 'audit_vector_base',
        timestamp: baseTimestamp,
        action: 'REVOKE_DEVICE',
        actorId: 'admin@secops.corp',
        actorRole: 'admin',
        targetId: 'device_rogue_01',
        details: {'reason': 'breach_contained', 'quarantineLevel': 3},
        ipAddress: '192.168.10.55',
        privateKey: privateKey,
      );
    }

    test('Vector 1: Action string tampering fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: 'UNREVOKE_DEVICE', // Tampered
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 2: Actor ID tampering fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: 'attacker@evil.corp', // Tampered
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 3: Actor role privilege forgery fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: 'super_root', // Forged role
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 4: Target resource spoofing fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: 'device_critical_db_server', // Spoofed target
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 5: Details dictionary injection and mutation fails verification', () {
      final valid = makeValidEntry();
      // Mutated parameter in details
      final tamperedDetails = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: {'reason': 'breach_contained', 'quarantineLevel': 0}, // Tampered 3 -> 0
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tamperedDetails.verifyIntegrity(publicKey), isFalse);

      // Injected extra key
      final injectedDetails = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: {'reason': 'breach_contained', 'quarantineLevel': 3, 'backdoor': true},
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(injectedDetails.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 6: IP address spoofing fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: '10.0.0.99', // Spoofed IP
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 7: Timestamp forgery (1 ms alteration) fails verification', () {
      final valid = makeValidEntry();
      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp.add(const Duration(milliseconds: 1)), // 1 ms shifted
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: valid.integrityHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 8: HMAC single bit-flip attack fails verification', () {
      final valid = makeValidEntry();
      // Flip the last character in the 64-hex HMAC signature
      final lastChar = valid.integrityHash[valid.integrityHash.length - 1];
      final flippedChar = (lastChar == 'a') ? 'b' : 'a';
      final bitFlippedHash =
          valid.integrityHash.substring(0, valid.integrityHash.length - 1) + flippedChar;

      final tampered = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: bitFlippedHash,
      );
      expect(tampered.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 9: Truncated or malformed hex signature fails gracefully', () {
      final valid = makeValidEntry();
      final truncated = AuditLogEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        action: valid.action,
        actorId: valid.actorId,
        actorRole: valid.actorRole,
        targetId: valid.targetId,
        details: valid.details,
        ipAddress: valid.ipAddress,
        integrityHash: 'deadbeef', // Only 8 chars instead of 64
      );
      expect(truncated.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 10: Signature replay attack from different entry fails', () {
      final entryA = makeValidEntry();
      final entryB = AuditLogEntry.create(
        id: 'audit_vector_b',
        timestamp: baseTimestamp.add(const Duration(seconds: 10)),
        action: 'UPDATE_POLICY',
        actorId: 'admin@secops.corp',
        actorRole: 'admin',
        targetId: 'firewall',
        privateKey: privateKey,
      );

      // Replay signature of entryA into entryB
      final replayed = AuditLogEntry(
        id: entryB.id,
        timestamp: entryB.timestamp,
        action: entryB.action,
        actorId: entryB.actorId,
        actorRole: entryB.actorRole,
        targetId: entryB.targetId,
        details: entryB.details,
        ipAddress: entryB.ipAddress,
        integrityHash: entryA.integrityHash, // Replayed!
      );
      expect(replayed.verifyIntegrity(publicKey), isFalse);
    });

    test('Vector 11: Timestamp rollback insertion breaches chronological integrity', () {
      final engine = AuditLogEngine(privateKey: privateKey, publicKey: publicKey);

      // Entry 1: 12:00:00
      engine.logAction(
        action: 'FIRST_ACTION',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't1',
        timestamp: baseTimestamp,
      );

      // Entry 2: 12:00:10
      engine.logAction(
        action: 'SECOND_ACTION',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't2',
        timestamp: baseTimestamp.add(const Duration(seconds: 10)),
      );

      // Injected Entry 3: 11:59:59 (Anti-chronological rollback!)
      final forgedPastEntry = AuditLogEntry.create(
        id: 'forged_rollback',
        timestamp: baseTimestamp.subtract(const Duration(seconds: 1)),
        action: 'RETROACTIVE_FORGERY',
        actorId: 'admin',
        actorRole: 'admin',
        targetId: 't3',
        privateKey: privateKey,
      );

      engine.loadEntries([...engine.entries, forgedPastEntry]);

      final audit = engine.verifyAll();
      expect(audit.isValid, isFalse);
      expect(audit.isChronological, isFalse);
    });

    test('Vector 12: Public key substitution fails verification', () {
      final valid = makeValidEntry();
      // Verifying genuine entry with attacker's public key must reject
      expect(valid.verifyIntegrity(attackerPublicKey), isFalse);
    });
  });
}
