import 'dart:convert';
import 'dart:typed_data';
import '../../qr_generator_engine.dart';

/// Predefined page layouts for print-ready vector PDF generation.
enum PdfPageLayout {
  /// Standard single label (4x4 inches = 288x288 pt) with title and subtitle.
  singleLabel,

  /// Letter paper (612x792 pt) with a 3x4 grid of 12 QR code stickers.
  stickerSheet,

  /// CR80 credit-card / badge card (3.375 x 2.125 inches = 243 x 153 pt).
  badgeCard,
}

/// Pure-Dart print-ready vector PDF document exporter.
///
/// Produces ISO 32000-1 (PDF-1.4) compliant resolution-independent vector PDF documents
/// without third-party dependencies.
class PdfExporter {
  const PdfExporter();

  /// Exports [matrix] to a vector PDF document using the specified [layout].
  Uint8List export({
    required QrMatrix matrix,
    PdfPageLayout layout = PdfPageLayout.singleLabel,
    String? title,
    String? subtitle,
    QrColorConfig colorConfig = const QrColorConfig(),
    int quietZone = 4,
  }) {
    final builder = _PdfDocBuilder();

    switch (layout) {
      case PdfPageLayout.singleLabel:
        _buildSingleLabel(builder, matrix, colorConfig, quietZone, title, subtitle);
        break;
      case PdfPageLayout.stickerSheet:
        _buildStickerSheet(builder, matrix, colorConfig, quietZone, title, subtitle);
        break;
      case PdfPageLayout.badgeCard:
        _buildBadgeCard(builder, matrix, colorConfig, quietZone, title, subtitle);
        break;
    }

    return builder.build();
  }

  void _buildSingleLabel(
    _PdfDocBuilder builder,
    QrMatrix matrix,
    QrColorConfig colorConfig,
    int quietZone,
    String? title,
    String? subtitle,
  ) {
    const pageWidth = 288.0; // 4 inches @ 72 dpi
    const pageHeight = 288.0;

    final stream = StringBuffer();

    // 1. Background fill
    final bgRgb = _colorToRgb(colorConfig.backgroundColorHex);
    stream.writeln('${bgRgb[0]} ${bgRgb[1]} ${bgRgb[2]} rg');
    stream.writeln('0 0 $pageWidth $pageHeight re f');

    // 2. Title text at top
    final fgRgb = _colorToRgb(colorConfig.foregroundColorHex);
    if (title != null && title.isNotEmpty) {
      stream.writeln('BT');
      stream.writeln('/F2 16 Tf');
      stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');
      stream.writeln('20 252 Td');
      stream.writeln('(${_escapePdfText(title)}) Tj');
      stream.writeln('ET');
    }

    // 3. Vector QR code centered
    const qrSize = 176.0;
    const qrOriginX = (pageWidth - qrSize) / 2.0;
    const qrOriginY = 56.0;
    _drawVectorQr(stream, matrix, quietZone, qrOriginX, qrOriginY, qrSize, fgRgb);

    // 4. Subtitle / URL text at bottom
    if (subtitle != null && subtitle.isNotEmpty) {
      stream.writeln('BT');
      stream.writeln('/F1 9 Tf');
      stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');
      stream.writeln('20 30 Td');
      stream.writeln('(${_escapePdfText(subtitle)}) Tj');
      stream.writeln('ET');
    }

    builder.addPage(pageWidth, pageHeight, stream.toString());
  }

