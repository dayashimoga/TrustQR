import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../reticle/hud_scanner_reticle.dart';

/// Supported language codes for the Cyber-Precision QR ecosystem.
enum CyberLocaleCode {
  en,
  es,
  fr,
  de,
  hi,
  ja,
}

/// Comprehensive multi-language localization dictionary for the Universal QR platform.
///
/// Supports 6 global languages:
/// - English (`en`)
/// - Spanish (`es`)
/// - French (`fr`)
/// - German (`de`)
/// - Hindi (`hi`)
/// - Japanese (`ja`)
class CyberLocalizations {
  final Locale locale;

  const CyberLocalizations(this.locale);

  /// Supported locales list for [MaterialApp.supportedLocales].
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('hi'),
    Locale('ja'),
  ];

  /// Static delegate instance for [MaterialApp.localizationsDelegates].
  static const LocalizationsDelegate<CyberLocalizations> delegate =
      _CyberLocalizationsDelegate();

  /// Obtains the [CyberLocalizations] instance from the widget tree,
  /// falling back to English if not present.
  static CyberLocalizations of(BuildContext context) {
    return Localizations.of<CyberLocalizations>(context, CyberLocalizations) ??
        const CyberLocalizations(Locale('en'));
  }

  String get languageCode => locale.languageCode;

  // ---------------------------------------------------------------------------
  // Application & Brand Titles
  // ---------------------------------------------------------------------------

  String get appName => _select({
        'en': 'Universal QR',
        'es': 'QR Universal',
        'fr': 'QR Universel',
        'de': 'Universeller QR',
        'hi': 'यूनिवर्सल क्यूआर',
        'ja': 'ユニバーサルQR',
      });

  String get adminAppTitle => _select({
        'en': 'Universal QR Studio & Fleet Admin',
        'es': 'Estudio QR Universal y Administración de Flota',
        'fr': 'Studio QR Universel et Gestion de Flotte',
        'de': 'Universelles QR-Studio & Flottenverwaltung',
        'hi': 'यूनिवर्सल क्यूआर स्टूडियो एवं बेड़ा प्रशासन',
        'ja': 'ユニバーサルQRスタジオ＆フリート管理',
      });

  String get userAppTitle => _select({
        'en': 'Universal QR Scanner & Security',
        'es': 'Escáner QR Universal y Seguridad',
        'fr': 'Scanner QR Universel et Sécurité',
        'de': 'Universeller QR-Scanner & Sicherheit',
        'hi': 'यूनिवर्सल क्यूआर स्कैनर एवं सुरक्षा',
        'ja': 'ユニバーサルQRスキャナー＆セキュリティ',
      });

  // ---------------------------------------------------------------------------
  // Scanner Viewfinder & HUD Reticle
  // ---------------------------------------------------------------------------

  String get reticleIdle => _select({
        'en': 'READY // ALIGN QR CODE',
        'es': 'LISTO // ALINEAR CÓDIGO QR',
        'fr': 'PRÊT // ALIGNER LE CODE QR',
        'de': 'BEREIT // QR-CODE AUSRICHTEN',
        'hi': 'तैयार // क्यूआर कोड संरेखित करें',
        'ja': '準備完了 // QRコードを合わせてください',
      });

  String get reticleScanning => _select({
        'en': 'SCANNING // ZERO-TRUST FIREWALL ACTIVE',
        'es': 'ESCANEANDO // CORTAFUEGOS ZERO-TRUST ACTIVO',
        'fr': 'ANALYSE EN COURS // PARE-FEU ZERO-TRUST ACTIF',
        'de': 'SCANNT // ZERO-TRUST-FIREWALL AKTIV',
        'hi': 'स्कैनिंग // ज़ीरो-ट्रस्ट फ़ायरवॉल सक्रिय',
        'ja': 'スキャン中 // ゼロトラストファイアウォール有効',
      });

  String get reticleSafe => _select({
        'en': 'VERIFIED // SAFE PAYLOAD',
        'es': 'VERIFICADO // CONTENIDO SEGURO',
        'fr': 'VÉRIFIÉ // CHARGE SÉCURISÉE',
        'de': 'VERIFIZIERT // SICHERE NUTZLAST',
        'hi': 'सत्यापित // सुरक्षित पेलोड',
        'ja': '検証済み // 安全なペイロード',
      });

  String get reticleWarning => _select({
        'en': 'CAUTION // SUSPICIOUS ANOMALY',
        'es': 'PRECAUCIÓN // ANOMALÍA SOSPECHOSA',
        'fr': 'ATTENTION // ANOMALIE SUSPECTE',
        'de': 'ACHTUNG // VERDÄCHTIGE ANOMALIE',
        'hi': 'सावधानी // संदिग्ध विसंगति',
        'ja': '警告 // 不審な異常を検出',
      });

  String get reticleThreat => _select({
        'en': 'THREAT DETECTED // ACCESS QUARANTINED',
        'es': 'AMENAZA DETECTADA // ACCESO EN CUARENTENA',
        'fr': 'MENACE DÉTECTÉE // ACCÈS MIS EN QUARANTAINE',
        'de': 'BEDROHUNG ERKANNT // ZUGRIFF ISOLIERT',
        'hi': 'खतरा पाया गया // पहुंच संगरोधित',
        'ja': '脅威検出 // アクセス隔離済み',
      });

  String reticleStatus(ScannerHudState state) {
    switch (state) {
      case ScannerHudState.idle:
        return reticleIdle;
      case ScannerHudState.scanning:
        return reticleScanning;
      case ScannerHudState.safe:
        return reticleSafe;
      case ScannerHudState.warning:
        return reticleWarning;
      case ScannerHudState.threat:
        return reticleThreat;
    }
  }

  String get scanPrompt => _select({
        'en': 'Hold camera steady over QR code',
        'es': 'Mantenga la cámara fija sobre el código QR',
        'fr': 'Maintenez la caméra stable au-dessus du code QR',
        'de': 'Kamera ruhig über den QR-Code halten',
        'hi': 'कैमरा को क्यूआर कोड पर स्थिर रखें',
        'ja': 'QRコードの上にカメラを静止させてください',
      });

  String get laserSweepActive => _select({
        'en': 'Laser sweep active',
        'es': 'Barrido láser activo',
        'fr': 'Balayage laser actif',
        'de': 'Laserabtastung aktiv',
        'hi': 'लेज़र स्वीप सक्रिय',
        'ja': 'レーザースイープ動作中',
      });

  // ---------------------------------------------------------------------------
  // Threat Safety Score Gauge
  // ---------------------------------------------------------------------------

  String get threatScore => _select({
        'en': 'Threat Safety Score',
        'es': 'Puntuación de Seguridad',
        'fr': 'Score de Sécurité',
        'de': 'Sicherheitsbewertung',
        'hi': 'खतरा सुरक्षा स्कोर',
        'ja': '脅威安全性スコア',
      });

  String get threatSecure => _select({
        'en': 'SECURE',
        'es': 'SEGURO',
        'fr': 'SÉCURISÉ',
        'de': 'SICHER',
        'hi': 'सुरक्षित',
        'ja': '安全',
      });

  String get threatCaution => _select({
        'en': 'CAUTION',
        'es': 'PRECAUCIÓN',
        'fr': 'ATTENTION',
        'de': 'VORSICHT',
        'hi': 'सावधानी',
        'ja': '注意',
      });

  String get threatCritical => _select({
        'en': 'CRITICAL',
        'es': 'CRÍTICO',
        'fr': 'CRITIQUE',
        'de': 'KRITISCH',
        'hi': 'गंभीर',
        'ja': '危険',
      });

  String threatRating(double score) {
    if (score >= 80.0) return threatSecure;
    if (score >= 50.0) return threatCaution;
    return threatCritical;
  }

  String threatScoreReading(int score, String rating) => _select({
        'en': '$score out of 100, $rating',
        'es': '$score de 100, $rating',
        'fr': '$score sur 100, $rating',
        'de': '$score von 100, $rating',
        'hi': '100 में से $score, $rating',
        'ja': '100点中$score点, $rating',
      });

  // ---------------------------------------------------------------------------
  // TrustQR Cryptographic Badges
  // ---------------------------------------------------------------------------

  String get trustQrVerified => _select({
        'en': 'TRUSTQR VERIFIED',
        'es': 'TRUSTQR VERIFICADO',
        'fr': 'TRUSTQR VÉRIFIÉ',
        'de': 'TRUSTQR VERIFIZIERT',
        'hi': 'TRUSTQR सत्यापित',
        'ja': 'TRUSTQR 検証完了',
      });

  String get trustQrInvalid => _select({
        'en': 'SIGNATURE INVALID',
        'es': 'FIRMA NO VÁLIDA',
        'fr': 'SIGNATURE INVALIDE',
        'de': 'SIGNATUR UNGÜLTIG',
        'hi': 'हस्ताक्षर अमान्य',
        'ja': '署名が無効です',
      });

  String get trustQrIssuer => _select({
        'en': 'Institutional Authority',
        'es': 'Autoridad Institucional',
        'fr': 'Autorité Institutionnelle',
        'de': 'Institutionelle Behörde',
        'hi': 'संस्थागत प्राधिकरण',
        'ja': '機関認証局',
      });

  String get trustQrKeyId => _select({
        'en': 'KEY',
        'es': 'CLAVE',
        'fr': 'CLÉ',
        'de': 'SCHLÜSSEL',
        'hi': 'कुंजी',
        'ja': '鍵',
      });

  String get trustQrIssuedAt => _select({
        'en': 'Issued At',
        'es': 'Emitido el',
        'fr': 'Délivré le',
        'de': 'Ausgestellt am',
        'hi': 'जारी करने का समय',
        'ja': '発行日時',
      });

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  String get navScanner => _select({
        'en': 'Scanner',
        'es': 'Escáner',
        'fr': 'Scanner',
        'de': 'Scanner',
        'hi': 'स्कैनर',
        'ja': 'スキャナー',
      });

  String get navGenerator => _select({
        'en': 'Generator',
        'es': 'Generador',
        'fr': 'Générateur',
        'de': 'Generator',
        'hi': 'जनरेटर',
        'ja': 'ジェネレーター',
      });

  String get navVault => _select({
        'en': 'Vault',
        'es': 'Bóveda',
        'fr': 'Coffre',
        'de': 'Tresor',
        'hi': 'वॉल्ट',
        'ja': '保管庫',
      });

  String get navAnalytics => _select({
        'en': 'Analytics',
        'es': 'Analítica',
        'fr': 'Analytique',
        'de': 'Analytik',
        'hi': 'विश्लेषण',
        'ja': 'アナリティクス',
      });

  String get navSettings => _select({
        'en': 'Settings',
        'es': 'Ajustes',
        'fr': 'Paramètres',
        'de': 'Einstellungen',
        'hi': 'सेटिंग्स',
        'ja': '設定',
      });

  String get navBatch => _select({
        'en': 'Batch Studio',
        'es': 'Estudio por Lotes',
        'fr': 'Traitement par Lot',
        'de': 'Batch-Studio',
        'hi': 'बैच स्टूडियो',
        'ja': 'バッチスタジオ',
      });

  String get navHistory => _select({
        'en': 'History',
        'es': 'Historial',
        'fr': 'Historique',
        'de': 'Verlauf',
        'hi': 'इतिहास',
        'ja': '履歴',
      });

  String get navFavorites => _select({
        'en': 'Favorites',
        'es': 'Favoritos',
        'fr': 'Favoris',
        'de': 'Favoriten',
        'hi': 'पसंदीदा',
        'ja': 'お気に入り',
      });

  // ---------------------------------------------------------------------------
  // Common Actions & Buttons
  // ---------------------------------------------------------------------------

  String get buttonScan => _select({
        'en': 'Scan Now',
        'es': 'Escanear Ahora',
        'fr': 'Scanner',
        'de': 'Jetzt scannen',
        'hi': 'अब स्कैन करें',
        'ja': '今すぐスキャン',
      });

  String get buttonGenerate => _select({
        'en': 'Generate QR',
        'es': 'Generar QR',
        'fr': 'Générer QR',
        'de': 'QR generieren',
        'hi': 'क्यूआर बनाएं',
        'ja': 'QR生成',
      });

  String get buttonExport => _select({
        'en': 'Export',
        'es': 'Exportar',
        'fr': 'Exporter',
        'de': 'Exportieren',
        'hi': 'निर्यात करें',
        'ja': 'エクスポート',
      });

  String get buttonSave => _select({
        'en': 'Save to Vault',
        'es': 'Guardar en Bóveda',
        'fr': 'Enregistrer au Coffre',
        'de': 'Im Tresor speichern',
        'hi': 'वॉल्ट में सहेजें',
        'ja': '保管庫に保存',
      });

  String get buttonCancel => _select({
        'en': 'Cancel',
        'es': 'Cancelar',
        'fr': 'Annuler',
        'de': 'Abbrechen',
        'hi': 'रद्द करें',
        'ja': 'キャンセル',
      });

  String get buttonCopy => _select({
        'en': 'Copy to Clipboard',
        'es': 'Copiar al Portapapeles',
        'fr': 'Copier dans le Presse-papiers',
        'de': 'In Zwischenablage kopieren',
        'hi': 'क्लिपबोर्ड पर कॉपी करें',
        'ja': 'クリップボードにコピー',
      });

  String get buttonOpenUrl => _select({
        'en': 'Open Safe Link',
        'es': 'Abrir Enlace Seguro',
        'fr': 'Ouvrir le Lien Sécurisé',
        'de': 'Sicheren Link öffnen',
        'hi': 'सुरक्षित लिंक खोलें',
        'ja': '安全なリンクを開く',
      });

  String get buttonShare => _select({
        'en': 'Share',
        'es': 'Compartir',
        'fr': 'Partager',
        'de': 'Teilen',
        'hi': 'साझा करें',
        'ja': '共有',
      });

  String get buttonRetry => _select({
        'en': 'Retry',
        'es': 'Reintentar',
        'fr': 'Réessayer',
        'de': 'Wiederholen',
        'hi': 'पुनः प्रयास करें',
        'ja': '再試行',
      });

  String get buttonClose => _select({
        'en': 'Close',
        'es': 'Cerrar',
        'fr': 'Fermer',
        'de': 'Schließen',
        'hi': 'बंद करें',
        'ja': '閉じる',
      });

  String get buttonQuarantine => _select({
        'en': 'Quarantine Threat',
        'es': 'Poner Amenaza en Cuarentena',
        'fr': 'Mettre la Menace en Quarantaine',
        'de': 'Bedrohung isolieren',
        'hi': 'खतरे को संगरोध करें',
        'ja': '脅威を隔離',
      });

  // ---------------------------------------------------------------------------
  // Vault & Search
  // ---------------------------------------------------------------------------

  String get vaultSearchPlaceholder => _select({
        'en': 'Search scan history, payloads, tags...',
        'es': 'Buscar historial, contenidos, etiquetas...',
        'fr': 'Rechercher historique, contenus, tags...',
        'de': 'Verlauf, Inhalte, Tags durchsuchen...',
        'hi': 'स्कैन इतिहास, पेलोड, टैग खोजें...',
        'ja': 'スキャン履歴、ペイロード、タグを検索...',
      });

  String get vaultFilterAll => _select({
        'en': 'All Formats',
        'es': 'Todos los Formatos',
        'fr': 'Tous les Formats',
        'de': 'Alle Formate',
        'hi': 'सभी प्रारूप',
        'ja': 'すべての形式',
      });

  String get vaultExportJson => _select({
        'en': 'Export Vault (JSON)',
        'es': 'Exportar Bóveda (JSON)',
        'fr': 'Exporter le Coffre (JSON)',
        'de': 'Tresor exportieren (JSON)',
        'hi': 'वॉल्ट निर्यात करें (JSON)',
        'ja': '保管庫をエクスポート (JSON)',
      });

  String get vaultImportJson => _select({
        'en': 'Import Vault (JSON)',
        'es': 'Importar Bóveda (JSON)',
        'fr': 'Importer dans le Coffre (JSON)',
        'de': 'Tresor importieren (JSON)',
        'hi': 'वॉल्ट आयात करें (JSON)',
        'ja': '保管庫をインポート (JSON)',
      });

  String get vaultClearHistory => _select({
        'en': 'Clear History',
        'es': 'Borrar Historial',
        'fr': 'Effacer l\'Historique',
        'de': 'Verlauf löschen',
        'hi': 'इतिहास साफ़ करें',
        'ja': '履歴を消去',
      });

  String get vaultItemDeleted => _select({
        'en': 'Record deleted',
        'es': 'Registro eliminado',
        'fr': 'Enregistrement supprimé',
        'de': 'Eintrag gelöscht',
        'hi': 'रिकॉर्ड हटाया गया',
        'ja': 'レコードが削除されました',
      });

  // ---------------------------------------------------------------------------
  // WCAG Accessibility & Screen Reader Hints
  // ---------------------------------------------------------------------------

  String get a11yScannerReticle => _select({
        'en': 'QR Scanner Viewfinder',
        'es': 'Visor del Escáner QR',
        'fr': 'Viseur du Scanner QR',
        'de': 'QR-Scanner-Sucher',
        'hi': 'क्यूआर स्कैनर व्यूफ़ाइंडर',
        'ja': 'QRスキャナーファインダー',
      });

  String get a11yScannerReticleHint => _select({
        'en': 'Align QR code inside reticle tracking brackets to scan',
        'es': 'Alinee el código QR dentro de los corchetes para escanear',
        'fr': 'Alignez le code QR dans les repères de visée pour scanner',
        'de': 'Richten Sie den QR-Code innerhalb der Halterungen aus',
        'hi': 'स्कैन करने के लिए ब्रैकेट के अंदर क्यूआर कोड संरेखित करें',
        'ja': 'スキャンするにはブラケット内にQRコードを合わせてください',
      });

  String get a11yThreatGauge => _select({
        'en': 'Threat Safety Score Gauge',
        'es': 'Medidor de Seguridad contra Amenazas',
        'fr': 'Jauge de Sécurité contre les Menaces',
        'de': 'Bedrohungssicherheitsanzeige',
        'hi': 'खतरा सुरक्षा स्कोर गेज',
        'ja': '脅威安全性スコアゲージ',
      });

  String get a11yThreatGaugeHint => _select({
        'en': 'Visual indicator of payload risk level from 0 to 100',
        'es': 'Indicador visual del nivel de riesgo del contenido de 0 a 100',
        'fr': 'Indicateur visuel du niveau de risque de 0 à 100',
        'de': 'Visuelle Anzeige des Risikoniveaus von 0 bis 100',
        'hi': '0 से 100 तक पेलोड जोखिम स्तर का दृश्य संकेतक',
        'ja': '0から100までのペイロードリスクレベルの視覚的インジケータ',
      });

  String get a11yTrustBadge => _select({
        'en': 'TrustQR Cryptographic Authenticity Badge',
        'es': 'Insignia de Autenticidad Criptográfica TrustQR',
        'fr': 'Badge d\'Authenticité Cryptographique TrustQR',
        'de': 'Kryptografisches TrustQR-Authentizitätsabzeichen',
        'hi': 'TrustQR क्रिप्टोग्राफ़िक प्रामाणिकता बैज',
        'ja': 'TrustQR 暗号化真正性バッジ',
      });

  String get a11yTrustBadgeHint => _select({
        'en': 'Displays cryptographic Ed25519 institutional verification status',
        'es': 'Muestra el estado de verificación institucional criptográfica Ed25519',
        'fr': 'Affiche le statut de vérification cryptographique institutionnelle Ed25519',
        'de': 'Zeigt den institutionellen kryptografischen Ed25519-Verifikationsstatus an',
        'hi': 'क्रिप्टोग्राफ़िक Ed25519 संस्थागत सत्यापन स्थिति प्रदर्शित करता है',
        'ja': '暗号化Ed25519機関認証ステータスを表示します',
      });

  String get a11yLoading => _select({
        'en': 'Loading...',
        'es': 'Cargando...',
        'fr': 'Chargement...',
        'de': 'Laden...',
        'hi': 'लोड हो रहा है...',
        'ja': '読み込み中...',
      });

  String get a11yHighContrastActive => _select({
        'en': 'High-contrast mode enabled',
        'es': 'Modo de alto contraste activado',
        'fr': 'Mode contraste élevé activé',
        'de': 'Hoher Kontrastmodus aktiviert',
        'hi': 'उच्च कंट्रास्ट मोड सक्षम है',
        'ja': 'ハイコントラストモード有効',
      });

  String get a11yReducedMotionActive => _select({
        'en': 'Reduced motion mode enabled',
        'es': 'Modo de movimiento reducido activado',
        'fr': 'Mode mouvement réduit activé',
        'de': 'Reduzierte Bewegung aktiviert',
        'hi': 'घटी हुई गति मोड सक्षम है',
        'ja': '視覚効果の削減モード有効',
      });

  // ---------------------------------------------------------------------------
  // Internal Dictionary Resolution Helper
  // ---------------------------------------------------------------------------

  String _select(Map<String, String> translations) {
    return translations[locale.languageCode] ?? translations['en'] ?? '';
  }
}

class _CyberLocalizationsDelegate
    extends LocalizationsDelegate<CyberLocalizations> {
  const _CyberLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'de', 'hi', 'ja']
        .contains(locale.languageCode.toLowerCase());
  }

  @override
  Future<CyberLocalizations> load(Locale locale) {
    return SynchronousFuture<CyberLocalizations>(CyberLocalizations(locale));
  }

  @override
  bool shouldReload(_CyberLocalizationsDelegate old) => false;
}
