import 'dart:math';
import 'dart:typed_data';
import '../image/image_buffer.dart';
import 'finder_pattern.dart';

/// Perspective matrix transform for sampling aligned QR modules.
class PerspectiveTransform {
  final double a11, a12, a13;
  final double a21, a22, a23;
  final double a31, a32, a33;

  const PerspectiveTransform(
    this.a11, this.a12, this.a13,
    this.a21, this.a22, this.a23,
    this.a31, this.a32, this.a33,
  );

  /// Computes perspective transform mapping quadrilateral (p0..p3) to rectangle (dim x dim).
  static PerspectiveTransform quadrilateralToSquare(
    double x0, double y0,
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
  ) {
    return squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3).invert();
  }

  static PerspectiveTransform squareToQuadrilateral(
    double x0, double y0,
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
  ) {
    final dx3 = x0 - x1 + x2 - x3;
    final dy3 = y0 - y1 + y2 - y3;

    if (dx3 == 0.0 && dy3 == 0.0) {
      // Affine transform
      return PerspectiveTransform(
        x1 - x0, x2 - x1, x0,
        y1 - y0, y2 - y1, y0,
        0.0, 0.0, 1.0,
      );
    }

    final dx1 = x1 - x2;
    final dx2 = x3 - x2;
    final dy1 = y1 - y2;
    final dy2 = y3 - y2;
    final denominator = dx1 * dy2 - dx2 * dy1;
    final a13 = (dx3 * dy2 - dx2 * dy3) / (denominator != 0 ? denominator : 1.0);
    final a23 = (dx1 * dy3 - dx3 * dy1) / (denominator != 0 ? denominator : 1.0);

    return PerspectiveTransform(
      x1 - x0 + a13 * x1, x3 - x0 + a23 * x3, x0,
      y1 - y0 + a13 * y1, y3 - y0 + a23 * y3, y0,
      a13, a23, 1.0,
    );
  }

  PerspectiveTransform invert() {
    return PerspectiveTransform(
      a22 * a33 - a23 * a32, a13 * a32 - a12 * a33, a12 * a23 - a13 * a22,
      a23 * a31 - a21 * a33, a11 * a33 - a13 * a31, a13 * a21 - a11 * a23,
      a21 * a32 - a22 * a31, a12 * a31 - a11 * a32, a11 * a22 - a12 * a21,
    );
  }

  void transformPoints(List<double> points) {
    final max = points.length;
    for (var i = 0; i < max; i += 2) {
      final x = points[i];
      final y = points[i + 1];
      final denominator = a31 * x + a32 * y + a33;
      final den = denominator != 0 ? denominator : 1.0;
      points[i] = (a11 * x + a12 * y + a13) / den;
      points[i + 1] = (a21 * x + a22 * y + a23) / den;
    }
  }
}

/// Vision detector for locating and extracting QR code module matrices.
class QrDetector {
  /// Locates all finder pattern candidates in the binarized image.
  List<FinderPattern> findFinderPatterns(BinarizedBitMatrix matrix) {
    final width = matrix.width;
    final height = matrix.height;
    final possibleCenters = <FinderPattern>[];
    final stateCount = Int32List(5);

    // Skip rows dynamically based on image height for rapid initial scanning
    var iSkip = (height ~/ 100).clamp(1, 3);

    for (var row = iSkip - 1; row < height; row += iSkip) {
      stateCount.fillRange(0, 5, 0);
      var currentState = 0;

      for (var col = 0; col < width; col++) {
        if (matrix.get(col, row)) {
          // Black pixel
          if ((currentState & 1) == 1) {
            currentState++;
          }
          stateCount[currentState]++;
        } else {
          // White pixel
          if ((currentState & 1) == 0) {
            if (currentState == 4) {
              if (foundPatternCross(stateCount)) {
                final handleResult = _handlePossibleCenter(stateCount, row, col, matrix, possibleCenters);
                if (handleResult) {
                  // After finding a center, advance scan
                  iSkip = 2;
                }
              }
              // Shift state counts by 2
              stateCount[0] = stateCount[2];
              stateCount[1] = stateCount[3];
              stateCount[2] = stateCount[4];
              stateCount[3] = 1;
              stateCount[4] = 0;
              currentState = 3;
              continue;
            } else {
              currentState++;
            }
          }
          stateCount[currentState]++;
        }
      }

      if (foundPatternCross(stateCount)) {
        _handlePossibleCenter(stateCount, row, width, matrix, possibleCenters);
      }
    }

    return possibleCenters;
  }

  /// Verifies standard 1:1:3:1:1 module ratio with 50% tolerance.
  static bool foundPatternCross(Int32List stateCount) {
    var totalModuleSize = 0;
    for (var i = 0; i < 5; i++) {
      final count = stateCount[i];
      if (count == 0) return false;
      totalModuleSize += count;
    }
    if (totalModuleSize < 7) return false;

    final moduleSize = totalModuleSize / 7.0;
    final maxVariance = moduleSize / 2.0;

    return (moduleSize - stateCount[0]).abs() < maxVariance &&
        (moduleSize - stateCount[1]).abs() < maxVariance &&
        (3.0 * moduleSize - stateCount[2]).abs() < 3.0 * maxVariance &&
        (moduleSize - stateCount[3]).abs() < maxVariance &&
        (moduleSize - stateCount[4]).abs() < maxVariance;
  }

