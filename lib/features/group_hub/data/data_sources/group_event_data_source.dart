import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for group events from Supabase
/// 
/// P2 Implementation Requirements:
/// - Query 'group_events' table with proper RLS policies
/// - Join with 'event_rsvps' to get vote counts and user participation
/// - Select only necessary columns (id, name, emoji, date, ends_at, location, status, etc.)
/// - Use indexes for performance (group_id, date DESC)
/// - Implement pagination with LIMIT/OFFSET for large datasets
abstract class GroupEventDataSource {
  /// Get all events for a specific group
  /// 
  /// SQL Query Example:
  /// ```sql
  /// SELECT 
  ///   e.id, e.name, e.emoji, e.date, e.ends_at, e.location, e.status,
  ///   COUNT(CASE WHEN r.status = 'going' THEN 1 END) as going_count,
  ///   COUNT(r.user_id) as participant_count,
  ///   e.photo_count, e.max_photos,
  ///   ARRAY_AGG(u.avatar_url) FILTER (WHERE r.status = 'going') as attendee_avatars,
  ///   ARRAY_AGG(u.name) FILTER (WHERE r.status = 'going') as attendee_names
  /// FROM group_events e
  /// LEFT JOIN event_rsvps r ON e.id = r.event_id
  /// LEFT JOIN profiles u ON r.user_id = u.id
  /// WHERE e.group_id = ? AND e.deleted_at IS NULL
  /// GROUP BY e.id
  /// ORDER BY e.date DESC
  /// LIMIT 50;
  /// ```
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId);

  /// Get a specific event by ID with all RSVP details
  /// 
  /// Returns event data including current user's vote status
  Future<Map<String, dynamic>?> getEventById(String eventId);

  /// Get all RSVP votes for a specific event
  /// 
  /// SQL Query Example:
  /// ```sql
  /// SELECT 
  ///   r.id, r.user_id, r.status, r.voted_at,
  ///   u.name as user_name, u.avatar_url as user_avatar
  /// FROM event_rsvps r
  /// JOIN profiles u ON r.user_id = u.id
  /// WHERE r.event_id = ?
  /// ORDER BY r.voted_at DESC;
  /// ```
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId);
}

/// Supabase implementation of GroupEventDataSource
/// 
/// P2 TODO:
/// 1. Implement getGroupEvents() with proper joins and aggregations
/// 2. Implement getEventById() with user vote status
/// 3. Implement getEventRsvps() for bottom sheet display
/// 4. Add error handling for network failures
/// 5. Respect RLS policies (only group members can see events)
/// 6. Use proper indexes for performance
class SupabaseGroupEventDataSource implements GroupEventDataSource {
  // ignore: unused_field
  final SupabaseClient _client;

  SupabaseGroupEventDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
    // P2 TODO: Implement Supabase query
    // - Query group_events table filtered by group_id
    // - Join with event_rsvps to get counts
    // - Join with profiles to get attendee info
    // - Order by date DESC
    // - Handle errors and return empty list on failure
    throw UnimplementedError('P2: Implement Supabase query for group events');
  }

  @override
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    // P2 TODO: Implement single event query
    // - Get event by ID
    // - Include current user's RSVP status
    // - Return null if not found
    throw UnimplementedError('P2: Implement Supabase query for event by ID');
  }

  @override
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId) async {
    // P2 TODO: Implement RSVP query
    // - Get all RSVPs for event
    // - Join with profiles for user details
    // - Order by voted_at DESC
    throw UnimplementedError('P2: Implement Supabase query for event RSVPs');
  }
}
