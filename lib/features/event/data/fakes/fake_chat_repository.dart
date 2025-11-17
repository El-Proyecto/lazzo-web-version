import 'dart:async';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Event status for chat state configuration
enum FakeEventChatStatus { planning, living, recap }

/// Global configuration for testing different event chat states
class FakeEventChatConfig {
  /// Current event status (determines UI colors and FAB icon)
  /// - planning: green colors (current behavior)
  /// - living: purple colors + camera FAB
  /// - recap: orange colors + add_photo FAB
  static FakeEventChatStatus eventStatus = FakeEventChatStatus.planning;

  /// Helper to check if event is in living state
  static bool get isLiving => eventStatus == FakeEventChatStatus.living;

  /// Helper to check if event is in recap state
  static bool get isRecap => eventStatus == FakeEventChatStatus.recap;

  /// Helper to check if event is in planning state
  static bool get isPlanning => eventStatus == FakeEventChatStatus.planning;
}

/// Fake chat repository for development
class FakeChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [];
  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();

  @override
  Stream<List<ChatMessage>> watchMessages(String eventId) {
    // Return stream with current messages sorted by created_at DESCENDING (newest first)
    // This matches Supabase behavior: order('created_at', ascending: false)
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    Future.microtask(() => _messagesController.add(eventMessages));
    return _messagesController.stream;
  }

  FakeChatRepository() {
    _initializeMessages();
  }

  void _initializeMessages() {
    // Message that will be replied to
    final msg1 = ChatMessage(
      id: 'msg-1',
      eventId: 'event-1',
      userId: 'user-2',
      userName: 'Maria Santos',
      userAvatar: null,
      content: 'Mal posso esperar! 🔥',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      read: true,
    );

    // Message that will be pinned
    final msg2 = ChatMessage(
      id: 'msg-2',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      content: 'IMPORTANTE: Encontro às 14h no parque!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 90)),
      read: true,
      isPinned: true, // This message is pinned
    );

    _messages.addAll([
      msg1,
      msg2,
      ChatMessage(
        id: 'msg-3',
        eventId: 'event-1',
        userId: 'user-3',
        userName: 'Ana Costa',
        userAvatar: null,
        content: 'Preciso de boleia, alguém passa pela Amadora?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        read: true,
        replyTo: msg1, // Reply to Maria's message
      ),
      ChatMessage(
        id: 'msg-4',
        eventId: 'event-1',
        userId: 'current-user',
        userName: 'Carlos Pereira',
        userAvatar: null,
        content: 'Eu passo! Mando mensagem quando sair.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        read: true,
      ),
      ChatMessage(
        id: 'msg-5',
        eventId: 'event-1',
        userId: 'user-4',
        userName: 'Ricardo Alves',
        userAvatar: null,
        content: 'Levo cerveja artesanal para toda a gente 🍺',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        read: false,
      ),
      ChatMessage(
        id: 'msg-6',
        eventId: 'event-1',
        userId: 'user-5',
        userName: 'Sofia Lima',
        userAvatar: null,
        content: 'Perfeito! Levo as sobremesas então 🍰',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        read: false,
      ),
      // Deleted message example
      ChatMessage(
        id: 'msg-7',
        eventId: 'event-1',
        userId: 'user-6',
        userName: 'Pedro Costa',
        userAvatar: null,
        content: 'Message Deleted',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        read: false,
        isDeleted: true, // This message was deleted
      ),
      ChatMessage(
        id: 'msg-8',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'João Silva',
        userAvatar: null,
        content: 'Não há problema! Para a próxima 👍',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        read: false,
      ),
      ChatMessage(
        id: 'msg-9',
        eventId: 'event-1',
        userId: 'user-7',
        userName: 'Beatriz Sousa',
        userAvatar: null,
        content: 'Também não consigo... talvez podíamos mudar a data?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        read: false,
      ),
      // Consecutive messages from same user
      ChatMessage(
        id: 'msg-10',
        eventId: 'event-1',
        userId: 'user-2',
        userName: 'Maria Santos',
        userAvatar: null,
        content: 'Ei pessoal!',
        createdAt: DateTime.now().subtract(const Duration(seconds: 50)),
        read: false,
      ),
      ChatMessage(
        id: 'msg-11',
        eventId: 'event-1',
        userId: 'user-2',
        userName: 'Maria Santos',
        userAvatar: null,
        content: 'Esqueci de dizer',
        createdAt: DateTime.now().subtract(const Duration(seconds: 48)),
        read: false,
      ),
      ChatMessage(
        id: 'msg-12',
        eventId: 'event-1',
        userId: 'user-2',
        userName: 'Maria Santos',
        userAvatar: null,
        content: 'Vou levar saladas também!',
        createdAt: DateTime.now().subtract(const Duration(seconds: 46)),
        read: false,
      ),
      // Reply with multiple messages
      ChatMessage(
        id: 'msg-13',
        eventId: 'event-1',
        userId: 'current-user',
        userName: 'Carlos Pereira',
        userAvatar: null,
        content: 'Ótimo!',
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
        read: true,
        replyTo: ChatMessage(
          id: 'msg-12',
          eventId: 'event-1',
          userId: 'user-2',
          userName: 'Maria Santos',
          userAvatar: null,
          content: 'Vou levar saladas também!',
          createdAt: DateTime.now().subtract(const Duration(seconds: 46)),
          read: false,
        ),
      ),
      ChatMessage(
        id: 'msg-14',
        eventId: 'event-1',
        userId: 'current-user',
        userName: 'Carlos Pereira',
        userAvatar: null,
        content: 'Assim temos variedade',
        createdAt: DateTime.now().subtract(const Duration(seconds: 38)),
        read: true,
      ),
    ]);
  }

  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();

    // Sort DESCENDING (newest first) to match Supabase: order('created_at', ascending: false)
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return eventMessages.take(limit).toList();
  }

  // DEPRECATED: Use watchMessages instead
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();
    // Sort DESCENDING (newest first) to match Supabase: order('created_at', ascending: false)
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return eventMessages;
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final message = ChatMessage(
      id: 'msg-${_messages.length + 1}',
      eventId: eventId,
      userId: userId,
      userName: 'Current User',
      content: content,
      createdAt: DateTime.now(),
      read: true,
      replyTo: replyTo,
    );

    _messages.add(message);
    // Emit updated list to stream (sorted DESCENDING like Supabase)
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _messagesController.add(eventMessages);
    return message;
  }

  @override
  Future<ChatMessage> pinMessage(
      String eventId, String messageId, bool isPinned) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      throw Exception('Message not found');
    }

    // If pinning a new message, unpin all others in the same event (only one pinned at a time)
    if (isPinned) {
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].eventId == eventId && _messages[i].isPinned) {
          _messages[i] = _messages[i].copyWith(isPinned: false);
        }
      }
    }

    final updatedMessage = _messages[index].copyWith(isPinned: isPinned);
    _messages[index] = updatedMessage;
    // Emit updated list to stream
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _messagesController.add(eventMessages);
    return updatedMessage;
  }

  @override
  Future<ChatMessage> deleteMessage(String eventId, String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      throw Exception('Message not found');
    }

    final updatedMessage = _messages[index].copyWith(
      isDeleted: true,
      content: 'Message Deleted',
    );
    _messages[index] = updatedMessage;
    // Emit updated list to stream
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _messagesController.add(eventMessages);
    return updatedMessage;
  }
}