  bool _handlePossibleCenter(
    Int32List stateCount,
    int row,
    int col,
    BinarizedBitMatrix matrix,
    List<FinderPattern> possibleCenters,
  ) {
    final stateSum = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    final centerCol = col - stateCount[4] - stateCount[3] - (stateCount[2] / 2.0);
    final centerRow = _crossCheckVertical(matrix, row, centerCol.toInt(), stateCount[2], stateSum);

    if (centerRow != null) {
      final verifiedCol = _crossCheckHorizontal(matrix, centerRow.toInt(), centerCol.toInt(), stateCount[2], stateSum);
      if (verifiedCol != null) {
        final estimatedModuleSize = stateSum / 7.0;
        var found = false;
        for (var i = 0; i < possibleCenters.length; i++) {
          final existing = possibleCenters[i];
          if (existing.aboutEquals(estimatedModuleSize, centerRow, verifiedCol)) {
            possibleCenters[i] = existing.combineEstimate(centerRow, verifiedCol, estimatedModuleSize);
            found = true;
            break;
          }
        }
        if (!found) {
          possibleCenters.add(FinderPattern(
            x: verifiedCol,
            y: centerRow,
            estimatedModuleSize: estimatedModuleSize,
          ));
        }
        return true;
      }
    }
    return false;
  }

  double? _crossCheckVertical(BinarizedBitMatrix matrix, int startRow, int centerCol, int centerCount, int stateSum) {
    final height = matrix.height;
    final stateCount = Int32List(5);

    var row = startRow;
    while (row >= 0 && matrix.get(centerCol, row)) {
      stateCount[2]++;
      row--;
    }
    if (row < 0) return null;

    while (row >= 0 && !matrix.get(centerCol, row) && stateCount[1] <= centerCount) {
      stateCount[1]++;
      row--;
    }
    if (row < 0 || stateCount[1] > centerCount) return null;

    while (row >= 0 && matrix.get(centerCol, row) && stateCount[0] <= centerCount) {
      stateCount[0]++;
      row--;
    }
    if (stateCount[0] > centerCount) return null;

    row = startRow + 1;
    while (row < height && matrix.get(centerCol, row)) {
      stateCount[2]++;
      row++;
    }
    if (row >= height) return null;

    while (row < height && !matrix.get(centerCol, row) && stateCount[3] <= centerCount) {
      stateCount[3]++;
      row++;
    }
    if (row >= height || stateCount[3] > centerCount) return null;

    while (row < height && matrix.get(centerCol, row) && stateCount[4] <= centerCount) {
      stateCount[4]++;
      row++;
    }
    if (stateCount[4] > centerCount) return null;

    final verticalStateSum = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    if (5 * (verticalStateSum - stateSum).abs() >= 2 * stateSum) return null;

    return foundPatternCross(stateCount)
        ? (row - stateCount[4] - stateCount[3] - stateCount[2] / 2.0).toDouble()
        : null;
  }

  double? _crossCheckHorizontal(BinarizedBitMatrix matrix, int centerRow, int startCol, int centerCount, int stateSum) {
    final width = matrix.width;
    final stateCount = Int32List(5);

    var col = startCol;
    while (col >= 0 && matrix.get(col, centerRow)) {
      stateCount[2]++;
      col--;
    }
    if (col < 0) return null;

    while (col >= 0 && !matrix.get(col, centerRow) && stateCount[1] <= centerCount) {
      stateCount[1]++;
      col--;
    }
    if (col < 0 || stateCount[1] > centerCount) return null;

    while (col >= 0 && matrix.get(col, centerRow) && stateCount[0] <= centerCount) {
      stateCount[0]++;
      col--;
    }
    if (stateCount[0] > centerCount) return null;

    col = startCol + 1;
    while (col < width && matrix.get(col, centerRow)) {
      stateCount[2]++;
      col++;
    }
    if (col >= width) return null;

    while (col < width && !matrix.get(col, centerRow) && stateCount[3] <= centerCount) {
      stateCount[3]++;
      col++;
    }
    if (col >= width || stateCount[3] > centerCount) return null;

    while (col < width && matrix.get(col, centerRow) && stateCount[4] <= centerCount) {
      stateCount[4]++;
      col++;
    }
    if (stateCount[4] > centerCount) return null;

    final horizontalStateSum = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    if (5 * (horizontalStateSum - stateSum).abs() >= 2 * stateSum) return null;

    return foundPatternCross(stateCount)
        ? (col - stateCount[4] - stateCount[3] - stateCount[2] / 2.0).toDouble()
        : null;
  }

