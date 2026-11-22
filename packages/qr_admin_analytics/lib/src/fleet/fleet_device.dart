/// Fleet device registration record tracking hardware, OS, app version, and activity telemetry.
class FleetDevice {
  final String deviceId;
  final String deviceName;
  final String os;
  final String appVersion;
  final DateTime registeredAt;
  final DateTime lastActiveAt;
  final bool isRevoked;
  final String? revocationReason;
  final int scansRecorded;
  final int threatsEncountered;

  const FleetDevice({
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.appVersion,
    required this.registeredAt,
    required this.lastActiveAt,
    this.isRevoked = false,
    this.revocationReason,
    this.scansRecorded = 0,
    this.threatsEncountered = 0,
  });

  /// Alias for [lastActiveAt].
  DateTime get lastSeenAt => lastActiveAt;

  /// Whether this device has been active recently (e.g. within 15 minutes) and is not revoked.
  bool isActive({DateTime? now, Duration window = const Duration(minutes: 15)}) {
    if (isRevoked) return false;
    final current = (now ?? DateTime.now()).toUtc();
    return current.difference(lastActiveAt).abs() <= window;
  }

  FleetDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? os,
    String? appVersion,
    DateTime? registeredAt,
    DateTime? lastActiveAt,
    bool? isRevoked,
    String? revocationReason,
    int? scansRecorded,
    int? threatsEncountered,
  }) {
    return FleetDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      os: os ?? this.os,
      appVersion: appVersion ?? this.appVersion,
      registeredAt: registeredAt ?? this.registeredAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isRevoked: isRevoked ?? this.isRevoked,
      revocationReason: revocationReason ?? this.revocationReason,
      scansRecorded: scansRecorded ?? this.scansRecorded,
      threatsEncountered: threatsEncountered ?? this.threatsEncountered,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'os': os,
    'appVersion': appVersion,
    'registeredAt': registeredAt.toUtc().toIso8601String(),
    'lastActiveAt': lastActiveAt.toUtc().toIso8601String(),
    'isRevoked': isRevoked,
    'revocationReason': revocationReason,
    'scansRecorded': scansRecorded,
    'threatsEncountered': threatsEncountered,
  };

  factory FleetDevice.fromJson(Map<String, dynamic> json) {
    return FleetDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      os: json['os'] as String,
      appVersion: json['appVersion'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String).toUtc(),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String).toUtc(),
      isRevoked: (json['isRevoked'] as bool?) ?? false,
      revocationReason: json['revocationReason'] as String?,
      scansRecorded: (json['scansRecorded'] as num?)?.toInt() ?? 0,
      threatsEncountered: (json['threatsEncountered'] as num?)?.toInt() ?? 0,
    );
  }
}
