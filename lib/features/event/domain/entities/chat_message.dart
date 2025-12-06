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

  @Deprecated(
      'Use isReadBySomeone instead. This field does not track per-user read status.')
  final bool read;

  final bool isPinned;
  final bool isDeleted;
  final ChatMessage? replyTo;

  /// True if at least one participant (other than sender) has read this message
  final bool isReadBySomeone;

  /// True if message is still being sent (optimistic UI)
  final bool isPending;

  const ChatMessage({
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
    this.replyTo,
    this.isReadBySomeone = false,
    this.isPending = false,
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
    bool? isReadBySomeone,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isReadBySomeone: isReadBySomeone ?? this.isReadBySomeone,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo ?? this.replyTo,
      isPending: isPending ?? this.isPending,
    );
  }
}
