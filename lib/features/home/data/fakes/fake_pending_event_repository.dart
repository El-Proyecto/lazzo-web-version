import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';

class FakePendingEventRepository implements PendingEventRepository {
  @override
  Future<List<PendingEvent>> getPendingEvents(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return [
      PendingEvent(
        eventId: 'event_1',
        title: 'Jolada no Magic',
        emoji: '🍻',
        scheduledDate: now.add(const Duration(days: 2)),
        location: 'Magic',
        userVote: null, // ✅ User ainda não votou neste evento
        goingTotal: 2,
        notGoingTotal: 1,
        noResponseTotal: 2,
        goingUsers: [
          VoterInfo(
            id: 'user_1',
            name: 'Ana Silva',
            avatarUrl: 'https://i.pravatar.cc/150?img=1',
            votedAt: now.subtract(const Duration(hours: 2)),
          ),
          VoterInfo(
            id: 'user_3',
            name: 'Maria Costa',
            avatarUrl: 'https://i.pravatar.cc/150?img=3',
            votedAt: now.subtract(const Duration(minutes: 30)),
          ),
        ],
        notGoingUsers: [
          VoterInfo(
            id: 'user_2',
            name: 'Pedro Santos',
            avatarUrl: 'https://i.pravatar.cc/150?img=2',
            votedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        noResponseUsers: const [
          VoterInfo(
            id: 'user_10',
            name: 'João Oliveira',
            avatarUrl: 'https://i.pravatar.cc/150?img=10',
            votedAt: null,
          ),
          VoterInfo(
            id: 'user_11',
            name: 'Sofia Martins',
            avatarUrl: 'https://i.pravatar.cc/150?img=11',
            votedAt: null,
          ),
        ],
      ),
      PendingEvent(
        eventId: 'event_2',
        title: 'Futebol no Parque',
        emoji: '⚽',
        scheduledDate: now.add(const Duration(days: 5)),
        location: 'Parque da Cidade',
        userVote: true, // ✅ User já votou SIM neste evento
        goingTotal: 5,
        notGoingTotal: 2,
        noResponseTotal: 3,
        goingUsers: [
          VoterInfo(
            id: userId, // ✅ Incluir o próprio user
            name: 'You',
            avatarUrl: 'https://i.pravatar.cc/150?img=50',
            votedAt: now.subtract(const Duration(hours: 3)),
          ),
          VoterInfo(
            id: 'user_4',
            name: 'Carlos Rodrigues',
            avatarUrl: 'https://i.pravatar.cc/150?img=4',
            votedAt: now.subtract(const Duration(hours: 1)),
          ),
          VoterInfo(
            id: 'user_5',
            name: 'Rita Ferreira',
            avatarUrl: 'https://i.pravatar.cc/150?img=5',
            votedAt: now.subtract(const Duration(minutes: 45)),
          ),
          VoterInfo(
            id: 'user_6',
            name: 'Bruno Alves',
            avatarUrl: 'https://i.pravatar.cc/150?img=6',
            votedAt: now.subtract(const Duration(minutes: 20)),
          ),
          VoterInfo(
            id: 'user_7',
            name: 'Inês Sousa',
            avatarUrl: 'https://i.pravatar.cc/150?img=7',
            votedAt: now.subtract(const Duration(minutes: 10)),
          ),
        ],
        notGoingUsers: [
          VoterInfo(
            id: 'user_8',
            name: 'Tiago Pereira',
            avatarUrl: 'https://i.pravatar.cc/150?img=8',
            votedAt: now.subtract(const Duration(hours: 2)),
          ),
          VoterInfo(
            id: 'user_9',
            name: 'Luísa Gomes',
            avatarUrl: 'https://i.pravatar.cc/150?img=9',
            votedAt: now.subtract(const Duration(minutes: 50)),
          ),
        ],
        noResponseUsers: const [
          VoterInfo(
            id: 'user_12',
            name: 'André Lima',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            votedAt: null,
          ),
          VoterInfo(
            id: 'user_13',
            name: 'Beatriz Nunes',
            avatarUrl: 'https://i.pravatar.cc/150?img=13',
            votedAt: null,
          ),
          VoterInfo(
            id: 'user_14',
            name: 'Miguel Ramos',
            avatarUrl: 'https://i.pravatar.cc/150?img=14',
            votedAt: null,
          ),
        ],
      ),
      PendingEvent(
        eventId: 'event_3',
        title: 'Cinema: Dune 3',
        emoji: '🎬',
        scheduledDate: now.add(const Duration(days: 7)),
        location: 'Cinema NOS',
        userVote: false, // ✅ User já votou NÃO neste evento
        goingTotal: 3,
        notGoingTotal: 2,
        noResponseTotal: 1,
        goingUsers: [
          VoterInfo(
            id: 'user_15',
            name: 'Diogo Castro',
            avatarUrl: 'https://i.pravatar.cc/150?img=15',
            votedAt: now.subtract(const Duration(hours: 5)),
          ),
          VoterInfo(
            id: 'user_16',
            name: 'Marta Vieira',
            avatarUrl: 'https://i.pravatar.cc/150?img=16',
            votedAt: now.subtract(const Duration(hours: 4)),
          ),
          VoterInfo(
            id: 'user_17',
            name: 'Ricardo Lopes',
            avatarUrl: 'https://i.pravatar.cc/150?img=17',
            votedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        notGoingUsers: [
          VoterInfo(
            id: userId, // ✅ User votou NÃO
            name: 'You',
            avatarUrl: 'https://i.pravatar.cc/150?img=50',
            votedAt: now.subtract(const Duration(hours: 6)),
          ),
          VoterInfo(
            id: 'user_18',
            name: 'Sara Fernandes',
            avatarUrl: 'https://i.pravatar.cc/150?img=18',
            votedAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
        noResponseUsers: const [
          VoterInfo(
            id: 'user_19',
            name: 'Paulo Carvalho',
            avatarUrl: 'https://i.pravatar.cc/150?img=19',
            votedAt: null,
          ),
        ],
      ),
    ];
  }

  @override
  Future<bool> voteOnEvent(String eventId, String userId, bool isYes) async {
    await Future.delayed(const Duration(milliseconds: 800));
    print('🎭 Fake vote: eventId=$eventId, userId=$userId, isYes=$isYes');
    return true;
  }
}