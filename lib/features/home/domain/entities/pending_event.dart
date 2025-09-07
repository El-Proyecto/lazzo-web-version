class PendingEvent {
  final String eventId;
  final String title;
  final String emoji;
  final DateTime scheduledDate;
  final String location;
  final VoteStatus voteStatus;
  final int totalVoters;
  final List<VoterInfo> voters;
  final List<VoterInfo> noResponseVoters; // People who haven't responded
  final int noResponseCount;

  const PendingEvent({
    required this.eventId,
    required this.title,
    required this.emoji,
    required this.scheduledDate,
    required this.location,
    required this.voteStatus,
    required this.totalVoters,
    required this.voters,
    required this.noResponseVoters,
    required this.noResponseCount,
  });
}

class VoterInfo {
  final String name;
  final String avatarUrl;
  final String response; // 'yes', 'no', or 'pending'
  final DateTime? votedAt; // When the vote was cast

  const VoterInfo({
    required this.name,
    required this.avatarUrl,
    required this.response,
    this.votedAt,
  });
}

enum VoteStatus {
  vote, // User hasn't voted yet
  voting, // Vote in progress (loading)
  voted, // User has voted, collapsed view
  votersExpanded, // User has voted, expanded view showing voters
}
