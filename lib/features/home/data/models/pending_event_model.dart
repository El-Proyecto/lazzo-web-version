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
    final List<dynamic> votersRaw = (row['voters'] as List<dynamic>?) ?? [];
    final List<dynamic> noResponseRaw =
        (row['no_response_voters'] as List<dynamic>?) ?? [];

    return PendingEventModel(
      eventId: row['event_id'],
      title: row['title'],
      emoji: _asString(row['emoji'])?.trim().isNotEmpty == true
          ? row['emoji'] as String
          : '🗓️',
      scheduledDate: _parseDate(row['start_time']),
      location: _asString(row['location_name']) ?? '',
      voteStatus: _parseVoteStatus(_asString(row['vote_status'])),
      totalVoters: (row['total_voters'] as int?) ?? 0,
      voters: votersRaw.map(_parseVoterInfoDynamic).toList(),
      noResponseVoters: noResponseRaw.map(_parseVoterInfoDynamic).toList(),
      noResponseCount: (row['no_response_count'] as int?) ?? 0,
    );
  }

  // Aceita tanto Map<String,dynamic> (voters) como String (IDs em no_response_voters)
  static VoterInfo _parseVoterInfoDynamic(dynamic v) {
    if (v is Map<String, dynamic>) {
      return _parseVoterInfoFromMap(v);
    }
    if (v is String) {
      // Quando vem só o user_id numa string (no_response_voters)
      return VoterInfo(
        name: v, // podes trocar para 'Unknown' se preferires
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        response: 'pending',
        votedAt: null,
      );
    }
    // Qualquer outro formato inesperado
    return VoterInfo(
      name: 'Unknown',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      response: 'pending',
      votedAt: null,
    );
  }

  static VoterInfo _parseVoterInfoFromMap(Map<String, dynamic> data) {
    // Suporta chaves alternativas comuns vindas do SQL/JSON
    final name =
        _asString(data['name']) ??
        _asString(data['user_name']) ??
        _asString(data['display_name']) ??
        _asString(data['user_id']) ?? // fallback: mostra o id como nome
        'Unknown';

    final avatarUrl =
        _asString(data['avatar_url']) ??
        _asString(data['avatar']) ??
        'https://i.pravatar.cc/150?img=3';

    final response =
        (_asString(data['rsvp']) ?? _asString(data['response']) ?? 'pending')
            .toLowerCase();

    final votedAtRaw = data['votedAt'] ?? data['voted_at'];
    final votedAt = _tryParseDate(votedAtRaw);

    return VoterInfo(
      name: name,
      avatarUrl: avatarUrl,
      response: response,
      votedAt: votedAt,
    );
  }

  static VoteStatus _parseVoteStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'vote':
        return VoteStatus.vote;
      case 'voting':
        return VoteStatus.voting;
      case 'voted':
        return VoteStatus.voted;
      case 'voters_expanded':
        return VoteStatus.votersExpanded;
      default:
        return VoteStatus.vote;
    }
  }

  static String? _asString(dynamic v) => v is String ? v : (v?.toString());

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw FormatException('Data inválida: $v');
  }

  static DateTime? _tryParseDate(dynamic v) {
    try {
      if (v == null) return null;
      return _parseDate(v);
    } catch (_) {
      return null;
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
