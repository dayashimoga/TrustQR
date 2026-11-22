import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';

/// State coordinator for the Admin QR Studio.
///
/// Manages payload models across all 15 formats, artistic styling,
/// real-time Scannability simulations, Ed25519 TrustQR institutional signing,
/// and multi-format exports (PNG, SVG, PDF, BMP).
class StudioController extends ChangeNotifier {
  final ArtisticQrGeneratorEngine generator;

  // Active payload selection
  QrPayloadType _payloadType = QrPayloadType.url;
  QrPayloadType get payloadType => _payloadType;

  // Manual raw payload override
  bool _useManualRawPayload = false;
  bool get useManualRawPayload => _useManualRawPayload;

  String _manualRawPayload = 'https://universal-qr.org/enterprise';
  String get manualRawPayload => _manualRawPayload;

  // Structured payload fields for 15 formats
  // 1. URL
  String urlAddress = 'https://universal-qr.org/enterprise';

  // 2. Wi-Fi
  String wifiSsid = 'Universal_HQ_Secure';
  String wifiPassword = 'CyberSecurity2026!';
  WifiAuthType wifiAuth = WifiAuthType.wpa2;
  bool wifiIsHidden = false;

  // 3. vCard
  String vcardFormattedName = 'Dr. Alex Vance';
  String vcardFirstName = 'Alex';
  String vcardLastName = 'Vance';
  String vcardOrg = 'Universal QR Systems';
  String vcardTitle = 'Chief Security Officer';
  String vcardPhone = '+1-555-0199';
  String vcardEmail = 'alex.vance@universal-qr.org';
  String vcardUrl = 'https://universal-qr.org';
  String vcardAddress = '100 Cyber Tower, Tech City';

  // 4. MeCard
  String mecardName = 'Vance,Alex';
  String mecardPhone = '+1-555-0199';
  String mecardEmail = 'alex.vance@universal-qr.org';
  String mecardUrl = 'https://universal-qr.org';

  // 5. Geo
  double geoLat = 37.7749;
  double geoLng = -122.4194;
  double? geoAlt = 15.0;
  String geoQuery = 'Universal HQ';

  // 6. Event
  String eventSummary = 'Universal QR Global Keynote 2026';
  DateTime eventStart = DateTime.utc(2026, 12, 1, 10, 0);
  DateTime eventEnd = DateTime.utc(2026, 12, 1, 12, 0);
  String eventLocation = 'Auditorium Cyber Alpha';
  String eventDescription = 'Annual architecture and security release showcase.';

  // 7. Email
  String emailTo = 'security@universal-qr.org';
  String emailSubject = 'TrustQR Institutional Verification';
  String emailBody = 'Requesting cryptographic signature confirmation for fleet node.';

  // 8. SMS
  String smsPhone = '+1-555-0199';
  String smsMessage = 'TrustQR 2FA Code: 994821. Valid for 120s.';

  // 9. Tel
  String telPhone = '+1-555-0199';

  // 10. OTP / 2FA
  OtpType otpType = OtpType.totp;
  String otpAccount = 'cso@universal-qr.org';
  String otpSecret = 'JBSWY3DPEHPK3PXP';
  String otpIssuer = 'Universal QR Shield';
  OtpAlgorithm otpAlgorithm = OtpAlgorithm.sha256;
  int otpDigits = 6;
  int otpPeriod = 30;

  // 11. UPI
  String upiVpa = 'merchant@universalqr';
  String upiPayee = 'Universal QR Commerce Ltd';
  double upiAmount = 249.99;
  String upiCurrency = 'INR';
  String upiNote = 'Enterprise Studio Annual License';

  // 12. EPC
  String epcBic = 'UNIVDEFFXXX';
  String epcRecipient = 'Universal QR Europe GmbH';
  String epcIban = 'DE89370400440532013000';
  double epcAmount = 499.00;
  String epcRemittance = 'INV-2026-9812-SEPA';

