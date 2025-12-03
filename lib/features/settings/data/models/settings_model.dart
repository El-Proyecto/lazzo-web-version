import '../../domain/entities/settings_entity.dart';

/// Data Transfer Object for Settings
/// Maps between Supabase JSON and domain entity
class SettingsModel {
  final bool notificationsEnabled;
  final String language;
  final int earlyAccessInvites;

  const SettingsModel({
    required this.notificationsEnabled,
    required this.language,
    required this.earlyAccessInvites,
  });

  /// Create SettingsModel from Supabase JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      earlyAccessInvites: json['early_access_invites'] as int? ?? 3,
    );
  }

  /// Convert SettingsModel to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'language': language,
      'early_access_invites': earlyAccessInvites,
    };
  }

  /// Convert to domain entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      notificationsEnabled: notificationsEnabled,
      language: language,
      earlyAccessInvites: earlyAccessInvites,
    );
  }

  /// Create from domain entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      language: entity.language,
      earlyAccessInvites: entity.earlyAccessInvites,
    );
  }
}
