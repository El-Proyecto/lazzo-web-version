import 'package:flutter/foundation.dart';
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

/// Helper provider to get unread messages count
final unreadMessagesCountProvider = Provider.family<int, String>(
  (ref, eventId) {
    final messagesAsync = ref.watch(chatMessagesProvider(eventId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    return messagesAsync.when(
      data: (messages) => messages
          .where((m) => !m.read && m.userId != currentUserId)
          .length,
      loading: () => 0,
      error: (_, __) => 0,
    );
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
    if (kDebugMode) {
      print('📝 [ChatActions] sendMessage called');
      print('   - Event ID: $eventId');
      print('   - Content: "$content"');
      print('   - Reply To: ${replyTo?.id}');
    }
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) {
      if (kDebugMode) {
        print('❌ [ChatActions] User not authenticated!');
      }
      throw Exception('User not authenticated');
    }
    
    if (kDebugMode) {
      print('👤 [ChatActions] Sending as user: $userId');
    }
    await repository.sendMessage(
      eventId,
      userId,
      content,
      replyTo: replyTo,
    );
    if (kDebugMode) {
      print('✅ [ChatActions] sendMessage completed, waiting for stream update...');
    }
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
