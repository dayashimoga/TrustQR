import '../../qr_generator_engine.dart';

/// Pre-configured branded artistic styling template for QR generation.
class QrTemplate {
  final String id;
  final String name;
  final String description;
  final QrModuleShape moduleShape;
  final QrEyeStyle eyeStyle;
  final QrColorConfig colorConfig;
  final QrLogoConfig? logoConfig;

  const QrTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.moduleShape,
    required this.eyeStyle,
    required this.colorConfig,
    this.logoConfig,
  });

  /// Cyberpunk Neon: futuristic cyberGrid modules with glowing cyan/magenta gradient.
  static final QrTemplate cyberpunkNeon = QrTemplate(
    id: 'cyberpunk-neon',
    name: 'Cyberpunk Neon',
    description: 'High-tech dark aesthetics with glowing cyan and neon magenta accents.',
    moduleShape: QrModuleShape.cyberGrid,
    eyeStyle: const QrEyeStyle(
      frameShape: QrEyeFrameShape.circle,
      pupilShape: QrEyePupilShape.diamond,
      frameColorHex: 0xFF00F0FF,
      pupilColorHex: 0xFFFF007F,
    ),
    colorConfig: QrColorConfig.linear(
      const [
        QrColorStop(offset: 0.0, colorHex: 0xFF00F0FF),
        QrColorStop(offset: 1.0, colorHex: 0xFFFF007F),
      ],
      angleDegrees: 45.0,
      backgroundHex: 0xFF0A0E17,
    ),
  );

  /// Corporate Navy: professional rounded modules with deep navy blue tone.
  static final QrTemplate corporateNavy = QrTemplate(
    id: 'corporate-navy',
    name: 'Corporate Navy',
    description: 'Crisp executive styling for business cards, enterprise IDs, and documents.',
    moduleShape: QrModuleShape.rounded,
    eyeStyle: const QrEyeStyle(
      frameShape: QrEyeFrameShape.rounded,
      pupilShape: QrEyePupilShape.square,
      frameColorHex: 0xFF0A2540,
      pupilColorHex: 0xFF0066CC,
    ),
    colorConfig: QrColorConfig.solid(
      0xFF0A2540,
      backgroundHex: 0xFFFFFFFF,
    ),
  );

  /// Emerald Trust: verified cryptographic TrustQR styling with organic emerald and teal tones.
  static final QrTemplate emeraldTrust = QrTemplate(
    id: 'emerald-trust',
    name: 'Emerald Trust',
    description: 'Modern cryptographic look with lush emerald and teal gradient.',
    moduleShape: QrModuleShape.rounded,
    eyeStyle: const QrEyeStyle(
      frameShape: QrEyeFrameShape.rounded,
      pupilShape: QrEyePupilShape.rounded,
      frameColorHex: 0xFF065F46,
      pupilColorHex: 0xFF064E3B,
    ),
    colorConfig: QrColorConfig.linear(
      const [
        QrColorStop(offset: 0.0, colorHex: 0xFF065F46),
        QrColorStop(offset: 1.0, colorHex: 0xFF0F766E),
      ],
      angleDegrees: 135.0,
      backgroundHex: 0xFFFFFFFF,
    ),
  );

  /// High Contrast Mono: standard WCAG-compliant black-on-white square matrix.
  static final QrTemplate highContrastMono = QrTemplate(
    id: 'high-contrast-mono',
    name: 'High Contrast Mono',
    description: 'Ultra-reliable maximum-contrast monochrome matrix for demanding industrial scanners.',
    moduleShape: QrModuleShape.square,
    eyeStyle: const QrEyeStyle(
      frameShape: QrEyeFrameShape.square,
      pupilShape: QrEyePupilShape.square,
      frameColorHex: 0xFF000000,
      pupilColorHex: 0xFF000000,
    ),
    colorConfig: QrColorConfig.solid(
      0xFF000000,
      backgroundHex: 0xFFFFFFFF,
    ),
  );

  /// Sunset Vibrant: organic liquid modules with warm coral to rose gradient.
  static final QrTemplate sunsetVibrant = QrTemplate(
    id: 'sunset-vibrant',
    name: 'Sunset Vibrant',
    description: 'Dynamic fluid styling with warm sunset coral and vibrant rose blend.',
    moduleShape: QrModuleShape.liquid,
    eyeStyle: const QrEyeStyle(
      frameShape: QrEyeFrameShape.rounded,
      pupilShape: QrEyePupilShape.circle,
      frameColorHex: 0xFFFF5E3A,
      pupilColorHex: 0xFFFF2A68,
    ),
    colorConfig: QrColorConfig.linear(
      const [
        QrColorStop(offset: 0.0, colorHex: 0xFFFF5E3A),
        QrColorStop(offset: 1.0, colorHex: 0xFFFF2A68),
      ],
      angleDegrees: 90.0,
      backgroundHex: 0xFFFFFFFF,
    ),
  );

  /// List of all built-in artistic templates.
  static final List<QrTemplate> builtInTemplates = [
    cyberpunkNeon,
    corporateNavy,
    emeraldTrust,
    highContrastMono,
    sunsetVibrant,
  ];

  /// Finds a template by its unique ID.
  static QrTemplate? findById(String id) {
    for (final template in builtInTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'moduleShape': moduleShape.name,
    'eyeStyle': eyeStyle.toJson(),
    'colorConfig': colorConfig.toJson(),
    'logoConfig': logoConfig?.toJson(),
  };

  factory QrTemplate.fromJson(Map<String, dynamic> json) {
    return QrTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      moduleShape: QrModuleShape.values.byName(json['moduleShape'] as String? ?? 'square'),
      eyeStyle: QrEyeStyle.fromJson(json['eyeStyle'] as Map<String, dynamic>? ?? {}),
      colorConfig: QrColorConfig.fromJson(json['colorConfig'] as Map<String, dynamic>? ?? {}),
      logoConfig: json['logoConfig'] != null
          ? QrLogoConfig.fromJson(json['logoConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}
