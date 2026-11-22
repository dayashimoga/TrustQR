/// Core domain models and constants for the Universal QR Platform.
library qr_core;

/// Supported structured QR payload formats.
enum QrPayloadType {
  url,
  wifi,
  vcard,
  mecard,
  geo,
  event,
  email,
  sms,
  tel,
  otpauth,
  upi,
  epc,
  crypto,
  gs1,
  plainText,
}

/// Security risk classification levels determined by Threat Firewall.
enum SecurityThreatLevel {
  safe,
  caution,
  suspicious,
  critical,
}

/// Role classification for RBAC and cryptographic entitlements.
enum UserRole {
  user,
  admin,
}

/// Base entity for a scanned or generated QR code item.
class QrItem {
  final String id;
  final String rawContent;
  final QrPayloadType payloadType;
  final SecurityThreatLevel threatLevel;
  final DateTime createdAt;
  final bool isFavorite;
  final List<String> tags;

  const QrItem({
    required this.id,
    required this.rawContent,
    required this.payloadType,
    required this.threatLevel,
    required this.createdAt,
    this.isFavorite = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'rawContent': rawContent,
    'payloadType': payloadType.name,
    'threatLevel': threatLevel.name,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'tags': tags,
  };
}
