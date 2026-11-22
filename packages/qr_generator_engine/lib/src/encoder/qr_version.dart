import '../../qr_generator_engine.dart';

/// Block division specification for a given version and ECC level.
class QrBlockConfig {
  final int eccCodewordsPerBlock;
  final int numBlocksGroup1;
  final int dataCodewordsGroup1;
  final int numBlocksGroup2;
  final int dataCodewordsGroup2;

  const QrBlockConfig({
    required this.eccCodewordsPerBlock,
    required this.numBlocksGroup1,
    required this.dataCodewordsGroup1,
    this.numBlocksGroup2 = 0,
    this.dataCodewordsGroup2 = 0,
  });

  int get totalDataCodewords =>
      (numBlocksGroup1 * dataCodewordsGroup1) + (numBlocksGroup2 * dataCodewordsGroup2);

  int get totalBlocks => numBlocksGroup1 + numBlocksGroup2;

  int get totalCodewords => totalDataCodewords + (totalBlocks * eccCodewordsPerBlock);
}

/// Standards-compliant specifications for an ISO/IEC 18004 QR version (1 to 40).
class QrVersionTable {
  final int version;
  final Map<QrErrorCorrectionLevel, QrBlockConfig> blocks;
  final List<int> alignmentPositions;

  const QrVersionTable({
    required this.version,
    required this.blocks,
    this.alignmentPositions = const [],
  });

  int get dimension => 17 + 4 * version;

  /// Retrieves the block configuration for the given [eccLevel].
  QrBlockConfig getBlockConfig(QrErrorCorrectionLevel eccLevel) {
    final cfg = blocks[eccLevel];
    if (cfg == null) {
      throw ArgumentError('No block config found for version $version and level $eccLevel');
    }
    return cfg;
  }

  /// Calculates the 18-bit BCH(18, 6) version information bits for versions >= 7.
  int? getVersionInfoBits() {
    if (version < 7) return null;
    var d = version << 12;
    const g = 0x1F25; // 7973
    for (var i = 17; i >= 12; i--) {
      if ((d & (1 << i)) != 0) {
        d ^= (g << (i - 12));
      }
    }
    return (version << 12) | d;
  }

  /// Finds the minimal QR version capable of holding [dataByteCount] under [eccLevel].
  static QrVersionTable findOptimalVersion({
    required int dataByteCount,
    required QrErrorCorrectionLevel eccLevel,
    int? maxVersion,
  }) {
    final limit = maxVersion ?? 40;
    for (var v = 1; v <= limit && v <= _allVersions.length; v++) {
      final table = _allVersions[v - 1];
      final cfg = table.getBlockConfig(eccLevel);
      if (cfg.totalDataCodewords >= dataByteCount) {
        return table;
      }
    }
    throw ArgumentError(
      'Payload size ($dataByteCount bytes) exceeds maximum capacity under ECC level ${eccLevel.name} (max version: $limit)',
    );
  }

  /// Retrieves version table by version number (1 to 40).
  static QrVersionTable getVersion(int version) {
    if (version < 1 || version > _allVersions.length) {
      throw RangeError.range(version, 1, _allVersions.length, 'version');
    }
    return _allVersions[version - 1];
  }

  static final List<QrVersionTable> _allVersions = _buildVersions();

