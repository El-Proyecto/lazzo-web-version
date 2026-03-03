import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../../../services/avatar_cache_service.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/participant_photo.dart';

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
  final int photoCount; // ✅ Total photos in event
  final int maxPhotos; // ✅ Maximum allowed photos
  final String? currentUserId;
  final SupabaseClient supabaseClient;

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
    required this.photoCount,
    required this.maxPhotos,
    this.currentUserId,
    required this.supabaseClient,
  });

  factory _HomeEventModel.fromMap(
    Map<String, dynamic> map, {
    Function(String eventId, String fromStatus, String toStatus)?
        onStatusMismatch,
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
      onStatusMismatch(eventId, backendStatus, calculatedStatus);
    }

    return _HomeEventModel(
      id: _asString(map['event_id']) ?? '',
      name: _asString(map['event_name']) ?? '',
      emoji: _normalizeEmoji(map['emoji']),
      date: startDate,
      endDate: endDate,
      location: _asString(map['location_name']),
      status: calculatedStatus, // ✅ Calculado, não lido do DB
      userRsvp: _asString(map['user_rsvp']),
      votedAt: _parseDateTime(map['voted_at']),
      goingCount: _asInt(map['going_count']) + _asInt(map['guest_going_count']),
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

    // ✅ FIX: home_events_view has no photo_count/max_photos columns.
    // Compute both from what we already have:
    //   photoCount  = sum of each participant's photo count
    //   maxPhotos   = max(20, 5 × total participants) — business rule
    final computedPhotoCount =
        participantPhotos.fold(0, (sum, p) => sum + p.photoCount);
    final computedMaxPhotos =
        [20, 5 * participantsTotal].reduce((a, b) => a > b ? a : b);

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
      photoCount: computedPhotoCount,
      maxPhotos: computedMaxPhotos,
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
          .from('event_photos')
          .select(
              'uploader_id, users!event_photos_uploader_id_fkey(id, name, avatar_url)')
          .eq('event_id', id)
          .order('captured_at', ascending: false);

      if (response.isEmpty) {
        // Still need to build 0-photo list from goingUsers
        final zeroPhotoList = <ParticipantPhoto>[];
        for (final u in goingUsers) {
          if (u is! Map<String, dynamic>) continue;
          final userId = u['user_id'] as String?;
          if (userId == null) continue;
          final displayName = u['display_name'] as String? ?? 'Unknown';
          final avatarUrl = u['avatar_url'] as String?;
          zeroPhotoList.add(ParticipantPhoto(
            userId: userId,
            userName: currentUserId == userId ? 'You' : displayName,
            userAvatar: avatarUrl,
            photoCount: 0,
          ));
        }
        return zeroPhotoList;
      }

      // ✅ OPTIMIZATION: Collect all unique avatar paths first
      final avatarPaths = <String>{};
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) continue;
        final userData = row['users'];
        if (userData is! Map<String, dynamic>) continue;
        final avatarPath = userData['avatar_url'] as String?;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          avatarPaths.add(avatarPath);
        }
      }

      // ✅ Batch fetch all avatar signed URLs in parallel
      final avatarCache = AvatarCacheService();
      final signedUrls = await avatarCache.batchGetAvatarUrls(
        supabaseClient,
        avatarPaths.toList(),
      );

      // Group photos by uploader
      final Map<String, ParticipantPhoto> participantsMap = {};

      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) continue;

        final uploaderId = row['uploader_id'] as String?;
        if (uploaderId == null) continue;

        final userData = row['users'];
        if (userData is! Map<String, dynamic>) continue;

        final displayName = userData['name'] as String? ?? 'Unknown';
        final avatarPath = userData['avatar_url'] as String?;

        // ✅ Get signed URL from batch result (already fetched)
        final avatarUrl = avatarPath != null ? signedUrls[avatarPath] : null;

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

      // ✅ Include all going participants with 0 photos (not yet in map)
      for (final u in goingUsers) {
        if (u is! Map<String, dynamic>) {
          continue;
        }
        final userId = u['user_id'] as String?;
        final displayName = u['display_name'] as String? ?? 'Unknown';

        if (userId == null || participantsMap.containsKey(userId)) continue;
        final avatarUrl = u['avatar_url'] as String?; // already signed
        participantsMap[userId] = ParticipantPhoto(
          userId: userId,
          userName: currentUserId == userId ? 'You' : displayName,
          userAvatar: avatarUrl,
          photoCount: 0,
        );
      }

      // Sort: participants with photos first, then 0-photo participants
      final result = participantsMap.values.toList()
        ..sort((a, b) => b.photoCount.compareTo(a.photoCount));
      return result;
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

        // ✅ OPTIMIZATION: Avatar URL is already signed by batch processing in data source
        // No need to call createSignedUrl here anymore
        final signedAvatarUrl = _asString(u['avatar_url']);

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

    // CRITICAL: Pending events with past start_datetime → expired
    if (backendStatus == 'pending') {
      if (start != null && start.isBefore(now)) {
        return 'expired';
      }
      return 'pending';
    }

    // Already expired in DB — keep it
    if (backendStatus == 'expired') {
      return 'expired';
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
      case 'expired':
        return HomeEventStatus.expired;
      default:
        return HomeEventStatus.pending;
    }
  }

  static RsvpVoteStatus _mapUserVote(String? rsvp) {
    if (rsvp == null) return RsvpVoteStatus.pending;
    final s = rsvp.toLowerCase();
    if (s == 'yes' || s == 'going' || s == 'attending' || s == 'accepted') {
      return RsvpVoteStatus.going;
    }
    if (s == 'no' || s == 'not_going' || s == 'declined' || s == 'rejected') {
      return RsvpVoteStatus.notGoing;
    }
    if (s == 'maybe') {
      return RsvpVoteStatus.maybe;
    }
    // 'pending' and unknown values
    return RsvpVoteStatus.pending;
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
  Function(String eventId, String fromStatus, String toStatus)?
      onStatusMismatch,
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
