// DTO pending event

import '../../domain/entities/pending_event.dart';

class PendingEventModel {
  final String eventId;
  final String title;
  final String emoji;
  final DateTime scheduledDate;
  final String location; // continua a chamar-se 'location' no domínio
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
      eventId: _asString(row['event_id']) ?? '',
      title: _asString(row['event_name']) ?? '',
      emoji: _normalizeEmoji(row['emoji']),
      scheduledDate: _parseDate(row['start_datetime']),
      location: _asString(row['location_name']) ?? '',
      voteStatus: _mapRsvpToVoteStatus(_asString(row['vote_status'])),
      totalVoters: _asInt(row['voters_total']),
      voters: votersRaw.map(_parseVoterInfoDynamic).toList(),
      noResponseVoters: noResponseRaw.map(_parseVoterInfoDynamic).toList(),
      noResponseCount: _asInt(row['no_response_count']),
    );
  }

  static VoterInfo _parseVoterInfoDynamic(dynamic v) {
    if (v is Map<String, dynamic>) return _parseVoterInfoFromMap(v);
    if (v is String) {
      return VoterInfo(
        name: v, // aqui mostra o user_id; troca para 'Unknown' se preferires
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        response: 'pending',
        votedAt: null,
      );
    }
    return const VoterInfo(
      name: 'Unknown',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      response: 'pending',
      votedAt: null,
    );
  }

  static VoterInfo _parseVoterInfoFromMap(Map<String, dynamic> data) {
    final name =
        _asString(data['name']) ??
        _asString(data['user_name']) ??
        _asString(data['display_name']) ??
        _asString(data['user_id']) ??
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

  static VoteStatus _mapRsvpToVoteStatus(String? rsvp) {
    final s = (rsvp ?? 'pending').toLowerCase();
    const yesSet = {'yes', 'going', 'attending', 'accepted'};
    const noSet = {'no', 'declined', 'not_going', 'rejected'};
    if (s == 'pending' || s == 'invited' || s.isEmpty) return VoteStatus.vote;
    if (yesSet.contains(s) || noSet.contains(s)) return VoteStatus.voted;
    return VoteStatus.vote;
  }

  static String _normalizeEmoji(dynamic v) {
    final s = _asString(v)?.trim() ?? '';
    return s.isNotEmpty ? s : '🗓️';
    }

  static String? _asString(dynamic v) => v is String ? v : v?.toString();

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

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
    location: location, // já é o nome
    voteStatus: voteStatus,
    totalVoters: totalVoters,
    voters: voters,
    noResponseVoters: noResponseVoters,
    noResponseCount: noResponseCount,
  );
}
