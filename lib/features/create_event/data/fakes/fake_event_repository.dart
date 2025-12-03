import '../../domain/entities/event.dart';
import '../../domain/entities/event_history.dart';
import '../../domain/repositories/event_repository.dart';
import 'package:uuid/uuid.dart';

/// Fake implementation of EventRepository for development and testing
/// Returns mock data without external dependencies
class FakeEventRepository implements EventRepository {
  static final List<Event> _events = [];
  static const _uuid = Uuid();

  // Initialize with some test data
  static void _initializeTestData() {
    if (_events.isEmpty) {
      _events.addAll([
        Event(
          id: 'event-1',
          name: 'Churrascada no Parque',
          emoji: '🍖',
          groupId: '1',
          startDateTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
          endDateTime: DateTime.now().add(const Duration(days: 2, hours: 20)),
          location: const EventLocation(
            id: 'loc-1',
            displayName: 'Parque da Cidade',
            formattedAddress: 'Parque da Cidade, Lisboa, Portugal',
            latitude: 38.7223,
            longitude: -9.1393,
          ),
          status: EventStatus.confirmed,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Event(
          id: 'event-2',
          name: 'Jantar de Aniversário',
          emoji: '🎂',
          groupId: '2',
          startDateTime: DateTime.now().add(const Duration(days: 5, hours: 19)),
          endDateTime: DateTime.now().add(const Duration(days: 5, hours: 23)),
          status: EventStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ]);
    }
  }

  @override
  Future<Event> createEvent(Event event) async {
    // Initialize test data if needed
    _initializeTestData();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate UUID-compatible ID for compatibility with real Supabase
    final createdEvent = event.copyWith(
      id: _uuid.v4(),
      status: EventStatus.pending,
    );

    _events.add(createdEvent);

    return createdEvent;
  }

  @override
  Future<Event?> getEventById(String id) async {
    // Initialize test data if needed
    _initializeTestData();

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

  @override
  Future<List<EventHistory>> getUserEventHistory({
    required String userId,
    int limit = 10,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock realistic Portuguese events for development
    final mockHistory = [
      EventHistory(
        id: 'hist-1',
        name: 'Baza ao Rio',
        emoji: '🌊',
        startDateTime: DateTime.now().subtract(const Duration(days: 15)),
        locationName: 'Tascardoso Lisboa',
        locationAddress: 'Rua do Alecrim 47, 1200-014 Lisboa',
        latitude: 38.7093,
        longitude: -9.1431,
        groupId: 'group-1',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      EventHistory(
        id: 'hist-2',
        name: 'Futebol',
        emoji: '⚽',
        startDateTime: DateTime.now().subtract(const Duration(days: 30)),
        locationName: 'Campo do Jamor',
        locationAddress: 'Estádio Nacional, 1495-751 Cruz Quebrada',
        latitude: 38.7182,
        longitude: -9.2344,
        groupId: 'group-2',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      EventHistory(
        id: 'hist-3',
        name: 'Cinema Night',
        emoji: '🎬',
        startDateTime: DateTime.now().subtract(const Duration(days: 45)),
        locationName: 'Cinemas NOS Alvalade',
        locationAddress: 'Praça Alvalade 6, 1700-036 Lisboa',
        latitude: 38.7575,
        longitude: -9.1440,
        groupId: 'group-1',
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
      ),
    ];

    // Respect limit parameter
    return mockHistory.take(limit).toList();
  }
}
