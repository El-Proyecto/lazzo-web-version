import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../domain/entities/home_event.dart';

/// DTO for home event - converts Supabase rows to entities
class _HomeEventModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate;
  final String? location;
  final String status;
  final String? userRsvp;
  final DateTime? votedAt; // ✅ NOVO: timestamp do voto do user
  final int goingCount;
  final int participantsTotal; // ✅ NOVO: total de participantes
  final int votersTotal; // ✅ NOVO: total de votantes
  final List<dynamic> goingUsers;
  final List<dynamic> notGoingUsers; // ✅ NOVO
  final List<dynamic> noResponseUsers; // ✅ NOVO

  const _HomeEventModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endDate,
    this.location,
    required this.status,
    this.userRsvp,
    this.votedAt,
    required this.goingCount,
    required this.participantsTotal,
    required this.votersTotal,
    required this.goingUsers,
    required this.notGoingUsers,
    required this.noResponseUsers,
  });

  factory _HomeEventModel.fromMap(Map<String, dynamic> map) {
    return _HomeEventModel(
      id: _asString(map['event_id']) ?? '',
      name: _asString(map['event_name']) ?? '',
      emoji: _normalizeEmoji(map['emoji']),
      date: _parseDateTime(map['start_datetime']),
      endDate: _parseDateTime(map['end_datetime']),
      location: _asString(map['location_name']),
      status: _asString(map['event_status']) ?? 'pending',
      userRsvp: _asString(map['user_rsvp']),
      votedAt: _parseDateTime(map['voted_at']),
      goingCount: _asInt(map['going_count']),
      participantsTotal: _asInt(map['participants_total']),
      votersTotal: _asInt(map['voters_total']),
      goingUsers: _parseJsonArray(map['going_users']),
      notGoingUsers: _parseJsonArray(map['not_going_users']),
      noResponseUsers: _parseJsonArray(map['no_response_users']),
    );
  }

  HomeEventEntity toEntity() {
    // ✅ Combinar todos os votos (going + not_going + no_response)
    final allVotes = <RsvpVote>[
      ..._parseVotesFromUsers(goingUsers, RsvpVoteStatus.going),
      ..._parseVotesFromUsers(notGoingUsers, RsvpVoteStatus.notGoing),
      ..._parseVotesFromUsers(noResponseUsers, RsvpVoteStatus.pending),
    ];

    return HomeEventEntity(
      id: id,
      name: name,
      emoji: emoji,
      date: date,
      endDate: endDate,
      location: location,
      status: _mapStatus(status),
      goingCount: goingCount,
      attendeeAvatars: _extractAvatars(goingUsers),
      attendeeNames: _extractNames(goingUsers),
      userVote: _mapUserVote(userRsvp),
      allVotes: allVotes,
      photoCount: 0, // ✅ TODO: Add quando view incluir fotos
      maxPhotos: 0,
      participantPhotos: const [],
    );
  }

  // ✅ NOVO: Parse votes from user arrays with status
  static List<RsvpVote> _parseVotesFromUsers(
    List<dynamic> users,
    RsvpVoteStatus status,
  ) {
    return users.map((u) {
      if (u is Map<String, dynamic>) {
        return RsvpVote(
          id: _asString(u['user_id']) ?? '',
          userId: _asString(u['user_id']) ?? '',
          userName: _asString(u['display_name']) ?? 'Unknown',
          userAvatar: _asString(u['avatar_url']),
          status: status,
          votedAt: _parseDateTime(u['voted_at']),
        );
      }
      return const RsvpVote(
        id: '',
        userId: '',
        userName: 'Unknown',
        userAvatar: null,
        status: RsvpVoteStatus.pending,
        votedAt: null,
      );
    }).toList();
  }

  static HomeEventStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return HomeEventStatus.pending;
      case 'confirmed':
        return HomeEventStatus.confirmed;
      case 'living':
        return HomeEventStatus.living;
      case 'recap':
        return HomeEventStatus.recap;
      default:
        return HomeEventStatus.pending;
    }
  }

  static bool? _mapUserVote(String? rsvp) {
    if (rsvp == null) return null;
    final s = rsvp.toLowerCase();
    if (s == 'going' || s == 'yes' || s == 'attending' || s == 'accepted') {
      return true;
    }
    if (s == 'not_going' || s == 'no' || s == 'declined' || s == 'rejected') {
      return false;
    }
    return null; // pending/invited
  }

  static List<String> _extractAvatars(List<dynamic> users) {
    return users.map((u) {
      if (u is Map<String, dynamic>) {
        return _asString(u['avatar_url']) ?? '';
      }
      return '';
    }).toList();
  }

  static List<String> _extractNames(List<dynamic> users) {
    return users.map((u) {
      if (u is Map<String, dynamic>) {
        return _asString(u['display_name']) ?? 'Unknown';
      }
      return 'Unknown';
    }).toList();
  }

  // ✅ NOVO: Parse JSON array safely
  static List<dynamic> _parseJsonArray(dynamic v) {
    if (v == null) return [];
    if (v is List) return v;
    if (v is String) {
      try {
        // Pode vir como string JSON da view
        return []; // TODO: parse JSON string se necessário
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static String? _asString(dynamic v) => v is String ? v : v?.toString();

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

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

  static String _normalizeEmoji(dynamic v) {
    final s = _asString(v)?.trim() ?? '';
    return s.isNotEmpty ? s : '🗓️';
  }
}

/// Public function to convert Map to HomeEventEntity
HomeEventEntity homeEventFromMap(Map<String, dynamic> map) {
  return _HomeEventModel.fromMap(map).toEntity();
}