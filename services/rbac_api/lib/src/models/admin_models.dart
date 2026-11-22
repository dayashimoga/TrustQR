/// Admin QR generation request payload.
class QrGenerateRequest {
  final String content;
  final String eccLevel;
  final String shape;
  final String foregroundColor;
  final String backgroundColor;

  const QrGenerateRequest({
    required this.content,
    this.eccLevel = 'M',
    this.shape = 'square',
    this.foregroundColor = '#000000',
    this.backgroundColor = '#FFFFFF',
  });

  static QrGenerateRequest fromJson(Map<String, dynamic> json) {
    return QrGenerateRequest(
      content: json['content'] as String? ?? '',
      eccLevel: json['eccLevel'] as String? ?? 'M',
      shape: json['shape'] as String? ?? 'square',
      foregroundColor: json['foregroundColor'] as String? ?? '#000000',
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'eccLevel': eccLevel,
    'shape': shape,
    'foregroundColor': foregroundColor,
    'backgroundColor': backgroundColor,
  };
}

/// Admin QR generation response payload.
class QrGenerateResponse {
  final String status;
  final String content;
  final String eccLevel;
  final int version;
  final int matrixDimension;

  const QrGenerateResponse({
    required this.status,
    required this.content,
    required this.eccLevel,
    required this.version,
    required this.matrixDimension,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    'content': content,
    'eccLevel': eccLevel,
    'version': version,
    'matrixDimension': matrixDimension,
  };
}

/// Single item within a batch generation request.
class QrBatchItem {
  final String id;
  final String content;
  final String eccLevel;

  const QrBatchItem({
    required this.id,
    required this.content,
    this.eccLevel = 'M',
  });

  static QrBatchItem fromJson(Map<String, dynamic> json) {
    return QrBatchItem(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      eccLevel: json['eccLevel'] as String? ?? 'M',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'eccLevel': eccLevel,
  };
}

/// Batch QR generation request payload.
class QrBatchRequest {
  final List<QrBatchItem> items;

  const QrBatchRequest({required this.items});

  static QrBatchRequest fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return QrBatchRequest(
      items: rawItems
          .map((item) => QrBatchItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// Batch QR generation response payload.
class QrBatchResponse {
  final String batchId;
  final int count;
  final List<Map<String, dynamic>> items;

  const QrBatchResponse({
    required this.batchId,
    required this.count,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'count': count,
    'items': items,
  };
}

/// Request to cryptographically sign a QR payload with institutional TrustQR key.
class QrSignRequest {
  final String payload;
  final int? expiresInSeconds;

  const QrSignRequest({
    required this.payload,
    this.expiresInSeconds,
  });

  static QrSignRequest fromJson(Map<String, dynamic> json) {
    return QrSignRequest(
      payload: json['payload'] as String? ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'payload': payload,
    if (expiresInSeconds != null) 'expiresInSeconds': expiresInSeconds,
  };
}

/// Response containing signed TrustQR envelope and URI.
class QrSignResponse {
  final String trustQrUri;
  final String issuer;
  final String keyId;
  final String signature;
  final String payload;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const QrSignResponse({
    required this.trustQrUri,
    required this.issuer,
    required this.keyId,
    required this.signature,
    required this.payload,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'trustQrUri': trustQrUri,
    'issuer': issuer,
    'keyId': keyId,
    'signature': signature,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };
}

/// Branded QR template definition.
class QrTemplate {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> styleConfig;
  final DateTime createdAt;

  const QrTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.styleConfig,
    required this.createdAt,
  });

  static QrTemplate fromJson(Map<String, dynamic> json) {
    return QrTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      styleConfig: Map<String, dynamic>.from(json['styleConfig'] as Map? ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'styleConfig': styleConfig,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Fleet-wide admin analytics summary.
class AdminAnalytics {
  final int totalScans;
  final int totalGenerations;
  final int threatsBlocked;
  final int activeSessions;
  final int trustQrSignaturesIssued;
  final int uptimeSeconds;

  const AdminAnalytics({
    required this.totalScans,
    required this.totalGenerations,
    required this.threatsBlocked,
    required this.activeSessions,
    required this.trustQrSignaturesIssued,
    required this.uptimeSeconds,
  });

  Map<String, dynamic> toJson() => {
    'totalScans': totalScans,
    'totalGenerations': totalGenerations,
    'threatsBlocked': threatsBlocked,
    'activeSessions': activeSessions,
    'trustQrSignaturesIssued': trustQrSignaturesIssued,
    'uptimeSeconds': uptimeSeconds,
  };
}

/// Append-only administrative audit log record.
class AdminAuditEvent {
  final String id;
  final String action;
  final String actor;
  final DateTime timestamp;
  final String status;
  final String? ip;
  final Map<String, dynamic>? details;

  const AdminAuditEvent({
    required this.id,
    required this.action,
    required this.actor,
    required this.timestamp,
    required this.status,
    this.ip,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'actor': actor,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    if (ip != null) 'ip': ip,
    if (details != null) 'details': details,
  };
}