  static List<QrVersionTable> _buildVersions() {
    return [
      // Version 1 (21x21)
      const QrVersionTable(
        version: 1,
        alignmentPositions: [],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 7, numBlocksGroup1: 1, dataCodewordsGroup1: 19),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 10, numBlocksGroup1: 1, dataCodewordsGroup1: 16),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 13, numBlocksGroup1: 1, dataCodewordsGroup1: 13),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 17, numBlocksGroup1: 1, dataCodewordsGroup1: 9),
        },
      ),
      // Version 2 (25x25)
      const QrVersionTable(
        version: 2,
        alignmentPositions: [6, 18],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 10, numBlocksGroup1: 1, dataCodewordsGroup1: 34),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 16, numBlocksGroup1: 1, dataCodewordsGroup1: 28),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 1, dataCodewordsGroup1: 22),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 28, numBlocksGroup1: 1, dataCodewordsGroup1: 16),
        },
      ),
      // Version 3 (29x29)
      const QrVersionTable(
        version: 3,
        alignmentPositions: [6, 22],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 15, numBlocksGroup1: 1, dataCodewordsGroup1: 55),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 1, dataCodewordsGroup1: 44),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 17),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 2, dataCodewordsGroup1: 13),
        },
      ),
      // Version 4 (33x33)
      const QrVersionTable(
        version: 4,
        alignmentPositions: [6, 26],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 20, numBlocksGroup1: 1, dataCodewordsGroup1: 80),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 32),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 2, dataCodewordsGroup1: 24),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 16, numBlocksGroup1: 4, dataCodewordsGroup1: 9),
        },
      ),
      // Version 5 (37x37)
      const QrVersionTable(
        version: 5,
        alignmentPositions: [6, 30],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 1, dataCodewordsGroup1: 108),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 24, numBlocksGroup1: 2, dataCodewordsGroup1: 43),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 15, numBlocksGroup2: 2, dataCodewordsGroup2: 16),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 2, dataCodewordsGroup1: 11, numBlocksGroup2: 2, dataCodewordsGroup2: 12),
        },
      ),
      // Version 6 (41x41)
      const QrVersionTable(
        version: 6,
        alignmentPositions: [6, 34],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 68),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 16, numBlocksGroup1: 4, dataCodewordsGroup1: 27),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 24, numBlocksGroup1: 4, dataCodewordsGroup1: 19),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 28, numBlocksGroup1: 4, dataCodewordsGroup1: 15),
        },
      ),
      // Version 7 (45x45)
      const QrVersionTable(
        version: 7,
        alignmentPositions: [6, 22, 38],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 20, numBlocksGroup1: 2, dataCodewordsGroup1: 78),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 4, dataCodewordsGroup1: 31),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 14, numBlocksGroup2: 4, dataCodewordsGroup2: 15),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 4, dataCodewordsGroup1: 13, numBlocksGroup2: 1, dataCodewordsGroup2: 14),
        },
      ),
      // Version 8 (49x49)
      const QrVersionTable(
        version: 8,
        alignmentPositions: [6, 24, 42],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 24, numBlocksGroup1: 2, dataCodewordsGroup1: 97),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 2, dataCodewordsGroup1: 38, numBlocksGroup2: 2, dataCodewordsGroup2: 39),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 4, dataCodewordsGroup1: 18, numBlocksGroup2: 2, dataCodewordsGroup2: 19),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 4, dataCodewordsGroup1: 14, numBlocksGroup2: 2, dataCodewordsGroup2: 15),
        },
      ),
      // Version 9 (53x53)
      const QrVersionTable(
        version: 9,
        alignmentPositions: [6, 26, 46],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 30, numBlocksGroup1: 2, dataCodewordsGroup1: 116),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 22, numBlocksGroup1: 3, dataCodewordsGroup1: 36, numBlocksGroup2: 2, dataCodewordsGroup2: 37),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 20, numBlocksGroup1: 4, dataCodewordsGroup1: 16, numBlocksGroup2: 4, dataCodewordsGroup2: 17),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 24, numBlocksGroup1: 4, dataCodewordsGroup1: 12, numBlocksGroup2: 4, dataCodewordsGroup2: 13),
        },
      ),
      // Version 10 (57x57)
      const QrVersionTable(
        version: 10,
        alignmentPositions: [6, 28, 50],
        blocks: {
          QrErrorCorrectionLevel.low: QrBlockConfig(eccCodewordsPerBlock: 18, numBlocksGroup1: 2, dataCodewordsGroup1: 68, numBlocksGroup2: 2, dataCodewordsGroup2: 69),
          QrErrorCorrectionLevel.medium: QrBlockConfig(eccCodewordsPerBlock: 26, numBlocksGroup1: 4, dataCodewordsGroup1: 43, numBlocksGroup2: 1, dataCodewordsGroup2: 44),
          QrErrorCorrectionLevel.quartile: QrBlockConfig(eccCodewordsPerBlock: 24, numBlocksGroup1: 6, dataCodewordsGroup1: 19, numBlocksGroup2: 2, dataCodewordsGroup2: 20),
          QrErrorCorrectionLevel.high: QrBlockConfig(eccCodewordsPerBlock: 28, numBlocksGroup1: 6, dataCodewordsGroup1: 15, numBlocksGroup2: 2, dataCodewordsGroup2: 16),
        },
      ),
    ];
  }
}
