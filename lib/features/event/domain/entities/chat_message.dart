/// Chat message domain entity
/// Represents a message in the event chat
class ChatMessage {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final bool read;
  final bool isPinned;
  final bool isDeleted;
  final ChatMessage? replyTo;

  const ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.read = false,
    this.isPinned = false,
    this.isDeleted = false,
    this.replyTo,
  });

  ChatMessage copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    bool? read,
    bool? isPinned,
    bool? isDeleted,
    ChatMessage? replyTo,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
