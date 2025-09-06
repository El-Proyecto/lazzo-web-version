import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';

class FakePendingEventRepository implements PendingEventRepository {
  @override
  Future<List<PendingEvent>> getPendingEvents(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      PendingEvent(
        eventId: 'event_1',
        title: 'Jolada no Magic',
        emoji: '🍻',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        location: 'Magic',
        voteStatus: VoteStatus.vote, // User hasn't voted yet
        totalVoters: 3,
        voters: [
          VoterInfo(
            name: 'Ana Silva',
            avatarUrl: 'https://i.pravatar.cc/150?img=1',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          VoterInfo(
            name: 'Pedro Santos',
            avatarUrl: 'https://i.pravatar.cc/150?img=2',
            response: 'no',
            votedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          VoterInfo(
            name: 'Maria Costa',
            avatarUrl: 'https://i.pravatar.cc/150?img=3',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        noResponseVoters: [
          const VoterInfo(
            name: 'João Oliveira',
            avatarUrl: 'https://i.pravatar.cc/150?img=10',
            response: 'pending',
          ),
          const VoterInfo(
            name: 'Sofia Martins',
            avatarUrl: 'https://i.pravatar.cc/150?img=11',
            response: 'pending',
          ),
        ],
        noResponseCount: 2,
      ),
      PendingEvent(
        eventId: 'event_2',
        title: 'Jantar na casa do João',
        emoji: '🍽️',
        scheduledDate: DateTime.now().add(const Duration(days: 5)),
        location: 'Casa do João',
        voteStatus: VoteStatus.voted,
        totalVoters: 5,
        voters: [
          VoterInfo(
            name: 'Tatiana Filipa Lopes',
            avatarUrl: 'https://i.pravatar.cc/150?img=4',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          VoterInfo(
            name: 'Jéssica Patrícia Rocha',
            avatarUrl: 'https://i.pravatar.cc/150?img=5',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(hours: 12)),
          ),
          VoterInfo(
            name: 'João Miguel',
            avatarUrl: 'https://i.pravatar.cc/150?img=6',
            response: 'no',
            votedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          VoterInfo(
            name: 'Carlos Pereira',
            avatarUrl: 'https://i.pravatar.cc/150?img=7',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(hours: 18)),
          ),
          VoterInfo(
            name: 'Rita Oliveira',
            avatarUrl: 'https://i.pravatar.cc/150?img=8',
            response: 'no',
            votedAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
        noResponseVoters: [
          const VoterInfo(
            name: 'Miguel Ferreira',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            response: 'pending',
          ),
        ],
        noResponseCount: 1,
      ),
      PendingEvent(
        eventId: 'event_3',
        title: 'Cinema + Pipocas',
        emoji: '🍿',
        scheduledDate: DateTime.now().add(const Duration(days: 7)),
        location: 'Cinema City',
        voteStatus: VoteStatus.vote,
        totalVoters: 1,
        voters: [
          VoterInfo(
            name: 'Sofia Lima',
            avatarUrl: 'https://i.pravatar.cc/150?img=9',
            response: 'yes',
            votedAt: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
        ],
        noResponseVoters: [
          const VoterInfo(
            name: 'Bruno Costa',
            avatarUrl: 'https://i.pravatar.cc/150?img=13',
            response: 'pending',
          ),
          const VoterInfo(
            name: 'Inês Rodrigues',
            avatarUrl: 'https://i.pravatar.cc/150?img=14',
            response: 'pending',
          ),
          const VoterInfo(
            name: 'André Silva',
            avatarUrl: 'https://i.pravatar.cc/150?img=15',
            response: 'pending',
          ),
        ],
        noResponseCount: 3,
      ),
      PendingEvent(
        eventId: 'event_4',
        title: 'Workshop de Flutter',
        emoji: '💻',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        location: 'Online',
        voteStatus: VoteStatus.vote,
        totalVoters: 0,
        voters: [], // No voters yet - test complete workflow
        noResponseVoters: [
          const VoterInfo(
            name: 'Paulo Mendes',
            avatarUrl: 'https://i.pravatar.cc/150?img=16',
            response: 'pending',
          ),
          const VoterInfo(
            name: 'Carla Santos',
            avatarUrl: 'https://i.pravatar.cc/150?img=17',
            response: 'pending',
          ),
          const VoterInfo(
            name: 'Rui Pereira',
            avatarUrl: 'https://i.pravatar.cc/150?img=18',
            response: 'pending',
          ),
        ],
        noResponseCount: 3,
      ),
    ];
  }

  @override
  Future<bool> voteOnEvent(String eventId, String userId, bool isYes) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate success
    return true;
  }
}