  // 13. Crypto
  CryptoCurrency cryptoCurrency = CryptoCurrency.bitcoin;
  String cryptoAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';
  String cryptoAmount = '0.045';
  String cryptoLabel = 'Enterprise Security Escrow';

  // 14. GS1
  String gs1Gtin = '01234567890128';
  String gs1Serial = 'SN8892104';
  String gs1Batch = 'LOT2026B';
  String gs1Expiry = '261231';

  // 15. PlainText
  String plainTextContent = 'Universal QR Code Platform — Cyber-Precision Glassmorphism 2026';

  // Artistic Customization
  QrModuleShape _moduleShape = QrModuleShape.cyberGrid;
  QrModuleShape get moduleShape => _moduleShape;

  QrErrorCorrectionLevel _errorCorrection = QrErrorCorrectionLevel.high;
  QrErrorCorrectionLevel get errorCorrection => _errorCorrection;

  int _foregroundColorHex = 0xFF00F5FF; // Neon Cyan
  int get foregroundColorHex => _foregroundColorHex;

  int _backgroundColorHex = 0xFF090D14; // Obsidian
  int get backgroundColorHex => _backgroundColorHex;

  QrGradientType _gradientType = QrGradientType.linear;
  QrGradientType get gradientType => _gradientType;

  int _gradientColor2Hex = 0xFFFF007F; // Neon Magenta
  int get gradientColor2Hex => _gradientColor2Hex;

  double _linearAngleDegrees = 45.0;
  double get linearAngleDegrees => _linearAngleDegrees;

  QrEyeFrameShape _eyeFrameShape = QrEyeFrameShape.circle;
  QrEyeFrameShape get eyeFrameShape => _eyeFrameShape;

  QrEyePupilShape _eyePupilShape = QrEyePupilShape.diamond;
  QrEyePupilShape get eyePupilShape => _eyePupilShape;

  int? _eyeFrameColorHex;
  int? get eyeFrameColorHex => _eyeFrameColorHex;

  int? _eyePupilColorHex;
  int? get eyePupilColorHex => _eyePupilColorHex;

  bool _hasLogo = false;
  bool get hasLogo => _hasLogo;

  double _logoSizeRatio = 0.20;
  double get logoSizeRatio => _logoSizeRatio;

  QrTemplate? _activeTemplate;
  QrTemplate? get activeTemplate => _activeTemplate;

  // Ed25519 TrustQR Institutional Cryptography
  bool _isTrustQrEnabled = false;
  bool get isTrustQrEnabled => _isTrustQrEnabled;

  String _authorityIssuer = 'Universal QR Institutional Authority';
  String get authorityIssuer => _authorityIssuer;

  String _keyId = 'admin-master-ed25519-01';
  String get keyId => _keyId;

  late CryptoKeyPair _activeKeyPair;
  CryptoKeyPair get activeKeyPair => _activeKeyPair;

  TrustQrEnvelope? _signedEnvelope;
  TrustQrEnvelope? get signedEnvelope => _signedEnvelope;

  TrustQrVerificationResult? _envelopeVerification;
  TrustQrVerificationResult? get envelopeVerification => _envelopeVerification;

  // Engine state outputs
  String _effectivePayload = '';
  String get effectivePayload => _effectivePayload;

  QrMatrix? _currentMatrix;
  QrMatrix? get currentMatrix => _currentMatrix;

  QrGeneratedImage? _currentImage;
  QrGeneratedImage? get currentImage => _currentImage;

  ScannabilityReport? _scannabilityReport;
  ScannabilityReport? get scannabilityReport => _scannabilityReport;

  String _matrixRepresentation = '';
  String get matrixRepresentation => _matrixRepresentation;

  // Export history / telemetry
  String? _lastExportFormat;
  String? get lastExportFormat => _lastExportFormat;

  int? _lastExportBytes;
  int? get lastExportBytes => _lastExportBytes;

  String? _lastExportMessage;
  String? get lastExportMessage => _lastExportMessage;