  /// Orders 3 finder patterns into Top-Left, Top-Right, and Bottom-Left orientation.
  FinderPatternInfo? orderBestFinderPatterns(List<FinderPattern> patterns) {
    if (patterns.length < 3) return null;

    // Filter to patterns with highest count / consistency
    final sorted = List<FinderPattern>.from(patterns)
      ..sort((a, b) => b.count.compareTo(a.count));

    for (var i = 0; i < sorted.length - 2; i++) {
      for (var j = i + 1; j < sorted.length - 1; j++) {
        for (var k = j + 1; k < sorted.length; k++) {
          final pA = sorted[i];
          final pB = sorted[j];
          final pC = sorted[k];

          final info = _tryOrderTriplet(pA, pB, pC);
          if (info != null) return info;
        }
      }
    }
    return null;
  }

  FinderPatternInfo? _tryOrderTriplet(FinderPattern pA, FinderPattern pB, FinderPattern pC) {
    final dAB = pA.distanceTo(pB);
    final dBC = pB.distanceTo(pC);
    final dCA = pC.distanceTo(pA);

    FinderPattern topLeft;
    FinderPattern topRight;
    FinderPattern bottomLeft;

    // The hypotenuse connects Top-Right and Bottom-Left; Top-Left is opposite it
    if (dBC >= dAB && dBC >= dCA) {
      topLeft = pA;
      topRight = pB;
      bottomLeft = pC;
    } else if (dCA >= dAB && dCA >= dBC) {
      topLeft = pB;
      topRight = pA;
      bottomLeft = pC;
    } else {
      topLeft = pC;
      topRight = pA;
      bottomLeft = pB;
    }

    // Check if right angle is approximately 90 degrees: (d1^2 + d2^2) ~ dHyp^2
    final side1 = topLeft.distanceTo(topRight);
    final side2 = topLeft.distanceTo(bottomLeft);
    final hyp = topRight.distanceTo(bottomLeft);
    final expectedHypSq = side1 * side1 + side2 * side2;
    final actualHypSq = hyp * hyp;
    if (expectedHypSq > 0 && (actualHypSq - expectedHypSq).abs() / expectedHypSq > 0.6) return null;
    final ratio = (side1 - side2).abs() / max(side1, side2);
    if (ratio > 0.4) return null; // Sides should be roughly equal in a square QR code

    // Cross product (topRight - topLeft) x (bottomLeft - topLeft)
    // If negative, swap topRight and bottomLeft to correct orientation
    final crossProduct = (topRight.x - topLeft.x) * (bottomLeft.y - topLeft.y) -
        (topRight.y - topLeft.y) * (bottomLeft.x - topLeft.x);

    if (crossProduct < 0) {
      final temp = topRight;
      topRight = bottomLeft;
      bottomLeft = temp;
    }

    return FinderPatternInfo(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
    );
  }

  /// Estimates the QR version dimension (21, 25, 29, etc.) from pattern geometry.
  int computeDimension(FinderPatternInfo info) {
    final modSize = info.averageModuleSize;
    final distTLTR = info.topLeft.distanceTo(info.topRight);
    final distTLBL = info.topLeft.distanceTo(info.bottomLeft);
    final avgDistance = (distTLTR + distTLBL) / 2.0;

    // In a QR code, distance between centers of TL and TR is (dimension - 7) modules
    final rawDimension = ((avgDistance / modSize) + 7.0).round();
    // Round to nearest valid dimension: 17 + 4 * version
    final mod4 = (rawDimension - 17) % 4;
    var dimension = rawDimension;
    if (mod4 == 1) {
      dimension = rawDimension - 1;
    } else if (mod4 == 2) {
      dimension = rawDimension + 2;
    } else if (mod4 == 3) {
      dimension = rawDimension + 1;
    }

    return dimension.clamp(21, 177);
  }

  /// Samples the perspective-corrected module grid into an aligned [BinarizedBitMatrix].
  BinarizedBitMatrix sampleGrid(
    BinarizedBitMatrix image,
    FinderPatternInfo info,
    int dimension,
  ) {
    final tl = info.topLeft;
    final tr = info.topRight;
    final bl = info.bottomLeft;

    // Estimate Bottom-Right corner point from parallelogram
    final brX = tr.x - tl.x + bl.x;
    final brY = tr.y - tl.y + bl.y;

    // Map unit square (where finders are at (0,0), (1,0), (1,1), (0,1)) to image coordinates
    final transform = PerspectiveTransform.squareToQuadrilateral(
      tl.x, tl.y,
      tr.x, tr.y,
      brX, brY,
      bl.x, bl.y,
    );

    final bits = BinarizedBitMatrix(dimension, dimension);
    final points = List<double>.filled(dimension * 2, 0.0);
    final normFactor = dimension - 7.0;

    for (var y = 0; y < dimension; y++) {
      final v = (y + 0.5 - 3.5) / normFactor;
      for (var x = 0; x < dimension; x++) {
        points[x * 2] = (x + 0.5 - 3.5) / normFactor;
        points[x * 2 + 1] = v;
      }

      transform.transformPoints(points);

      for (var x = 0; x < dimension; x++) {
        final imgX = points[x * 2].round();
        final imgY = points[x * 2 + 1].round();

        if (imgX >= 0 && imgX < image.width && imgY >= 0 && imgY < image.height) {
          bits.set(x, y, image.get(imgX, imgY));
        }
      }
    }

    return bits;
  }
}
