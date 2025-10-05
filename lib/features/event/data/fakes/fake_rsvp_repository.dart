import '../../domain/entities/rsvp.dart';
import '../../domain/repositories/rsvp_repository.dart';

/// Fake RSVP repository for development
class FakeRsvpRepository implements RsvpRepository {
  final List<Rsvp> _rsvps = [
    Rsvp(
      id: 'rsvp-1',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      status: RsvpStatus.going,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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
      userName: 'Pedro Costa',
      userAvatar: null,
      status: RsvpStatus.notGoing,
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
    return _rsvps.firstWhere(
      (r) => r.eventId == eventId && r.userId == userId,
      orElse: () => Rsvp(
        id: 'rsvp-new',
        eventId: eventId,
        userId: userId,
        userName: 'Current User',
        status: RsvpStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
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
      id: existingIndex >= 0 ? _rsvps[existingIndex].id : 'rsvp-new',
      eventId: eventId,
      userId: userId,
      userName: 'Current User',
      status: status,
      createdAt: DateTime.now(),
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
}
