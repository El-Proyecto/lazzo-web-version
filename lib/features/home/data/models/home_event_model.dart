import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/participant_photo.dart';

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
  final int photoCount; // ✅ Total photos in event
  final int maxPhotos; // ✅ Maximum allowed photos
  final String? currentUserId;
  final SupabaseClient supabaseClient;

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
    required this.photoCount,
    required this.maxPhotos,
    this.currentUserId,
    required this.supabaseClient,
  });

  factory _HomeEventModel.fromMap(
    Map<String, dynamic> map, {
    Function(String, String)? onStatusMismatch,
    String? currentUserId,
    required SupabaseClient supabaseClient,
  }) {
    final startDate = _parseDateTime(map['start_datetime']);
    final endDate = _parseDateTime(map['end_datetime']);
    final backendStatus = _asString(map['event_status']) ?? 'pending';
    final eventId = _asString(map['event_id']) ?? '';

    // ✅ CALCULAR estado baseado em datas e status da DB
    final calculatedStatus =
        _calculateStatusFromDates(startDate, endDate, backendStatus);

    // ✅ Se status calculado difere do DB, notifica para atualizar
    if (calculatedStatus != backendStatus && onStatusMismatch != null) {
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
      photoCount: _asInt(map['photo_count']),
      maxPhotos: _asInt(map['max_photos']),
      currentUserId: currentUserId,
      supabaseClient: supabaseClient,
    );
  }

  Future<HomeEventEntity> toEntity() async {
    // ✅ Combinar todos os votos (going + not_going + no_response) with signed URLs
    final goingVotes = await _parseVotesFromUsers(
      goingUsers,
      RsvpVoteStatus.going,
      currentUserId,
      supabaseClient,
    );
    final notGoingVotes = await _parseVotesFromUsers(
      notGoingUsers,
      RsvpVoteStatus.notGoing,
      currentUserId,
      supabaseClient,
    );
    final pendingVotes = await _parseVotesFromUsers(
      noResponseUsers,
      RsvpVoteStatus.pending,
      currentUserId,
      supabaseClient,
    );

    final allVotes = <RsvpVote>[
      ...goingVotes,
      ...notGoingVotes,
      ...pendingVotes,
    ];

    // Fetch participant photos for living/recap events
    final participantPhotos = await _fetchParticipantPhotos();

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
      photoCount: photoCount,
      maxPhotos: maxPhotos,
      participantPhotos: participantPhotos,
    );
  }

  // Fetch participant photos from Supabase
  Future<List<ParticipantPhoto>> _fetchParticipantPhotos() async {
    try {
      // Only fetch photos for living/recap events
      if (status != 'living' && status != 'recap') {
        return [];
      }

      // Query to get photo count by participant
      final response = await supabaseClient
          .from('group_photos')
          .select(
              'uploader_id, users!group_photos_uploader_id_fkey(id, display_name, avatar_url)')
          .eq('event_id', id)
          .order('captured_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      // Group photos by uploader
      final Map<String, ParticipantPhoto> participantsMap = {};

      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) continue;

        final uploaderId = row['uploader_id'] as String?;
        if (uploaderId == null) continue;

        final userData = row['users'];
        if (userData is! Map<String, dynamic>) continue;

        final displayName = userData['display_name'] as String? ?? 'Unknown';
        final avatarPath = userData['avatar_url'] as String?;

        // Get signed URL for avatar
        String? avatarUrl;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          try {
            final normalizedPath = avatarPath.startsWith('/')
                ? avatarPath.substring(1)
                : avatarPath;
            avatarUrl = await supabaseClient.storage
                .from('users-profile-pic')
                .createSignedUrl(normalizedPath, 3600);
          } catch (e) {
            avatarUrl = null;
          }
        }

        // Add or update participant
        if (participantsMap.containsKey(uploaderId)) {
          participantsMap[uploaderId] = ParticipantPhoto(
            userId: uploaderId,
            userName: currentUserId == uploaderId ? 'You' : displayName,
            userAvatar: avatarUrl,
            photoCount: participantsMap[uploaderId]!.photoCount + 1,
          );
        } else {
          participantsMap[uploaderId] = ParticipantPhoto(
            userId: uploaderId,
            userName: currentUserId == uploaderId ? 'You' : displayName,
            userAvatar: avatarUrl,
            photoCount: 1,
          );
        }
      }

      return participantsMap.values.toList()
        ..sort((a, b) => b.photoCount.compareTo(a.photoCount));
    } catch (e) {
      return [];
    }
  }

  // ✅ NOVO: Parse votes from user arrays with status
  static Future<List<RsvpVote>> _parseVotesFromUsers(
    List<dynamic> users,
    RsvpVoteStatus status,
    String? currentUserId,
    SupabaseClient supabaseClient,
  ) async {
    final votes = <RsvpVote>[];

    for (final u in users) {
      if (u is Map<String, dynamic>) {
        final userId = _asString(u['user_id']) ?? '';
        final displayName = _asString(u['display_name']) ?? 'Unknown';
        final avatarPath = _asString(u['avatar_url']);

        // Convert avatar to signed URL if present
        String? signedAvatarUrl;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          try {
            final normalizedPath = avatarPath.startsWith('/')
                ? avatarPath.substring(1)
                : avatarPath;
            signedAvatarUrl = await supabaseClient.storage
                .from('users-profile-pic')
                .createSignedUrl(normalizedPath, 3600);
          } catch (e) {
            signedAvatarUrl = null;
          }
        }

        // Use "You" for current user
        final userName = userId == currentUserId ? 'You' : displayName;

        votes.add(RsvpVote(
          id: userId,
          userId: userId,
          userName: userName,
          userAvatar: signedAvatarUrl,
          status: status,
          votedAt: _parseDateTime(u['voted_at']),
        ));
      } else {
        votes.add(const RsvpVote(
          id: '',
          userId: '',
          userName: 'Unknown',
          userAvatar: null,
          status: RsvpVoteStatus.pending,
          votedAt: null,
        ));
      }
    }

    return votes;
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

    // CRITICAL: Pending events NEVER auto-transition, even if date has passed
    if (backendStatus == 'pending') {
      return 'pending'; // Always return pending, regardless of dates
    }

    // Sem data ou data futura = PLANNING → usa status da DB (pending/confirmed)
    if (start == null || start.isAfter(now)) {
      return backendStatus; // Mantém 'pending' ou 'confirmed' da DB
    }

    // Evento a decorrer = LIVING (only for confirmed+ events)
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
    if (s == 'yes' || s == 'going' || s == 'attending' || s == 'accepted') {
      return true;
    }
    if (s == 'no' || s == 'not_going' || s == 'declined' || s == 'rejected') {
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
Future<HomeEventEntity> homeEventFromMap(
  Map<String, dynamic> map, {
  Function(String, String)? onStatusMismatch,
  String? currentUserId,
  required SupabaseClient supabaseClient,
}) async {
  return await _HomeEventModel.fromMap(
    map,
    onStatusMismatch: onStatusMismatch,
    currentUserId: currentUserId,
    supabaseClient: supabaseClient,
  ).toEntity();
}
