import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

/// Fake implementation of EventRepository for development and testing
/// Returns mock data without external dependencies
class FakeEventRepository implements EventRepository {
  final List<Event> _events = [];
  int _idCounter = 1;

  @override
  Future<Event> createEvent(Event event) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final createdEvent = event.copyWith(
      id: _idCounter.toString(),
      status: EventStatus.planning,
    );

    _events.add(createdEvent);
    _idCounter++;

    return createdEvent;
  }

  @override
  Future<Event?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _events.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<Event> updateEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      throw Exception('Event not found');
    }

    _events[index] = event;
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Event>> getEventsForGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.where((e) => e.groupId == groupId).toList();
  }

  @override
  Future<List<EventLocation>> searchLocations(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Mock location data for development
    return [
          const EventLocation(
            id: '1',
            displayName: 'Starbucks Coffee',
            formattedAddress: '123 Main St, Downtown',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          const EventLocation(
            id: '2',
            displayName: 'Central Park',
            formattedAddress: 'Central Park, New York, NY',
            latitude: 40.7829,
            longitude: -73.9654,
          ),
          const EventLocation(
            id: '3',
            displayName: 'Local Restaurant',
            formattedAddress: '456 Oak Ave, Midtown',
            latitude: 40.7589,
            longitude: -73.9851,
          ),
        ]
        .where(
          (loc) =>
              loc.displayName.toLowerCase().contains(query.toLowerCase()) ||
              loc.formattedAddress.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<EventLocation?> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Mock current location
    return const EventLocation(
      id: 'current',
      displayName: 'Current Location',
      formattedAddress: '789 Current St, My Location',
      latitude: 40.7831,
      longitude: -73.9712,
    );
  }
}
