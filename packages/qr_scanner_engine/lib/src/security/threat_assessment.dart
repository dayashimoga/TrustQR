import 'package:qr_core/qr_core.dart';

/// Individual security finding produced by the Threat Firewall.
class ThreatFinding {
  final String code;
  final SecurityThreatLevel severity;
  final String title;
  final String description;
  final String remediationRecommendation;

  const ThreatFinding({
    required this.code,
    required this.severity,
    required this.title,
    required this.description,
    required this.remediationRecommendation,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'severity': severity.name,
    'title': title,
    'description': description,
    'remediationRecommendation': remediationRecommendation,
  };
}

/// Comprehensive security evaluation of a scanned QR payload.
class ThreatAssessment {
  final int safetyScore; // 0 to 100
  final SecurityThreatLevel threatLevel;
  final List<ThreatFinding> findings;
  final bool isActionAllowed;
  final String summary;

  const ThreatAssessment({
    required this.safetyScore,
    required this.threatLevel,
    required this.findings,
    required this.isActionAllowed,
    required this.summary,
  });

  bool get isSafe => threatLevel == SecurityThreatLevel.safe;
  bool get isCritical => threatLevel == SecurityThreatLevel.critical;

  Map<String, dynamic> toJson() => {
    'safetyScore': safetyScore,
    'threatLevel': threatLevel.name,
    'findings': findings.map((f) => f.toJson()).toList(),
    'isActionAllowed': isActionAllowed,
    'summary': summary,
  };
}
