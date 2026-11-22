/// Privacy settings and auto-purge retention policies for local vault records.
class VaultPrivacyPolicy {
  final int? autoPurgeHistoryDays;
  final bool isIncognitoMode;
  final bool keepFavoritesOnPurge;

  const VaultPrivacyPolicy({
    this.autoPurgeHistoryDays,
    this.isIncognitoMode = false,
    this.keepFavoritesOnPurge = true,
  });

  Map<String, dynamic> toJson() => {
    'autoPurgeHistoryDays': autoPurgeHistoryDays,
    'isIncognitoMode': isIncognitoMode,
    'keepFavoritesOnPurge': keepFavoritesOnPurge,
  };

  factory VaultPrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return VaultPrivacyPolicy(
      autoPurgeHistoryDays: json['autoPurgeHistoryDays'] as int?,
      isIncognitoMode: (json['isIncognitoMode'] as bool?) ?? false,
      keepFavoritesOnPurge: (json['keepFavoritesOnPurge'] as bool?) ?? true,
    );
  }

  VaultPrivacyPolicy copyWith({
    int? autoPurgeHistoryDays,
    bool? isIncognitoMode,
    bool? keepFavoritesOnPurge,
  }) {
    return VaultPrivacyPolicy(
      autoPurgeHistoryDays: autoPurgeHistoryDays ?? this.autoPurgeHistoryDays,
      isIncognitoMode: isIncognitoMode ?? this.isIncognitoMode,
      keepFavoritesOnPurge: keepFavoritesOnPurge ?? this.keepFavoritesOnPurge,
    );
  }
}
