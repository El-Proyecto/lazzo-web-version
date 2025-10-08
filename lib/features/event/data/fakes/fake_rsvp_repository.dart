import '../../domain/entities/rsvp.dart';
import '../../domain/repositories/rsvp_repository.dart';

/// Fake RSVP repository for development
class FakeRsvpRepository implements RsvpRepository {
  final List<Rsvp> _rsvps = [
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
    await Future.delayed(const Duration(milliseconds: 400));

    final existingIndex = _rsvps.indexWhere(
      (r) => r.eventId == eventId && r.userId == userId,
    );

    final newRsvp = Rsvp(
      id: existingIndex >= 0
          ? _rsvps[existingIndex].id
          : 'rsvp-new-${_rsvps.length}',
      eventId: eventId,
      userId: userId,
      userName: existingIndex >= 0
          ? _rsvps[existingIndex].userName
          : 'Current User',
      userAvatar: existingIndex >= 0 ? _rsvps[existingIndex].userAvatar : null,
      status: status,
      createdAt: existingIndex >= 0
          ? _rsvps[existingIndex].createdAt
          : DateTime.now(),
    );

    if (existingIndex >= 0) {
      _rsvps[existingIndex] = newRsvp;
    } else {
      _rsvps.add(newRsvp);
    }

    return newRsvp;
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

    // In a real implementation, this would:
    // 1. Find all RSVP votes for the event that voted on the given suggestion
    // 2. Update those votes to reflect their suggestion choice (going/not going)
    // 3. Clear their suggestion vote data

    // For fake implementation, just simulate the operation
    print(
      'Resetting RSVP votes for event $eventId from suggestion voters: $suggestionVoterUserIds',
    );
  }
}
