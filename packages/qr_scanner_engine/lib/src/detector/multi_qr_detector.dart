import 'dart:math';
import '../decoder/qr_matrix_decoder.dart';
import '../image/image_buffer.dart';
import 'finder_pattern.dart';
import 'qr_detector.dart';

/// Detection result containing the decoded string and its physical bounding points.
class DetectedQrCode {
  final String content;
  final FinderPatternInfo finderPatterns;
  final int dimension;
  final double confidence;

  const DetectedQrCode({
    required this.content,
    required this.finderPatterns,
    required this.dimension,
    this.confidence = 1.0,
  });
}

/// Vision detector capable of detecting and decoding multiple QR codes in a single image.
class MultiQrDetector {
  final QrDetector detector;
  final QrMatrixDecoder matrixDecoder;

  MultiQrDetector({
    QrDetector? detector,
    QrMatrixDecoder? matrixDecoder,
  })  : detector = detector ?? QrDetector(),
        matrixDecoder = matrixDecoder ?? QrMatrixDecoder();

  /// Detects all QR codes present in [image].
  List<DetectedQrCode> detectMultiple(BinarizedBitMatrix image) {
    var patterns = detector.findFinderPatterns(image);
    var effectiveImage = image;

    if (patterns.length < 3) {
      final inverted = image.inverted();
      final invertedPatterns = detector.findFinderPatterns(inverted);
      if (invertedPatterns.length >= 3) {
        patterns = invertedPatterns;
        effectiveImage = inverted;
      }
    }

    if (patterns.length < 3) return const [];

    final triplets = _findValidTriplets(patterns);
    final results = <DetectedQrCode>[];
    final seenContents = <String>{};

    for (final triplet in triplets) {
      final dimension = detector.computeDimension(triplet);
      if (dimension < 21) continue;

      final sampledMatrix = detector.sampleGrid(effectiveImage, triplet, dimension);
      var content = matrixDecoder.decode(sampledMatrix);

      // If normal decoding fails, try inverted bit matrix (for dark/inverted QR codes)
      if (content == null) {
        final invertedMatrix = sampledMatrix.inverted();
        content = matrixDecoder.decode(invertedMatrix);
      }

      if (content != null && !seenContents.contains(content)) {
        seenContents.add(content);
        results.add(DetectedQrCode(
          content: content,
          finderPatterns: triplet,
          dimension: dimension,
          confidence: 1.0,
        ));
      }
    }

    return results;
  }

  List<FinderPatternInfo> _findValidTriplets(List<FinderPattern> patterns) {
    final triplets = <FinderPatternInfo>[];
    final count = patterns.length;

    for (var i = 0; i < count - 2; i++) {
      for (var j = i + 1; j < count - 1; j++) {
        for (var k = j + 1; k < count; k++) {
          final pA = patterns[i];
          final pB = patterns[j];
          final pC = patterns[k];

          // 1. Verify module size consistency across the 3 patterns
          final maxMod = max(pA.estimatedModuleSize, max(pB.estimatedModuleSize, pC.estimatedModuleSize));
          final minMod = min(pA.estimatedModuleSize, min(pB.estimatedModuleSize, pC.estimatedModuleSize));
          if ((maxMod - minMod) / maxMod > 0.45) continue;

          // 2. Try orienting into Top-Left, Top-Right, Bottom-Left
          final dAB = pA.distanceTo(pB);
          final dBC = pB.distanceTo(pC);
          final dCA = pC.distanceTo(pA);

          FinderPattern tl, tr, bl;
          if (dBC >= dAB && dBC >= dCA) {
            tl = pA;
            tr = pB;
            bl = pC;
          } else if (dCA >= dAB && dCA >= dBC) {
            tl = pB;
            tr = pA;
            bl = pC;
          } else {
            tl = pC;
            tr = pA;
            bl = pB;
          }

          final side1 = tl.distanceTo(tr);
          final side2 = tl.distanceTo(bl);
          final avgSide = (side1 + side2) / 2.0;

          // Side ratio check (should be nearly equal)
          if ((side1 - side2).abs() / max(side1, side2) > 0.35) continue;

          // Minimum size check (must be at least 14 modules across)
          if (avgSide / tl.estimatedModuleSize < 13.0) continue;

          // Verify cross product orientation
          final cross = (tr.x - tl.x) * (bl.y - tl.y) - (tr.y - tl.y) * (bl.x - tl.x);
          if (cross < 0) {
            final tmp = tr;
            tr = bl;
            bl = tmp;
          }

          triplets.add(FinderPatternInfo(
            topLeft: tl,
            topRight: tr,
            bottomLeft: bl,
          ));
        }
      }
    }

    return triplets;
  }
}
