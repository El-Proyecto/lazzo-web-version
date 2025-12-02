/// Settings entity for user preferences
class SettingsEntity {
  final bool notificationsEnabled;
  final String language; // 'en' or 'pt'
  final int earlyAccessInvites;

  const SettingsEntity({
    required this.notificationsEnabled,
    required this.language,
    required this.earlyAccessInvites,
  });

  SettingsEntity copyWith({
    bool? notificationsEnabled,
    String? language,
    int? earlyAccessInvites,
  }) {
    return SettingsEntity(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      earlyAccessInvites: earlyAccessInvites ?? this.earlyAccessInvites,
    );
  }

  @override
  String toString() {
    return 'SettingsEntity(notificationsEnabled: $notificationsEnabled, language: $language, earlyAccessInvites: $earlyAccessInvites)';
  }
}
