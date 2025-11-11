import '../../domain/entities/home_event.dart';
import '../../domain/repositories/home_event_repository.dart';

/// Fake repository for home events - used for UI development
/// Returns mock data without backend calls
class FakeHomeEventRepository implements HomeEventRepository {
  @override
  Future<HomeEventEntity?> getNextEvent() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return const HomeEventEntity(
      id: 'event_1',
      name: 'Beach Day with the Squad',
      emoji: '🏖️',
      date: null, // Will show formatted date in UI
      location: 'Praia da Rocha',
      status: HomeEventStatus.confirmed,
      goingCount: 8,
      attendeeAvatars: [
        'https://i.pravatar.cc/150?img=1',
        'https://i.pravatar.cc/150?img=2',
        'https://i.pravatar.cc/150?img=3',
        'https://i.pravatar.cc/150?img=4',
        'https://i.pravatar.cc/150?img=5',
      ],
      attendeeNames: [
        'You',
        'João',
        'Maria',
        'Pedro',
        'Ana',
        'Carlos',
        'Rita',
        'Miguel',
      ],
    );
  }

  @override
  Future<List<HomeEventEntity>> getConfirmedEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const HomeEventEntity(
        id: 'event_2',
        name: 'Dinner at New Restaurant',
        emoji: '🍽️',
        date: null,
        location: 'Downtown Lisbon',
        status: HomeEventStatus.confirmed,
        goingCount: 6,
        attendeeAvatars: [
          'https://i.pravatar.cc/150?img=6',
          'https://i.pravatar.cc/150?img=7',
        ],
        attendeeNames: [
          'Sofia',
          'Tiago',
          'Laura',
          'Bruno',
          'Inês',
          'André',
        ],
      ),
      const HomeEventEntity(
        id: 'event_3',
        name: 'Weekend Hiking Trip',
        emoji: '⛰️',
        date: null,
        location: 'Sintra Mountains',
        status: HomeEventStatus.confirmed,
        goingCount: 5,
        attendeeAvatars: [
          'https://i.pravatar.cc/150?img=8',
          'https://i.pravatar.cc/150?img=9',
        ],
        attendeeNames: [
          'Rui',
          'Catarina',
          'Filipe',
          'Beatriz',
          'You',
        ],
      ),
    ];
  }

  @override
  Future<List<HomeEventEntity>> getPendingEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const HomeEventEntity(
        id: 'event_4',
        name: 'Movie Night',
        emoji: '🎬',
        date: null,
        location: 'To be decided',
        status: HomeEventStatus.pending,
        goingCount: 3,
        attendeeAvatars: [
          'https://i.pravatar.cc/150?img=10',
        ],
        attendeeNames: [
          'Diogo',
          'Mariana',
          'You',
        ],
      ),
      const HomeEventEntity(
        id: 'event_5',
        name: 'Birthday Party',
        emoji: '🎂',
        date: null,
        location: 'Someone\'s House',
        status: HomeEventStatus.pending,
        goingCount: 12,
        attendeeAvatars: [
          'https://i.pravatar.cc/150?img=11',
          'https://i.pravatar.cc/150?img=12',
          'https://i.pravatar.cc/150?img=13',
        ],
        attendeeNames: [
          'Gonçalo',
          'Teresa',
          'Vasco',
          'Marta',
          'Ricardo',
          'Joana',
          'Paulo',
          'Sara',
          'Hugo',
          'Vera',
          'Nuno',
          'Carla',
        ],
      ),
    ];
  }
}
