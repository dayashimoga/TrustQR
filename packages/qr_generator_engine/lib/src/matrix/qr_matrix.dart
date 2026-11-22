import 'dart:typed_data';

/// Classification of QR matrix module types to allow contextual artistic styling.
enum QrModuleType {
  data,
  finderOuter,
  finderInner,
  finderPupil,
  separator,
  timing,
  alignment,
  formatInfo,
  versionInfo,
  logoArea,
}

/// Bit matrix for a QR code representing dark/light states and module role classifications.
class QrMatrix {
  final int dimension;
  final Uint8List _bits;
  final Uint8List _types;

  QrMatrix(this.dimension)
      : _bits = Uint8List((dimension * dimension + 7) >> 3),
        _types = Uint8List(dimension * dimension);

  /// Gets the boolean state of the module at (x, y): true = dark/black, false = light/white.
  bool get(int x, int y) {
    if (x < 0 || x >= dimension || y < 0 || y >= dimension) return false;
    final idx = y * dimension + x;
    return ((_bits[idx >> 3] >> (idx & 7)) & 1) != 0;
  }

  /// Sets the boolean state of the module at (x, y).
  void set(int x, int y, bool isDark, {QrModuleType type = QrModuleType.data}) {
    if (x < 0 || x >= dimension || y < 0 || y >= dimension) return;
    final idx = y * dimension + x;
    final byteIdx = idx >> 3;
    final bitIdx = idx & 7;

    if (isDark) {
      _bits[byteIdx] |= (1 << bitIdx);
    } else {
      _bits[byteIdx] &= ~(1 << bitIdx);
    }
    _types[idx] = type.index;
  }

  /// Gets the functional role type of the module at (x, y).
  QrModuleType getType(int x, int y) {
    if (x < 0 || x >= dimension || y < 0 || y >= dimension) return QrModuleType.data;
    return QrModuleType.values[_types[y * dimension + x]];
  }

  /// Sets the functional role type without modifying the dark/light state.
  void setType(int x, int y, QrModuleType type) {
    if (x < 0 || x >= dimension || y < 0 || y >= dimension) return;
    _types[y * dimension + x] = type.index;
  }

  /// Checks if the module at (x, y) is part of a reserved function pattern (finders, timing, alignment, format, version).
  bool isFunctionPattern(int x, int y) {
    final t = getType(x, y);
    return t != QrModuleType.data && t != QrModuleType.logoArea;
  }

  /// Creates an identical deep copy of this matrix.
  QrMatrix clone() {
    final copy = QrMatrix(dimension);
    copy._bits.setAll(0, _bits);
    copy._types.setAll(0, _types);
    return copy;
  }
}
