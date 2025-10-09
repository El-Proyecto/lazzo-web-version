import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fakes/fake_event_repository.dart';
import '../../data/fakes/fake_rsvp_repository.dart';
import '../../data/fakes/fake_poll_repository.dart';
import '../../data/fakes/fake_chat_repository.dart';
import '../../data/fakes/fake_suggestion_repository.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/poll.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/rsvp_repository.dart';
import '../../domain/repositories/poll_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../../domain/usecases/get_event_detail.dart';
import '../../domain/usecases/get_event_rsvps.dart';
import '../../domain/usecases/submit_rsvp.dart';
import '../../domain/usecases/get_event_polls.dart';
import '../../domain/usecases/get_recent_messages.dart';
import '../../domain/usecases/get_event_suggestions.dart';
import '../../domain/usecases/create_suggestion.dart';
import '../../domain/usecases/toggle_suggestion_vote.dart';

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

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  return FakeSuggestionRepository();
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

final getEventSuggestionsProvider = Provider<GetEventSuggestions>((ref) {
  return GetEventSuggestions(ref.watch(suggestionRepositoryProvider));
});

final createSuggestionProvider = Provider<CreateSuggestion>((ref) {
  return CreateSuggestion(ref.watch(suggestionRepositoryProvider));
});

final toggleSuggestionVoteProvider = Provider<ToggleSuggestionVote>((ref) {
  return ToggleSuggestionVote(ref.watch(suggestionRepositoryProvider));
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
final recentMessagesProvider =
    StateNotifierProvider.family<
      MessagesNotifier,
      AsyncValue<List<ChatMessage>>,
      String
    >((ref, eventId) {
      return MessagesNotifier(
        repository: ref.watch(chatRepositoryProvider),
        eventId: eventId,
      );
    });

// Unread messages count provider
final unreadMessagesCountProvider = Provider.family<int, String>((
  ref,
  eventId,
) {
  final messagesAsync = ref.watch(recentMessagesProvider(eventId));

  return messagesAsync.when(
    data: (messages) {
      // Count unread messages from other users only
      return messages
          .where((m) => !m.read && m.userId != 'current-user')
          .length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Messages notifier to manage state without losing messages
class MessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository repository;
  final String eventId;

  MessagesNotifier({required this.repository, required this.eventId})
    : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await repository.getRecentMessages(eventId);
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addMessage(ChatMessage message) async {
    state.whenData((currentMessages) {
      final updatedMessages = [...currentMessages, message];
      // Sort by timestamp to maintain order
      updatedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(updatedMessages);
    });
  }

  Future<void> refreshMessages() async {
    await _loadMessages();
  }
}

// Event suggestions state provider
final eventSuggestionsProvider =
    FutureProvider.family<List<Suggestion>, String>((ref, eventId) async {
      final useCase = ref.watch(getEventSuggestionsProvider);
      final result = await useCase(eventId);
      return result;
    });

// Suggestion votes state provider
final suggestionVotesProvider =
    FutureProvider.family<List<SuggestionVote>, String>((ref, eventId) async {
      final repository = ref.watch(suggestionRepositoryProvider);
      return await repository.getEventSuggestionVotes(eventId);
    });

// User suggestion votes state provider
final userSuggestionVotesProvider =
    FutureProvider.family<List<SuggestionVote>, String>((ref, eventId) async {
      final repository = ref.watch(suggestionRepositoryProvider);
      // TODO: Get current user ID from auth service
      return await repository.getUserSuggestionVotes(
        eventId: eventId,
        userId: 'current-user',
      );
    });

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

  Future<void> submitVote(RsvpStatus status, {WidgetRef? ref}) async {
    try {
      // TODO: Get current user ID from auth service
      final rsvp = await repository.submitRsvp(eventId, 'current-user', status);
      state = AsyncValue.data(rsvp);

      // If changing to "Can" (going), auto-vote for current event suggestion
      // If changing from "Can" to something else, remove vote from current event suggestion
      if (ref != null) {
        try {
          await _syncWithCurrentEventSuggestion(status, ref);
        } catch (e) {
          // Log error but don't fail the RSVP submission
          // print('Failed to sync RSVP with suggestion vote: $e');
        }
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Reload on error to get consistent state
      _loadUserRsvp();
    }
  }

  Future<void> _syncWithCurrentEventSuggestion(
    RsvpStatus status,
    WidgetRef ref,
  ) async {
    try {
      // Get suggestions to find the current event suggestion
      final suggestions = await ref.read(
        eventSuggestionsProvider(eventId).future,
      );
      if (suggestions.isEmpty) return;

      // Find current event suggestion (it should be the first one with event's date/time)
      final event = await ref.read(eventDetailProvider(eventId).future);
      if (event.startDateTime == null) return;

      final currentEventSuggestion = suggestions.firstWhere(
        (s) =>
            s.startDateTime.isAtSameMomentAs(event.startDateTime!) &&
            (s.endDateTime?.isAtSameMomentAs(
                  event.endDateTime ?? event.startDateTime!,
                ) ??
                true),
        orElse: () => suggestions
            .first, // Fallback to first suggestion if exact match not found
      );

      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      final userVotes = await ref.read(
        userSuggestionVotesProvider(eventId).future,
      );
      final hasVotedForCurrentSuggestion = userVotes.any(
        (vote) => vote.suggestionId == currentEventSuggestion.id,
      );

      if (status == RsvpStatus.going && !hasVotedForCurrentSuggestion) {
        // User voted "Can" - add vote for current event suggestion
        await suggestionRepository.voteOnSuggestion(
          suggestionId: currentEventSuggestion.id,
          userId: 'current-user',
        );
        ref.invalidate(suggestionVotesProvider(eventId));
        ref.invalidate(userSuggestionVotesProvider(eventId));
      } else if (status != RsvpStatus.going && hasVotedForCurrentSuggestion) {
        // User voted "Can't" or "Pending" - remove vote from current event suggestion
        await suggestionRepository.removeVoteFromSuggestion(
          suggestionId: currentEventSuggestion.id,
          userId: 'current-user',
        );
        ref.invalidate(suggestionVotesProvider(eventId));
        ref.invalidate(userSuggestionVotesProvider(eventId));
      }
    } catch (e) {
      // Log but don't throw
      // print('Error syncing RSVP with suggestion: $e');
    }
  }
}

// Send message notifier
final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
      return SendMessageNotifier(
        repository: ref.watch(chatRepositoryProvider),
        ref: ref,
      );
    });

// Create suggestion notifier
final createSuggestionNotifierProvider =
    StateNotifierProvider<CreateSuggestionNotifier, AsyncValue<void>>((ref) {
      return CreateSuggestionNotifier(
        createSuggestion: ref.watch(createSuggestionProvider),
        ref: ref,
      );
    });

// Toggle suggestion vote notifier
final toggleSuggestionVoteNotifierProvider =
    StateNotifierProvider<ToggleSuggestionVoteNotifier, AsyncValue<void>>((
      ref,
    ) {
      return ToggleSuggestionVoteNotifier(
        toggleVote: ref.watch(toggleSuggestionVoteProvider),
        ref: ref,
      );
    });

class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository repository;
  final Ref ref;

  SendMessageNotifier({required this.repository, required this.ref})
    : super(const AsyncValue.data(null));

  Future<void> sendMessage(String eventId, String content) async {
    state = const AsyncValue.loading();
    try {
      // Send the message
      final message = await repository.sendMessage(
        eventId,
        'current-user',
        content,
      );

      // Add the message to the local state without losing other messages
      ref.read(recentMessagesProvider(eventId).notifier).addMessage(message);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class CreateSuggestionNotifier extends StateNotifier<AsyncValue<void>> {
  final CreateSuggestion createSuggestion;
  final Ref ref;

  CreateSuggestionNotifier({required this.createSuggestion, required this.ref})
    : super(const AsyncValue.data(null));

  Future<void> createSuggestion_({
    required String eventId,
    required DateTime startDateTime,
    DateTime? endDateTime,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Create the requested suggestion
      // Get event details for current dates
      final event = await ref.read(eventDetailProvider(eventId).future);

      final userSuggestion = await createSuggestion(
        eventId: eventId,
        userId: 'current-user',
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        currentEventStartDateTime: event.startDateTime,
        currentEventEndDateTime: event.endDateTime,
      );

      // Automatically vote for the user's new suggestion
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.voteOnSuggestion(
        suggestionId: userSuggestion.id,
        userId: 'current-user',
      );

      // Invalidate providers to refresh data
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ToggleSuggestionVoteNotifier extends StateNotifier<AsyncValue<void>> {
  final ToggleSuggestionVote toggleVote;
  final Ref ref;

  ToggleSuggestionVoteNotifier({required this.toggleVote, required this.ref})
    : super(const AsyncValue.data(null));

  Future<void> toggleVote_(String eventId, String suggestionId) async {
    state = const AsyncValue.loading();
    try {
      // Check if this is the current event suggestion before toggling
      final isCurrentEventSuggestion = await _isCurrentEventSuggestion(
        eventId,
        suggestionId,
      );

      // Get current vote status
      final userVotes = await ref.read(
        userSuggestionVotesProvider(eventId).future,
      );
      final hasCurrentVote = userVotes.any(
        (vote) => vote.suggestionId == suggestionId,
      );

      // TODO: Get current user ID from auth service
      await toggleVote(
        suggestionId: suggestionId,
        userId: 'current-user',
        eventId: eventId,
      );

      // If this is the current event suggestion, sync with RSVP
      if (isCurrentEventSuggestion) {
        try {
          final rsvpRepository = ref.read(rsvpRepositoryProvider);
          final currentRsvp = await rsvpRepository.getUserRsvp(
            eventId,
            'current-user',
          );

          if (!hasCurrentVote) {
            // User just voted for current event suggestion - change RSVP to "Can"
            if (currentRsvp?.status != RsvpStatus.going) {
              await rsvpRepository.submitRsvp(
                eventId,
                'current-user',
                RsvpStatus.going,
              );
              ref.invalidate(userRsvpProvider(eventId));
              ref.invalidate(eventRsvpsProvider(eventId));
            }
          } else {
            // User just removed vote from current event suggestion - change RSVP to "Can't"
            if (currentRsvp?.status != RsvpStatus.notGoing) {
              await rsvpRepository.submitRsvp(
                eventId,
                'current-user',
                RsvpStatus.notGoing,
              );
              ref.invalidate(userRsvpProvider(eventId));
              ref.invalidate(eventRsvpsProvider(eventId));
            }
          }
        } catch (e) {
          // Log error but don't fail suggestion vote
          // print('Failed to sync suggestion vote with RSVP: $e');
        }
      }

      // Invalidate providers to refresh data
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> _isCurrentEventSuggestion(
    String eventId,
    String suggestionId,
  ) async {
    try {
      final suggestions = await ref.read(
        eventSuggestionsProvider(eventId).future,
      );
      if (suggestions.isEmpty) return false;

      final event = await ref.read(eventDetailProvider(eventId).future);
      if (event.startDateTime == null) return false;

      // Find the suggestion with matching date/time to current event
      final currentEventSuggestion = suggestions.firstWhere(
        (s) =>
            s.startDateTime.isAtSameMomentAs(event.startDateTime!) &&
            (s.endDateTime?.isAtSameMomentAs(
                  event.endDateTime ?? event.startDateTime!,
                ) ??
                true),
        orElse: () => suggestions.first, // Fallback to first suggestion
      );

      return currentEventSuggestion.id == suggestionId;
    } catch (e) {
      return false;
    }
  }
}
