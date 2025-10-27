// domain/entities/pending_event.dart

class VoterInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? votedAt; // ✅ NOVO: quando a pessoa votou

  const VoterInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.votedAt, // ✅ Opcional para noResponseUsers
  });
}

class PendingEvent {
  // --- essenciais do evento ---
  final String eventId;
  final String title;
  final String emoji;
  final DateTime scheduledDate;
  final String location;      // nome já resolvido (location_name)
  final bool? userVote; // estado do "eu" para o CTA

  // --- totais por estado ---
  final int goingTotal;
  final int notGoingTotal;
  final int noResponseTotal;

  // --- listas por estado (id + nome + avatar) ---
  final List<VoterInfo> goingUsers;
  final List<VoterInfo> notGoingUsers;
  final List<VoterInfo> noResponseUsers;

  const PendingEvent({
    required this.eventId,
    required this.title,
    required this.emoji,
    required this.scheduledDate,
    required this.location,
    required this.userVote,
    required this.goingTotal,
    required this.notGoingTotal,
    required this.noResponseTotal,
    required this.goingUsers,
    required this.notGoingUsers,
    required this.noResponseUsers,
  });
}

enum VoteStatus {
  vote,           // user ainda não votou
  voting,         // loading
  voted,          // já votou (vista colapsada)
  votersExpanded, // já votou (vista expandida com listas)
}
