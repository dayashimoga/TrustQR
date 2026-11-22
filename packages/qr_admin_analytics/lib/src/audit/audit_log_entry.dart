import 'dart:convert';
import 'dart:typed_data';
import 'package:qr_core/qr_core.dart';

/// An immutable, cryptographically verifiable audit log entry for administrative actions.
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String action;
  final String actorId;
  final String actorRole;
  final String targetId;
  final Map<String, dynamic> details;
  final String ipAddress;
  final String integrityHash;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.actorId,
    required this.actorRole,
    required this.targetId,
    required this.details,
    required this.ipAddress,
    required this.integrityHash,
  });

  /// Deterministically serializes fields into canonical UTF-8 bytes for cryptographic signing.
  static Uint8List canonicalBytes({
    required String id,
    required DateTime timestamp,
    required String action,
    required String actorId,
    required String actorRole,
    required String targetId,
    required Map<String, dynamic> details,
    required String ipAddress,
  }) {
    // Sort details keys for deterministic serialization.
    final sortedDetails = <String, dynamic>{};
    final sortedKeys = details.keys.toList()..sort();
    for (final key in sortedKeys) {
      sortedDetails[key] = details[key];
    }

    final canonicalString = [
      id,
      timestamp.toUtc().toIso8601String(),
      action,
      actorId,
      actorRole,
      targetId,
      jsonEncode(sortedDetails),
      ipAddress,
    ].join('|');

    return Uint8List.fromList(utf8.encode(canonicalString));
  }

  /// Signs entry data using HMAC-SHA256 and returns a lowercase hex digest.
  static String computeIntegrityHash({
    required String id,
    required DateTime timestamp,
    required String action,
    required String actorId,
    required String actorRole,
    required String targetId,
    required Map<String, dynamic> details,
    required String ipAddress,
    required CryptoPrivateKey privateKey,
  }) {
    final payloadBytes = canonicalBytes(
      id: id,
      timestamp: timestamp,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      targetId: targetId,
      details: details,
      ipAddress: ipAddress,
    );
    final sigBytes = HmacEngine.sign(message: payloadBytes, privateKey: privateKey);
    return sigBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Factory constructing and automatically signing a new audit log entry.
  factory AuditLogEntry.create({
    required String id,
    DateTime? timestamp,
    required String action,
    required String actorId,
    required String actorRole,
    required String targetId,
    Map<String, dynamic> details = const {},
    String ipAddress = '127.0.0.1',
    required CryptoPrivateKey privateKey,
  }) {
    final ts = (timestamp ?? DateTime.now()).toUtc();
    final hash = computeIntegrityHash(
      id: id,
      timestamp: ts,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      targetId: targetId,
      details: details,
      ipAddress: ipAddress,
      privateKey: privateKey,
    );

    return AuditLogEntry(
      id: id,
      timestamp: ts,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      targetId: targetId,
      details: Map.unmodifiable(details),
      ipAddress: ipAddress,
      integrityHash: hash,
    );
  }

  /// Verifies the cryptographic HMAC integrity of this log entry.
  bool verifyIntegrity(CryptoPublicKey publicKey) {
    try {
      final payloadBytes = canonicalBytes(
        id: id,
        timestamp: timestamp,
        action: action,
        actorId: actorId,
        actorRole: actorRole,
        targetId: targetId,
        details: details,
        ipAddress: ipAddress,
      );

      final sigBytes = Uint8List(integrityHash.length ~/ 2);
      for (var i = 0; i < sigBytes.length; i++) {
        final hex = integrityHash.substring(i * 2, i * 2 + 2);
        sigBytes[i] = int.parse(hex, radix: 16);
      }

      return HmacEngine.verify(
        message: payloadBytes,
        signature: sigBytes,
        publicKey: publicKey,
      );
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'action': action,
        'actorId': actorId,
        'actorRole': actorRole,
        'targetId': targetId,
        'details': details,
        'ipAddress': ipAddress,
        'integrityHash': integrityHash,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        action: json['action'] as String,
        actorId: json['actorId'] as String,
        actorRole: json['actorRole'] as String,
        targetId: json['targetId'] as String,
        details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
        ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
        integrityHash: json['integrityHash'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          action == other.action &&
          actorId == other.actorId &&
          actorRole == other.actorRole &&
          targetId == other.targetId &&
          integrityHash == other.integrityHash;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        action,
        actorId,
        actorRole,
        targetId,
        integrityHash,
      );

  @override
  String toString() =>
      'AuditLogEntry(id: $id, action: $action, actor: $actorId [$actorRole], target: $targetId, hash: ${integrityHash.substring(0, 8)}...)';
}
