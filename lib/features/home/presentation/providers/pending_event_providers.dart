// TODO P2: Remove this file - replaced by new home structure
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';
import '../../domain/usecases/get_pending_events.dart';
import '../../domain/usecases/vote_on_event.dart';
import '../../data/fakes/fake_pending_event_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final pendingEventRepositoryProvider = Provider<PendingEventRepository>(
  (_) => FakePendingEventRepository(),
);

final getPendingEventsProvider = Provider.autoDispose<GetPendingEvents>(
  (ref) => GetPendingEvents(ref.watch(pendingEventRepositoryProvider)),
);

final voteOnEventProvider = Provider.autoDispose<VoteOnEvent>(
  (ref) => VoteOnEvent(ref.watch(pendingEventRepositoryProvider)),
);

final currentUserIdProvider = Provider.autoDispose<String?>(
  (ref) {
    final authState = ref.watch(authProvider);
    return authState.valueOrNull?.id;
  },
);

final stackedEventsStateProvider =
    StateNotifierProvider.autoDispose<StackedEventsNotifier, bool>(
  (ref) => StackedEventsNotifier(ref),
);

class StackedEventsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  StackedEventsNotifier(this._ref) : super(true);

  void toggleStacking() {
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
        state = false;
      }
    });
  }

  void resetToStacked() {
    final eventsAsync = _ref.read(pendingEventsControllerProvider);
    eventsAsync.whenData((events) {
      if (events.length > 1) {
        state = true;
      }
    });
  }
}

final pendingEventsControllerProvider =
    FutureProvider.autoDispose<List<PendingEvent>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);

  if (uid == null) {
    return [];
  }

  final getPendingEvents = ref.watch(getPendingEventsProvider);
  final events = await getPendingEvents(uid);

  final sortedEvents = List<PendingEvent>.from(events)
    ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

  return sortedEvents;
});

// ✅ SIMPLIFICADO: Provider usa eventId, lê userVote do evento
final voteStateProvider =
    StateNotifierProvider.family<VoteStateNotifier, VoteState, String>(
  (ref, eventId) {
    final currentUserId = ref.watch(currentUserIdProvider);

    // Buscar evento da lista
    final eventsAsync = ref.watch(pendingEventsControllerProvider);
    final event = eventsAsync.whenData((events) {
      return events.firstWhere(
        (e) => e.eventId == eventId,
        orElse: () => throw StateError('Event $eventId not found'),
      );
    }).value;

    return VoteStateNotifier(
      ref: ref,
      eventId: eventId,
      initialUserVote: event?.userVote, // ✅ Direto da entity
      voteOnEvent: ref.watch(voteOnEventProvider),
      currentUserId: currentUserId ?? '',
    );
  },
);

class VoteState {
  final VoteStatus status; // UI state (vote/voting/voted/votersExpanded)
  final bool isLoading;
  final String? error;
  final bool? userVote; // null/true/false

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

class VoteStateNotifier extends StateNotifier<VoteState> {
  final Ref ref;
  final String eventId;
  final VoteOnEvent voteOnEvent;
  final String currentUserId;

  VoteStateNotifier({
    required this.ref,
    required this.eventId,
    required bool? initialUserVote, // ✅ SIMPLIFICADO: bool? diretamente
    required this.voteOnEvent,
    required this.currentUserId,
  }) : super(
          VoteState(
            status: initialUserVote == null
                ? VoteStatus.vote // Não votou
                : VoteStatus.voted, // Já votou (yes ou no)
            userVote: initialUserVote,
          ),
        );

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
    state = state.copyWith(
      status: VoteStatus.voting,
      isLoading: false,
      error: null,
    );
  }

  Future<void> vote(bool isYes) async {
    if (state.isLoading) return;

    if (currentUserId.isEmpty) {
      print('❌ Cannot vote: user not authenticated');
      state = state.copyWith(
        status: VoteStatus.vote,
        isLoading: false,
        error: 'User not authenticated',
      );
      return;
    }

    print(
        '🗳️ Starting vote: eventId=$eventId, userId=$currentUserId, isYes=$isYes');
    state = state.copyWith(status: VoteStatus.voting, isLoading: true);

    try {
      final success = await voteOnEvent(eventId, currentUserId, isYes);

      if (success) {
        print('✅ Vote success - updating UI state');

        state = state.copyWith(
          status: VoteStatus.voted,
          isLoading: false,
          error: null,
          userVote: isYes,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        print('🔄 Invalidating events cache...');
        ref.invalidate(pendingEventsControllerProvider);
      } else {
        print('❌ Vote failed - returned false');
        state = state.copyWith(
          status: VoteStatus.vote,
          isLoading: false,
          error: 'Failed to vote',
        );
      }
    } catch (e) {
      print('❌ Vote exception: $e');
      state = state.copyWith(
        status: VoteStatus.vote,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
