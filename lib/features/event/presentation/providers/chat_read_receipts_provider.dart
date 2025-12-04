import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_unread_message_count.dart';
import '../../domain/usecases/update_last_read_message.dart';
import 'event_providers.dart';

/// Provider for UpdateLastReadMessage use case
final updateLastReadMessageProvider = Provider<UpdateLastReadMessage>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return UpdateLastReadMessage(repository);
});

/// Provider for GetUnreadMessageCount use case
final getUnreadMessageCountProvider = Provider<GetUnreadMessageCount>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetUnreadMessageCount(repository);
});

/// Provider for unread message count for a specific event
///
/// Usage:
/// ```dart
/// final unreadCount = ref.watch(eventUnreadCountProvider((
///   eventId: 'event-123',
///   currentUserId: 'user-456',
/// )));
/// ```
final eventUnreadCountProvider = FutureProvider.autoDispose
    .family<int, ({String eventId, String currentUserId})>((ref, params) async {
  print('[eventUnreadCountProvider] Fetching unread count');
  print('  Event ID: ${params.eventId}');
  print('  User ID: ${params.currentUserId}');

  final useCase = ref.watch(getUnreadMessageCountProvider);

  final count = await useCase(
    eventId: params.eventId,
    currentUserId: params.currentUserId,
  );

  print('[eventUnreadCountProvider] Result: $count unread messages');
  return count;
});
