/// A named categorization folder for grouping QR items within the vault.
class QrCollection {
  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final DateTime createdAt;
  final int itemCount;

  const QrCollection({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    required this.createdAt,
    this.itemCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'colorHex': colorHex,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'itemCount': itemCount,
  };

  factory QrCollection.fromJson(Map<String, dynamic> json) {
    return QrCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      colorHex: json['colorHex'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    );
  }

  QrCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    DateTime? createdAt,
    int? itemCount,
  }) {
    return QrCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}
