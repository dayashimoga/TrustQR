import 'dart:math';
import 'package:qr_core/qr_core.dart';
import 'threat_assessment.dart';

/// Zero-Trust QR Threat Firewall & Heuristic Anti-Phishing Inspection Engine.
class QrThreatFirewall {
  static const Set<String> _dangerousSchemes = {
    'javascript',
    'vbscript',
    'data',
    'file',
    'blob',
    'about',
    'chrome',
    'ms-appx',
    'ms-settings',
    'powershell',
  };

  static const Set<String> _urlShorteners = {
    'bit.ly',
    'tinyurl.com',
    't.co',
    'goo.gl',
    'ow.ly',
    'is.gd',
    'buff.ly',
    'adf.ly',
    'bit.do',
    'rb.gy',
    'shorte.st',
  };

  static const Set<String> _sensitivePathKeywords = {
    'login',
    'signin',
    'auth',
    'password',
    'credential',
    'account',
    'checkout',
    'payment',
    'pay',
    'bank',
    'wallet',
    'admin',
  };

  // Common Cyrillic and Greek lookalikes mixed with Latin letters in homograph attacks
  static final RegExp _confusableUnicode = RegExp(
    r'[\u0430\u0441\u0435\u043E\u0440\u0445\u0443\u0456\u0458\u03BF\u03B1\u03C1\u03BD]',
  );

  final Map<String, CryptoPublicKey> trustedInstitutionalKeys;

  const QrThreatFirewall({
    this.trustedInstitutionalKeys = const {},
  });

  /// Evaluates any raw string payload and returns a comprehensive [ThreatAssessment].
  ThreatAssessment inspectRaw(String raw, {Map<String, CryptoPublicKey>? customTrustedKeys}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ThreatAssessment(
        safetyScore: 100,
        threatLevel: SecurityThreatLevel.safe,
        findings: [],
        isActionAllowed: true,
        summary: 'Empty payload',
      );
    }

    final findings = <ThreatFinding>[];
    int score = 100;

    // 1. Check for TrustQR envelope
    if (trimmed.toLowerCase().startsWith('trustqr://')) {
      return _inspectTrustQr(trimmed, customTrustedKeys);
    }

    // 2. Dangerous Scheme Blocking
    final colonIdx = trimmed.indexOf(':');
    if (colonIdx != -1) {
      final scheme = trimmed.substring(0, colonIdx).toLowerCase();
      if (_dangerousSchemes.contains(scheme)) {
        findings.add(const ThreatFinding(
          code: 'TF_SCHEME_DANGEROUS',
          severity: SecurityThreatLevel.critical,
          title: 'Dangerous Executable / Local Scheme',
          description: 'The QR code uses an executable, script, or local file scheme capable of code execution.',
          remediationRecommendation: 'Do not execute or launch this QR code. It poses a severe security risk.',
        ));
        return ThreatAssessment(
          safetyScore: 0,
          threatLevel: SecurityThreatLevel.critical,
          findings: findings,
          isActionAllowed: false,
          summary: 'Blocked dangerous executable URI scheme: $scheme',
        );
      }
    }

    // Parse into structured payload
    final payload = QrPayloadParser.parse(trimmed);

    // 3. URL-specific inspection
    if (payload is UrlPayload) {
      score = _inspectUrl(payload, findings, score);
    } else if (payload is WifiPayload) {
      score = _inspectWifi(payload, findings, score);
    } else if (payload is VCardPayload) {
      score = _inspectVCard(payload, findings, score);
    }

    score = score.clamp(0, 100);

    var threatLevel = SecurityThreatLevel.safe;
    if (findings.any((f) => f.severity == SecurityThreatLevel.critical) || score < 40) {
      threatLevel = SecurityThreatLevel.critical;
    } else if (findings.any((f) => f.severity == SecurityThreatLevel.suspicious) || score < 70) {
      threatLevel = SecurityThreatLevel.suspicious;
    } else if (findings.any((f) => f.severity == SecurityThreatLevel.caution) || score < 90) {
      threatLevel = SecurityThreatLevel.caution;
    }

