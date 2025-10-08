import '../../domain/entities/event_detail.dart';
import '../../domain/repositories/event_repository.dart';

/// Fake event repository for development
class FakeEventRepository implements EventRepository {
  @override
  Future<EventDetail> getEventDetail(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return EventDetail(
      id: eventId,
      name: 'Churrascada em Sesimbra',
      emoji: '🍖',
      groupId: 'group-1',
      startDateTime: DateTime.now().add(const Duration(days: 3, hours: 14)),
      endDateTime: DateTime.now().add(const Duration(days: 3, hours: 20)),
      location: const EventLocation(
        id: 'loc-1',
        displayName: 'Praia do Meco',
        formattedAddress: 'Praia do Meco, Sesimbra, Portugal',
        latitude: 38.4738,
        longitude: -9.1334,
      ),
      status: EventStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      hostId: 'current-user',
      goingCount: 8,
      notGoingCount: 2,
    );
  }

  @override
  Future<bool> isUserHost(String eventId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return userId == 'current-user';
  }

  @override
  Future<EventDetail> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real implementation, this would update the database
    // For now, return the updated event detail
    return EventDetail(
      id: eventId,
      name: 'Churrascada em Sesimbra',
      emoji: '🍖',
      groupId: 'group-1',
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: const EventLocation(
        id: 'loc-1',
        displayName: 'Praia do Meco',
        formattedAddress: 'Praia do Meco, Sesimbra, Portugal',
        latitude: 38.4738,
        longitude: -9.1334,
      ),
      status: EventStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      hostId: 'current-user',
      goingCount: 8,
      notGoingCount: 2,
    );
  }
}
