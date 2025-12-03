import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../domain/entities/home_event.dart';

/// DTO for home event - converts Supabase rows to entities
class _HomeEventModel {
  final String id;
  final String name;
  final String emoji;
  final String? groupId;
  final String? groupName;
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
    this.groupId,
    this.groupName,
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

  factory _HomeEventModel.fromMap(Map<String, dynamic> map, {Function(String, String)? onStatusMismatch}) {
    final startDate = _parseDateTime(map['start_datetime']);
    final endDate = _parseDateTime(map['end_datetime']);
    final backendStatus = _asString(map['event_status']) ?? 'pending';
    final eventId = _asString(map['event_id']) ?? '';

    print(
        '📊 Event: ${map['event_name']} | DB status: $backendStatus | Start: $startDate');
    print(
        '   🏷️ Group: ${_asString(map['group_name']) ?? 'No group'} (ID: ${_asString(map['group_id']) ?? 'null'})');

    // ✅ CALCULAR estado baseado em datas e status da DB
    final calculatedStatus =
        _calculateStatusFromDates(startDate, endDate, backendStatus);

    print('   → Calculated status: $calculatedStatus');
    
    // ✅ Se status calculado difere do DB, notifica para atualizar
    if (calculatedStatus != backendStatus && onStatusMismatch != null) {
      print('   ⚠️ Status mismatch detected! Updating DB: $backendStatus → $calculatedStatus');
      onStatusMismatch(eventId, calculatedStatus);
    }

    return _HomeEventModel(
      id: _asString(map['event_id']) ?? '',
      name: _asString(map['event_name']) ?? '',
      emoji: _normalizeEmoji(map['emoji']),
      groupId: _asString(map['group_id']),
      groupName: _asString(map['group_name']),
      date: startDate,
      endDate: endDate,
      location: _asString(map['location_name']),
      status: calculatedStatus, // ✅ Calculado, não lido do DB
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
      groupId: groupId,
      groupName: groupName,
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

  // ✅ NOVO: Calcular estado baseado em timestamps e status da DB
  // Decide apenas: planning / living / recap
  // Se planning → usa status da DB (pending ou confirmed)
  static String _calculateStatusFromDates(
    DateTime? start,
    DateTime? end,
    String backendStatus,
  ) {
    final now = DateTime.now();
    const recapDuration = Duration(hours: 24);

    // Sem data ou data futura = PLANNING → usa status da DB (pending/confirmed)
    if (start == null || start.isAfter(now)) {
      return backendStatus; // Mantém 'pending' ou 'confirmed' da DB
    }

    // Evento a decorrer = LIVING
    if (end == null || end.isAfter(now)) return 'living';

    // Evento terminou há menos de 24h = RECAP
    if (now.difference(end) < recapDuration) return 'recap';

    // Evento terminou há mais de 24h = ended (não deve aparecer na view)
    return 'ended';
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
HomeEventEntity homeEventFromMap(Map<String, dynamic> map, {Function(String, String)? onStatusMismatch}) {
  return _HomeEventModel.fromMap(map, onStatusMismatch: onStatusMismatch).toEntity();
}
