import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'event_providers.dart';

/// Stream provider for chat messages (real-time updates)
/// Automatically updates when messages change in Supabase
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, eventId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.watchMessages(eventId);
  },
);

/// Realtime subscription for unread count updates
/// Listens to chat_messages and message_reads changes and invalidates unreadMessagesCountProvider
final unreadCountRealtimeProvider = StreamProvider.family<void, String>(
  (ref, eventId) {
    final supabase = Supabase.instance.client;

    // Create a stream controller to merge both table subscriptions
    final controller = Stream.multi((controller) {
      // Subscribe to chat_messages changes for this event
      final messagesSubscription = supabase
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('event_id', eventId)
          .listen((data) {
            // Invalidate the unread count provider to trigger refetch
            ref.invalidate(unreadMessagesCountProvider(eventId));
            controller.add(null);
          });

      // Subscribe to message_reads changes for this event
      final readsSubscription = supabase
          .from('message_reads')
          .stream(primaryKey: ['id'])
          .eq('event_id', eventId)
          .listen((data) {
            // Invalidate the unread count provider to trigger refetch
            ref.invalidate(unreadMessagesCountProvider(eventId));
            controller.add(null);
          });

      // Cleanup on stream cancel
      controller.onCancel = () {
        messagesSubscription.cancel();
        readsSubscription.cancel();
      };
    });

    return controller;
  },
);

/// Helper provider to get unread messages count using new read receipts system
/// This uses the message_reads table to accurately track per-user read status
final unreadMessagesCountProvider = FutureProvider.family<int, String>(
  (ref, eventId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      return 0;
    }

    try {
      final repository = ref.watch(chatRepositoryProvider);
      final count = await repository.getUnreadMessageCount(
        eventId: eventId,
        currentUserId: currentUserId,
      );

      return count;
    } catch (e) {
      return 0;
    }
  },
);

/// Actions provider for chat operations (send, pin, delete)
final chatActionsProvider = Provider.family<ChatActions, String>(
  (ref, eventId) {
    final repository = ref.watch(chatRepositoryProvider);
    return ChatActions(eventId: eventId, repository: repository);
  },
);

/// Chat actions class
/// Handles all chat operations (send, pin, delete)
class ChatActions {
  final String eventId;
  final ChatRepository repository;

  ChatActions({
    required this.eventId,
    required this.repository,
  });

  /// Send a new message
  Future<void> sendMessage(String content, {ChatMessage? replyTo}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await repository.sendMessage(
      eventId,
      userId,
      content,
      replyTo: replyTo,
    );
    // No need to refresh - stream will auto-update
  }

  /// Toggle pin status of a message
  Future<void> togglePin(String messageId, bool isPinned) async {
    await repository.pinMessage(eventId, messageId, isPinned);
    // No need to refresh - stream will auto-update
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await repository.deleteMessage(eventId, messageId);
    // No need to refresh - stream will auto-update
  }
}
