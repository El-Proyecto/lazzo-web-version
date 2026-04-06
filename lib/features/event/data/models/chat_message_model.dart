// DTO model for ChatMessage - maps Supabase JSON to/from domain entity

import 'package:lazzo/core/utils/date_utils.dart';

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
  @Deprecated('Use isReadBySomeone instead')
  final bool read;

  final bool isPinned;
  final bool isDeleted;
  final String? replyToId;
  final bool isReadBySomeone;

  const ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    @Deprecated('Use isReadBySomeone') this.read = false,
    this.isPinned = false,
    this.isDeleted = false,
    this.replyToId,
    this.isReadBySomeone = false,
  });

  /// Create model from Supabase JSON (with user join)
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;

    // Handle both regular query format and RPC format
    final userName = userData?['name'] as String? ??
        json['user_name'] as String? ??
        'Unknown User';
    final userAvatar =
        userData?['avatar_url'] as String? ?? json['user_avatar'] as String?;

    // RPC returns is_read_by_someone, fallback to read for backwards compatibility
    final isReadBySomeone =
        json['is_read_by_someone'] as bool? ?? json['read'] as bool? ?? false;

    return ChatMessageModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      userName: userName,
      userAvatar: userAvatar,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isReadBySomeone: isReadBySomeone,
      isPinned: json['is_pinned'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      replyToId: json['reply_to_id'] as String?,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toSupabaseIso8601String(),
      'read': isReadBySomeone,
      'is_pinned': isPinned,
      'is_deleted': isDeleted,
      if (replyToId != null) 'reply_to_id': replyToId,
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
      isReadBySomeone: isReadBySomeone,
      isPinned: isPinned,
      isDeleted: isDeleted,
      replyTo: null, // Will be populated by repository if needed
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
      isReadBySomeone: entity.isReadBySomeone,
      isPinned: entity.isPinned,
      isDeleted: entity.isDeleted,
      replyToId: entity.replyTo?.id,
    );
  }
}
