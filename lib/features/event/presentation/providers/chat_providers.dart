import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/send_chat_message.dart';
import 'event_providers.dart';

/// Use case providers for chat
final getChatMessagesProvider = Provider<GetChatMessages>((ref) {
  return GetChatMessages(ref.watch(chatRepositoryProvider));
});

final sendChatMessageProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(ref.watch(chatRepositoryProvider));
});

/// Chat messages state notifier
/// Manages the list of messages for an event with real-time updates
class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final String eventId;
  final ChatRepository repository;

  ChatMessagesNotifier({
    required this.eventId,
    required this.repository,
  }) : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  /// Load all messages for the event
  Future<void> _loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await repository.getAllMessages(eventId);
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Send a new message
  Future<void> sendMessage(String content) async {
    try {
      // TODO: Get current user ID from auth service
      final newMessage = await repository.sendMessage(
        eventId,
        'current-user',
        content,
      );

      // Update state with new message
      state.whenData((messages) {
        final updatedMessages = [newMessage, ...messages];
        state = AsyncValue.data(updatedMessages);
      });
    } catch (error, stackTrace) {
      // Keep current state but could show error to user
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh messages from repository
  Future<void> refresh() async {
    await _loadMessages();
  }
}

/// Chat messages provider
/// Provides access to chat messages state for a specific event
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    AsyncValue<List<ChatMessage>>, String>(
  (ref, eventId) {
    final repository = ref.watch(chatRepositoryProvider);
    return ChatMessagesNotifier(
      eventId: eventId,
      repository: repository,
    );
  },
);
