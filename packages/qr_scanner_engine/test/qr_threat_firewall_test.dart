import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';

void main() {
  group('QrThreatFirewall Security & Anti-Phishing Tests', () {
    const firewall = QrThreatFirewall();

    test('Empty payload produces safe assessment', () {
      final res = firewall.inspectRaw('');
      expect(res.isSafe, isTrue);
      expect(res.safetyScore, equals(100));
      expect(res.findings, isEmpty);
      expect(res.isActionAllowed, isTrue);
      expect(res.toJson()['safetyScore'], equals(100));
    });

    test('Dangerous executable schemes blocked immediately with 0 safety score', () {
      final schemes = [
        'javascript:alert(document.cookie)',
        'vbscript:MsgBox("Hacked")',
        'data:text/html,<script>alert(1)</script>',
        'file:///etc/shadow',
        'powershell:Start-Process calc',
      ];

      for (final raw in schemes) {
        final res = firewall.inspectRaw(raw);
        expect(res.isCritical, isTrue);
        expect(res.safetyScore, equals(0));
        expect(res.isActionAllowed, isFalse);
        expect(res.findings.first.code, equals('TF_SCHEME_DANGEROUS'));
      }
    });

    test('Credential in URL detected as critical phishing masquerade', () {
      const raw = 'https://admin:SuperSecretPassword123@secure-login.com/dashboard';
      final res = firewall.inspectRaw(raw);
      expect(res.isCritical, isTrue);
      expect(res.isActionAllowed, isFalse);
      expect(res.findings.any((f) => f.code == 'TF_CREDENTIAL_IN_URL'), isTrue);
    });

    test('IDN Homograph and Punycode spoofing detected', () {
      // Punycode xn-- domain
      final punycodeRes = firewall.inspectRaw('https://xn--apple-43d.com');
      expect(punycodeRes.isCritical, isTrue);
      expect(punycodeRes.findings.any((f) => f.code == 'TF_HOMOGRAPH_SPOOF'), isTrue);

      // Mixed Cyrillic 'а' (U+0430) in paypal
      final cyrillicHomograph = firewall.inspectRaw('https://p\u0430ypal.com/signin');
      expect(cyrillicHomograph.isCritical, isTrue);
      expect(cyrillicHomograph.findings.any((f) => f.code == 'TF_HOMOGRAPH_SPOOF'), isTrue);
    });

    test('Raw IP and Private SSRF destinations detected and scored', () {
      // Public raw IP
      final publicIpRes = firewall.inspectRaw('http://203.0.113.195/update');
      expect(publicIpRes.findings.any((f) => f.code == 'TF_IP_OBFUSCATION'), isTrue);

      // Private loopback / RFC 1918 (SSRF attempt)
      final privateIpRes = firewall.inspectRaw('http://192.168.1.1/admin/reboot');
      expect(privateIpRes.isCritical, isTrue);
      expect(privateIpRes.findings.any((f) => f.code == 'TF_IP_OBFUSCATION'), isTrue);

      // Localhost
      final localhostRes = firewall.inspectRaw('http://localhost:8080/secrets');
      expect(localhostRes.isCritical, isTrue);

      // Hex IP (0x7f000001 = 127.0.0.1)
      final hexIpRes = firewall.inspectRaw('http://0x7f000001/status');
      expect(hexIpRes.findings.any((f) => f.code == 'TF_IP_OBFUSCATION'), isTrue);
    });

    test('URL Shorteners generate caution warning', () {
      final res = firewall.inspectRaw('https://bit.ly/3xY8Z1');
      expect(res.threatLevel, equals(SecurityThreatLevel.caution));
      expect(res.findings.any((f) => f.code == 'TF_SHORTENER_TRAP'), isTrue);
    });

    test('Insecure HTTP on sensitive paths vs normal paths', () {
      // Sensitive path over HTTP
      final sensitiveHttp = firewall.inspectRaw('http://secure-bank.com/login?redirect=account');
      expect(sensitiveHttp.threatLevel, equals(SecurityThreatLevel.suspicious));
      expect(sensitiveHttp.findings.any((f) => f.code == 'TF_INSECURE_SENSITIVE_TRANSPORT'), isTrue);

      // Normal path over HTTP
      final normalHttp = firewall.inspectRaw('http://example.org/about-us');
      expect(normalHttp.threatLevel, equals(SecurityThreatLevel.caution));
      expect(normalHttp.findings.any((f) => f.code == 'TF_INSECURE_TRANSPORT'), isTrue);
    });

    test('Excessive subdomain depth and high-entropy DGA detection', () {
      final deepSubdomains = firewall.inspectRaw('https://a.b.c.d.e.legitimate-looking.com/');
      expect(deepSubdomains.findings.any((f) => f.code == 'TF_EXCESSIVE_SUBDOMAINS'), isTrue);

      final dgaDomain = firewall.inspectRaw('https://xkjqw9182zla09.xyz/portal');
      expect(dgaDomain.findings.any((f) => f.code == 'TF_HIGH_ENTROPY_DGA'), isTrue);
    });

    test('Wi-Fi threat detection: open vs WEP vs WPA', () {
      final openWifi = firewall.inspectRaw('WIFI:S:CoffeeShop;T:nopass;P:;;');
      expect(openWifi.threatLevel, equals(SecurityThreatLevel.caution));
      expect(openWifi.findings.any((f) => f.code == 'TF_WIFI_UNENCRYPTED'), isTrue);

      final wepWifi = firewall.inspectRaw('WIFI:S:OldOffice;T:WEP;P:12345;;');
      expect(wepWifi.threatLevel, equals(SecurityThreatLevel.suspicious));
      expect(wepWifi.findings.any((f) => f.code == 'TF_WIFI_WEAK_WEP'), isTrue);

      final wpaWifi = firewall.inspectRaw('WIFI:S:HomeNet;T:WPA;P:Secr3tP@ss;;');
      expect(wpaWifi.isSafe, isTrue);
      expect(wpaWifi.safetyScore, equals(100));
    });

    test('vCard threat detection: flags insecure HTTP website', () {
      const vcardWithHttp = '''BEGIN:VCARD
VERSION:3.0
FN:Alice Hacker
URL:http://insecure-phishing.com
END:VCARD''';
      final res = firewall.inspectRaw(vcardWithHttp);
      expect(res.threatLevel, equals(SecurityThreatLevel.caution));
      expect(res.findings.any((f) => f.code == 'TF_VCARD_INSECURE_URL'), isTrue);
    });

    test('TrustQR signature verification with institutional registry', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => i * 17 % 256));
      final keyPair = Ed25519Engine.generateKeyPairFromSeed(seed, keyId: 'gov-cert-key');
      final institutionalFirewall = QrThreatFirewall(
        trustedInstitutionalKeys: {'gov-cert-key': keyPair.publicKey},
      );

      // 1. Authentic signed TrustQR
      final validEnvelope = TrustQrEnvelope.sign(
        issuer: 'org.health.cert',
        payload: 'https://health.gov/verify?id=42',
        privateKey: keyPair.privateKey,
      );
      final authenticRes = institutionalFirewall.inspectRaw(validEnvelope.toUriString());
      expect(authenticRes.isSafe, isTrue);
      expect(authenticRes.safetyScore, equals(100));
      expect(authenticRes.findings.first.code, equals('TF_TRUSTQR_AUTHENTIC'));

      // 2. Tampered TrustQR code
      final parsedUri = Uri.parse(validEnvelope.toUriString());
      final tamperedParams = Map<String, String>.from(parsedUri.queryParameters);
      tamperedParams['payload'] = base64UrlEncode(utf8.encode('https://evil-phish.com'));
      final tamperedUri = parsedUri.replace(queryParameters: tamperedParams).toString();

      final tamperedRes = institutionalFirewall.inspectRaw(tamperedUri);
      expect(tamperedRes.isCritical, isTrue);
      expect(tamperedRes.safetyScore, equals(0));
      expect(tamperedRes.findings.first.code, equals('TF_TRUSTQR_TAMPERED'));

      // 3. Unregistered key ID
      final unknownKeyEnvelope = TrustQrEnvelope.sign(
        issuer: 'org.unknown.issuer',
        payload: 'https://unknown.com',
        privateKey: CryptoPrivateKey(bytes: seed, algorithm: CryptoAlgorithm.ed25519, keyId: 'unregistered-key'),
      );
      final unknownRes = institutionalFirewall.inspectRaw(unknownKeyEnvelope.toUriString());
      expect(unknownRes.threatLevel, equals(SecurityThreatLevel.caution));
      expect(unknownRes.findings.first.code, equals('TF_TRUSTQR_UNKNOWN_ISSUER'));

      // 4. Malformed TrustQR
      final malformedRes = institutionalFirewall.inspectRaw('trustqr://v1?broken=yes');
      expect(malformedRes.isCritical, isTrue);
      expect(malformedRes.findings.first.code, equals('TF_TRUSTQR_MALFORMED'));
    });

    test('ThreatAssessment and ThreatFinding serialization toJson', () {
      const finding = ThreatFinding(
        code: 'TEST_CODE',
        severity: SecurityThreatLevel.caution,
        title: 'Test Title',
        description: 'Test Desc',
        remediationRecommendation: 'Test Rec',
      );
      final json = finding.toJson();
      expect(json['code'], equals('TEST_CODE'));
      expect(json['severity'], equals('caution'));
      expect(json['title'], equals('Test Title'));
      expect(json['description'], equals('Test Desc'));
      expect(json['remediationRecommendation'], equals('Test Rec'));

      const assessment = ThreatAssessment(
        safetyScore: 85,
        threatLevel: SecurityThreatLevel.caution,
        findings: [finding],
        isActionAllowed: true,
        summary: 'Test summary',
      );
      final assessmentJson = assessment.toJson();
      expect(assessmentJson['safetyScore'], equals(85));
      expect((assessmentJson['findings'] as List).length, equals(1));
    });
  });
}
