import '../../domain/entities/group_invite_link_entity.dart';

class GroupInviteLinkModel {
  final String token;
  final DateTime expiresAt;

  GroupInviteLinkModel({
    required this.token,
    required this.expiresAt,
  });

  factory GroupInviteLinkModel.fromJson(Map<String, dynamic> json) {
    return GroupInviteLinkModel(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  GroupInviteLinkEntity toEntity() {
    return GroupInviteLinkEntity(
      token: token,
      expiresAt: expiresAt,
    );
  }
}
