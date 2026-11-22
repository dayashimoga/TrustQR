/// Outer frame shape of QR finder patterns (the 7x7 outer border).
enum QrEyeFrameShape {
  square,
  rounded,
  circle,
  squircle,
  hexagonal,
}

/// Inner pupil shape of QR finder patterns (the 3x3 center eye).
enum QrEyePupilShape {
  square,
  rounded,
  circle,
  diamond,
}

/// Complete styling specification for QR code finder patterns.
class QrEyeStyle {
  final QrEyeFrameShape frameShape;
  final QrEyePupilShape pupilShape;
  final int? frameColorHex;
  final int? pupilColorHex;

  const QrEyeStyle({
    this.frameShape = QrEyeFrameShape.square,
    this.pupilShape = QrEyePupilShape.square,
    this.frameColorHex,
    this.pupilColorHex,
  });

  Map<String, dynamic> toJson() => {
    'frameShape': frameShape.name,
    'pupilShape': pupilShape.name,
    'frameColorHex': frameColorHex != null ? '0x${frameColorHex!.toRadixString(16).padLeft(8, '0')}' : null,
    'pupilColorHex': pupilColorHex != null ? '0x${pupilColorHex!.toRadixString(16).padLeft(8, '0')}' : null,
  };

  factory QrEyeStyle.fromJson(Map<String, dynamic> json) {
    return QrEyeStyle(
      frameShape: QrEyeFrameShape.values.byName(json['frameShape'] as String? ?? 'square'),
      pupilShape: QrEyePupilShape.values.byName(json['pupilShape'] as String? ?? 'square'),
      frameColorHex: json['frameColorHex'] != null ? int.parse(json['frameColorHex'] as String) : null,
      pupilColorHex: json['pupilColorHex'] != null ? int.parse(json['pupilColorHex'] as String) : null,
    );
  }
}
