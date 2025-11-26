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
      name: 'Beach Day',
      emoji: '🏖️',
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Cascais Beach',
      status: GroupEventStatus.confirmed,
      goingCount: 5,
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Sarah', 'Mike', 'Emma', 'Alex'],
      userVote: true, // User is going
      allVotes: [
        RsvpVote(
          id: '1',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RsvpVote(
          id: '2',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        RsvpVote(
          id: '3',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        RsvpVote(
          id: '4',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        RsvpVote(
          id: '5',
          userId: 'user5',
          userName: 'Alex',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        RsvpVote(
          id: '6',
          userId: 'user6',
          userName: 'John',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.notGoing,
          votedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        const RsvpVote(
          id: '7',
          userId: 'user7',
          userName: 'Kate',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.pending,
        ),
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
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: ['You', 'Tom', 'Lisa'],
      userVote: null, // User hasn't voted yet
      allVotes: [
        RsvpVote(
          id: '8',
          userId: 'user8',
          userName: 'Tom',
          userAvatar:
              'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        RsvpVote(
          id: '9',
          userId: 'user9',
          userName: 'Lisa',
          userAvatar:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        const RsvpVote(
          id: '10',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.pending,
        ),
        RsvpVote(
          id: '11',
          userId: 'user10',
          userName: 'Mark',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
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
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
      ],
      attendeeNames: [
        'You',
        'Sarah',
        'Mike',
        'Emma',
        'Alex',
        'Chris',
        'Kate',
        'Ryan'
      ],
      userVote: false, // User can't go
      allVotes: [
        RsvpVote(
          id: '12',
          userId: 'current_user',
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.notGoing,
          votedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        RsvpVote(
          id: '13',
          userId: 'user2',
          userName: 'Sarah',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RsvpVote(
          id: '14',
          userId: 'user3',
          userName: 'Mike',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        RsvpVote(
          id: '15',
          userId: 'user4',
          userName: 'Emma',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        RsvpVote(
          id: '16',
          userId: 'user5',
          userName: 'Alex',
          userAvatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        RsvpVote(
          id: '17',
          userId: 'user11',
          userName: 'Chris',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        RsvpVote(
          id: '18',
          userId: 'user12',
          userName: 'Kate',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        RsvpVote(
          id: '19',
          userId: 'user13',
          userName: 'Ryan',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        RsvpVote(
          id: '20',
          userId: 'user14',
          userName: 'Anna',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          status: RsvpVoteStatus.going,
          votedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
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
