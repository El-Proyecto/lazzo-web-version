import '../../domain/entities/rsvp.dart';
import '../../domain/repositories/rsvp_repository.dart';
import 'fake_event_repository.dart';
import 'fake_suggestion_repository.dart';

/// Fake RSVP repository for development
class FakeRsvpRepository implements RsvpRepository {
  static final List<Rsvp> _rsvps = [
    // Can votes (5 people)
    Rsvp(
      id: 'rsvp-1',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Rsvp(
      id: 'rsvp-2',
      eventId: 'event-1',
      userId: 'user-2',
      userName: 'Maria Santos',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Rsvp(
      id: 'rsvp-3',
      eventId: 'event-1',
      userId: 'user-3',
      userName: 'Ana Costa',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Rsvp(
      id: 'rsvp-4',
      eventId: 'event-1',
      userId: 'user-4',
      userName: 'Ricardo Alves',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(minutes: 90)),
    ),
    Rsvp(
      id: 'rsvp-5',
      eventId: 'event-1',
      userId: 'user-5',
      userName: 'Sofia Lima',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),

    // Can't votes (3 people)
    Rsvp(
      id: 'rsvp-6',
      eventId: 'event-1',
      userId: 'user-6',
      userName: 'Pedro Costa',
      userAvatar: null,
      status: RsvpStatus.notGoing,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Rsvp(
      id: 'rsvp-7',
      eventId: 'event-1',
      userId: 'user-7',
      userName: 'Beatriz Sousa',
      userAvatar: null,
      status: RsvpStatus.notGoing,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Rsvp(
      id: 'rsvp-8',
      eventId: 'event-1',
      userId: 'user-8',
      userName: 'Miguel Rocha',
      userAvatar: null,
      status: RsvpStatus.notGoing,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),

    // Haven't responded (2 people)
    Rsvp(
      id: 'rsvp-9',
      eventId: 'event-1',
      userId: 'user-9',
      userName: 'Inês Ferreira',
      userAvatar: null,
      status: RsvpStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Rsvp(
      id: 'rsvp-10',
      eventId: 'event-1',
      userId: 'user-10',
      userName: 'Tiago Santos',
      userAvatar: null,
      status: RsvpStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),

    // Current user starts as pending
    Rsvp(
      id: 'rsvp-current',
      eventId: 'event-1',
      userId: 'current-user',
      userName: 'Carlos Pereira',
      userAvatar: null,
      status: RsvpStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<Rsvp>> getEventRsvps(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rsvps.where((r) => r.eventId == eventId).toList();
  }

  @override
  Future<Rsvp?> getUserRsvp(String eventId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _rsvps.firstWhere(
        (r) => r.eventId == eventId && r.userId == userId,
      );
    } catch (e) {
      // Return null if no RSVP exists
      return null;
    }
  }

  @override
  Future<Rsvp> submitRsvp(
    String eventId,
    String userId,
    RsvpStatus status,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Find current user name from existing RSVPs or generate one
    String userName;
    String? userAvatar;

    final existingRsvp = _rsvps.firstWhere(
      (r) => r.eventId == eventId && r.userId == userId,
      orElse: () => Rsvp(
        id: '',
        eventId: eventId,
        userId: userId,
        userName: userId == 'current-user' ? 'Carlos Pereira' : 'User $userId',
        userAvatar: null,
        status: RsvpStatus.pending,
        createdAt: DateTime.now(),
      ),
    );

    userName = existingRsvp.userName;
    userAvatar = existingRsvp.userAvatar;

    final rsvp = Rsvp(
      id: 'rsvp_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      status: status,
      createdAt: DateTime.now(),
    );

    // Remove any existing RSVP for this user/event
    _rsvps.removeWhere((r) => r.eventId == eventId && r.userId == userId);
    _rsvps.add(rsvp);

    // Sync with current suggestion votes after RSVP change
    await FakeSuggestionRepository.syncCurrentSuggestionWithRsvp(eventId);

    // Sync with current location suggestion votes after RSVP change
    await FakeSuggestionRepository.syncCurrentLocationSuggestionWithRsvp(
      eventId,
    );

    return rsvp;
  }

  @override
  Future<List<Rsvp>> getRsvpsByStatus(String eventId, RsvpStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rsvps
        .where((r) => r.eventId == eventId && r.status == status)
        .toList();
  }

  @override
  Future<void> resetRsvpVotesFromSuggestion(
    String eventId,
    List<String> suggestionVoterUserIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all RSVPs for this event to update their status
    final eventRsvps = _rsvps.where((rsvp) => rsvp.eventId == eventId).toList();

    // Update each RSVP based on whether they voted on the suggestion
    for (int i = 0; i < eventRsvps.length; i++) {
      final currentRsvp = eventRsvps[i];
      final rsvpIndex = _rsvps.indexWhere((r) => r.id == currentRsvp.id);

      if (rsvpIndex >= 0) {
        // Determine new status: "going" if they voted, "pending" otherwise
        final newStatus = suggestionVoterUserIds.contains(currentRsvp.userId)
            ? RsvpStatus.going
            : RsvpStatus.pending;

        // Create updated RSVP with new status
        final updatedRsvp = Rsvp(
          id: currentRsvp.id,
          eventId: currentRsvp.eventId,
          userId: currentRsvp.userId,
          userName: currentRsvp.userName,
          userAvatar: currentRsvp.userAvatar,
          status: newStatus,
          createdAt: currentRsvp.createdAt,
        );

        _rsvps[rsvpIndex] = updatedRsvp;
      }
    }

    // Update event counts
    await _updateEventCounts(eventId);

    // Sync current suggestion votes with updated RSVP status
    await FakeSuggestionRepository.syncCurrentSuggestionWithRsvp(eventId);

    // Sync current location suggestion votes with updated RSVP status
    await FakeSuggestionRepository.syncCurrentLocationSuggestionWithRsvp(
      eventId,
    );
  }

  Future<void> _updateEventCounts(String eventId) async {
    final eventRsvps = _rsvps.where((r) => r.eventId == eventId).toList();
    final goingCount = eventRsvps
        .where((r) => r.status == RsvpStatus.going)
        .length;
    final notGoingCount = eventRsvps
        .where((r) => r.status == RsvpStatus.notGoing)
        .length;

    // Update counts in FakeEventRepository
    FakeEventRepository.updateRsvpCounts(eventId, goingCount, notGoingCount);
  }
}