  StudioController({
    ArtisticQrGeneratorEngine? generator,
    CryptoKeyPair? keyPair,
  }) : generator = generator ?? const DefaultQrGeneratorEngine() {
    _activeKeyPair = keyPair ?? _generateEd25519Key(_keyId);
    recalculate();
  }

  static CryptoKeyPair _generateEd25519Key(String keyId) {
    final rng = math.Random(1337);
    final seed = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      seed[i] = rng.nextInt(256);
    }
    return Ed25519Engine.generateKeyPairFromSeed(seed, keyId: keyId);
  }

  // --- Mutators ---

  void setPayloadType(QrPayloadType type) {
    if (_payloadType == type) return;
    _payloadType = type;
    recalculate();
  }

  void setUseManualRawPayload(bool useManual) {
    _useManualRawPayload = useManual;
    recalculate();
  }

  void setManualRawPayload(String text) {
    _manualRawPayload = text;
    recalculate();
  }

  void setModuleShape(QrModuleShape shape) {
    _moduleShape = shape;
    _activeTemplate = null;
    recalculate();
  }

  void setErrorCorrection(QrErrorCorrectionLevel level) {
    _errorCorrection = level;
    recalculate();
  }

  void setColors({
    int? foreground,
    int? background,
    QrGradientType? gradient,
    int? gradientColor2,
    double? linearAngle,
  }) {
    if (foreground != null) _foregroundColorHex = foreground;
    if (background != null) _backgroundColorHex = background;
    if (gradient != null) _gradientType = gradient;
    if (gradientColor2 != null) _gradientColor2Hex = gradientColor2;
    if (linearAngle != null) _linearAngleDegrees = linearAngle;
    _activeTemplate = null;
    recalculate();
  }

  void setEyeStyle({
    QrEyeFrameShape? frameShape,
    QrEyePupilShape? pupilShape,
    int? frameColor,
    int? pupilColor,
  }) {
    if (frameShape != null) _eyeFrameShape = frameShape;
    if (pupilShape != null) _eyePupilShape = pupilShape;
    if (frameColor != null) _eyeFrameColorHex = frameColor;
    if (pupilColor != null) _eyePupilColorHex = pupilColor;
    _activeTemplate = null;
    recalculate();
  }

  void setLogoConfig({
    required bool hasLogo,
    double? sizeRatio,
  }) {
    _hasLogo = hasLogo;
    if (sizeRatio != null) _logoSizeRatio = sizeRatio.clamp(0.05, 0.30);
    _activeTemplate = null;
    recalculate();
  }

  void applyTemplate(QrTemplate template) {
    _activeTemplate = template;
    _moduleShape = template.moduleShape;
    _eyeFrameShape = template.eyeStyle.frameShape;
    _eyePupilShape = template.eyeStyle.pupilShape;
    _eyeFrameColorHex = template.eyeStyle.frameColorHex;
    _eyePupilColorHex = template.eyeStyle.pupilColorHex;
    _foregroundColorHex = template.colorConfig.foregroundColorHex;
    _backgroundColorHex = template.colorConfig.backgroundColorHex;
    _gradientType = template.colorConfig.gradientType;
    if (template.colorConfig.stops.length >= 2) {
      _gradientColor2Hex = template.colorConfig.stops[1].colorHex;
    }
    _linearAngleDegrees = template.colorConfig.linearAngleDegrees;
    _hasLogo = template.logoConfig != null;
    if (template.logoConfig != null) {
      _logoSizeRatio = template.logoConfig!.sizeRatio;
    }
    recalculate();
  }

  void setTrustQrEnabled(bool enabled) {
    _isTrustQrEnabled = enabled;
    recalculate();
  }

  void setAuthorityDetails({String? issuer, String? keyId}) {
    if (issuer != null) _authorityIssuer = issuer;
    if (keyId != null) {
      _keyId = keyId;
      _activeKeyPair = _generateEd25519Key(_keyId);
    }
    recalculate();
  }

  // --- Payload Construction ---

  QrPayload buildStructuredPayload() {
    switch (_payloadType) {
      case QrPayloadType.url:
        return UrlPayload(uri: Uri.parse(urlAddress));
      case QrPayloadType.wifi:
        return WifiPayload(
          ssid: wifiSsid,
          password: wifiPassword,
          authType: wifiAuth,
          isHidden: wifiIsHidden,
        );
      case QrPayloadType.vcard:
        return VCardPayload(
          formattedName: vcardFormattedName,
          firstName: vcardFirstName.isNotEmpty ? vcardFirstName : null,
          lastName: vcardLastName.isNotEmpty ? vcardLastName : null,
          organization: vcardOrg.isNotEmpty ? vcardOrg : null,
          title: vcardTitle.isNotEmpty ? vcardTitle : null,
          phoneNumbers: vcardPhone.isNotEmpty ? [vcardPhone] : [],
          emails: vcardEmail.isNotEmpty ? [vcardEmail] : [],
          urls: vcardUrl.isNotEmpty ? [vcardUrl] : [],
          addresses: vcardAddress.isNotEmpty ? [vcardAddress] : [],
        );
      case QrPayloadType.mecard:
        return MeCardPayload(
          name: mecardName,
          telephone: mecardPhone.isNotEmpty ? mecardPhone : null,
          email: mecardEmail.isNotEmpty ? mecardEmail : null,
          url: mecardUrl.isNotEmpty ? mecardUrl : null,
        );
      case QrPayloadType.geo:
        return GeoPayload(
          latitude: geoLat,
          longitude: geoLng,
          altitude: geoAlt,
          query: geoQuery.isNotEmpty ? geoQuery : null,
        );
      case QrPayloadType.event:
        return EventPayload(
          summary: eventSummary,
          dtStart: eventStart,
          dtEnd: eventEnd,
          location: eventLocation.isNotEmpty ? eventLocation : null,
          description: eventDescription.isNotEmpty ? eventDescription : null,
        );
      case QrPayloadType.email:
        return EmailPayload(
          to: emailTo,
          subject: emailSubject.isNotEmpty ? emailSubject : null,
          body: emailBody.isNotEmpty ? emailBody : null,
        );
      case QrPayloadType.sms:
        return SmsPayload(
          phoneNumber: smsPhone,
          message: smsMessage.isNotEmpty ? smsMessage : null,
        );
      case QrPayloadType.tel:
        return TelPayload(phoneNumber: telPhone);
      case QrPayloadType.otpauth:
        return OtpAuthPayload(
          otpType: otpType,
          accountName: otpAccount,
          secret: otpSecret,
          issuer: otpIssuer.isNotEmpty ? otpIssuer : null,
          algorithm: otpAlgorithm,
          digits: otpDigits,
          period: otpPeriod,
        );
      case QrPayloadType.upi:
        return UpiPaymentPayload(
          payeeVpa: upiVpa,
          payeeName: upiPayee,
          amount: upiAmount,
          currency: upiCurrency,
          transactionNote: upiNote.isNotEmpty ? upiNote : null,
        );
      case QrPayloadType.epc:
        return EpcPaymentPayload(
          bic: epcBic,
          recipientName: epcRecipient,
          iban: epcIban,
          amount: epcAmount,
          remittanceInfo: epcRemittance.isNotEmpty ? epcRemittance : null,
        );
      case QrPayloadType.crypto:
        return CryptoPaymentPayload(
          currency: cryptoCurrency,
          address: cryptoAddress,
          amount: cryptoAmount.isNotEmpty ? cryptoAmount : null,
          label: cryptoLabel.isNotEmpty ? cryptoLabel : null,
        );
      case QrPayloadType.gs1:
        return Gs1DigitalLinkPayload(
          gtin: gs1Gtin,
          serialNumber: gs1Serial.isNotEmpty ? gs1Serial : null,
          batchLot: gs1Batch.isNotEmpty ? gs1Batch : null,
          expiryDate: gs1Expiry.isNotEmpty ? gs1Expiry : null,
        );
      case QrPayloadType.plainText:
        return PlainTextPayload(text: plainTextContent);
    }
  }

  // --- Recalculate State ---

  void recalculate() {
    // 1. Resolve raw payload
    final rawText = _useManualRawPayload
        ? _manualRawPayload
        : buildStructuredPayload().toRawPayload();

    // 2. Handle TrustQR Signing
    if (_isTrustQrEnabled) {
      _signedEnvelope = TrustQrEnvelope.sign(
        issuer: _authorityIssuer,
        payload: rawText,
        privateKey: _activeKeyPair.privateKey,
        createdAt: DateTime.now().toUtc(),
      );
      _envelopeVerification = _signedEnvelope!.verify(publicKey: _activeKeyPair.publicKey);
      _effectivePayload = _signedEnvelope!.toUriString();
    } else {
      _signedEnvelope = null;
      _envelopeVerification = null;
      _effectivePayload = rawText;
    }

    // 3. Resolve Color Config
    final QrColorConfig colorConfig;
    if (_gradientType == QrGradientType.linear) {
      colorConfig = QrColorConfig.linear(
        [
          QrColorStop(offset: 0.0, colorHex: _foregroundColorHex),
          QrColorStop(offset: 1.0, colorHex: _gradientColor2Hex),
        ],
        angleDegrees: _linearAngleDegrees,
        backgroundHex: _backgroundColorHex,
      );
    } else if (_gradientType == QrGradientType.radial) {
      colorConfig = QrColorConfig.radial(
        [
          QrColorStop(offset: 0.0, colorHex: _foregroundColorHex),
          QrColorStop(offset: 1.0, colorHex: _gradientColor2Hex),
        ],
        backgroundHex: _backgroundColorHex,
      );
    } else {
      colorConfig = QrColorConfig.solid(
        _foregroundColorHex,
        backgroundHex: _backgroundColorHex,
      );
    }

    // 4. Resolve Eye Style
    final eyeStyle = QrEyeStyle(
      frameShape: _eyeFrameShape,
      pupilShape: _eyePupilShape,
      frameColorHex: _eyeFrameColorHex,
      pupilColorHex: _eyePupilColorHex,
    );

    // 5. Resolve Logo Config
    final QrLogoConfig? logoConfig = _hasLogo
        ? QrLogoConfig(
            sizeRatio: _logoSizeRatio,
            quietZoneModules: 1,
            clearUnderlyingModules: true,
          )
        : null;

    // 6. Generate Matrix
    try {
      _currentMatrix = generator.generateMatrix(
        _effectivePayload,
        errorCorrection: _errorCorrection,
        logoConfig: logoConfig,
      );

      // 7. Generate Styled Raster Image
      _currentImage = generator.generateStyledImage(
        _effectivePayload,
        moduleShape: _moduleShape,
        colorConfig: colorConfig,
        eyeStyle: eyeStyle,
        logoConfig: logoConfig,
        errorCorrection: _errorCorrection,
      );

      // 8. Run Scannability Simulation
      _scannabilityReport = generator.simulateScannability(
        _effectivePayload,
        moduleShape: _moduleShape,
        colorConfig: colorConfig,
        eyeStyle: eyeStyle,
        logoConfig: logoConfig,
        errorCorrection: _errorCorrection,
      );

      // 9. Matrix ASCII representation for accessibility / logging / tests
      _matrixRepresentation = generator.generateMatrixRepresentation(
        _effectivePayload,
        QrCustomizationOptions(
          moduleShape: _moduleShape,
          errorCorrection: _errorCorrection,
          foregroundColorHex: _foregroundColorHex,
          backgroundColorHex: _backgroundColorHex,
          hasEmbeddedLogo: _hasLogo,
          logoOcclusionPercentage: _hasLogo ? _logoSizeRatio : 0.0,
        ),
      );
    } catch (e) {
      // In case of error
      _matrixRepresentation = '[ERROR: $e]';
    }

    notifyListeners();
  }

  // --- Export Actions ---

  Uint8List exportPng({int dpi = 300, int moduleSize = 10}) {
    final bytes = generator.exportPng(
      _effectivePayload,
      moduleShape: _moduleShape,
      colorConfig: _buildColorConfig(),
      eyeStyle: _buildEyeStyle(),
      logoConfig: _buildLogoConfig(),
      errorCorrection: _errorCorrection,
      dpi: dpi,
      moduleSize: moduleSize,
    );
    _lastExportFormat = 'PNG';
    _lastExportBytes = bytes.length;
    _lastExportMessage = 'Generated ${dpi}DPI PNG (${bytes.length} bytes)';
    notifyListeners();
    return bytes;
  }

  String exportSvg({int moduleSize = 10}) {
    final svg = generator.exportSvg(
      _effectivePayload,
      moduleShape: _moduleShape,
      colorConfig: _buildColorConfig(),
      eyeStyle: _buildEyeStyle(),
      logoConfig: _buildLogoConfig(),
      errorCorrection: _errorCorrection,
      moduleSize: moduleSize,
    );
    _lastExportFormat = 'SVG';
    _lastExportBytes = svg.length;
    _lastExportMessage = 'Generated Vector SVG (${svg.length} chars)';
    notifyListeners();
    return svg;
  }

  Uint8List exportPdf({PdfPageLayout layout = PdfPageLayout.singleLabel}) {
    final bytes = generator.exportPdf(
      _effectivePayload,
      colorConfig: _buildColorConfig(),
      errorCorrection: _errorCorrection,
      layout: layout,
      title: _isTrustQrEnabled ? 'TrustQR Verified Code' : 'Universal QR Studio',
      subtitle: _authorityIssuer,
    );
    _lastExportFormat = 'PDF';
    _lastExportBytes = bytes.length;
    _lastExportMessage = 'Generated Print-Ready PDF (${bytes.length} bytes)';
    notifyListeners();
    return bytes;
  }

  Uint8List exportBmp({int moduleSize = 10}) {
    final bytes = generator.generateBmp(
      _effectivePayload,
      moduleShape: _moduleShape,
      colorConfig: _buildColorConfig(),
      eyeStyle: _buildEyeStyle(),
      logoConfig: _buildLogoConfig(),
      errorCorrection: _errorCorrection,
      moduleSize: moduleSize,
    );
    _lastExportFormat = 'BMP';
    _lastExportBytes = bytes.length;
    _lastExportMessage = 'Generated 24-bit BMP (${bytes.length} bytes)';
    notifyListeners();
    return bytes;
  }

  QrColorConfig _buildColorConfig() {
    if (_gradientType == QrGradientType.linear) {
      return QrColorConfig.linear(
        [
          QrColorStop(offset: 0.0, colorHex: _foregroundColorHex),
          QrColorStop(offset: 1.0, colorHex: _gradientColor2Hex),
        ],
        angleDegrees: _linearAngleDegrees,
        backgroundHex: _backgroundColorHex,
      );
    } else if (_gradientType == QrGradientType.radial) {
      return QrColorConfig.radial(
        [
          QrColorStop(offset: 0.0, colorHex: _foregroundColorHex),
          QrColorStop(offset: 1.0, colorHex: _gradientColor2Hex),
        ],
        backgroundHex: _backgroundColorHex,
      );
    }
    return QrColorConfig.solid(
      _foregroundColorHex,
      backgroundHex: _backgroundColorHex,
    );
  }

  QrEyeStyle _buildEyeStyle() {
    return QrEyeStyle(
      frameShape: _eyeFrameShape,
      pupilShape: _eyePupilShape,
      frameColorHex: _eyeFrameColorHex,
      pupilColorHex: _eyePupilColorHex,
    );
  }

  QrLogoConfig? _buildLogoConfig() {
    return _hasLogo
        ? QrLogoConfig(
            sizeRatio: _logoSizeRatio,
            quietZoneModules: 1,
            clearUnderlyingModules: true,
          )
        : null;
  }
}
