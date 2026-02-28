import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/analytics_service.dart';
import '../../data/fakes/fake_event_repository.dart';
import '../../data/fakes/fake_rsvp_repository.dart';
import '../../data/fakes/fake_poll_repository.dart';

import '../../data/fakes/fake_suggestion_repository.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/poll.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/rsvp_repository.dart';
import '../../domain/repositories/poll_repository.dart';

import '../../domain/repositories/suggestion_repository.dart';
import '../../domain/repositories/event_photo_repository.dart';
import '../../domain/usecases/get_event_detail.dart';
import '../../domain/usecases/get_event_rsvps.dart';
import '../../domain/usecases/submit_rsvp.dart';
import '../../domain/usecases/get_event_polls.dart';
import '../../domain/usecases/get_event_suggestions.dart';
import '../../domain/usecases/create_suggestion.dart';
import '../../domain/usecases/create_location_suggestion.dart';
import '../../domain/usecases/toggle_suggestion_vote.dart';
import '../../domain/usecases/update_event_status.dart';
import '../../domain/usecases/extend_event_time.dart';
import '../../domain/usecases/end_event_now.dart';
import '../../domain/entities/event_participant_entity.dart';

// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// LAZZO 2.0: isUserGroupAdminProvider removed (groups removed)

/// Provider to check if current user can manage event (host)
/// LAZZO 2.0: Simplified — only checks if user is event host (no group admin)
final canManageEventProvider =
    FutureProvider.family<bool, String>((ref, eventId) async {
  try {
    // Get event details to check host
    final event = await ref.watch(eventDetailProvider(eventId).future);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) return false;

    // Check if user is event host
    return event.hostId == currentUserId;
  } catch (e) {
    return false;
  }
});

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

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  return FakeSuggestionRepository();
});

