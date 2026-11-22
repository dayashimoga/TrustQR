import 'package:qr_core/qr_core.dart';
import 'threat_analytics_summary.dart';

class _RecordedInspection {
  final int safetyScore;
  final SecurityThreatLevel threatLevel;
  final List<String> threatFlags;
  final String? domain;

  _RecordedInspection({
    required this.safetyScore,
    required this.threatLevel,
    required this.threatFlags,
    this.domain,
  });
}

/// Engine analyzing scanned vault records or live telemetry to extract threat distributions, attack vectors,
/// and malicious domain intelligence.
class ThreatAnalyticsEngine {
  final List<_RecordedInspection> _inspections = [];

  ThreatAnalyticsEngine();

  /// Records a live scan inspection event.
  void recordInspection({
    required int safetyScore,
    required SecurityThreatLevel threatLevel,
    List<String> threatFlags = const [],
    String? domain,
  }) {
    _inspections.add(_RecordedInspection(
      safetyScore: safetyScore,
      threatLevel: threatLevel,
      threatFlags: threatFlags,
      domain: domain,
    ));
  }

  /// Clears recorded inspections.
  void clear() {
    _inspections.clear();
  }

  /// Produces a summary from recorded inspections or from an optional list of vault items.
  ThreatAnalyticsSummary summarize([List<QrVaultItem>? items]) {
    if (items != null && items.isNotEmpty) {
      return analyze(items);
    }

    if (_inspections.isEmpty) {
      return const ThreatAnalyticsSummary(
        totalAudited: 0,
        safeCount: 0,
        cautionCount: 0,
        suspiciousCount: 0,
        criticalCount: 0,
        averageSafetyScore: 100.0,
        attackCategoryCounts: {},
        topMaliciousDomains: {},
        scoreHistogram: {
          '0-19': 0,
          '20-39': 0,
          '40-59': 0,
          '60-79': 0,
          '80-100': 0,
        },
      );
    }

    int safe = 0;
    int caution = 0;
    int suspicious = 0;
    int critical = 0;
    int totalScore = 0;

    final categories = <String, int>{};
    final domainMap = <String, int>{};
    final histogram = <String, int>{
      '0-19': 0,
      '20-39': 0,
      '40-59': 0,
      '60-79': 0,
      '80-100': 0,
    };

    for (final insp in _inspections) {
      totalScore += insp.safetyScore;

      switch (insp.threatLevel) {
        case SecurityThreatLevel.safe:
          safe++;
          break;
        case SecurityThreatLevel.caution:
          caution++;
          break;
        case SecurityThreatLevel.suspicious:
          suspicious++;
          break;
        case SecurityThreatLevel.critical:
          critical++;
          break;
      }

      final score = insp.safetyScore;
      if (score < 20) {
        histogram['0-19'] = (histogram['0-19'] ?? 0) + 1;
      } else if (score < 40) {
        histogram['20-39'] = (histogram['20-39'] ?? 0) + 1;
      } else if (score < 60) {
        histogram['40-59'] = (histogram['40-59'] ?? 0) + 1;
      } else if (score < 80) {
        histogram['60-79'] = (histogram['60-79'] ?? 0) + 1;
      } else {
        histogram['80-100'] = (histogram['80-100'] ?? 0) + 1;
      }

      if (insp.threatLevel != SecurityThreatLevel.safe) {
        if (insp.domain != null && insp.domain!.isNotEmpty) {
          final d = insp.domain!.toLowerCase();
          domainMap[d] = (domainMap[d] ?? 0) + 1;
        }

        for (final flag in insp.threatFlags) {
          final cat = _mapFlagToCategory(flag);
          categories[cat] = (categories[cat] ?? 0) + 1;
        }
      }
    }

    final sortedDomains = Map.fromEntries(
      domainMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    final avgScore = double.parse((totalScore / _inspections.length).toStringAsFixed(2));

    return ThreatAnalyticsSummary(
      totalAudited: _inspections.length,
      safeCount: safe,
      cautionCount: caution,
      suspiciousCount: suspicious,
      criticalCount: critical,
      averageSafetyScore: avgScore,
      attackCategoryCounts: categories,
      topMaliciousDomains: sortedDomains,
      scoreHistogram: histogram,
    );
  }

  /// Analyzes vault items to produce a complete ThreatAnalyticsSummary.
  ThreatAnalyticsSummary analyze(List<QrVaultItem> items) {
    if (items.isEmpty) {
      return const ThreatAnalyticsSummary(
        totalAudited: 0,
        safeCount: 0,
        cautionCount: 0,
        suspiciousCount: 0,
        criticalCount: 0,
        averageSafetyScore: 100.0,
        attackCategoryCounts: {
          'phishing_idn_homograph': 0,
          'dangerous_scheme': 0,
          'malicious_ip': 0,
          'url_shortener': 0,
          'high_entropy_dga': 0,
          'insecure_wifi': 0,
          'suspicious_payload': 0,
        },
        topMaliciousDomains: {},
        scoreHistogram: {
          '0-19': 0,
          '20-39': 0,
          '40-59': 0,
          '60-79': 0,
          '80-100': 0,
        },
      );
    }

    int safe = 0;
    int caution = 0;
    int suspicious = 0;
    int critical = 0;
    int totalScore = 0;

    final categories = <String, int>{
      'phishing_idn_homograph': 0,
      'dangerous_scheme': 0,
      'malicious_ip': 0,
      'url_shortener': 0,
      'high_entropy_dga': 0,
      'insecure_wifi': 0,
      'suspicious_payload': 0,
    };

    final domainMap = <String, int>{};
    final histogram = <String, int>{
      '0-19': 0,
      '20-39': 0,
      '40-59': 0,
      '60-79': 0,
      '80-100': 0,
    };

    for (final item in items) {
      totalScore += item.safetyScore;

      // Classify threat levels
      switch (item.threatLevel) {
        case SecurityThreatLevel.safe:
          safe++;
          break;
        case SecurityThreatLevel.caution:
          caution++;
          break;
        case SecurityThreatLevel.suspicious:
          suspicious++;
          break;
        case SecurityThreatLevel.critical:
          critical++;
          break;
      }

      // Populate score histogram
      final score = item.safetyScore;
      if (score < 20) {
        histogram['0-19'] = (histogram['0-19'] ?? 0) + 1;
      } else if (score < 40) {
        histogram['20-39'] = (histogram['20-39'] ?? 0) + 1;
      } else if (score < 60) {
        histogram['40-59'] = (histogram['40-59'] ?? 0) + 1;
      } else if (score < 80) {
        histogram['60-79'] = (histogram['60-79'] ?? 0) + 1;
      } else {
        histogram['80-100'] = (histogram['80-100'] ?? 0) + 1;
      }

      // If threat detected, analyze attack vector indicators
      if (item.threatLevel != SecurityThreatLevel.safe) {
        final raw = item.rawContent.trim();
        final rawLower = raw.toLowerCase();

        // Check for dangerous schemes
        if (rawLower.startsWith('javascript:') ||
            rawLower.startsWith('data:') ||
            rawLower.startsWith('file:') ||
            rawLower.startsWith('vbscript:')) {
          categories['dangerous_scheme'] = (categories['dangerous_scheme'] ?? 0) + 1;
        }

        // Check for URL shorteners
        final shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'is.gd', 'buff.ly', 'ow.ly'];
        for (final s in shorteners) {
          if (rawLower.contains(s)) {
            categories['url_shortener'] = (categories['url_shortener'] ?? 0) + 1;
            break;
          }
        }

        // Check for IDN Homographs / Punycode
        if (rawLower.contains('xn--') || RegExp(r'[^\x00-\x7F]').hasMatch(raw)) {
          categories['phishing_idn_homograph'] = (categories['phishing_idn_homograph'] ?? 0) + 1;
        }

        // Check for raw IP / Hex IP addresses in URLs
        if (RegExp(r'https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(raw) ||
            RegExp(r'https?://0x[0-9a-fA-F]+').hasMatch(raw)) {
          categories['malicious_ip'] = (categories['malicious_ip'] ?? 0) + 1;
        }

        // Check for insecure Wi-Fi
        if (item.payloadType == QrPayloadType.wifi &&
            (rawLower.contains('t:nopass') || rawLower.contains('t:none') || rawLower.contains('t:wep'))) {
          categories['insecure_wifi'] = (categories['insecure_wifi'] ?? 0) + 1;
        }

        // Check for high-entropy DGA domain indicators
        if (RegExp(r'https?://[a-z0-9]{22,}\.').hasMatch(rawLower)) {
          categories['high_entropy_dga'] = (categories['high_entropy_dga'] ?? 0) + 1;
        }

        // Suspicious payload fallback if non-safe and no specific flag matched
        final hasMatched = categories.values.any((count) => count > 0);
        if (!hasMatched) {
          categories['suspicious_payload'] = (categories['suspicious_payload'] ?? 0) + 1;
        }

        // Extract domain if URL payload
        if (item.payloadType == QrPayloadType.url || rawLower.startsWith('http')) {
          try {
            final uri = Uri.parse(raw);
            final host = uri.host.toLowerCase();
            if (host.isNotEmpty) {
              domainMap[host] = (domainMap[host] ?? 0) + 1;
            }
          } catch (_) {}
        }
      }
    }

    final sortedDomains = Map.fromEntries(
      domainMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    final avgScore = double.parse((totalScore / items.length).toStringAsFixed(2));

    return ThreatAnalyticsSummary(
      totalAudited: items.length,
      safeCount: safe,
      cautionCount: caution,
      suspiciousCount: suspicious,
      criticalCount: critical,
      averageSafetyScore: avgScore,
      attackCategoryCounts: categories,
      topMaliciousDomains: sortedDomains,
      scoreHistogram: histogram,
    );
  }

  static String _mapFlagToCategory(String flag) {
    final lower = flag.toLowerCase();
    if (lower.contains('phish')) return 'Phishing / Social Engineering';
    if (lower.contains('homograph') || lower.contains('idn')) return 'IDN Homograph / Spoofing';
    if (lower.contains('shortener')) return 'URL Shortener Cloaking';
    if (lower.contains('ip') || lower.contains('ssrf') || lower.contains('loopback')) {
      return 'SSRF / Local Network Probe';
    }
    if (lower.contains('scheme')) return 'Dangerous URI Scheme';
    if (lower.contains('wifi')) return 'Insecure Wi-Fi Network';
    if (lower.contains('dga') || lower.contains('entropy')) return 'Algorithmic DGA Domain';

    // Title case fallback
    final words = flag.split(RegExp(r'[_\s]+'));
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
