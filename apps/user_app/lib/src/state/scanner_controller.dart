import 'package:flutter/foundation.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

/// Central state controller managing the scanner viewfinder, pipeline execution,
/// threat assessment results, multi-QR candidate selection, and vault persistence.
class ScannerController extends ChangeNotifier {
  final ScanToVaultPipeline pipeline;

  ScannerHudState _hudState = ScannerHudState.idle;
  PipelineScanResult? _activeScanResult;
  List<PipelineScanResult> _multiQrCandidates = const [];
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _isIncognito = false;
  String? _lastErrorMessage;

  ScannerController({
    ScanToVaultPipeline? pipeline,
  }) : pipeline = pipeline ??
            ScanToVaultPipeline(
              scanner: UniversalQrScannerEngine(),
              firewall: QrThreatFirewall(),
              vault: QrVault.inMemory(
                integrityKey: CryptoKeyPair.generateHmacKey().privateKey,
              ),
            ) {
    pipeline?.vault?.init();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  ScannerHudState get hudState => _hudState;
  PipelineScanResult? get activeScanResult => _activeScanResult;
  List<PipelineScanResult> get multiQrCandidates => _multiQrCandidates;
  bool get isProcessing => _isProcessing;
  bool get isTorchOn => _isTorchOn;
  bool get isIncognito => _isIncognito;
  String? get lastErrorMessage => _lastErrorMessage;
  QrVault? get vault => pipeline.vault;

  // ---------------------------------------------------------------------------
  // Scanning Pipelines
  // ---------------------------------------------------------------------------

  /// Scans and audits a raw string payload.
  Future<PipelineScanResult?> scanRawString(
    String raw, {
    String? title,
    String? notes,
  }) async {
    if (raw.trim().isEmpty) return null;
    await pipeline.vault?.init();
    _setProcessing(true);
    _lastErrorMessage = null;

    try {
      final opts = PipelineOptions(
        saveToVault: !_isIncognito,
        blockVaultOnCriticalThreat: true,
      );

      final result = await pipeline.processRawString(
        raw.trim(),
        options: opts,
        title: title,
        notes: notes,
      );

      _updateStateFromResult(result);
      return result;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _hudState = ScannerHudState.threat;
      notifyListeners();
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Scans and audits a decoded frame or screenshot buffer.
  Future<PipelineScanResult?> scanImageBuffer(
    ImageBuffer buffer, {
    String? title,
    String? notes,
  }) async {
    await pipeline.vault?.init();
    _setProcessing(true);
    _lastErrorMessage = null;

    try {
      final opts = PipelineOptions(
        saveToVault: !_isIncognito,
        blockVaultOnCriticalThreat: true,
      );

      final result = await pipeline.processImageBuffer(
        buffer,
        options: opts,
        title: title,
        notes: notes,
      );

      if (result == null) {
        _hudState = ScannerHudState.idle;
        _lastErrorMessage = 'No QR code detected in viewfinder frame.';
        notifyListeners();
        return null;
      }

      _updateStateFromResult(result);
      return result;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _hudState = ScannerHudState.threat;
      notifyListeners();
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Scans and audits raw file bytes (e.g. BMP/PNG).
  Future<PipelineScanResult?> scanFileBytes(
    Uint8List fileBytes, {
    String? title,
    String? notes,
  }) async {
    if (fileBytes.isEmpty) return null;
    await pipeline.vault?.init();
    _setProcessing(true);
    _lastErrorMessage = null;

    try {
      final opts = PipelineOptions(
        saveToVault: !_isIncognito,
        blockVaultOnCriticalThreat: true,
      );

      final result = await pipeline.processFileBytes(
        fileBytes,
        options: opts,
        title: title,
        notes: notes,
      );

      if (result == null) {
        _hudState = ScannerHudState.idle;
        _lastErrorMessage = 'No decodable QR matrix found in file.';
        notifyListeners();
        return null;
      }

      _updateStateFromResult(result);
      return result;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _hudState = ScannerHudState.threat;
      notifyListeners();
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Scans a multi-QR composite image containing potentially multiple codes.
  Future<List<PipelineScanResult>> scanMultiQrBuffer(ImageBuffer buffer) async {
    _setProcessing(true);
    _lastErrorMessage = null;

    try {
      final opts = PipelineOptions(
        saveToVault: !_isIncognito,
        blockVaultOnCriticalThreat: true,
      );

      final results = await pipeline.processMultiQrImage(
        buffer,
        options: opts,
      );

      if (results.isEmpty) {
        _hudState = ScannerHudState.idle;
        _lastErrorMessage = 'No QR matrices detected in multi-QR image.';
        _multiQrCandidates = const [];
        notifyListeners();
        return const [];
      }

      if (results.length == 1) {
        _multiQrCandidates = const [];
        _updateStateFromResult(results.first);
      } else {
        _multiQrCandidates = results;
        _activeScanResult = null;
        _hudState = ScannerHudState.scanning;
        notifyListeners();
      }

      return results;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _hudState = ScannerHudState.threat;
      notifyListeners();
      return const [];
    } finally {
      _setProcessing(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Candidate Selection & Dismissal
  // ---------------------------------------------------------------------------

  /// Selects a specific candidate from a multi-QR detection session.
  void selectMultiQrCandidate(PipelineScanResult candidate) {
    _multiQrCandidates = const [];
    _updateStateFromResult(candidate);
  }

  /// Dismisses the active threat inspection result and returns reticle to idle.
  void dismissActiveResult() {
    _activeScanResult = null;
    _multiQrCandidates = const [];
    _hudState = ScannerHudState.idle;
    notifyListeners();
  }

  /// Sets mock multi-QR candidates for UI testing.
  @visibleForTesting
  void setCandidatesForTesting(List<PipelineScanResult> candidates) {
    _multiQrCandidates = candidates;
    _activeScanResult = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Toggles & Actions
  // ---------------------------------------------------------------------------

  /// Toggles the camera torch / flashlight.
  void toggleTorch() {
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  /// Toggles privacy incognito mode (bypasses vault recording).
  void toggleIncognito() {
    _isIncognito = !_isIncognito;
    notifyListeners();
  }

  /// Explicitly persists an active scan result into the vault (e.g. override quarantine).
  Future<QrVaultItem?> saveCurrentToVault({
    String? title,
    String? notes,
    List<String>? tags,
  }) async {
    if (_activeScanResult == null || pipeline.vault == null) return null;
    await pipeline.vault?.init();

    final result = _activeScanResult!;
    final item = await pipeline.vault!.recordItem(
      rawContent: result.rawContent,
      payloadType: result.payload.type,
      threatLevel: result.threatAssessment.threatLevel,
      safetyScore: result.threatAssessment.safetyScore,
      title: title ?? result.payload.type.name.toUpperCase(),
      notes: notes,
      tags: tags ?? ['manual-save', result.payload.type.name],
    );

    notifyListeners();
    return item;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setProcessing(bool val) {
    _isProcessing = val;
    if (val) {
      _hudState = ScannerHudState.scanning;
    }
    notifyListeners();
  }

  void _updateStateFromResult(PipelineScanResult result) {
    _activeScanResult = result;
    final score = result.threatAssessment.safetyScore;

    if (!result.isAllowed || result.threatAssessment.isCritical || score < 50) {
      _hudState = ScannerHudState.threat;
    } else if (score < 80) {
      _hudState = ScannerHudState.warning;
    } else {
      _hudState = ScannerHudState.safe;
    }

    notifyListeners();
  }
}
