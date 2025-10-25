// DTO model for ChatMessage - maps Supabase JSON to/from domain entity

import '../../domain/entities/chat_message.dart';

/// Chat Message DTO Model
class ChatMessageModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final bool read;

  const ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.read = false,
  });

  /// Create model from Supabase JSON (with user join)
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;
    
    return ChatMessageModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      userName: userData?['name'] as String? ?? 'Unknown User',
      userAvatar: userData?['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      read: json['read'] as bool? ?? false,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'read': read,
    };
  }

  /// Convert to domain entity
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: createdAt,
      read: read,
    );
  }

  /// Create model from domain entity
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      eventId: entity.eventId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      content: entity.content,
      createdAt: entity.createdAt,
      read: entity.read,
    );
  }
}
