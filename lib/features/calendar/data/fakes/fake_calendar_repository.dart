import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';

/// Fake calendar repository with sample data for development
class FakeCalendarRepository implements CalendarRepository {
  @override
  Future<List<CalendarEventEntity>> getEventsForMonth(
      int year, int month) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return fake events for the requested month
    final allEvents = _generateFakeEvents();
    return allEvents
        .where((e) =>
            e.date != null && e.date!.year == year && e.date!.month == month)
        .toList()
      ..sort((a, b) =>
          (a.date ?? DateTime(2099)).compareTo(b.date ?? DateTime(2099)));
  }

  @override
  Future<List<CalendarEventEntity>> getAllUpcomingEvents() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final allEvents = _generateFakeEvents();

    // Return upcoming + recent past events sorted by date
    return allEvents
        .where((e) =>
            e.date != null &&
            e.date!.isAfter(now.subtract(const Duration(days: 60))))
        .toList()
      ..sort((a, b) =>
          (a.date ?? DateTime(2099)).compareTo(b.date ?? DateTime(2099)));
  }

  List<CalendarEventEntity> _generateFakeEvents() {
    final now = DateTime.now();
    return [
      CalendarEventEntity(
        id: '1',
        name: 'Cinema (Teste)',
        emoji: '🥳',
        date: DateTime(now.year, now.month, now.day - 7),
        location: 'Teste loc',
        status: CalendarEventStatus.pending,
        groupName: null,
      ),
      CalendarEventEntity(
        id: '2',
        name: 'vbbv',
        emoji: '🏈',
        date: DateTime(now.year, now.month, now.day - 7),
        location: 'União das freguesias de Leiria',
        status: CalendarEventStatus.confirmed,
        groupName: 'Grupo de Teste',
      ),
      CalendarEventEntity(
        id: '3',
        name: 'Football Game',
        emoji: '🏈',
        date: DateTime(now.year, now.month, now.day + 3),
        location: 'Estádio Nacional',
        status: CalendarEventStatus.confirmed,
        groupName: null,
      ),
      CalendarEventEntity(
        id: '4',
        name: 'Party Night',
        emoji: '🥳',
        date: DateTime(now.year, now.month, now.day + 3),
        location: 'Downtown',
        status: CalendarEventStatus.pending,
        groupName: 'Amigos',
      ),
      CalendarEventEntity(
        id: '5',
        name: 'Beach Day',
        emoji: '🏖️',
        date: DateTime(now.year, now.month, now.day + 15),
        coverPhotoUrl: 'https://picsum.photos/200',
        location: 'Praia',
        status: CalendarEventStatus.confirmed,
        groupName: null,
      ),
      CalendarEventEntity(
        id: '6',
        name: 'Movie Night',
        emoji: '🎬',
        date: DateTime(now.year, now.month, now.day - 14),
        location: 'NOS Cinemas',
        status: CalendarEventStatus.confirmed,
        coverPhotoUrl: 'https://picsum.photos/201',
        groupName: null,
      ),
      // Next month event
      CalendarEventEntity(
        id: '7',
        name: 'Dinner',
        emoji: '🍝',
        date: DateTime(now.year, now.month + 1, 10),
        location: 'Restaurante',
        status: CalendarEventStatus.pending,
        groupName: null,
      ),
      // Memory events — ended with cover photo (show as MemorySmallCard)
      CalendarEventEntity(
        id: '8',
        name: 'Weekend Trip',
        emoji: '🏕️',
        date: DateTime(now.year, now.month, 5),
        location: 'Serra da Estrela',
        status: CalendarEventStatus.ended,
        coverPhotoUrl: 'https://picsum.photos/seed/trip/400/300',
        groupName: 'Amigos',
      ),
      CalendarEventEntity(
        id: '9',
        name: 'Birthday Party',
        emoji: '🎂',
        date: DateTime(now.year, now.month - 1, 20),
        location: 'Casa do João',
        status: CalendarEventStatus.ended,
        coverPhotoUrl: 'https://picsum.photos/seed/birthday/400/300',
        groupName: null,
      ),
    ];
  }
}
