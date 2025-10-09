import '../../domain/entities/event_detail.dart';
import '../../domain/repositories/event_repository.dart';

/// Fake event repository for development
class FakeEventRepository implements EventRepository {
  // Static storage to persist data across calls
  static final Map<String, EventDetail> _events = {};

  // Initialize with default data
  static void _initializeIfEmpty() {
    if (_events.isEmpty) {
      _events['event-1'] = EventDetail(
        id: 'event-1',
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
  }

  // Method to update RSVP counts (called after date is set)
  static void updateRsvpCounts(
    String eventId,
    int goingCount,
    int notGoingCount,
  ) {
    final event = _events[eventId];
    if (event != null) {
      _events[eventId] = EventDetail(
        id: event.id,
        name: event.name,
        emoji: event.emoji,
        groupId: event.groupId,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        location: event.location,
        status: event.status,
        createdAt: event.createdAt,
        hostId: event.hostId,
        goingCount: goingCount,
        notGoingCount: notGoingCount,
      );
    }
  }

  @override
  Future<EventDetail> getEventDetail(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _initializeIfEmpty();

    final event = _events[eventId];
    if (event != null) {
      return event;
    }
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

    _initializeIfEmpty();

    // Get the existing event or create a default one
    final existingEvent =
        _events[eventId] ??
        EventDetail(
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

    // Update the event with new date/time
    final updatedEvent = EventDetail(
      id: existingEvent.id,
      name: existingEvent.name,
      emoji: existingEvent.emoji,
      groupId: existingEvent.groupId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: existingEvent.location,
      status: existingEvent.status,
      createdAt: existingEvent.createdAt,
      hostId: existingEvent.hostId,
      goingCount: existingEvent.goingCount,
      notGoingCount: existingEvent.notGoingCount,
    );

    // Store the updated event
    _events[eventId] = updatedEvent;

    return updatedEvent;
  }
}
