import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw action data returned by the get_host_action_data() RPC function
/// or computed from direct queries.
class HostActionRow {
  final String eventId;
  final String eventName;
  final String? eventEmoji;
  final String eventStatus;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final String? locationId;
  final int totalParticipants;
  final int maybeCount;
  final int pendingCount;
  final int hostPhotoCount;

  const HostActionRow({
    required this.eventId,
    required this.eventName,
    this.eventEmoji,
    required this.eventStatus,
    this.startDatetime,
    this.endDatetime,
    this.locationId,
    required this.totalParticipants,
    required this.maybeCount,
    required this.pendingCount,
    required this.hostPhotoCount,
  });

  factory HostActionRow.fromJson(Map<String, dynamic> json) {
    return HostActionRow(
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String? ?? 'Untitled Event',
      eventEmoji: json['event_emoji'] as String?,
      eventStatus: json['event_status'] as String,
      startDatetime: json['start_datetime'] != null
          ? DateTime.parse(json['start_datetime'] as String)
          : null,
      endDatetime: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'] as String)
          : null,
      locationId: json['location_id'] as String?,
      totalParticipants: (json['total_participants'] as num?)?.toInt() ?? 0,
      maybeCount: (json['maybe_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      hostPhotoCount: (json['host_photo_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data source that fetches raw event data needed to compute host actions.
/// For beta, actions are computed client-side from event/participant state.
class ActionRemoteDataSource {
  final SupabaseClient _client;

  ActionRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  /// Fetch host action data using the RPC function.
  /// Falls back to direct queries if the RPC function is not deployed yet.
  Future<List<HostActionRow>> getHostActionData() async {
    try {
      return await _fetchViaRpc();
    } catch (_) {
      // Fallback: direct queries if RPC not available
      return await _fetchViaDirect();
    }
  }

  /// Use the get_host_action_data() PostgreSQL function
  Future<List<HostActionRow>> _fetchViaRpc() async {
    final response = await _client.rpc(
      'get_host_action_data',
      params: {'host_user_id': _userId},
    );

    final rows = (response as List)
        .map((json) => HostActionRow.fromJson(json as Map<String, dynamic>))
        .toList();

    return rows;
  }

  /// Fallback: direct Supabase queries (no RPC function needed)
  Future<List<HostActionRow>> _fetchViaDirect() async {
    if (_userId.isEmpty) return [];

    // Get events where user is host, with statuses relevant for actions
    final eventsResponse = await _client
        .from('events')
        .select(
            'id, name, emoji, status, start_datetime, end_datetime, location_id')
        .eq('created_by', _userId)
        .inFilter('status', ['pending', 'confirmed', 'living', 'recap']);

    final events = eventsResponse as List;
    if (events.isEmpty) return [];

    final eventIds = events.map((e) => e['id'] as String).toList();

    // Get participant RSVP counts per event
    final participantsResponse = await _client
        .from('event_participants')
        .select('pevent_id, rsvp')
        .inFilter('pevent_id', eventIds);

    final participants = participantsResponse as List;

    // Get host photo counts per event
    final photosResponse = await _client
        .from('event_photos')
        .select('event_id')
        .eq('uploader_id', _userId)
        .inFilter('event_id', eventIds);

    final photos = photosResponse as List;

    // Build aggregated data
    final Map<String, int> maybeCounts = {};
    final Map<String, int> pendingCounts = {};
    final Map<String, int> totalCounts = {};

    for (final p in participants) {
      final eventId = p['pevent_id'] as String;
      final rsvp = p['rsvp'] as String?;

      totalCounts[eventId] = (totalCounts[eventId] ?? 0) + 1;
      if (rsvp == 'maybe') {
        maybeCounts[eventId] = (maybeCounts[eventId] ?? 0) + 1;
      } else if (rsvp == 'pending') {
        pendingCounts[eventId] = (pendingCounts[eventId] ?? 0) + 1;
      }
    }

    final Map<String, int> photoCounts = {};
    for (final p in photos) {
      final eventId = p['event_id'] as String;
      photoCounts[eventId] = (photoCounts[eventId] ?? 0) + 1;
    }

    // Build rows
    return events.map((e) {
      final eventId = e['id'] as String;
      return HostActionRow(
        eventId: eventId,
        eventName: e['name'] as String? ?? 'Untitled Event',
        eventEmoji: e['emoji'] as String?,
        eventStatus: e['status'] as String,
        startDatetime: e['start_datetime'] != null
            ? DateTime.parse(e['start_datetime'] as String)
            : null,
        endDatetime: e['end_datetime'] != null
            ? DateTime.parse(e['end_datetime'] as String)
            : null,
        locationId: e['location_id'] as String?,
        totalParticipants: totalCounts[eventId] ?? 0,
        maybeCount: maybeCounts[eventId] ?? 0,
        pendingCount: pendingCounts[eventId] ?? 0,
        hostPhotoCount: photoCounts[eventId] ?? 0,
      );
    }).toList();
  }

  /// Get dismissed action IDs for the current user.
  /// Returns empty list if dismissed_actions table doesn't exist yet (beta).
  Future<Set<String>> getDismissedActionKeys() async {
    try {
      final response = await _client
          .from('dismissed_actions')
          .select('action_type, event_id')
          .eq('user_id', _userId);

      final rows = response as List;
      return rows.map((r) => '${r['action_type']}_${r['event_id']}').toSet();
    } catch (_) {
      // Table doesn't exist yet in beta — no dismissals
      return {};
    }
  }

  /// Dismiss an action (persist to DB if dismissed_actions table exists).
  Future<void> dismissAction({
    required String actionType,
    required String eventId,
  }) async {
    try {
      await _client.from('dismissed_actions').upsert({
        'user_id': _userId,
        'action_type': actionType,
        'event_id': eventId,
      });
    } catch (_) {
      // Table doesn't exist yet — dismissal is local-only in beta
    }
  }
}
