// DTO pending event

import '../../domain/entities/pending_event.dart';

class PendingEventModel {
  final String eventId;
  final String title;
  final String emoji;
  final DateTime scheduledDate;
  final String location;
  final VoteStatus voteStatus;
  final int totalVoters;
  final List<VoterInfo> voters;
  final List<VoterInfo> noResponseVoters;
  final int noResponseCount;

  const PendingEventModel({
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

  factory PendingEventModel.fromMap(Map<String, dynamic> row) {
    final List<dynamic> votersRaw = row['voters'] as List<dynamic>? ?? [];
    final List<dynamic> noResponseRaw = row['no_response_voters'] as List<dynamic>? ?? [];

    return PendingEventModel(
      eventId: row['event_id'] as String,
      title: row['title'] as String,
      emoji: row['emoji'] as String? ?? '🗓️',
      scheduledDate: DateTime.parse(row['start_time'] as String),
      location: row['location_name'] as String,
      voteStatus: _parseVoteStatus(row['vote_status'] as String?),
      totalVoters: row['total_voters'] as int? ?? 0,
      voters: votersRaw.map((v) => _parseVoterInfo(v as Map<String, dynamic>)).toList(),
      noResponseVoters: noResponseRaw.map((v) => _parseVoterInfo(v as Map<String, dynamic>)).toList(),
      noResponseCount: row['no_response_count'] as int? ?? 0,
    );
  }

  static VoterInfo _parseVoterInfo(Map<String, dynamic> data) {
    print('VoterInfo data: $data');
    return VoterInfo(
      name: data['name'] as String,
      avatarUrl: data['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?img=3',
      response: data['rsvp'] as String,
      votedAt: data['votedAt'] != null 
          ? DateTime.parse(data['votedAt'] as String)
          : null,
    );
  }

  static VoteStatus _parseVoteStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'vote': return VoteStatus.vote;
      case 'voting': return VoteStatus.voting;
      case 'voted': return VoteStatus.voted;
      case 'voters_expanded': return VoteStatus.votersExpanded;
      default: return VoteStatus.vote;
    }
  }

  PendingEvent toEntity() => PendingEvent(
    eventId: eventId,
    title: title,
    emoji: emoji,
    scheduledDate: scheduledDate,
    location: location,
    voteStatus: voteStatus,
    totalVoters: totalVoters,
    voters: voters,
    noResponseVoters: noResponseVoters,
    noResponseCount: noResponseCount,
  );
}