import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fakes/fake_event_repository.dart';
import '../../data/fakes/fake_rsvp_repository.dart';
import '../../data/fakes/fake_poll_repository.dart';
import '../../data/fakes/fake_chat_repository.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/poll.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/rsvp_repository.dart';
import '../../domain/repositories/poll_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_event_detail.dart';
import '../../domain/usecases/get_event_rsvps.dart';
import '../../domain/usecases/submit_rsvp.dart';
import '../../domain/usecases/get_event_polls.dart';
import '../../domain/usecases/get_recent_messages.dart';

// Repository providers (default to fake implementations)
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return FakeEventRepository();
});

final rsvpRepositoryProvider = Provider<RsvpRepository>((ref) {
  return FakeRsvpRepository();
});

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return FakePollRepository();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FakeChatRepository();
});

// Use case providers
final getEventDetailProvider = Provider<GetEventDetail>((ref) {
  return GetEventDetail(ref.watch(eventRepositoryProvider));
});

final getEventRsvpsProvider = Provider<GetEventRsvps>((ref) {
  return GetEventRsvps(ref.watch(rsvpRepositoryProvider));
});

final submitRsvpProvider = Provider<SubmitRsvp>((ref) {
  return SubmitRsvp(ref.watch(rsvpRepositoryProvider));
});

final getEventPollsProvider = Provider<GetEventPolls>((ref) {
  return GetEventPolls(ref.watch(pollRepositoryProvider));
});

final getRecentMessagesProvider = Provider<GetRecentMessages>((ref) {
  return GetRecentMessages(ref.watch(chatRepositoryProvider));
});

// Event detail state provider
final eventDetailProvider = FutureProvider.family<EventDetail, String>((
  ref,
  eventId,
) async {
  final useCase = ref.watch(getEventDetailProvider);
  return await useCase(eventId);
});

// RSVPs state provider
final eventRsvpsProvider = FutureProvider.family<List<Rsvp>, String>((
  ref,
  eventId,
) async {
  final useCase = ref.watch(getEventRsvpsProvider);
  return await useCase(eventId);
});

// User RSVP state provider
final userRsvpProvider =
    StateNotifierProvider.family<UserRsvpNotifier, AsyncValue<Rsvp?>, String>((
      ref,
      eventId,
    ) {
      return UserRsvpNotifier(
        eventId: eventId,
        repository: ref.watch(rsvpRepositoryProvider),
      );
    });

// Polls state provider
final eventPollsProvider = FutureProvider.family<List<Poll>, String>((
  ref,
  eventId,
) async {
  final useCase = ref.watch(getEventPollsProvider);
  return await useCase(eventId);
});

// Recent messages state provider
final recentMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, eventId) async {
    final useCase = ref.watch(getRecentMessagesProvider);
    return await useCase(eventId);
  },
);

// User RSVP state notifier
class UserRsvpNotifier extends StateNotifier<AsyncValue<Rsvp?>> {
  final String eventId;
  final RsvpRepository repository;

  UserRsvpNotifier({required this.eventId, required this.repository})
    : super(const AsyncValue.loading()) {
    _loadUserRsvp();
  }

  Future<void> _loadUserRsvp() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Get current user ID from auth service
      final userRsvp = await repository.getUserRsvp(eventId, 'current-user');
      state = AsyncValue.data(userRsvp);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitVote(RsvpStatus status) async {
    try {
      // TODO: Get current user ID from auth service
      final rsvp = await repository.submitRsvp(eventId, 'current-user', status);
      state = AsyncValue.data(rsvp);

      // No need to reload, the repository should return the updated RSVP
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Reload on error to get consistent state
      _loadUserRsvp();
    }
  }
}

// Send message notifier
final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
      return SendMessageNotifier(repository: ref.watch(chatRepositoryProvider));
    });

class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository repository;

  SendMessageNotifier({required this.repository})
    : super(const AsyncValue.data(null));

  Future<void> sendMessage(String eventId, String content) async {
    state = const AsyncValue.loading();
    try {
      // TODO: Get current user ID from auth service
      await repository.sendMessage(eventId, 'current-user', content);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
