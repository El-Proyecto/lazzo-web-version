import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';
import '../../domain/usecases/get_pending_events.dart';
import '../../domain/usecases/vote_on_event.dart';
import '../../data/fakes/fake_pending_event_repository.dart';

// Repository provider (default: Fake)
final pendingEventRepositoryProvider = Provider<PendingEventRepository>(
  (_) => FakePendingEventRepository(),
);

// Use cases
final getPendingEventsProvider = Provider.autoDispose<GetPendingEvents>(
  (ref) => GetPendingEvents(ref.watch(pendingEventRepositoryProvider)),
);

final voteOnEventProvider = Provider.autoDispose<VoteOnEvent>(
  (ref) => VoteOnEvent(ref.watch(pendingEventRepositoryProvider)),
);

// Current user ID
final currentUserIdProvider = Provider.autoDispose<String?>(
  (_) => Supabase.instance.client.auth.currentUser?.id,
);

// Stacked events state provider
final stackedEventsStateProvider =
    StateNotifierProvider.autoDispose<StackedEventsNotifier, bool>(
      (ref) => StackedEventsNotifier(ref),
    );

// Stacked events notifier
class StackedEventsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  StackedEventsNotifier(this._ref) : super(true); // Always start stacked

  void toggleStacking() {
    // Only allow stacking if there are multiple events
    final eventsAsync = _ref.read(pendingEventsControllerProvider);
    eventsAsync.whenData((events) {
      if (events.length > 1) {
        state = !state;
      }
    });
  }

  void setStacked(bool isStacked) {
    final eventsAsync = _ref.read(pendingEventsControllerProvider);
    eventsAsync.whenData((events) {
      if (events.length > 1) {
        state = isStacked;
      } else {
        state = false; // Single event should never be stacked
      }
    });
  }

  // Reset to stacked state (called when entering the page)
  void resetToStacked() {
    final eventsAsync = _ref.read(pendingEventsControllerProvider);
    eventsAsync.whenData((events) {
      if (events.length > 1) {
        state = true;
      }
    });
  }
}

// Pending events list controller
final pendingEventsControllerProvider =
    FutureProvider.autoDispose<List<PendingEvent>>((ref) async {
      final uid =
          ref.watch(currentUserIdProvider) ??
          '1d473830-e62a-4aaf-a744-9b22343bfd1d';
      final getPendingEvents = ref.watch(getPendingEventsProvider);
      final events = await getPendingEvents(uid);

      // Sort events by scheduled date (closest first)
      final sortedEvents = events
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      // If multiple events and user has voted, start collapsed
      if (sortedEvents.length > 1) {
        return sortedEvents.map((event) {
          if (event.voteStatus == VoteStatus.votersExpanded) {
            return PendingEvent(
              eventId: event.eventId,
              title: event.title,
              emoji: event.emoji,
              scheduledDate: event.scheduledDate,
              location: event.location,
              voteStatus: VoteStatus.voted, // Start collapsed
              totalVoters: event.totalVoters,
              voters: event.voters,
              noResponseVoters: event.noResponseVoters,
              noResponseCount: event.noResponseCount,
            );
          }
          return event;
        }).toList();
      }

      return sortedEvents;
    });

// Individual vote state controller
final voteStateProvider =
    StateNotifierProvider.family<VoteStateNotifier, VoteState, String>(
      (ref, eventId) => VoteStateNotifier(
        eventId: eventId,
        voteOnEvent: ref.watch(voteOnEventProvider),
        currentUserId:
            ref.watch(currentUserIdProvider) ??
            '1d473830-e62a-4aaf-a744-9b22343bfd1d',
      ),
    );

// Vote state for individual events
class VoteState {
  final VoteStatus status;
  final bool isLoading;
  final String? error;
  final bool? userVote; // true=yes, false=no, null=no vote

  const VoteState({
    required this.status,
    this.isLoading = false,
    this.error,
    this.userVote,
  });

  VoteState copyWith({
    VoteStatus? status,
    bool? isLoading,
    String? error,
    bool? userVote,
  }) {
    return VoteState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userVote: userVote ?? this.userVote,
    );
  }
}

// Vote state notifier
class VoteStateNotifier extends StateNotifier<VoteState> {
  final String eventId;
  final VoteOnEvent voteOnEvent;
  final String currentUserId;

  VoteStateNotifier({
    required this.eventId,
    required this.voteOnEvent,
    required this.currentUserId,
  }) : super(const VoteState(status: VoteStatus.vote));

  void toggleExpansion() {
    if (state.status == VoteStatus.voted || state.status == VoteStatus.vote) {
      state = state.copyWith(status: VoteStatus.votersExpanded);
    } else if (state.status == VoteStatus.votersExpanded) {
      state = state.copyWith(status: VoteStatus.voted);
    }
  }

  void startVoting() {
    if (state.status == VoteStatus.vote) {
      state = state.copyWith(status: VoteStatus.voting);
    }
  }

  void resetToVoting() {
    // Allow user to vote again, going back to voting state
    state = state.copyWith(
      status: VoteStatus.voting,
      isLoading: false,
      error: null,
    );
  }

  Future<void> vote(bool isYes) async {
    if (state.isLoading) return;

    state = state.copyWith(status: VoteStatus.voting, isLoading: true);

    try {
      final success = await voteOnEvent(eventId, currentUserId, isYes);
      if (success) {
        state = state.copyWith(
          status: VoteStatus.voted,
          isLoading: false,
          error: null,
          userVote: isYes,
        );
      } else {
        state = state.copyWith(
          status: VoteStatus.vote,
          isLoading: false,
          error: 'Failed to vote',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: VoteStatus.vote,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