  void _buildStickerSheet(
    _PdfDocBuilder builder,
    QrMatrix matrix,
    QrColorConfig colorConfig,
    int quietZone,
    String? title,
    String? subtitle,
  ) {
    const pageWidth = 612.0; // Letter width @ 72 dpi
    const pageHeight = 792.0; // Letter height

    final stream = StringBuffer();

    // Background
    final bgRgb = _colorToRgb(colorConfig.backgroundColorHex);
    stream.writeln('${bgRgb[0]} ${bgRgb[1]} ${bgRgb[2]} rg');
    stream.writeln('0 0 $pageWidth $pageHeight re f');

    // 3 columns x 4 rows = 12 stickers
    const cols = 3;
    const rows = 4;
    const marginX = 36.0;
    const marginY = 36.0;
    const cellWidth = (pageWidth - marginX * 2) / cols; // 180 pt
    const cellHeight = (pageHeight - marginY * 2) / rows; // 180 pt
    const qrSize = 120.0;

    final fgRgb = _colorToRgb(colorConfig.foregroundColorHex);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cellX = marginX + c * cellWidth;
        final cellY = pageHeight - marginY - (r + 1) * cellHeight;

        // Subtle sticker border
        stream.writeln('0.85 0.85 0.85 RG');
        stream.writeln('0.5 w');
        stream.writeln('$cellX $cellY $cellWidth $cellHeight re S');

        // Draw QR code centered in cell
        final qx = cellX + (cellWidth - qrSize) / 2.0;
        final qy = cellY + 32.0;
        _drawVectorQr(stream, matrix, quietZone, qx, qy, qrSize, fgRgb);

        // Label below QR
        final label = title ?? subtitle ?? 'QR Sticker #${r * cols + c + 1}';
        stream.writeln('BT');
        stream.writeln('/F1 8 Tf');
        stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');
        stream.writeln('${cellX + 12} ${cellY + 14} Td');
        stream.writeln('(${_escapePdfText(label)}) Tj');
        stream.writeln('ET');
      }
    }

    builder.addPage(pageWidth, pageHeight, stream.toString());
  }

  void _buildBadgeCard(
    _PdfDocBuilder builder,
    QrMatrix matrix,
    QrColorConfig colorConfig,
    int quietZone,
    String? title,
    String? subtitle,
  ) {
    const pageWidth = 243.0; // 3.375 inches @ 72 dpi (CR80 badge)
    const pageHeight = 153.0; // 2.125 inches

    final stream = StringBuffer();

    // 1. Background
    final bgRgb = _colorToRgb(colorConfig.backgroundColorHex);
    stream.writeln('${bgRgb[0]} ${bgRgb[1]} ${bgRgb[2]} rg');
    stream.writeln('0 0 $pageWidth $pageHeight re f');

    // 2. Top header accent bar
    final fgRgb = _colorToRgb(colorConfig.foregroundColorHex);
    stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');
    stream.writeln('0 135 $pageWidth 18 re f');

    // Header title
    stream.writeln('BT');
    stream.writeln('/F2 10 Tf');
    stream.writeln('1.0 1.0 1.0 rg');
    stream.writeln('12 139 Td');
    stream.writeln('(EVENT ACCESS PASS) Tj');
    stream.writeln('ET');

    // 3. Attendee / Badge Info on Left
    stream.writeln('BT');
    stream.writeln('/F2 12 Tf');
    stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');
    stream.writeln('14 100 Td');
    stream.writeln('(${_escapePdfText(title ?? "VIP Passholder")}) Tj');
    stream.writeln('ET');

    if (subtitle != null && subtitle.isNotEmpty) {
      stream.writeln('BT');
      stream.writeln('/F1 8 Tf');
      stream.writeln('0.3 0.3 0.3 rg');
      stream.writeln('14 84 Td');
      stream.writeln('(${_escapePdfText(subtitle)}) Tj');
      stream.writeln('ET');
    }

    // 4. QR Code on Right
    const qrSize = 96.0;
    const qrOriginX = 135.0;
    const qrOriginY = 22.0;
    _drawVectorQr(stream, matrix, quietZone, qrOriginX, qrOriginY, qrSize, fgRgb);

    builder.addPage(pageWidth, pageHeight, stream.toString());
  }

  void _drawVectorQr(
    StringBuffer stream,
    QrMatrix matrix,
    int quietZone,
    double originX,
    double originY,
    double qrSize,
    List<double> fgRgb,
  ) {
    final dim = matrix.dimension;
    final totalModules = dim + quietZone * 2;
    final moduleSizePt = qrSize / totalModules;

    stream.writeln('${fgRgb[0]} ${fgRgb[1]} ${fgRgb[2]} rg');

    for (var y = 0; y < dim; y++) {
      for (var x = 0; x < dim; x++) {
        if (matrix.get(x, y)) {
          final mx = originX + (x + quietZone) * moduleSizePt;
          // PDF Y coordinates go bottom-up
          final my = originY + (totalModules - 1 - (y + quietZone)) * moduleSizePt;
          stream.writeln('${mx.toStringAsFixed(2)} ${my.toStringAsFixed(2)} ${moduleSizePt.toStringAsFixed(2)} ${moduleSizePt.toStringAsFixed(2)} re f');
        }
      }
    }
  }

  List<double> _colorToRgb(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return [
      double.parse(r.toStringAsFixed(3)),
      double.parse(g.toStringAsFixed(3)),
      double.parse(b.toStringAsFixed(3)),
    ];
  }

  String _escapePdfText(String text) {
    return text.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
  }
}

/// Internal helper for constructing well-formed PDF binary documents.
class _PdfDocBuilder {
  final List<String> _objects = [];
  final List<int> _pageObjIndices = [];

  void addPage(double width, double height, String contentStream) {
    final contentIndex = _objects.length + 1;
    final streamBytes = utf8.encode(contentStream);
    _objects.add('<< /Length ${streamBytes.length} >>\nstream\n$contentStream\nendstream');

    final pageIndex = _objects.length + 1;
    _pageObjIndices.add(pageIndex);
    _objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $width $height] /Contents $contentIndex 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>',
    );
  }

  Uint8List build() {
    final buffer = BytesBuilder(copy: false);

    // PDF Header
    buffer.add(utf8.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));

    // We will place Catalog at 1 0 obj, Pages at 2 0 obj, Fonts at 5 and 6
    final totalPages = _pageObjIndices.length;
    final kids = _pageObjIndices.map((i) => '$i 0 R').join(' ');

    final obj1 = '<< /Type /Catalog /Pages 2 0 R >>';
    final obj2 = '<< /Type /Pages /Kids [$kids] /Count $totalPages >>';
    final obj5Font1 = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    final obj6Font2 = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';

    final allObjects = <String>[];
    allObjects.add(obj1); // 1
    allObjects.add(obj2); // 2

    // Add content & page objects
    for (final obj in _objects) {
      allObjects.add(obj);
    }

    allObjects.add(obj5Font1); // 5 (or next index)
    allObjects.add(obj6Font2); // 6

    final offsets = <int>[0]; // 0 is dummy for generation 65535

    for (var i = 0; i < allObjects.length; i++) {
      final objNum = i + 1;
      offsets.add(buffer.length);
      buffer.add(utf8.encode('$objNum 0 obj\n${allObjects[i]}\nendobj\n'));
    }

    // XRef Table
    final startXref = buffer.length;
    final xref = StringBuffer();
    xref.writeln('xref');
    xref.writeln('0 ${offsets.length}');
    xref.writeln('0000000000 65535 f ');

    for (var i = 1; i < offsets.length; i++) {
      final off = offsets[i].toString().padLeft(10, '0');
      xref.writeln('$off 00000 n ');
    }

    xref.writeln('trailer');
    xref.writeln('<< /Size ${offsets.length} /Root 1 0 R >>');
    xref.writeln('startxref');
    xref.writeln('$startXref');
    xref.writeln('%%EOF');

    buffer.add(utf8.encode(xref.toString()));
    return buffer.takeBytes();
  }
}
