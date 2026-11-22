import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

/// State coordinator managing batch QR payload parsing, generation,
/// scannability evaluation, and pure-Dart ZIP bundle exporting.
class BatchController extends ChangeNotifier {
  final BatchExporter _batchExporter;
  final ScannabilitySimulator _simulator;
  final QrEncoder _encoder;

  final List<BatchItemRequest> _items = [];
  final Map<String, ScannabilityReport> _scannabilityReports = {};
  bool _isProcessing = false;
  double _progress = 0.0;
  int _processedCount = 0;
  int _successCount = 0;
  int _failureCount = 0;
  final List<String> _errors = [];

  Uint8List? _lastZipBytes;
  String? _lastZipName;
  int? _lastZipSize;
  String? _lastZipSha256;
  ExportFormat _selectedFormat = ExportFormat.png;

  BatchController({
    BatchExporter? batchExporter,
    ScannabilitySimulator? simulator,
    QrEncoder? encoder,
  })  : _batchExporter = batchExporter ?? const BatchExporter(),
        _simulator = simulator ?? const ScannabilitySimulator(),
        _encoder = encoder ?? const QrEncoder() {
    // Pre-populate with standard asset tags preset for instant preview
    loadAssetTagsPreset();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<BatchItemRequest> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  int get processedCount => _processedCount;
  int get successCount => _successCount;
  int get failureCount => _failureCount;
  List<String> get errors => List.unmodifiable(_errors);
  Uint8List? get lastZipBytes => _lastZipBytes;
  String? get lastZipName => _lastZipName;
  int? get lastZipSize => _lastZipSize;
  String? get lastZipSha256 => _lastZipSha256;
  ExportFormat get selectedFormat => _selectedFormat;

  ScannabilityReport? getScannability(String id) => _scannabilityReports[id];

  void setSelectedFormat(ExportFormat format) {
    if (_selectedFormat != format) {
      _selectedFormat = format;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Item Management
  // ---------------------------------------------------------------------------

  void addItem(BatchItemRequest item) {
    _items.removeWhere((existing) => existing.id == item.id);
    _items.add(item);
    _evaluateSingleScannability(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _scannabilityReports.remove(id);
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    _scannabilityReports.clear();
    _errors.clear();
    _processedCount = 0;
    _successCount = 0;
    _failureCount = 0;
    _progress = 0.0;
    _lastZipBytes = null;
    _lastZipName = null;
    _lastZipSize = null;
    _lastZipSha256 = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Presets
  // ---------------------------------------------------------------------------

  void loadAssetTagsPreset() {
    clearItems();
    final sampleItems = [
      const BatchItemRequest(
        id: 'ASSET-CORP-001',
        content: 'https://inventory.corp.local/asset/ASSET-CORP-001',
        title: 'MacBook Pro M3 Max',
        subtitle: 'DevOps Primary Machine',
        templateId: 'corporateNavy',
      ),
      const BatchItemRequest(
        id: 'ASSET-CORP-002',
        content: 'https://inventory.corp.local/asset/ASSET-CORP-002',
        title: 'Dell PowerEdge R760',
        subtitle: 'Rack 42 Node 03',
        templateId: 'highContrastMono',
      ),
      const BatchItemRequest(
        id: 'ASSET-CORP-003',
        content: 'https://inventory.corp.local/asset/ASSET-CORP-003',
        title: 'Cisco Catalyst 9300',
        subtitle: 'Core Switch Alpha',
        templateId: 'emeraldTrust',
      ),
      const BatchItemRequest(
        id: 'ASSET-CORP-004',
        content: 'https://inventory.corp.local/asset/ASSET-CORP-004',
        title: 'YubiKey 5C FIPS',
        subtitle: 'Hardware Auth Token',
        templateId: 'cyberpunkNeon',
      ),
      const BatchItemRequest(
        id: 'ASSET-CORP-005',
        content: 'https://inventory.corp.local/asset/ASSET-CORP-005',
        title: 'Ubiquiti UniFi 7 Pro',
        subtitle: 'Ceiling AP Floor 3',
        templateId: 'corporateNavy',
      ),
    ];
    for (final item in sampleItems) {
      _items.add(item);
      _evaluateSingleScannability(item);
    }
    notifyListeners();
  }

  void loadEmployeeBadgesPreset() {
    clearItems();
    final sampleItems = [
      const BatchItemRequest(
        id: 'EMP-9001',
        content: 'vcard:BEGIN:VCARD\nVERSION:4.0\nFN:Elena Rostova\nTITLE:Chief Security Officer\nEND:VCARD',
        title: 'Elena Rostova',
        subtitle: 'Chief Security Officer',
        templateId: 'emeraldTrust',
      ),
      const BatchItemRequest(
        id: 'EMP-9002',
        content: 'vcard:BEGIN:VCARD\nVERSION:4.0\nFN:Marcus Chen\nTITLE:Principal Architect\nEND:VCARD',
        title: 'Marcus Chen',
        subtitle: 'Principal Architect',
        templateId: 'corporateNavy',
      ),
      const BatchItemRequest(
        id: 'EMP-9003',
        content: 'vcard:BEGIN:VCARD\nVERSION:4.0\nFN:Sarah Connor\nTITLE:Lead Pen-Tester\nEND:VCARD',
        title: 'Sarah Connor',
        subtitle: 'Lead Pen-Tester',
        templateId: 'cyberpunkNeon',
      ),
      const BatchItemRequest(
        id: 'EMP-9004',
        content: 'vcard:BEGIN:VCARD\nVERSION:4.0\nFN:Devon Vance\nTITLE:Infrastructure Lead\nEND:VCARD',
        title: 'Devon Vance',
        subtitle: 'Infrastructure Lead',
        templateId: 'highContrastMono',
      ),
    ];
    for (final item in sampleItems) {
      _items.add(item);
      _evaluateSingleScannability(item);
    }
    notifyListeners();
  }

  void loadWifiHotspotsPreset() {
    clearItems();
    final sampleItems = [
      const BatchItemRequest(
        id: 'WIFI-HQ-GUEST',
        content: 'WIFI:S:CORP-GUEST;T:WPA;P:GuestSecure2026!;;',
        title: 'CORP Guest WiFi',
        subtitle: 'HQ Reception & Cafeteria',
        templateId: 'cyberpunkNeon',
      ),
      const BatchItemRequest(
        id: 'WIFI-HQ-SECURE',
        content: 'WIFI:S:CORP-INTERNAL-5G;T:WPA;P:K9#mQ8\$zL1!wX7;;',
        title: 'CORP Internal 5G',
        subtitle: 'Encrypted WPA3 Staff Only',
        templateId: 'emeraldTrust',
      ),
      const BatchItemRequest(
        id: 'WIFI-HQ-LAB',
        content: 'WIFI:S:IOT-HARDWARE-ISOLATED;T:WPA;P:HardwareTestNet2026;;',
        title: 'IoT Isolated Testnet',
        subtitle: 'Hardware R&D Lab',
        templateId: 'corporateNavy',
      ),
    ];
    for (final item in sampleItems) {
      _items.add(item);
      _evaluateSingleScannability(item);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CSV & JSON Parsers
  // ---------------------------------------------------------------------------

  /// Parses CSV formatted text: `id,content,title,subtitle,templateId,foregroundColorHex,backgroundColorHex`
  int parseCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent.trim());
    if (lines.isEmpty) return 0;

    var added = 0;
    var startIndex = 0;

    // Check if line 0 is a header
    if (lines.first.toLowerCase().contains('content') ||
        lines.first.toLowerCase().contains('id')) {
      startIndex = 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _splitCsvLine(line);
      if (cols.isEmpty) continue;

      final id = cols.isNotEmpty && cols[0].isNotEmpty
          ? cols[0]
          : 'item_${DateTime.now().millisecondsSinceEpoch}_$i';
      final content = cols.length > 1 ? cols[1] : cols[0];
      final title = cols.length > 2 && cols[2].isNotEmpty ? cols[2] : null;
      final subtitle = cols.length > 3 && cols[3].isNotEmpty ? cols[3] : null;
      final templateId = cols.length > 4 && cols[4].isNotEmpty ? cols[4] : null;

      int? fg;
      int? bg;
      if (cols.length > 5 && cols[5].isNotEmpty) {
        fg = _parseColor(cols[5]);
      }
      if (cols.length > 6 && cols[6].isNotEmpty) {
        bg = _parseColor(cols[6]);
      }

      final req = BatchItemRequest(
        id: id,
        content: content,
        title: title,
        subtitle: subtitle,
        templateId: templateId,
        foregroundColorHex: fg,
        backgroundColorHex: bg,
      );

      _items.removeWhere((e) => e.id == id);
      _items.add(req);
      _evaluateSingleScannability(req);
      added++;
    }

    notifyListeners();
    return added;
  }

  /// Parses JSON array formatted string.
  int parseJson(String jsonContent) {
    final trimmed = jsonContent.trim();
    if (trimmed.isEmpty) return 0;

    final decoded = jsonDecode(trimmed);
    if (decoded is! List) return 0;

    var added = 0;
    for (final element in decoded) {
      if (element is Map<String, dynamic>) {
        final req = BatchItemRequest.fromJson(element);
        _items.removeWhere((e) => e.id == req.id);
        _items.add(req);
        _evaluateSingleScannability(req);
        added++;
      }
    }

    notifyListeners();
    return added;
  }

  // ---------------------------------------------------------------------------
  // Batch Generation & ZIP Compilation
  // ---------------------------------------------------------------------------

  /// Generates the QR batch bundle and compiles into a pure-Dart PKZIP archive.
  Future<QrBatchExportBundle?> generateBatch({ExportFormat? format}) async {
    if (_items.isEmpty || _isProcessing) return null;

    final fmt = format ?? _selectedFormat;
    _isProcessing = true;
    _progress = 0.1;
    _errors.clear();
    _processedCount = 0;
    _successCount = 0;
    _failureCount = 0;
    notifyListeners();

    try {
      final bundle = await _batchExporter.exportBatch(
        requests: _items,
        format: fmt,
      );

      _processedCount = _items.length;
      _successCount = bundle.successCount;
      _failureCount = bundle.failureCount;
      _errors.addAll(bundle.errors);

      final zipBytes = bundle.toZipArchive();
      _lastZipBytes = zipBytes;
      _lastZipName = 'qr_batch_${fmt.name}_${DateTime.now().millisecondsSinceEpoch}.zip';
      _lastZipSize = zipBytes.length;

      // SHA-256 fingerprint of the archive
      final digest = sha256.convert(zipBytes);
      _lastZipSha256 = digest.toString();

      _progress = 1.0;
      _isProcessing = false;
      notifyListeners();
      return bundle;
    } catch (e) {
      _errors.add('Batch generation failed: $e');
      _failureCount = _items.length;
      _isProcessing = false;
      _progress = 0.0;
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  void _evaluateSingleScannability(BatchItemRequest item) {
    try {
      final matrix = _encoder.encode(item.content);
      final colorConfig = QrColorConfig(
        foregroundColorHex: item.foregroundColorHex ?? 0xFF00E5FF,
        backgroundColorHex: item.backgroundColorHex ?? 0xFF0A0E17,
      );
      final report = _simulator.simulate(
        matrix: matrix,
        colorConfig: colorConfig,
      );
      _scannabilityReports[item.id] = report;
    } catch (_) {
      // Ignored for invalid temporary payloads
    }
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  static int? _parseColor(String val) {
    try {
      final clean = val.replaceAll('#', '').replaceFirst('0x', '');
      if (clean.length == 6) {
        return int.parse('FF$clean', radix: 16);
      }
      return int.parse(clean, radix: 16);
    } catch (_) {
      return null;
    }
  }
}
