import 'dart:convert';
import 'dart:typed_data';
import '../../qr_generator_engine.dart';

/// Supported export formats for single and batch exports.
enum ExportFormat {
  png,
  svg,
  pdf,
  bmp,
}

/// Request parameters for an individual QR code item in a batch export.
class BatchItemRequest {
  /// Unique identifier or filename slug for this item.
  final String id;

  /// Raw payload content (URL, WiFi, vCard, TrustQR envelope, etc.).
  final String content;

  /// Optional display title (used in PDF labels and manifest).
  final String? title;

  /// Optional secondary subtitle or URL description.
  final String? subtitle;

  /// Preset template ID (e.g. 'cyberpunkNeon', 'corporateNavy').
  final String? templateId;

  /// Optional custom foreground color (ARGB).
  final int? foregroundColorHex;

  /// Optional custom background color (ARGB).
  final int? backgroundColorHex;

  /// Additional metadata key-values.
  final Map<String, dynamic>? metadata;

  const BatchItemRequest({
    required this.id,
    required this.content,
    this.title,
    this.subtitle,
    this.templateId,
    this.foregroundColorHex,
    this.backgroundColorHex,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'title': title,
    'subtitle': subtitle,
    'templateId': templateId,
    'foregroundColorHex': foregroundColorHex != null
        ? '0x${foregroundColorHex!.toRadixString(16).padLeft(8, '0')}'
        : null,
    'backgroundColorHex': backgroundColorHex != null
        ? '0x${backgroundColorHex!.toRadixString(16).padLeft(8, '0')}'
        : null,
    'metadata': metadata,
  };

  factory BatchItemRequest.fromJson(Map<String, dynamic> json) {
    int? parseHex(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.parse(val.toString().replaceAll('#', '').replaceFirst('0x', ''), radix: 16);
    }

    return BatchItemRequest(
      id: json['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      content: json['content'] as String,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      templateId: json['templateId'] as String?,
      foregroundColorHex: parseHex(json['foregroundColorHex']),
      backgroundColorHex: parseHex(json['backgroundColorHex']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// An exported file entry inside a batch bundle.
class BatchFileEntry {
  final String fileName;
  final Uint8List bytes;
  final String mimeType;

  const BatchFileEntry({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });
}

/// Comprehensive bundle of all generated files in a batch export operation.
class QrBatchExportBundle {
  final List<BatchFileEntry> files;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const QrBatchExportBundle({
    required this.files,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  /// Compiles all exported files into a single pure-Dart PKZIP 2.0 archive.
  Uint8List toZipArchive() {
    final buffer = BytesBuilder(copy: false);
    final centralDirectory = BytesBuilder(copy: false);
    var localHeaderOffset = 0;

    for (final file in files) {
      final fileNameBytes = utf8.encode(file.fileName);
      final fileData = file.bytes;
      final crc = Crc32.compute(fileData);
      final size = fileData.length;

      // 1. Local File Header (30 bytes + filename)
      final localHeader = Uint8List(30);
      final localView = ByteData.view(localHeader.buffer);
      localView.setUint32(0, 0x04034B50, Endian.little); // Signature
      localView.setUint16(4, 20, Endian.little); // Version needed (2.0)
      localView.setUint16(6, 0x0800, Endian.little); // Flags (UTF-8)
      localView.setUint16(8, 0, Endian.little); // Compression (Store)
      localView.setUint16(10, 0x5460, Endian.little); // Mod time
      localView.setUint16(12, 0x5821, Endian.little); // Mod date
      localView.setUint32(14, crc, Endian.little);
      localView.setUint32(18, size, Endian.little); // Compressed size
      localView.setUint32(22, size, Endian.little); // Uncompressed size
      localView.setUint16(26, fileNameBytes.length, Endian.little);
      localView.setUint16(28, 0, Endian.little); // Extra field length

      buffer.add(localHeader);
      buffer.add(fileNameBytes);
      buffer.add(fileData);

      // 2. Central Directory Header (46 bytes + filename)
      final cdHeader = Uint8List(46);
      final cdView = ByteData.view(cdHeader.buffer);
      cdView.setUint32(0, 0x02014B50, Endian.little); // Signature
      cdView.setUint16(4, 20, Endian.little); // Version made by
      cdView.setUint16(6, 20, Endian.little); // Version needed
      cdView.setUint16(8, 0x0800, Endian.little); // Flags (UTF-8)
      cdView.setUint16(10, 0, Endian.little); // Compression
      cdView.setUint16(12, 0x5460, Endian.little); // Mod time
      cdView.setUint16(14, 0x5821, Endian.little); // Mod date
      cdView.setUint32(16, crc, Endian.little);
      cdView.setUint32(20, size, Endian.little);
      cdView.setUint32(24, size, Endian.little);
      cdView.setUint16(28, fileNameBytes.length, Endian.little);
      cdView.setUint16(30, 0, Endian.little); // Extra length
      cdView.setUint16(32, 0, Endian.little); // Comment length
      cdView.setUint16(34, 0, Endian.little); // Disk number start
      cdView.setUint16(36, 0, Endian.little); // Internal attrs
      cdView.setUint32(38, 0, Endian.little); // External attrs
      cdView.setUint32(42, localHeaderOffset, Endian.little); // Header offset

      centralDirectory.add(cdHeader);
      centralDirectory.add(fileNameBytes);

      localHeaderOffset += 30 + fileNameBytes.length + size;
    }

    final cdBytes = centralDirectory.takeBytes();
    final cdSize = cdBytes.length;
    final cdOffset = localHeaderOffset;

    // 3. End of Central Directory Record (22 bytes)
    final eocd = Uint8List(22);
    final eocdView = ByteData.view(eocd.buffer);
    eocdView.setUint32(0, 0x06054B50, Endian.little); // Signature
    eocdView.setUint16(4, 0, Endian.little); // Disk number
    eocdView.setUint16(6, 0, Endian.little); // Start disk
    eocdView.setUint16(8, files.length, Endian.little); // Entries on disk
    eocdView.setUint16(10, files.length, Endian.little); // Total entries
    eocdView.setUint32(12, cdSize, Endian.little); // CD size
    eocdView.setUint32(16, cdOffset, Endian.little); // CD offset
    eocdView.setUint16(20, 0, Endian.little); // Comment length

    buffer.add(cdBytes);
    buffer.add(eocd);

    return buffer.takeBytes();
  }
}

/// Admin-only high-performance batch QR exporter.
class BatchExporter {
  final QrEncoder _encoder;
  final QrMatrixRasterizer _rasterizer;
  final PngExporter _pngExporter;
  final SvgExporter _svgExporter;
  final PdfExporter _pdfExporter;

  const BatchExporter({
    QrEncoder encoder = const QrEncoder(),
    QrMatrixRasterizer rasterizer = const QrMatrixRasterizer(),
    PngExporter pngExporter = const PngExporter(),
    SvgExporter svgExporter = const SvgExporter(),
    PdfExporter pdfExporter = const PdfExporter(),
  })  : _encoder = encoder,
        _rasterizer = rasterizer,
        _pngExporter = pngExporter,
        _svgExporter = svgExporter,
        _pdfExporter = pdfExporter;

  /// Executes a batch QR generation and export operation over [requests].
  Future<QrBatchExportBundle> exportBatch({
    required List<BatchItemRequest> requests,
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.medium,
    int moduleSize = 10,
    int quietZone = 4,
    int dpi = 300,
    void Function(int current, int total)? onProgress,
  }) async {
    final files = <BatchFileEntry>[];
    final errors = <String>[];
    var successCount = 0;
    var failureCount = 0;

    final total = requests.length;

    for (var i = 0; i < total; i++) {
      final req = requests[i];
      try {
        final template = req.templateId != null
            ? (QrTemplate.findById(req.templateId!) ?? defaultTemplate)
            : defaultTemplate;

        // Custom colors if supplied
        var colorConfig = template?.colorConfig ?? const QrColorConfig();
        if (req.foregroundColorHex != null || req.backgroundColorHex != null) {
          colorConfig = QrColorConfig(
            foregroundColorHex: req.foregroundColorHex ?? colorConfig.foregroundColorHex,
            backgroundColorHex: req.backgroundColorHex ?? colorConfig.backgroundColorHex,
            gradientType: colorConfig.gradientType,
            stops: colorConfig.stops,
          );
        }

        final moduleShape = template?.moduleShape ?? QrModuleShape.square;
        final eyeStyle = template?.eyeStyle ?? const QrEyeStyle();
        final logo = template?.logoConfig;

        final matrix = _encoder.encode(
          req.content,
          eccLevel: errorCorrection,
        );

        if (logo != null) {
          logo.carveLogoArea(matrix);
        }

        final fileNameBase = req.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        Uint8List fileBytes;
        String fileName;
        String mimeType;

        switch (format) {
          case ExportFormat.png:
            final img = _rasterizer.rasterize(
              matrix: matrix,
              moduleShape: moduleShape,
              colorConfig: colorConfig,
              eyeStyle: eyeStyle,
              logoConfig: logo,
              moduleSize: moduleSize,
              quietZone: quietZone,
            );
            fileBytes = _pngExporter.export(img, dpi: dpi);
            fileName = '$fileNameBase.png';
            mimeType = 'image/png';
            break;

          case ExportFormat.svg:
            final svgStr = _svgExporter.export(
              matrix: matrix,
              moduleShape: moduleShape,
              colorConfig: colorConfig,
              eyeStyle: eyeStyle,
              logoConfig: logo,
              moduleSize: moduleSize,
              quietZone: quietZone,
            );
            fileBytes = Uint8List.fromList(utf8.encode(svgStr));
            fileName = '$fileNameBase.svg';
            mimeType = 'image/svg+xml';
            break;

          case ExportFormat.pdf:
            fileBytes = _pdfExporter.export(
              matrix: matrix,
              title: req.title ?? req.id,
              subtitle: req.subtitle ?? req.content,
              colorConfig: colorConfig,
              quietZone: quietZone,
            );
            fileName = '$fileNameBase.pdf';
            mimeType = 'application/pdf';
            break;

          case ExportFormat.bmp:
            final img = _rasterizer.rasterize(
              matrix: matrix,
              moduleShape: moduleShape,
              colorConfig: colorConfig,
              eyeStyle: eyeStyle,
              logoConfig: logo,
              moduleSize: moduleSize,
              quietZone: quietZone,
            );
            fileBytes = img.toBmp();
            fileName = '$fileNameBase.bmp';
            mimeType = 'image/bmp';
            break;
        }

        files.add(BatchFileEntry(fileName: fileName, bytes: fileBytes, mimeType: mimeType));
        successCount++;
      } catch (e) {
        failureCount++;
        errors.add('Failed item "${req.id}": $e');
      }

      onProgress?.call(i + 1, total);
    }

    // Add manifest.json to bundle
    final manifestJson = {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'format': format.name,
      'totalRequested': total,
      'successCount': successCount,
      'failureCount': failureCount,
      'items': requests.map((r) => r.toJson()).toList(),
      'errors': errors,
    };
    final manifestBytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(manifestJson)));
    files.add(BatchFileEntry(fileName: 'manifest.json', bytes: manifestBytes, mimeType: 'application/json'));

    return QrBatchExportBundle(
      files: files,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  /// Parses CSV content and runs batch export.
  Future<QrBatchExportBundle> exportFromCsv(
    String csvContent, {
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    void Function(int current, int total)? onProgress,
  }) async {
    final lines = const LineSplitter().convert(csvContent.trim());
    if (lines.isEmpty) {
      return const QrBatchExportBundle(files: [], successCount: 0, failureCount: 0, errors: ['CSV content is empty']);
    }

    final requests = <BatchItemRequest>[];
    final hasHeader = lines.first.toLowerCase().contains('content') || lines.first.toLowerCase().contains('url');
    final startIndex = hasHeader ? 1 : 0;

    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Handle simple comma separation
      final parts = line.split(',').map((p) => p.trim()).toList();
      if (parts.isEmpty || parts[0].isEmpty) continue;

      if (parts.length == 1) {
        requests.add(BatchItemRequest(id: 'qr_${i + 1}', content: parts[0]));
      } else if (parts.length >= 2) {
        final id = parts[0];
        final content = parts[1];
        final title = parts.length > 2 ? parts[2] : null;
        final templateId = parts.length > 3 ? parts[3] : null;
        requests.add(BatchItemRequest(id: id, content: content, title: title, templateId: templateId));
      }
    }

    return exportBatch(
      requests: requests,
      format: format,
      defaultTemplate: defaultTemplate,
      onProgress: onProgress,
    );
  }

  /// Parses JSON content array and runs batch export.
  Future<QrBatchExportBundle> exportFromJson(
    String jsonContent, {
    ExportFormat format = ExportFormat.png,
    QrTemplate? defaultTemplate,
    void Function(int current, int total)? onProgress,
  }) async {
    final parsed = jsonDecode(jsonContent);
    final List<dynamic> list;
    if (parsed is List) {
      list = parsed;
    } else if (parsed is Map && parsed['items'] is List) {
      list = parsed['items'] as List;
    } else {
      throw FormatException('JSON must be a list of items or an object with an "items" array.');
    }

    final requests = list.map((item) => BatchItemRequest.fromJson(item as Map<String, dynamic>)).toList();

    return exportBatch(
      requests: requests,
      format: format,
      defaultTemplate: defaultTemplate,
      onProgress: onProgress,
    );
  }
}