// Event photo repository provider (default to fake, override in main.dart)
final eventPhotoRepositoryProvider = Provider<EventPhotoRepository>((ref) {
  throw UnimplementedError(
      'EventPhotoRepository must be overridden in main.dart');
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

final getEventSuggestionsProvider = Provider<GetEventSuggestions>((ref) {
  return GetEventSuggestions(ref.watch(suggestionRepositoryProvider));
});

final createSuggestionProvider = Provider<CreateSuggestion>((ref) {
  return CreateSuggestion(ref.watch(suggestionRepositoryProvider));
});

final createLocationSuggestionProvider = Provider<CreateLocationSuggestion>((
  ref,
) {
  return CreateLocationSuggestion(ref.watch(suggestionRepositoryProvider));
});

final toggleSuggestionVoteProvider = Provider<ToggleSuggestionVote>((ref) {
  return ToggleSuggestionVote(ref.watch(suggestionRepositoryProvider));
});

final updateEventStatusProvider = Provider<UpdateEventStatus>((ref) {
  return UpdateEventStatus(ref.watch(eventRepositoryProvider));
});

// Use cases for event time management
final extendEventTimeProvider = Provider<ExtendEventTime>((ref) {
  return ExtendEventTime(ref.watch(eventRepositoryProvider));
});

final endEventNowProvider = Provider<EndEventNow>((ref) {
  return EndEventNow(ref.watch(eventRepositoryProvider));
});

// Event participants provider
final eventParticipantsProvider =
    FutureProvider.family<List<EventParticipantEntity>, String>(
        (ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getEventParticipants(eventId);
});

// Event status update state provider
class EventStatusNotifier extends StateNotifier<AsyncValue<EventDetail?>> {
  final UpdateEventStatus _updateEventStatus;
  final Ref _ref;

  EventStatusNotifier(this._updateEventStatus, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateStatus(String eventId, EventStatus newStatus,
      {EventStatus? fromStatus}) async {
    state = const AsyncValue.loading();

    try {
      final updatedEvent = await _updateEventStatus(eventId, newStatus);
      state = AsyncValue.data(updatedEvent);

      // Invalidate the event detail provider to refresh the UI
      _ref.invalidate(eventDetailProvider(eventId));

      // Track event_phase_changed
      AnalyticsService.track('event_phase_changed', properties: {
        'event_id': eventId,
        if (fromStatus != null) 'from_phase': fromStatus.name,
        'to_phase': newStatus.name,
        'platform': 'ios',
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final eventStatusNotifierProvider = StateNotifierProvider.family<
    EventStatusNotifier, AsyncValue<EventDetail?>, String>((ref, eventId) {
  return EventStatusNotifier(
    ref.watch(updateEventStatusProvider),
    ref,
  );
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

/// Guest RSVP counts from web invite page (event_guest_rsvps table).
/// Returns a map with 'going', 'not_going', 'maybe' counts.
final guestRsvpCountsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, eventId) async {
  try {
    final response = await Supabase.instance.client
        .from('event_guest_rsvps')
        .select('rsvp')
        .eq('event_id', eventId);

    int going = 0, notGoing = 0, maybe = 0;
    for (final row in response) {
      switch (row['rsvp'] as String?) {
        case 'going':
          going++;
          break;
        case 'not_going':
          notGoing++;
          break;
        case 'maybe':
          maybe++;
          break;
      }
    }
    return {'going': going, 'not_going': notGoing, 'maybe': maybe};
  } catch (_) {
    return {'going': 0, 'not_going': 0, 'maybe': 0};
  }
});

/// Guest RSVP *list* from web invite page (event_guest_rsvps table).
/// Returns individual guest records with names — used for voter display
/// and manage-guests page alongside app participants.
final guestRsvpListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, eventId) async {
  try {
    final response = await Supabase.instance.client
        .from('event_guest_rsvps')
        .select('id, guest_name, rsvp, plus_one, created_at')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return [];
  }
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
    ref: ref,
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
  final currentUserId = ref.watch(currentUserIdProvider);
  return await repository.getUserSuggestionVotes(
    eventId: eventId,
    userId: currentUserId ?? '',
  );
});

// Location suggestions state provider
final eventLocationSuggestionsProvider =
    FutureProvider.family<List<LocationSuggestion>, String>((
  ref,
  eventId,
) async {
  final repository = ref.watch(suggestionRepositoryProvider);
  final suggestions = await repository.getEventLocationSuggestions(eventId);
  return suggestions;
});

// Location suggestion votes state provider
final locationSuggestionVotesProvider =
    FutureProvider.family<List<SuggestionVote>, String>((ref, eventId) async {
  final repository = ref.watch(suggestionRepositoryProvider);
  return await repository.getEventLocationSuggestionVotes(eventId);
});

// User location suggestion votes state provider
final userLocationSuggestionVotesProvider =
    FutureProvider.family<List<SuggestionVote>, String>((ref, eventId) async {
  final repository = ref.watch(suggestionRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return await repository.getUserLocationSuggestionVotes(
    eventId: eventId,
    userId: currentUserId ?? '',
  );
});

// User RSVP state notifier
class UserRsvpNotifier extends StateNotifier<AsyncValue<Rsvp?>> {
  final String eventId;
  final RsvpRepository repository;
  final Ref ref;

  UserRsvpNotifier({
    required this.eventId,
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _loadUserRsvp();
  }

  Future<void> _loadUserRsvp() async {
    state = const AsyncValue.loading();
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      final userRsvp =
          await repository.getUserRsvp(eventId, currentUserId ?? '');
      state = AsyncValue.data(userRsvp);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Submit a vote.
  /// [isAutoVote] — true when called programmatically (e.g. host auto-vote
  /// after edit). Skips analytics tracking.
  Future<void> submitVote(RsvpStatus status, {bool isAutoVote = false}) async {
    try {
      // Capture previous vote BEFORE submitting (for rsvp_changed tracking)
      final previousStatus = state.value?.status;

      final currentUserId = ref.read(currentUserIdProvider);

      final rsvp =
          await repository.submitRsvp(eventId, currentUserId ?? '', status);

      // Sync with current event suggestion
      try {
        await _syncWithCurrentEventSuggestion(status);
      } catch (e) {
        // Log error but don't fail the RSVP submission
      }

      // Invalidate providers using StateNotifier's ref
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));

      // Update local state - this triggers UI rebuild
      state = AsyncValue.data(rsvp);

      // Track analytics (skip for auto-votes like host auto-vote after edit)
      if (!isAutoVote) {
        final hadPreviousVote =
            previousStatus != null && previousStatus != RsvpStatus.pending;

        if (hadPreviousVote) {
          // User already had a vote → track as rsvp_changed
          AnalyticsService.track('rsvp_changed', properties: {
            'event_id': eventId,
            'from_vote': previousStatus.name,
            'to_vote': status.name,
            'platform': 'ios',
          });
        } else {
          // First vote → track as rsvp_submitted
          AnalyticsService.track('rsvp_submitted', properties: {
            'event_id': eventId,
            'vote': status.name,
            'platform': 'ios',
          });
        }
      }

      // Check auto-confirmation after RSVP submission
      await _checkAutoConfirmation();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _loadUserRsvp();
    }
  }

  Future<void> _checkAutoConfirmation() async {
    try {
      // Get fresh data directly from repositories to avoid cache issues
      final eventRepository = ref.read(eventRepositoryProvider);
      final rsvpRepository = ref.read(rsvpRepositoryProvider);

      final event = await eventRepository.getEventDetail(eventId);

      if (event.status == EventStatus.pending) {
        final rsvps = await rsvpRepository.getEventRsvps(eventId);
        final totalVotes = rsvps.length;
        final goingVotes =
            rsvps.where((r) => r.status == RsvpStatus.going).length;

        // Check conditions: >50% going AND minimum 3 going votes
        if (totalVotes > 0 && goingVotes >= 3) {
          final goingPercentage = (goingVotes / totalVotes) * 100;

          if (goingPercentage > 50) {
            // Auto-confirm the event
            await ref
                .read(eventStatusNotifierProvider(eventId).notifier)
                .updateStatus(eventId, EventStatus.confirmed,
                    fromStatus: EventStatus.pending);
          }
        }
      }
    } catch (e) {
      // Log error but don't fail the RSVP submission
    }
  }

  Future<void> _syncWithCurrentEventSuggestion(RsvpStatus status) async {
    try {
      // NOTE: Manual sync is disabled because the FakeRsvpRepository.submitRsvp()
      // already calls FakeSuggestionRepository.syncCurrentSuggestionWithRsvp()
      // which handles vote synchronization automatically.
      //
      // Keeping this method for potential future use with real Supabase implementation
      // where sync might need to be handled differently.

      // Just invalidate providers to refresh the UI with updated data
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));

      // Also invalidate location suggestion providers to sync location votes with RSVP
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));
    } catch (e) {
      // Silent fail - don't break RSVP flow
    }
  }
}

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

// Create location suggestion notifier
final createLocationSuggestionNotifierProvider =
    StateNotifierProvider<CreateLocationSuggestionNotifier, AsyncValue<void>>((
  ref,
) {
  return CreateLocationSuggestionNotifier(
    repository: ref.watch(suggestionRepositoryProvider),
    ref: ref,
  );
});

// Toggle location suggestion vote notifier
final toggleLocationSuggestionVoteNotifierProvider = StateNotifierProvider<
    ToggleLocationSuggestionVoteNotifier, AsyncValue<void>>((ref) {
  return ToggleLocationSuggestionVoteNotifier(
    repository: ref.watch(suggestionRepositoryProvider),
    ref: ref,
  );
});

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
      final currentUserId = ref.read(currentUserIdProvider);
      // Create the requested suggestion
      // Get event details for current dates
      final event = await ref.read(eventDetailProvider(eventId).future);

      final userSuggestion = await createSuggestion(
        eventId: eventId,
        userId: currentUserId ?? '',
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        currentEventStartDateTime: event.startDateTime,
        currentEventEndDateTime: event.endDateTime,
      );

      // Automatically vote for the user's new suggestion
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.voteOnSuggestion(
        suggestionId: userSuggestion.id,
        userId: currentUserId ?? '',
        eventId: eventId,
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
      final currentUserId = ref.read(currentUserIdProvider);
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

      await toggleVote(
        suggestionId: suggestionId,
        userId: currentUserId ?? '',
        eventId: eventId,
      );

      // If this is the current event suggestion, sync with RSVP
      if (isCurrentEventSuggestion) {
        try {
          final rsvpRepository = ref.read(rsvpRepositoryProvider);
          final currentRsvp = await rsvpRepository.getUserRsvp(
            eventId,
            currentUserId ?? '',
          );

          if (!hasCurrentVote) {
            // User just voted for current event suggestion - change RSVP to "Can"
            if (currentRsvp?.status != RsvpStatus.going) {
              await rsvpRepository.submitRsvp(
                eventId,
                currentUserId ?? '',
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
                currentUserId ?? '',
                RsvpStatus.notGoing,
              );
              ref.invalidate(userRsvpProvider(eventId));
              ref.invalidate(eventRsvpsProvider(eventId));
            }
          }
        } catch (e) {
          // Log error but don't fail suggestion vote
        }
      }

      // Invalidate and force immediate refresh to update vote counts in UI
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

class CreateLocationSuggestionNotifier extends StateNotifier<AsyncValue<void>> {
  final SuggestionRepository repository;
  final Ref ref;

  CreateLocationSuggestionNotifier({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> createLocationSuggestion({
    required String eventId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? currentEventLocationName,
    String? currentEventAddress,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      // Create the requested location suggestion
      final userSuggestion = await repository.createLocationSuggestion(
        eventId: eventId,
        userId: currentUserId ?? '',
        locationName: locationName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        currentEventLocationName: currentEventLocationName,
        currentEventAddress: currentEventAddress,
      );

      // Automatically vote for the user's new suggestion
      await repository.voteOnLocationSuggestion(
        suggestionId: userSuggestion.id,
        userId: currentUserId ?? '',
      );

      // Invalidate providers to refresh data
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ToggleLocationSuggestionVoteNotifier
    extends StateNotifier<AsyncValue<void>> {
  final SuggestionRepository repository;
  final Ref ref;

  ToggleLocationSuggestionVoteNotifier({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> toggleVote(String eventId, String suggestionId) async {
    state = const AsyncValue.loading();
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      // Get current vote status
      final userVotes = await ref.read(
        userLocationSuggestionVotesProvider(eventId).future,
      );
      final hasCurrentVote = userVotes.any(
        (vote) => vote.suggestionId == suggestionId,
      );

      if (hasCurrentVote) {
        // Remove vote
        await repository.removeVoteFromLocationSuggestion(
          suggestionId: suggestionId,
          userId: currentUserId ?? '',
        );
      } else {
        // Add vote
        await repository.voteOnLocationSuggestion(
          suggestionId: suggestionId,
          userId: currentUserId ?? '',
        );
      }

      // Invalidate and force immediate refresh to update vote counts in UI
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ===== COMBINED DATA PROVIDERS =====
// These providers combine multiple async dependencies into single data models
// Reduces nesting in UI from 3-4 levels to 1 level

/// Combined provider for date/time suggestions with all dependencies
/// Combines: suggestions, votes, user votes, and RSVP going count
final dateTimeSuggestionsDataProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, eventId) async {
    // Fetch all dependencies in parallel
    final results = await Future.wait([
      ref.watch(eventSuggestionsProvider(eventId).future),
      ref.watch(suggestionVotesProvider(eventId).future),
      ref.watch(userSuggestionVotesProvider(eventId).future),
      ref.watch(eventRsvpsProvider(eventId).future),
    ]);

    final suggestions = results[0] as List<Suggestion>;
    final allVotes = results[1] as List<SuggestionVote>;
    final userVotes = results[2] as List<SuggestionVote>;
    final rsvps = results[3] as List<Rsvp>;

    // Calculate going count for current event option
    final goingCount = rsvps.where((r) => r.status == RsvpStatus.going).length;

    final userVoteIds = userVotes.map((vote) => vote.suggestionId).toSet();

    return {
      'suggestions': suggestions,
      'allVotes': allVotes,
      'userVoteIds': userVoteIds,
      'goingCount': goingCount,
    };
  },
);

/// Combined provider for location suggestions with all dependencies
/// Combines: location suggestions, votes, user votes, and RSVP going count
final locationSuggestionsDataProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, eventId) async {
    // Fetch all dependencies in parallel
    final results = await Future.wait([
      ref.watch(eventLocationSuggestionsProvider(eventId).future),
      ref.watch(locationSuggestionVotesProvider(eventId).future),
      ref.watch(userLocationSuggestionVotesProvider(eventId).future),
      ref.watch(eventRsvpsProvider(eventId).future),
    ]);

    final locationSuggestions = results[0] as List<LocationSuggestion>;
    final locationVotes = results[1] as List<SuggestionVote>;
    final userLocationVotes = results[2] as List<SuggestionVote>;
    final rsvps = results[3] as List<Rsvp>;

    for (var i = 0; i < locationSuggestions.length; i++) {}

    // Calculate going count for current event location
    final goingCount = rsvps.where((r) => r.status == RsvpStatus.going).length;

    final userVoteIds =
        userLocationVotes.map((vote) => vote.suggestionId).toSet();

    return {
      'locationSuggestions': locationSuggestions,
      'locationVotes': locationVotes,
      'userVoteIds': userVoteIds,
      'goingCount': goingCount,
    };
  },
);
