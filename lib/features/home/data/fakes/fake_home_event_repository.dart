import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/repositories/home_event_repository.dart';

/// Fake repository for home events - used for UI development
/// Returns mock data without backend calls
class FakeHomeEventRepository implements HomeEventRepository {
  // Control variable to change the next event state for testing
  // Change this to test different card states:
  // - HomeEventStatus.pending
  // - HomeEventStatus.confirmed
  // - HomeEventStatus.living
  // - HomeEventStatus.recap
  static HomeEventStatus nextEventStatusOverride = HomeEventStatus.confirmed;

  @override
  Future<HomeEventEntity?> getNextEvent() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create sample votes
    final allVotes = [
      RsvpVote(
        id: 'vote_1',
        userId: 'user_1',
        userName: 'João',
        userAvatar: 'https://i.pravatar.cc/150?img=2',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RsvpVote(
        id: 'vote_2',
        userId: 'user_2',
        userName: 'Maria',
        userAvatar: 'https://i.pravatar.cc/150?img=3',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RsvpVote(
        id: 'vote_3',
        userId: 'user_3',
        userName: 'Pedro',
        userAvatar: 'https://i.pravatar.cc/150?img=4',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      RsvpVote(
        id: 'vote_4',
        userId: 'user_4',
        userName: 'Ana',
        userAvatar: 'https://i.pravatar.cc/150?img=5',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      RsvpVote(
        id: 'vote_5',
        userId: 'user_5',
        userName: 'Carlos',
        userAvatar: 'https://i.pravatar.cc/150?img=6',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      RsvpVote(
        id: 'vote_6',
        userId: 'user_6',
        userName: 'Rita',
        userAvatar: 'https://i.pravatar.cc/150?img=7',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      RsvpVote(
        id: 'vote_7',
        userId: 'user_7',
        userName: 'Miguel',
        userAvatar: 'https://i.pravatar.cc/150?img=8',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      // Current user - initially not voted (null)
      // When user votes, this will be added/updated dynamically
      RsvpVote(
        id: 'vote_current',
        userId: 'current_user',
        userName: 'You',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now(),
      ),
      RsvpVote(
        id: 'vote_8',
        userId: 'user_8',
        userName: 'Sofia',
        userAvatar: 'https://i.pravatar.cc/150?img=9',
        status: RsvpVoteStatus.notGoing,
        votedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RsvpVote(
        id: 'vote_9',
        userId: 'user_9',
        userName: 'Tiago',
        userAvatar: 'https://i.pravatar.cc/150?img=10',
        status: RsvpVoteStatus.pending,
        votedAt: null,
      ),
    ];

    final goingVotes =
        allVotes.where((v) => v.status == RsvpVoteStatus.going).toList();

    // Next Event only shows if user voted "Can" (userVote == true)
    // Change userVote to false or null to test - event won't appear as Next Event
    const userVote = true; // User has voted "Can"

    // Only return event if user voted "Can"
    if (userVote != true) {
      return null; // No next event if user hasn't voted or voted "Can't"
    }

    return HomeEventEntity(
      id: 'event_1',
      name: 'Beach Day with the Squad',
      emoji: '🏖️',
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Praia da Rocha',
      status: nextEventStatusOverride, // Use override for testing
      goingCount: goingVotes.length,
      attendeeAvatars: goingVotes.map((v) => v.userAvatar ?? '').toList(),
      attendeeNames: goingVotes.map((v) => v.userName).toList(),
      userVote: userVote,
      allVotes: allVotes,
    );
  }

  @override
  Future<List<HomeEventEntity>> getConfirmedEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final event2Votes = [
      RsvpVote(
        id: 'vote_e2_1',
        userId: 'user_11',
        userName: 'Sofia',
        userAvatar: 'https://i.pravatar.cc/150?img=6',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RsvpVote(
        id: 'vote_e2_2',
        userId: 'user_12',
        userName: 'Tiago',
        userAvatar: 'https://i.pravatar.cc/150?img=7',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      RsvpVote(
        id: 'vote_e2_3',
        userId: 'user_13',
        userName: 'Laura',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RsvpVote(
        id: 'vote_e2_4',
        userId: 'user_14',
        userName: 'Bruno',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RsvpVote(
        id: 'vote_e2_5',
        userId: 'user_15',
        userName: 'Inês',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RsvpVote(
        id: 'vote_e2_6',
        userId: 'user_16',
        userName: 'André',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    final event3Votes = [
      RsvpVote(
        id: 'vote_e3_1',
        userId: 'user_17',
        userName: 'Rui',
        userAvatar: 'https://i.pravatar.cc/150?img=8',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      RsvpVote(
        id: 'vote_e3_2',
        userId: 'user_18',
        userName: 'Catarina',
        userAvatar: 'https://i.pravatar.cc/150?img=9',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RsvpVote(
        id: 'vote_e3_3',
        userId: 'user_19',
        userName: 'Filipe',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      RsvpVote(
        id: 'vote_e3_4',
        userId: 'user_20',
        userName: 'Beatriz',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RsvpVote(
        id: 'vote_e3_current',
        userId: 'current_user',
        userName: 'You',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    return [
      HomeEventEntity(
        id: 'event_2',
        name: 'Dinner at New Restaurant',
        emoji: '🍽️',
        date: DateTime.now().add(const Duration(days: 7)),
        location: 'Downtown Lisbon',
        status: HomeEventStatus.confirmed,
        goingCount:
            event2Votes.where((v) => v.status == RsvpVoteStatus.going).length,
        attendeeAvatars: event2Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userAvatar ?? '')
            .toList(),
        attendeeNames: event2Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userName)
            .toList(),
        userVote: null, // User hasn't voted yet
        allVotes: event2Votes,
      ),
      HomeEventEntity(
        id: 'event_3',
        name: 'Weekend Hiking Trip',
        emoji: '⛰️',
        date: DateTime.now().add(const Duration(days: 14)),
        location: 'Sintra Mountains',
        status: HomeEventStatus.confirmed,
        goingCount:
            event3Votes.where((v) => v.status == RsvpVoteStatus.going).length,
        attendeeAvatars: event3Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userAvatar ?? '')
            .toList(),
        attendeeNames: event3Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userName)
            .toList(),
        userVote: true,
        allVotes: event3Votes,
      ),
    ];
  }

  @override
  Future<List<HomeEventEntity>> getPendingEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final event4Votes = [
      RsvpVote(
        id: 'vote_e4_1',
        userId: 'user_21',
        userName: 'Diogo',
        userAvatar: 'https://i.pravatar.cc/150?img=10',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RsvpVote(
        id: 'vote_e4_2',
        userId: 'user_22',
        userName: 'Mariana',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      RsvpVote(
        id: 'vote_e4_current',
        userId: 'current_user',
        userName: 'You',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    final event5Votes = [
      RsvpVote(
        id: 'vote_e5_1',
        userId: 'user_23',
        userName: 'Gonçalo',
        userAvatar: 'https://i.pravatar.cc/150?img=11',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      RsvpVote(
        id: 'vote_e5_2',
        userId: 'user_24',
        userName: 'Teresa',
        userAvatar: 'https://i.pravatar.cc/150?img=12',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
      RsvpVote(
        id: 'vote_e5_3',
        userId: 'user_25',
        userName: 'Vasco',
        userAvatar: 'https://i.pravatar.cc/150?img=13',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      RsvpVote(
        id: 'vote_e5_4',
        userId: 'user_26',
        userName: 'Marta',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RsvpVote(
        id: 'vote_e5_5',
        userId: 'user_27',
        userName: 'Ricardo',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      RsvpVote(
        id: 'vote_e5_6',
        userId: 'user_28',
        userName: 'Joana',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RsvpVote(
        id: 'vote_e5_7',
        userId: 'user_29',
        userName: 'Paulo',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RsvpVote(
        id: 'vote_e5_8',
        userId: 'user_30',
        userName: 'Sara',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RsvpVote(
        id: 'vote_e5_9',
        userId: 'user_31',
        userName: 'Hugo',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      RsvpVote(
        id: 'vote_e5_10',
        userId: 'user_32',
        userName: 'Vera',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      RsvpVote(
        id: 'vote_e5_11',
        userId: 'user_33',
        userName: 'Nuno',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      RsvpVote(
        id: 'vote_e5_12',
        userId: 'user_34',
        userName: 'Carla',
        userAvatar: '',
        status: RsvpVoteStatus.going,
        votedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      RsvpVote(
        id: 'vote_e5_13',
        userId: 'user_35',
        userName: 'António',
        userAvatar: '',
        status: RsvpVoteStatus.notGoing,
        votedAt: DateTime.now().subtract(const Duration(hours: 9)),
      ),
      RsvpVote(
        id: 'vote_e5_current',
        userId: 'current_user',
        userName: 'You',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        status: RsvpVoteStatus.pending,
        votedAt: null,
      ),
    ];

    return [
      HomeEventEntity(
        id: 'event_4',
        name: 'Movie Night',
        emoji: '🎬',
        date: null,
        location: 'To be decided',
        status: HomeEventStatus.pending,
        goingCount:
            event4Votes.where((v) => v.status == RsvpVoteStatus.going).length,
        attendeeAvatars: event4Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userAvatar ?? '')
            .toList(),
        attendeeNames: event4Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userName)
            .toList(),
        userVote: true,
        allVotes: event4Votes,
      ),
      HomeEventEntity(
        id: 'event_5',
        name: 'Birthday Party',
        emoji: '🎂',
        date: null,
        location: 'Someone\'s House',
        status: HomeEventStatus.pending,
        goingCount:
            event5Votes.where((v) => v.status == RsvpVoteStatus.going).length,
        attendeeAvatars: event5Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userAvatar ?? '')
            .toList(),
        attendeeNames: event5Votes
            .where((v) => v.status == RsvpVoteStatus.going)
            .map((v) => v.userName)
            .toList(),
        userVote: null, // User hasn't voted yet
        allVotes: event5Votes,
      ),
    ];
  }
}
