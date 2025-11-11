// TODO P2: Remove this file - old pending event model replaced by new home event structure
import '../../domain/entities/pending_event.dart';

class _VoterInfoDTO {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? votedAt;

  const _VoterInfoDTO({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.votedAt,
  });

  factory _VoterInfoDTO.fromMap(Map<String, dynamic> map) {
    return _VoterInfoDTO(
      id: _asString(map['user_id']) ?? '',
      name: _asString(map['display_name']) ??
          _asString(map['name']) ??
          _asString(map['user_name']) ??
          _asString(map['user_id']) ??
          'Unknown',
      avatarUrl: _asString(map['avatar_url']) ?? _asString(map['avatar']),
      votedAt: _parseDateTime(map['voted_at']),
    );
  }

  VoterInfo toEntity() => VoterInfo(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        votedAt: votedAt,
      );

  static String? _asString(dynamic v) => v is String ? v : v?.toString();

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class _PendingEventModel {
  final String eventId;
  final String title;
  final String emoji;
  final DateTime scheduledDate;
  final String location;
  final bool? userVote; // ✅ SIMPLIFICADO: null/true/false

  final int goingTotal;
  final int notGoingTotal;
  final int noResponseTotal;

  final List<_VoterInfoDTO> goingUsers;
  final List<_VoterInfoDTO> notGoingUsers;
  final List<_VoterInfoDTO> noResponseUsers;

  const _PendingEventModel({
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

  factory _PendingEventModel.fromMap(Map<String, dynamic> row) {
    final goingRaw = (row['going_users'] as List<dynamic>?) ?? const [];
    final notGoingRaw = (row['not_going_users'] as List<dynamic>?) ?? const [];
    final noRespRaw = (row['no_response_users'] as List<dynamic>?) ?? const [];

    return _PendingEventModel(
      eventId: _asString(row['event_id']) ?? '',
      title: _asString(row['event_name']) ?? '',
      emoji: _normalizeEmoji(row['emoji']),
      scheduledDate: _parseDate(row['start_datetime']),
      location: _asString(row['location_name']) ?? '',
      userVote:
          _parseUserVote(_asString(row['vote_status'])), // ✅ Conversão direta
      goingTotal: _asInt(row['going_count']),
      notGoingTotal: _asInt(row['not_going_count']),
      noResponseTotal: _asInt(row['no_response_count']),
      goingUsers: goingRaw.map(_miniUserDyn).toList(),
      notGoingUsers: notGoingRaw.map(_miniUserDyn).toList(),
      noResponseUsers: noRespRaw.map(_miniUserDyn).toList(),
    );
  }

  PendingEvent toEntity() {
    return PendingEvent(
      eventId: eventId,
      title: title,
      emoji: emoji,
      scheduledDate: scheduledDate,
      location: location,
      userVote: userVote, // ✅ Passa diretamente
      goingTotal: goingTotal,
      notGoingTotal: notGoingTotal,
      noResponseTotal: noResponseTotal,
      goingUsers: goingUsers.map((dto) => dto.toEntity()).toList(),
      notGoingUsers: notGoingUsers.map((dto) => dto.toEntity()).toList(),
      noResponseUsers: noResponseUsers.map((dto) => dto.toEntity()).toList(),
    );
  }

  // ✅ NOVO: Converte string SQL → bool?
  static bool? _parseUserVote(String? rsvp) {
    if (rsvp == null) return null;
    final s = rsvp.toLowerCase();

    const yesSet = {'yes', 'going', 'attending', 'accepted'};
    const noSet = {'no', 'declined', 'not_going', 'rejected'};

    if (yesSet.contains(s)) return true; // Votou SIM
    if (noSet.contains(s)) return false; // Votou NÃO
    return null; // 'pending', 'invited', etc → não votou
  }

  static _VoterInfoDTO _miniUserDyn(dynamic v) {
    if (v is Map<String, dynamic>) return _VoterInfoDTO.fromMap(v);
    if (v is String) {
      return _VoterInfoDTO(id: v, name: v, avatarUrl: null);
    }
    return const _VoterInfoDTO(id: '', name: 'Unknown', avatarUrl: null);
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
}

PendingEvent pendingEventFromMap(Map<String, dynamic> map) {
  return _PendingEventModel.fromMap(map).toEntity();
}
