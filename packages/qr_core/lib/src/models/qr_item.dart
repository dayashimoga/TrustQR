import 'qr_enums.dart';

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

  factory QrItem.fromJson(Map<String, dynamic> json) {
    return QrItem(
      id: json['id'] as String,
      rawContent: json['rawContent'] as String,
      payloadType: QrPayloadType.values.byName(json['payloadType'] as String),
      threatLevel: SecurityThreatLevel.values.byName(json['threatLevel'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      tags: List<String>.from((json['tags'] as List?) ?? []),
    );
  }

  QrItem copyWith({
    String? id,
    String? rawContent,
    QrPayloadType? payloadType,
    SecurityThreatLevel? threatLevel,
    DateTime? createdAt,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return QrItem(
      id: id ?? this.id,
      rawContent: rawContent ?? this.rawContent,
      payloadType: payloadType ?? this.payloadType,
      threatLevel: threatLevel ?? this.threatLevel,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }
}
