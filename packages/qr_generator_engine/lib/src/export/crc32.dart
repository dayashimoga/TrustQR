import 'dart:typed_data';

/// Pure-Dart high-performance standard CRC-32 (IEEE 802.3 / ISO 3309).
///
/// Uses the reversed polynomial 0xEDB88320 with precomputed 256-word lookup table.
class Crc32 {
  static final Uint32List _table = _initTable();

  static Uint32List _initTable() {
    final table = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[i] = c;
    }
    return table;
  }

  /// Computes the 32-bit CRC checksum for [bytes].
  static int compute(List<int> bytes, [int offset = 0, int? length]) {
    final len = length ?? (bytes.length - offset);
    var c = 0xFFFFFFFF;
    final end = offset + len;
    for (var i = offset; i < end; i++) {
      c = _table[(c ^ bytes[i]) & 0xFF] ^ (c >>> 8);
    }
    return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
