import '../../domain/entities/group_event_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../../home/domain/entities/participant_photo.dart';
import 'dart:math' as math;

/// Fake implementation of GroupEventRepository for development
class FakeGroupEventRepository implements GroupEventRepository {
  final List<GroupEventEntity> _events = [
    // Living event - currently active with photos being uploaded
    GroupEventEntity(
      id: '0',
      name: 'Beach Sunset',
      emoji: '🌅',
      date: DateTime.now().subtract(const Duration(hours: 1)),
      endDate: DateTime.now().add(const Duration(hours: 3)), // Ends in 3h
      location: 'Guincho Beach',
      status: GroupEventStatus.living,
      goingCount: 6,
      participantCount: 6,
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Sarah', 'Mike', 'Emma', 'Alex', 'Kate'],
      userVote: true,
      allVotes: [],
      photoCount: 18,
      maxPhotos: math.max(20, 6 * 5), // 30 photos max
      participantPhotos: [
        const ParticipantPhoto(
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          photoCount: 5,
        ),
        const ParticipantPhoto(
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          photoCount: 4,
        ),
        const ParticipantPhoto(
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          photoCount: 3,
        ),
        const ParticipantPhoto(
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          photoCount: 3,
        ),
        const ParticipantPhoto(
          userId: 'user5',
          userName: 'Alex',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          photoCount: 2,
        ),
        const ParticipantPhoto(
          userId: 'user12',
          userName: 'Kate',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
          photoCount: 1,
        ),
      ],
    ),
    // Recap event - ended 2h ago, 22h left to upload photos
    GroupEventEntity(
      id: '00',
      name: 'Hiking Adventure',
      emoji: '⛰️',
      date: DateTime.now().subtract(const Duration(hours: 6)),
      endDate:
          DateTime.now().subtract(const Duration(hours: 2)), // Ended 2h ago
      location: 'Sintra Mountains',
      status: GroupEventStatus.recap,
      goingCount: 7,
      participantCount: 7,
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Mike', 'Tom', 'Lisa', 'Ryan', 'Chris', 'Kate'],
      userVote: true,
      allVotes: [],
      photoCount: 12,
      maxPhotos: math.max(20, 7 * 5), // 35 photos max
      participantPhotos: [
        const ParticipantPhoto(
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          photoCount: 4,
        ),
        const ParticipantPhoto(
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          photoCount: 3,
        ),
        const ParticipantPhoto(
          userId: 'user8',
          userName: 'Tom',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          photoCount: 2,
        ),
        const ParticipantPhoto(
          userId: 'user9',
          userName: 'Lisa',
          userAvatar:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
          photoCount: 2,
        ),
        const ParticipantPhoto(
          userId: 'user13',
          userName: 'Ryan',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          photoCount: 1,
        ),
        const ParticipantPhoto(
          userId: 'user11',
          userName: 'Chris',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          photoCount: 0,
        ),
        const ParticipantPhoto(
          userId: 'user12',
          userName: 'Kate',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
          photoCount: 0,
        ),
      ],
    ),
    GroupEventEntity(
      id: '1',
      name: 'Beach Sunset',
      emoji: '🌅',
      date: DateTime.now()
          .subtract(const Duration(hours: 1)), // Started 1 hour ago
      endDate: DateTime.now().add(const Duration(hours: 2)), // Ends in 2 hours
      location: 'Guincho Beach',
      status: GroupEventStatus.living,
      goingCount: 4,
      participantCount: 6,
      photoCount: 18,
      maxPhotos: 30,
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Sarah', 'Mike', 'Emma'],
      userVote: true,
      allVotes: [
        RsvpVote(
          id: '1',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        RsvpVote(
          id: '2',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RsvpVote(
          id: '3',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RsvpVote(
          id: '4',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),

    // Recap Event - Hiking Adventure (21 hours left)
    GroupEventEntity(
      id: '2',
      name: 'Hiking Adventure',
      emoji: '⛰️',
      date: DateTime.now()
          .subtract(const Duration(hours: 3)), // Started 3 hours ago
      endDate:
          DateTime.now().add(const Duration(hours: 21)), // Ends in 21 hours
      location: 'Sintra Mountains',
      status: GroupEventStatus.recap,
      goingCount: 5,
      participantCount: 7,
      photoCount: 12,
      maxPhotos: 35,
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Sarah', 'Mike', 'Emma', 'Tom'],
      userVote: true,
      allVotes: [
        RsvpVote(
          id: '5',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 24)),
        ),
        RsvpVote(
          id: '6',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
        RsvpVote(
          id: '7',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 18)),
        ),
        RsvpVote(
          id: '8',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 15)),
        ),
        RsvpVote(
          id: '9',
          userId: 'user8',
          userName: 'Tom',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        const RsvpVote(
          id: '10',
          userId: 'user5',
          userName: 'Anna',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.notGoing,
        ),
        const RsvpVote(
          id: '11',
          userId: 'user6',
          userName: 'James',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.pending,
        ),
      ],
    ),

    // Confirmed Event - Beach Day (3 days from now)
    GroupEventEntity(
      id: '3',
      name: 'Beach Day',
      emoji: '🏖️',
      date: DateTime.now().add(const Duration(days: 3)),
      endDate: null, // No end time for confirmed future events
      location: 'Cascais Beach',
      status: GroupEventStatus.confirmed,
      goingCount: 5,
      participantCount: 5, // Same as going count for confirmed events
      photoCount: 0, // No photos yet (event hasn't started)
      maxPhotos: 0, // No limit set
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Sarah', 'Mike', 'Emma', 'Tom'],
      userVote: true,
      allVotes: [
        RsvpVote(
          id: '12',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        RsvpVote(
          id: '13',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RsvpVote(
          id: '14',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        RsvpVote(
          id: '15',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        RsvpVote(
          id: '16',
          userId: 'user8',
          userName: 'Tom',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        const RsvpVote(
          id: '17',
          userId: 'user5',
          userName: 'Anna',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.notGoing,
        ),
        const RsvpVote(
          id: '18',
          userId: 'user6',
          userName: 'James',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.pending,
        ),
      ],
    ),

    // Confirmed Event - BBQ Party (5 days from now)
    GroupEventEntity(
      id: '4',
      name: 'BBQ Party',
      emoji: '🍖',
      date: DateTime.now().add(const Duration(days: 5)),
      endDate: null, // No end time for confirmed future events
      location: 'Park Pavilion',
      status: GroupEventStatus.confirmed,
      goingCount: 8,
      participantCount: 8, // Same as going count for confirmed events
      photoCount: 0, // No photos yet (event hasn't started)
      maxPhotos: 0, // No limit set
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: [
        'You',
        'Sarah',
        'Mike',
        'Emma',
        'Tom',
        'Lisa',
        'Mark',
        'Anna'
      ],
      userVote: true,
      allVotes: [
        RsvpVote(
          id: '19',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        RsvpVote(
          id: '20',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        RsvpVote(
          id: '21',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RsvpVote(
          id: '22',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
        RsvpVote(
          id: '23',
          userId: 'user8',
          userName: 'Tom',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 15)),
        ),
        RsvpVote(
          id: '24',
          userId: 'user9',
          userName: 'Lisa',
          userAvatar:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        RsvpVote(
          id: '25',
          userId: 'user10',
          userName: 'Mark',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 10)),
        ),
        RsvpVote(
          id: '26',
          userId: 'user14',
          userName: 'Anna',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        const RsvpVote(
          id: '27',
          userId: 'user11',
          userName: 'Sophie',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.pending,
        ),
      ],
    ),
  ];

  @override
  Future<List<GroupEventEntity>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return paginated slice
    if (offset >= _events.length) {
      return [];
    }
    final end = (offset + pageSize).clamp(0, _events.length);
    return _events.sublist(offset, end);
  }

  @override
  Future<int> getGroupEventsCount(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _events.length;
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