    final isAllowed = threatLevel != SecurityThreatLevel.critical;
    final summary = findings.isEmpty
        ? 'Payload passed all Zero-Trust threat firewall checks cleanly.'
        : '${findings.length} security warning(s) detected. Threat level: ${threatLevel.name.toUpperCase()}.';

    return ThreatAssessment(
      safetyScore: score,
      threatLevel: threatLevel,
      findings: findings,
      isActionAllowed: isAllowed,
      summary: summary,
    );
  }

  int _inspectUrl(UrlPayload urlPayload, List<ThreatFinding> findings, int currentScore) {
    var score = currentScore;
    final uri = urlPayload.uri;
    final host = uri.host.toLowerCase();

    // 3a. Credential in URL check
    if (uri.userInfo.isNotEmpty) {
      findings.add(ThreatFinding(
        code: 'TF_CREDENTIAL_IN_URL',
        severity: SecurityThreatLevel.critical,
        title: 'Embedded Credentials / Phishing Masquerade',
        description: 'URL contains embedded username/password credentials (${uri.userInfo}@), commonly used in deceptive link spoofing.',
        remediationRecommendation: 'Do not visit this URL. The embedded authority masks the true destination server.',
      ));
      score -= 75;
    }

    // 3b. IDN Homograph & Punycode spoofing check
    final decodedHost = Uri.decodeComponent(host);
    final rawUrl = urlPayload.toRawPayload();
    if (decodedHost.startsWith('xn--') ||
        decodedHost.contains('.xn--') ||
        _confusableUnicode.hasMatch(decodedHost) ||
        _confusableUnicode.hasMatch(rawUrl) ||
        host.contains('%')) {
      findings.add(ThreatFinding(
        code: 'TF_HOMOGRAPH_SPOOF',
        severity: SecurityThreatLevel.critical,
        title: 'IDN Homograph / Punycode Deception Detected',
        description: 'Domain uses internationalized characters or punycode ($decodedHost) mimicking legitimate institutional brand names.',
        remediationRecommendation: 'Verify the true ASCII destination address before proceeding.',
      ));
      score -= 70;
    }

    // 3c. Raw IP or Obfuscated IP check
    if (_isRawOrObfuscatedIp(host) || _isPrivateIp(host)) {
      final isPrivate = _isPrivateIp(host);
      findings.add(ThreatFinding(
        code: 'TF_IP_OBFUSCATION',
        severity: isPrivate ? SecurityThreatLevel.critical : SecurityThreatLevel.suspicious,
        title: isPrivate ? 'Internal Private Network / SSRF Target' : 'Raw IP Address Target',
        description: 'URL directly targets an IP address ($host) rather than a verified domain name.',
        remediationRecommendation: 'Do not access unverified IP addresses directly from QR scans.',
      ));
      score -= isPrivate ? 65 : 40;
    }

    // 3d. URL Shortener warning
    if (_urlShorteners.contains(host)) {
      findings.add(ThreatFinding(
        code: 'TF_SHORTENER_TRAP',
        severity: SecurityThreatLevel.caution,
        title: 'URL Shortener Destination',
        description: 'The QR code uses a URL shortening service ($host), concealing the final destination.',
        remediationRecommendation: 'Proceed with caution as the final redirect target is masked.',
      ));
      score -= 25;
    }

    // 3e. Insecure HTTP on sensitive paths
    if (uri.scheme == 'http') {
      final fullPath = (uri.path + uri.query).toLowerCase();
      final hasSensitiveWord = _sensitivePathKeywords.any((kw) => fullPath.contains(kw) || host.contains(kw));
      if (hasSensitiveWord) {
        findings.add(const ThreatFinding(
          code: 'TF_INSECURE_SENSITIVE_TRANSPORT',
          severity: SecurityThreatLevel.suspicious,
          title: 'Unencrypted Sensitive / Login Channel',
          description: 'URL handles authentication, payment, or accounts over insecure plaintext HTTP.',
          remediationRecommendation: 'Never enter credentials or financial data over unencrypted HTTP.',
        ));
        score -= 45;
      } else {
        findings.add(const ThreatFinding(
          code: 'TF_INSECURE_TRANSPORT',
          severity: SecurityThreatLevel.caution,
          title: 'Unencrypted HTTP Connection',
          description: 'The target site uses plaintext HTTP rather than secure HTTPS.',
          remediationRecommendation: 'Ensure sensitive communications are sent over HTTPS only.',
        ));
        score -= 20;
      }
    }

    // 3f. Excessive subdomain depth & DGA entropy
    final subdomains = host.split('.');
    if (subdomains.length > 4) {
      findings.add(ThreatFinding(
        code: 'TF_EXCESSIVE_SUBDOMAINS',
        severity: SecurityThreatLevel.caution,
        title: 'Excessive Subdomain Depth',
        description: 'Domain has ${subdomains.length} label segments, commonly used in deceptive phishing chains.',
        remediationRecommendation: 'Inspect the root domain carefully.',
      ));
      score -= 20;
    }

    if (subdomains.isNotEmpty) {
      final mainLabel = subdomains.first;
      if (mainLabel.length > 10 && _calculateShannonEntropy(mainLabel) > 3.4) {
        findings.add(ThreatFinding(
          code: 'TF_HIGH_ENTROPY_DGA',
          severity: SecurityThreatLevel.suspicious,
          title: 'Suspicious High-Entropy Domain Name',
          description: 'Domain label ($mainLabel) has high character randomness typical of automated malware domain generation algorithms (DGA).',
          remediationRecommendation: 'Avoid accessing automatically generated or untrusted domains.',
        ));
        score -= 35;
      }
    }

    return score;
  }

  int _inspectWifi(WifiPayload wifiPayload, List<ThreatFinding> findings, int currentScore) {
    var score = currentScore;
    if (wifiPayload.authType == WifiAuthType.none) {
      findings.add(const ThreatFinding(
        code: 'TF_WIFI_UNENCRYPTED',
        severity: SecurityThreatLevel.caution,
        title: 'Open / Unencrypted Wi-Fi Network',
        description: 'Network transmits data without encryption. Susceptible to packet sniffing and evil-twin interception.',
        remediationRecommendation: 'Use a trusted VPN if connecting to open public Wi-Fi networks.',
      ));
      score -= 25;
    } else if (wifiPayload.authType == WifiAuthType.wep) {
      findings.add(const ThreatFinding(
        code: 'TF_WIFI_WEAK_WEP',
        severity: SecurityThreatLevel.suspicious,
        title: 'Deprecated Weak WEP Encryption',
        description: 'WEP encryption is cryptographically broken and trivially crackable within seconds.',
        remediationRecommendation: 'Upgrade network security to WPA2 or WPA3.',
      ));
      score -= 40;
    }
    return score;
  }

  int _inspectVCard(VCardPayload vcard, List<ThreatFinding> findings, int currentScore) {
    var score = currentScore;
    for (final url in vcard.urls) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.scheme == 'http') {
        findings.add(ThreatFinding(
          code: 'TF_VCARD_INSECURE_URL',
          severity: SecurityThreatLevel.caution,
          title: 'vCard Contains Unencrypted Website URL',
          description: 'Contact website ($url) uses unencrypted HTTP.',
          remediationRecommendation: 'Verify contact details independently.',
        ));
        score -= 15;
      }
    }
    return score;
  }

  ThreatAssessment _inspectTrustQr(String raw, Map<String, CryptoPublicKey>? customTrustedKeys) {
    final envelope = TrustQrEnvelope.tryParse(raw);
    if (envelope == null) {
      return const ThreatAssessment(
        safetyScore: 10,
        threatLevel: SecurityThreatLevel.critical,
        findings: [
          ThreatFinding(
            code: 'TF_TRUSTQR_MALFORMED',
            severity: SecurityThreatLevel.critical,
            title: 'Malformed TrustQR Envelope',
            description: 'The TrustQR envelope has invalid syntax or missing cryptographic parameters.',
            remediationRecommendation: 'Do not trust this payload.',
          ),
        ],
        isActionAllowed: false,
        summary: 'Malformed TrustQR envelope detected.',
      );
    }

    final keyStore = customTrustedKeys ?? trustedInstitutionalKeys;
    final trustedKey = keyStore[envelope.keyId];

    if (trustedKey == null) {
      return ThreatAssessment(
        safetyScore: 60,
        threatLevel: SecurityThreatLevel.caution,
        findings: [
          ThreatFinding(
            code: 'TF_TRUSTQR_UNKNOWN_ISSUER',
            severity: SecurityThreatLevel.caution,
            title: 'Unregistered TrustQR Issuer Key',
            description: 'Signed by issuer "${envelope.issuer}" with key ID "${envelope.keyId}", which is not in the trusted institutional registry.',
            remediationRecommendation: 'Verify the institution before relying on signed claims.',
          ),
        ],
        isActionAllowed: true,
        summary: 'Signed TrustQR payload with unregistered issuer key (${envelope.keyId}).',
      );
    }

    final verification = envelope.verify(publicKey: trustedKey);
    if (!verification.isValid) {
      return ThreatAssessment(
        safetyScore: 0,
        threatLevel: SecurityThreatLevel.critical,
        findings: [
          ThreatFinding(
            code: 'TF_TRUSTQR_TAMPERED',
            severity: SecurityThreatLevel.critical,
            title: 'Cryptographic Signature Tampering Detected',
            description: 'The physical or digital QR code has been altered after being signed by "${envelope.issuer}". Reason: ${verification.reason}',
            remediationRecommendation: 'CRITICAL WARNING: This QR code has been tampered with or replaced. Do not trust it.',
          ),
        ],
        isActionAllowed: false,
        summary: 'CRITICAL: Tampered TrustQR code detected! Signature verification failed.',
      );
    }

    return ThreatAssessment(
      safetyScore: 100,
      threatLevel: SecurityThreatLevel.safe,
      findings: [
        ThreatFinding(
          code: 'TF_TRUSTQR_AUTHENTIC',
          severity: SecurityThreatLevel.safe,
          title: 'Authentic Cryptographically Signed QR Code',
          description: 'Verified with Ed25519 institutional public key from "${envelope.issuer}". Payload is guaranteed authentic and unaltered.',
          remediationRecommendation: 'Payload is safe and cryptographically verified.',
        ),
      ],
      isActionAllowed: true,
      summary: 'Authentic TrustQR envelope verified from ${envelope.issuer}.',
    );
  }

  static bool _isRawOrObfuscatedIp(String host) {
    if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host)) return true;
    if (host.startsWith('0x') || host.contains('.0x')) return true;
    if (RegExp(r'^\d{8,11}$').hasMatch(host)) return true; // Dword IP
    if (host.startsWith('[') && host.endsWith(']')) return true; // IPv6
    return false;
  }

  static bool _isPrivateIp(String host) {
    if (host == 'localhost' || host == '127.0.0.1' || host == '[::1]') return true;
    if (host.startsWith('10.') || host.startsWith('192.168.') || host.startsWith('169.254.')) return true;
    if (RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(host)) return true;
    return false;
  }

  static double _calculateShannonEntropy(String s) {
    if (s.isEmpty) return 0.0;
    final map = <String, int>{};
    for (var i = 0; i < s.length; i++) {
      final char = s[i];
      map[char] = (map[char] ?? 0) + 1;
    }
    double entropy = 0.0;
    for (final count in map.values) {
      final p = count / s.length;
      entropy -= p * (log(p) / ln2);
    }
    return entropy;
  }
}
