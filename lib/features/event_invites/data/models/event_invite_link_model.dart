import '../../domain/entities/event_invite_link_entity.dart';

class EventInviteLinkModel {
  final String token;
  final DateTime expiresAt;

  EventInviteLinkModel({
    required this.token,
    required this.expiresAt,
  });

  factory EventInviteLinkModel.fromJson(Map<String, dynamic> json) {
    return EventInviteLinkModel(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  EventInviteLinkEntity toEntity() {
    return EventInviteLinkEntity(
      token: token,
      expiresAt: expiresAt,
    );
  }
}
