import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/pin_message.dart';
import '../../domain/usecases/delete_message.dart';
import 'event_providers.dart';

/// Use case providers for chat
final getChatMessagesProvider = Provider<GetChatMessages>((ref) {
  return GetChatMessages(ref.watch(chatRepositoryProvider));
});

final sendChatMessageProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(ref.watch(chatRepositoryProvider));
});

final pinMessageProvider = Provider<PinMessage>((ref) {
  return PinMessage(ref.watch(chatRepositoryProvider));
});

final deleteMessageProvider = Provider<DeleteMessage>((ref) {
  return DeleteMessage(ref.watch(chatRepositoryProvider));
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
  Future<void> sendMessage(String content, {ChatMessage? replyTo}) async {
    try {
      final newMessage = await repository.sendMessage(
        eventId,
        'current-user',
        content,
        replyTo: replyTo,
      );

      state.whenData((messages) {
        final updatedMessages = [newMessage, ...messages];
        state = AsyncValue.data(updatedMessages);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pin or unpin a message
  Future<void> togglePin(String messageId, bool isPinned) async {
    try {
      await repository.pinMessage(messageId, isPinned);

      // Update state locally without showing loading
      // Repository unpins others automatically
      final messages = await repository.getAllMessages(eventId);
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final updatedMessage = await repository.deleteMessage(messageId);

      state.whenData((messages) {
        final updatedMessages = messages.map((msg) {
          return msg.id == messageId ? updatedMessage : msg;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
    } catch (error, stackTrace) {
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
