import 'dart:math';

/// A located QR finder eye pattern candidate with sub-pixel center coordinates.
class FinderPattern {
  final double x;
  final double y;
  final double estimatedModuleSize;
  final int count;

  const FinderPattern({
    required this.x,
    required this.y,
    required this.estimatedModuleSize,
    this.count = 1,
  });

  /// Computes Euclidean distance to another pattern.
  double distanceTo(FinderPattern other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Determines if candidate pattern is close enough to merge with an existing pattern.
  bool aboutEquals(double moduleSize, double cy, double cx) {
    if ((cy - y).abs() <= moduleSize && (cx - x).abs() <= moduleSize) {
      final moduleSizeDiff = (moduleSize - estimatedModuleSize).abs();
      return moduleSizeDiff <= 1.0 || moduleSizeDiff <= estimatedModuleSize;
    }
    return false;
  }

  /// Returns a new pattern combining multiple candidate observations for higher precision.
  FinderPattern combineEstimate(double cy, double cx, double newModuleSize) {
    final combinedCount = count + 1;
    final combinedX = (count * x + cx) / combinedCount;
    final combinedY = (count * y + cy) / combinedCount;
    final combinedSize = (count * estimatedModuleSize + newModuleSize) / combinedCount;
    return FinderPattern(
      x: combinedX,
      y: combinedY,
      estimatedModuleSize: combinedSize,
      count: combinedCount,
    );
  }
}

/// A triplet of finder patterns forming a valid QR code orientation triangle.
class FinderPatternInfo {
  final FinderPattern topLeft;
  final FinderPattern topRight;
  final FinderPattern bottomLeft;

  const FinderPatternInfo({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
  });

  /// Estimates the distance between Top-Left and Top-Right centers.
  double get width => topLeft.distanceTo(topRight);

  /// Estimates the distance between Top-Left and Bottom-Left centers.
  double get height => topLeft.distanceTo(bottomLeft);

  /// Average module size across the 3 finder patterns.
  double get averageModuleSize =>
      (topLeft.estimatedModuleSize + topRight.estimatedModuleSize + bottomLeft.estimatedModuleSize) / 3.0;
}
