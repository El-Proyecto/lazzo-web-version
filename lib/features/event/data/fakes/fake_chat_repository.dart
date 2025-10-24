import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Fake chat repository for development
class FakeChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg-1',
      eventId: 'event-1',
      userId: 'user-2',
      userName: 'Maria Santos',
      userAvatar: null,
      content: 'Mal posso esperar! 🔥',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      read: true, // Older message, already read
    ),
    ChatMessage(
      id: 'msg-2',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      content: 'Vou levar a grelha grande!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 90)),
      read: true, // Already read
    ),
    ChatMessage(
      id: 'msg-3',
      eventId: 'event-1',
      userId: 'user-3',
      userName: 'Ana Costa',
      userAvatar: null,
      content: 'Preciso de boleia, alguém passa pela Amadora?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      read: true, // Already read
    ),
    ChatMessage(
      id: 'msg-4',
      eventId: 'event-1',
      userId: 'current-user',
      userName: 'Carlos Pereira',
      userAvatar: null,
      content: 'Eu passo! Mando mensagem quando sair.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      read: true, // Current user's message, always read
    ),
    ChatMessage(
      id: 'msg-5',
      eventId: 'event-1',
      userId: 'user-4',
      userName: 'Ricardo Alves',
      userAvatar: null,
      content: 'Levo cerveja artesanal para toda a gente 🍺',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      read: false, // UNREAD - New message!
    ),
    ChatMessage(
      id: 'msg-6',
      eventId: 'event-1',
      userId: 'user-5',
      userName: 'Sofia Lima',
      userAvatar: null,
      content: 'Perfeito! Levo as sobremesas então 🍰',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      read: false, // UNREAD - New message!
    ),
    ChatMessage(
      id: 'msg-7',
      eventId: 'event-1',
      userId: 'user-6',
      userName: 'Pedro Costa',
      userAvatar: null,
      content: 'Pessoal, não vou conseguir ir 😔',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      read: false, // UNREAD - New message!
    ),
    ChatMessage(
      id: 'msg-8',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      content: 'Não há problema! Para a próxima 👍',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      read: false, // UNREAD - New message!
    ),
    ChatMessage(
      id: 'msg-9',
      eventId: 'event-1',
      userId: 'user-7',
      userName: 'Beatriz Sousa',
      userAvatar: null,
      content: 'Também não consigo... talvez podíamos mudar a data?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      read: false, // UNREAD - New message!
    ),
    // Example of consecutive messages from different people
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
      userId: 'user-4',
      userName: 'Ricardo Alves',
      userAvatar: null,
      content: 'Boa tarde!',
      createdAt: DateTime.now().subtract(const Duration(seconds: 45)),
      read: false,
    ),
    ChatMessage(
      id: 'msg-12',
      eventId: 'event-1',
      userId: 'user-3',
      userName: 'Ana Costa',
      userAvatar: null,
      content: 'Olá! 👋',
      createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      read: false,
    ),
    ChatMessage(
      id: 'msg-13',
      eventId: 'event-1',
      userId: 'user-5',
      userName: 'Sofia Lima',
      userAvatar: null,
      content: 'Bom dia a todos!',
      createdAt: DateTime.now().subtract(const Duration(seconds: 35)),
      read: false,
    ),
  ];

  @override
  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 50, // Show all messages instead of just 2
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final eventMessages = _messages.where((m) => m.eventId == eventId).toList();

    // Sort by creation time descending (newest first)
    eventMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return eventMessages.take(limit).toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final message = ChatMessage(
      id: 'msg-${_messages.length + 1}',
      eventId: eventId,
      userId: userId,
      userName: 'Current User',
      content: content,
      createdAt: DateTime.now(),
      read: true, // Current user's messages are always read
    );

    _messages.add(message);
    return message;
  }

  @override
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messages
        .where((m) => m.eventId == eventId)
        .toList()
        .reversed
        .toList();
  }
}
