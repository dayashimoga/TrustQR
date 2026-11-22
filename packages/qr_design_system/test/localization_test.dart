import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  group('CyberLocalizations Dictionary & Language Tests', () {
    const supportedCodes = ['en', 'es', 'fr', 'de', 'hi', 'ja'];

    test('CyberLocalizationsDelegate supports expected locales and rejects others', () {
      const delegate = CyberLocalizations.delegate;

      for (final code in supportedCodes) {
        expect(delegate.isSupported(Locale(code)), isTrue, reason: 'Locale $code must be supported');
      }

      expect(delegate.isSupported(const Locale('zh')), isFalse);
      expect(delegate.isSupported(const Locale('ru')), isFalse);
      expect(delegate.isSupported(const Locale('ar')), isFalse);
      expect(delegate.shouldReload(delegate), isFalse);
    });

    test('CyberLocalizationsDelegate.load loads synchronous future successfully', () async {
      const delegate = CyberLocalizations.delegate;
      final l10n = await delegate.load(const Locale('es'));
      expect(l10n.languageCode, equals('es'));
      expect(l10n.appName, equals('QR Universal'));
    });

    test('All 6 supported locales have complete non-empty translation keys', () {
      for (final code in supportedCodes) {
        final l10n = CyberLocalizations(Locale(code));
        expect(l10n.languageCode, equals(code));

        // Brand titles
        expect(l10n.appName.isNotEmpty, isTrue);
        expect(l10n.adminAppTitle.isNotEmpty, isTrue);
        expect(l10n.userAppTitle.isNotEmpty, isTrue);

        // Reticle HUD
        expect(l10n.reticleIdle.isNotEmpty, isTrue);
        expect(l10n.reticleScanning.isNotEmpty, isTrue);
        expect(l10n.reticleSafe.isNotEmpty, isTrue);
        expect(l10n.reticleWarning.isNotEmpty, isTrue);
        expect(l10n.reticleThreat.isNotEmpty, isTrue);
        expect(l10n.scanPrompt.isNotEmpty, isTrue);
        expect(l10n.laserSweepActive.isNotEmpty, isTrue);

        // Reticle state mappings
        expect(l10n.reticleStatus(ScannerHudState.idle), equals(l10n.reticleIdle));
        expect(l10n.reticleStatus(ScannerHudState.scanning), equals(l10n.reticleScanning));
        expect(l10n.reticleStatus(ScannerHudState.safe), equals(l10n.reticleSafe));
        expect(l10n.reticleStatus(ScannerHudState.warning), equals(l10n.reticleWarning));
        expect(l10n.reticleStatus(ScannerHudState.threat), equals(l10n.reticleThreat));

        // Threat safety score
        expect(l10n.threatScore.isNotEmpty, isTrue);
        expect(l10n.threatSecure.isNotEmpty, isTrue);
        expect(l10n.threatCaution.isNotEmpty, isTrue);
        expect(l10n.threatCritical.isNotEmpty, isTrue);
        expect(l10n.threatRating(95.0), equals(l10n.threatSecure));
        expect(l10n.threatRating(65.0), equals(l10n.threatCaution));
        expect(l10n.threatRating(30.0), equals(l10n.threatCritical));
        expect(l10n.threatScoreReading(85, l10n.threatSecure).isNotEmpty, isTrue);

        // TrustQR Cryptography
        expect(l10n.trustQrVerified.isNotEmpty, isTrue);
        expect(l10n.trustQrInvalid.isNotEmpty, isTrue);
        expect(l10n.trustQrIssuer.isNotEmpty, isTrue);
        expect(l10n.trustQrKeyId.isNotEmpty, isTrue);
        expect(l10n.trustQrIssuedAt.isNotEmpty, isTrue);

        // Navigation
        expect(l10n.navScanner.isNotEmpty, isTrue);
        expect(l10n.navGenerator.isNotEmpty, isTrue);
        expect(l10n.navVault.isNotEmpty, isTrue);
        expect(l10n.navAnalytics.isNotEmpty, isTrue);
        expect(l10n.navSettings.isNotEmpty, isTrue);
        expect(l10n.navBatch.isNotEmpty, isTrue);
        expect(l10n.navHistory.isNotEmpty, isTrue);
        expect(l10n.navFavorites.isNotEmpty, isTrue);

        // Actions & Buttons
        expect(l10n.buttonScan.isNotEmpty, isTrue);
        expect(l10n.buttonGenerate.isNotEmpty, isTrue);
        expect(l10n.buttonExport.isNotEmpty, isTrue);
        expect(l10n.buttonSave.isNotEmpty, isTrue);
        expect(l10n.buttonCancel.isNotEmpty, isTrue);
        expect(l10n.buttonCopy.isNotEmpty, isTrue);
        expect(l10n.buttonOpenUrl.isNotEmpty, isTrue);
        expect(l10n.buttonShare.isNotEmpty, isTrue);
        expect(l10n.buttonRetry.isNotEmpty, isTrue);
        expect(l10n.buttonClose.isNotEmpty, isTrue);
        expect(l10n.buttonQuarantine.isNotEmpty, isTrue);

        // Vault & Search
        expect(l10n.vaultSearchPlaceholder.isNotEmpty, isTrue);
        expect(l10n.vaultFilterAll.isNotEmpty, isTrue);
        expect(l10n.vaultExportJson.isNotEmpty, isTrue);
        expect(l10n.vaultImportJson.isNotEmpty, isTrue);
        expect(l10n.vaultClearHistory.isNotEmpty, isTrue);
        expect(l10n.vaultItemDeleted.isNotEmpty, isTrue);

        // Accessibility hints
        expect(l10n.a11yScannerReticle.isNotEmpty, isTrue);
        expect(l10n.a11yScannerReticleHint.isNotEmpty, isTrue);
        expect(l10n.a11yThreatGauge.isNotEmpty, isTrue);
        expect(l10n.a11yThreatGaugeHint.isNotEmpty, isTrue);
        expect(l10n.a11yTrustBadge.isNotEmpty, isTrue);
        expect(l10n.a11yTrustBadgeHint.isNotEmpty, isTrue);
        expect(l10n.a11yLoading.isNotEmpty, isTrue);
        expect(l10n.a11yHighContrastActive.isNotEmpty, isTrue);
        expect(l10n.a11yReducedMotionActive.isNotEmpty, isTrue);
      }
    });

    test('Unsupported locale falls back gracefully to English defaults', () {
      final l10n = CyberLocalizations(const Locale('pt'));
      expect(l10n.languageCode, equals('pt'));
      expect(l10n.appName, equals('Universal QR'));
      expect(l10n.buttonScan, equals('Scan Now'));
      expect(l10n.reticleIdle, equals('READY // ALIGN QR CODE'));
    });

    test('CyberLocalizations.supportedLocales has 6 locales', () {
      expect(CyberLocalizations.supportedLocales.length, equals(6));
      expect(
        CyberLocalizations.supportedLocales.map((l) => l.languageCode).toList(),
        containsAll(supportedCodes),
      );
    });
  });

  group('Widget Tree Localization Integration Tests', () {
    testWidgets('CyberLocalizations.of falls back to English outside localized tree', (tester) async {
      late CyberLocalizations retrievedL10n;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              retrievedL10n = CyberLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(retrievedL10n.languageCode, equals('en'));
      expect(retrievedL10n.buttonScan, equals('Scan Now'));
    });

    testWidgets('Localized tree renders Spanish strings with Localizations.override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Localizations(
            locale: const Locale('es'),
            delegates: const [
              CyberLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Builder(
              builder: (context) {
                final l10n = CyberLocalizations.of(context);
                return Text(l10n.buttonScan);
              },
            ),
          ),
        ),
      );

      expect(find.text('Escanear Ahora'), findsOneWidget);
    });

    testWidgets('Localized tree renders Japanese strings with Localizations.override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Localizations(
            locale: const Locale('ja'),
            delegates: const [
              CyberLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Builder(
              builder: (context) {
                final l10n = CyberLocalizations.of(context);
                return Text(l10n.buttonScan);
              },
            ),
          ),
        ),
      );

      expect(find.text('今すぐスキャン'), findsOneWidget);
    });

    testWidgets('Localized tree renders Hindi strings with Localizations.override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Localizations(
            locale: const Locale('hi'),
            delegates: const [
              CyberLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Builder(
              builder: (context) {
                final l10n = CyberLocalizations.of(context);
                return Text(l10n.buttonScan);
              },
            ),
          ),
        ),
      );

      expect(find.text('अब स्कैन करें'), findsOneWidget);
    });

    testWidgets('Localized tree renders French strings with Localizations.override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Localizations(
            locale: const Locale('fr'),
            delegates: const [
              CyberLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Builder(
              builder: (context) {
                final l10n = CyberLocalizations.of(context);
                return Text(l10n.appName);
              },
            ),
          ),
        ),
      );

      expect(find.text('QR Universel'), findsOneWidget);
    });

    testWidgets('Localized tree renders German strings with Localizations.override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Localizations(
            locale: const Locale('de'),
            delegates: const [
              CyberLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Builder(
              builder: (context) {
                final l10n = CyberLocalizations.of(context);
                return Text(l10n.reticleIdle);
              },
            ),
          ),
        ),
      );

      expect(find.text('BEREIT // QR-CODE AUSRICHTEN'), findsOneWidget);
    });
  });
}
