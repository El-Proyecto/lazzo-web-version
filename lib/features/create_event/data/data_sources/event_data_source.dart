import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for event operations using Supabase
/// Handles all Supabase interactions following RLS and minimal column selection
class EventDataSource {
  final SupabaseClient _client;

  EventDataSource(this._client);


  String _calculateEventStatus(DateTime? startDateTime, DateTime? endDateTime, String currentStatus) {
    // If dates are not set, keep current status (draft/pending)
    if (startDateTime == null || endDateTime == null) {
      return currentStatus;
    }
    
    final now = DateTime.now().toUtc();
    final startUtc = startDateTime.toUtc();
    final endUtc = endDateTime.toUtc();
    
    // Event has ended → recap
    if (now.isAfter(endUtc)) {
      return 'recap';
    }
    
    // Event is happening now → living
    if (now.isAfter(startUtc) && now.isBefore(endUtc)) {
      return 'living';
    }
    
    // Event hasn't started yet → confirmed (or keep pending/draft)
    if (currentStatus == 'draft' || currentStatus == 'pending') {
      return currentStatus;
    }
    
    return 'confirmed';
  }

  /// Create a new event in Supabase
  /// Respects RLS - user can only create events in groups they belong to
  Future<Map<String, dynamic>> createEvent({
    //required String? id,
    required String name,
    required String emoji,
    required String groupId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? locationId,
    String status = 'draft',
    required String createdBy,
  }) async {
    // Calculate correct status based on time if event is being confirmed
    String finalStatus = status;
    if (status == 'confirmed' || status == 'living' || status == 'recap') {
      finalStatus = _calculateEventStatus(startDateTime, endDateTime, status);
      if (finalStatus != status) {
              }
    }
    
    final response = await _client.from('events').insert({
      'name': name,
      'emoji': emoji,
      'group_id': groupId,
      'start_datetime': startDateTime?.toIso8601String(),
      'end_datetime': endDateTime?.toIso8601String(),
      'location_id': locationId,
      'status': finalStatus,
      'created_by': createdBy,
    }).select('id, name, emoji, group_id, start_datetime, end_datetime, location_id, status, created_by, created_at').single();

    return response;
  }

  /// Get event by ID
  /// Selects minimal columns as per agent guide
  Future<Map<String, dynamic>?> getEventById(String id) async {
    final response = await _client
        .from('events')
        .select(
            'id, name, emoji, group_id, start_datetime, end_datetime, location_id, status, created_by, created_at')
        .eq('id', id)
        .maybeSingle();

    return response;
  }

  /// Update an existing event
  /// Respects RLS - user can only update events they created
  /// CRITICAL: Always includes fields in update to allow clearing nullable fields
  /// This prevents PGRST116 errors when switching from "Set Now" to "Decide Later"
  Future<Map<String, dynamic>> updateEvent({
    required String id,
    required String name,
    required String emoji,
    required String groupId,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
    required String? locationId,
    required String status,
  }) async {
    // Calculate correct status based on time if event is confirmed/living/recap
    String finalStatus = status;
    if (status == 'confirmed' || status == 'living' || status == 'recap') {
      finalStatus = _calculateEventStatus(startDateTime, endDateTime, status);
      if (finalStatus != status) {
              }
    }
    
    // Build update data - include ALL fields to allow clearing nullable ones
    final updateData = <String, dynamic>{
      'name': name,
      'emoji': emoji,
      'group_id': groupId,
      'start_datetime': startDateTime?.toIso8601String(),
      'end_datetime': endDateTime?.toIso8601String(),
      'location_id': locationId,
      'status': finalStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _client
          .from('events')
          .update(updateData)
          .eq('id', id)
          .select(
              'id, name, emoji, group_id, start_datetime, end_datetime, location_id, status, created_by, created_at, updated_at')
          .single(); // Use .single() instead of .maybeSingle() to get proper error

      return response;
    } on PostgrestException catch (e) {
      // PGRST116 = no rows returned (either doesn't exist or RLS blocked)
      if (e.code == 'PGRST116') {
        throw Exception(
            'Event not found or you do not have permission to update it. Make sure you are the creator of this event.');
      }
      rethrow;
    }
  }

  /// Delete an event
  /// Respects RLS - user can only delete events they created
  Future<void> deleteEvent(String id) async {
    
    try {
     
      final response = await _client.from('events').delete().eq('id', id);
                      } catch (e) {
                        
      if (e is PostgrestException) {
                                                
        if (e.code == '23503') {
                  } else if (e.code == '22P02') {
                  }
      }
      
      rethrow;
    }
  }

  /// Get events for a group with performance optimization
  /// Uses indexes: order by created_at (indexed) with limit
  Future<List<Map<String, dynamic>>> getEventsForGroup(
    String groupId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from('events')
        .select(
            'id, name, emoji, group_id, start_datetime, end_datetime, location_id, status, created_by, created_at')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a location entry
  /// Returns location ID for use in events
  /// Requires created_by for RLS compliance
  Future<Map<String, dynamic>> createLocation({
    String? displayName,
    required String formattedAddress,
    required double latitude,
    required double longitude,
    required String createdBy,
  }) async {
    final response = await _client
        .from('locations')
        .insert({
          'display_name': displayName,
          'formatted_address': formattedAddress,
          'latitude': latitude,
          'longitude': longitude,
          'created_by': createdBy,
        })
        .select('id, display_name, formatted_address, latitude, longitude')
        .single();

    return response;
  }

  /// Get location by ID
  Future<Map<String, dynamic>?> getLocationById(String id) async {
    final response = await _client
        .from('locations')
        .select('id, display_name, formatted_address, latitude, longitude')
        .eq('id', id)
        .maybeSingle();

    return response;
  }

  /// Search locations by address (using RPC for complex search if available)
  /// Falls back to simple text search if no RPC is implemented
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    // Simple text search - in production this could use a Supabase RPC for more sophisticated search
    final response = await _client
        .from('locations')
        .select('id, display_name, formatted_address, latitude, longitude')
        .ilike('formatted_address', '%$query%')
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user's recent events for history
  /// Joins with locations table to get denormalized location data
  /// Respects RLS - user can only see events they created
  Future<List<Map<String, dynamic>>> getUserEventHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Use explicit foreign key to avoid ambiguity: events.group_id → groups.id
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            emoji,
            start_datetime,
            location_id,
            group_id,
            created_at,
            status,
            locations (
              display_name,
              formatted_address,
              latitude,
              longitude
            ),
            groups!events_group_id_fkey (
              name
            )
          ''')
          .eq('created_by', userId)
          .inFilter('status', ['confirmed', 'living', 'recap', 'ended'])
          .not('start_datetime', 'is', null)
          .order('start_datetime', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch event history: $e');
    }
  }
}
