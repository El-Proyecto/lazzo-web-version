import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../../event/domain/entities/event_display_entity.dart';

/// Fake implementation of OtherProfileRepository for development
class FakeOtherProfileRepository implements OtherProfileRepository {
  @override
  Future<OtherProfileEntity> getOtherUserProfile(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return OtherProfileEntity(
      id: userId,
      name: 'Ana Silva',
      profileImageUrl: 'https://i.pravatar.cc/300?img=5',
      location: 'Lisbon, Portugal',
      birthday: DateTime(1995, 6, 15),
      upcomingTogether: _getMockUpcomingEvents(),
      memoriesTogether: _getMockMemories(),
    );
  }

  // LAZZO 2.0: Group invite methods removed (getInvitableGroups, inviteToGroup, acceptGroupInvite, declineGroupInvite)

  List<EventDisplayEntity> _getMockUpcomingEvents() {
    return [
      EventDisplayEntity(
        id: '1',
        name: 'Beach Day',
        emoji: '🏖️',
        date: DateTime.now().add(const Duration(days: 5)),
        location: 'Cascais Beach',
        status: EventDisplayStatus.confirmed,
        goingCount: 8,
        participantCount: 8,
        attendeeNames: ['You', 'Ana', 'Marco', '5 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=3',
        ],
      ),
      EventDisplayEntity(
        id: '2',
        name: 'Movie Night',
        emoji: '🎬',
        date: DateTime.now().add(const Duration(days: 12)),
        location: 'Cinema City',
        status: EventDisplayStatus.confirmed,
        goingCount: 6,
        participantCount: 6,
        attendeeNames: ['You', 'Ana', 'João', '3 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=4',
        ],
      ),
      EventDisplayEntity(
        id: '3',
        name: 'Birthday Party',
        emoji: '🎉',
        date: DateTime.now().add(const Duration(days: 20)),
        location: "Marco's Place",
        status: EventDisplayStatus.confirmed,
        goingCount: 12,
        participantCount: 12,
        attendeeNames: ['You', 'Ana', 'Marco', 'Sofia', '8 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=3',
        ],
      ),
    ];
  }

  List<MemoryEntity> _getMockMemories() {
    return [
      MemoryEntity(
        id: '1',
        title: 'Summer Vibes',
        coverImageUrl: 'https://picsum.photos/seed/mem1/400/400',
        date: DateTime.now().subtract(const Duration(days: 30)),
        location: 'Algarve',
      ),
      MemoryEntity(
        id: '2',
        title: 'New Year Party',
        coverImageUrl: 'https://picsum.photos/seed/mem2/400/400',
        date: DateTime.now().subtract(const Duration(days: 310)),
        location: 'Lisbon',
      ),
      MemoryEntity(
        id: '3',
        title: 'Concert Night',
        coverImageUrl: 'https://picsum.photos/seed/mem3/400/400',
        date: DateTime.now().subtract(const Duration(days: 90)),
        location: 'Porto',
      ),
      MemoryEntity(
        id: '4',
        title: 'Hiking Trip',
        coverImageUrl: 'https://picsum.photos/seed/mem4/400/400',
        date: DateTime.now().subtract(const Duration(days: 150)),
        location: 'Sintra',
      ),
    ];
  }
}
