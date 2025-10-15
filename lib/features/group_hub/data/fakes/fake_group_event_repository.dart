import '../../domain/entities/group_event_entity.dart';
import '../../domain/repositories/group_event_repository.dart';

/// Fake implementation of GroupEventRepository for development
class FakeGroupEventRepository implements GroupEventRepository {
  final List<GroupEventEntity> _events = [
    GroupEventEntity(
      id: '1',
      name: 'Beach Day',
      emoji: '🏖️',
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Cascais Beach',
      status: GroupEventStatus.confirmed,
      goingCount: 5,
      attendeeAvatars: [
        'https://example.com/avatar1.jpg',
        'https://example.com/avatar2.jpg',
        'https://example.com/avatar3.jpg',
      ],
    ),
    GroupEventEntity(
      id: '2',
      name: 'Movie Night',
      emoji: '🍿',
      date: DateTime.now().add(const Duration(days: 7)),
      location: 'Cinema City',
      status: GroupEventStatus.pending,
      goingCount: 3,
      attendeeAvatars: [
        'https://example.com/avatar4.jpg',
        'https://example.com/avatar5.jpg',
      ],
    ),
    GroupEventEntity(
      id: '3',
      name: 'BBQ Party',
      emoji: '🔥',
      date: DateTime.now().add(const Duration(days: 14)),
      location: 'João\'s House',
      status: GroupEventStatus.confirmed,
      goingCount: 8,
      attendeeAvatars: [
        'https://example.com/avatar1.jpg',
        'https://example.com/avatar2.jpg',
        'https://example.com/avatar3.jpg',
        'https://example.com/avatar4.jpg',
      ],
    ),
  ];

  @override
  Future<List<GroupEventEntity>> getGroupEvents(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _events;
  }

  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }
}
