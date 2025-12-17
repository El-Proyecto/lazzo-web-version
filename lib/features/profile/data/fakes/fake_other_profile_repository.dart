import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/invite_group_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../../group_hub/domain/entities/group_event_entity.dart';

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

  @override
  Future<List<InviteGroupEntity>> getInvitableGroups(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const InviteGroupEntity(
        id: '1',
        name: 'Family',
        groupPhotoUrl: 'https://i.pravatar.cc/300?img=20',
        memberCount: 8,
      ),
      const InviteGroupEntity(
        id: '2',
        name: 'Work Friends',
        groupPhotoUrl: 'https://i.pravatar.cc/300?img=21',
        memberCount: 12,
      ),
      const InviteGroupEntity(
        id: '3',
        name: 'College Crew',
        groupPhotoUrl: 'https://i.pravatar.cc/300?img=22',
        memberCount: 15,
      ),
    ];
  }

  @override
  Future<bool> inviteToGroup({
    required String userId,
    required String groupId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Always succeed in fake implementation
    return true;
  }

  @override
  Future<bool> acceptGroupInvite({
    required String userId,
    required String groupId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Always succeed in fake implementation
    print('[FakeRepository] ✅ Accepted group invite (fake)');
    return true;
  }

  @override
  Future<bool> declineGroupInvite({
    required String userId,
    required String groupId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Always succeed in fake implementation
    print('[FakeRepository] ✅ Declined group invite (fake)');
    return true;
  }

  List<GroupEventEntity> _getMockUpcomingEvents() {
    return [
      GroupEventEntity(
        id: '1',
        name: 'Beach Day',
        emoji: '🏖️',
        date: DateTime.now().add(const Duration(days: 5)),
        location: 'Cascais Beach',
        status: GroupEventStatus.confirmed,
        goingCount: 8,
        participantCount: 8,
        photoCount: 0,
        attendeeNames: ['You', 'Ana', 'Marco', '5 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=3',
        ],
        allVotes: [],
        userVote: true,
      ),
      GroupEventEntity(
        id: '2',
        name: 'Movie Night',
        emoji: '🎬',
        date: DateTime.now().add(const Duration(days: 12)),
        location: 'Cinema City',
        status: GroupEventStatus.confirmed,
        goingCount: 6,
        participantCount: 6,
        photoCount: 0,
        attendeeNames: ['You', 'Ana', 'João', '3 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=4',
        ],
        allVotes: [],
        userVote: true,
      ),
      GroupEventEntity(
        id: '3',
        name: 'Birthday Party',
        emoji: '🎉',
        date: DateTime.now().add(const Duration(days: 20)),
        location: "Marco's Place",
        status: GroupEventStatus.confirmed,
        goingCount: 12,
        participantCount: 12,
        photoCount: 0,
        attendeeNames: ['You', 'Ana', 'Marco', 'Sofia', '8 others'],
        attendeeAvatars: [
          'https://i.pravatar.cc/300?img=1',
          'https://i.pravatar.cc/300?img=5',
          'https://i.pravatar.cc/300?img=3',
        ],
        allVotes: [],
        userVote: true,
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
