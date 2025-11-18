import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for group events from Supabase
abstract class GroupEventDataSource {
  /// Get all events for a specific group using optimized view
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId);

  /// Get a specific event by ID with all RSVP details
  Future<Map<String, dynamic>?> getEventById(String eventId);

  /// Get all RSVP votes for a specific event
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId);
}

/// Supabase implementation using group_hub_events_view
class SupabaseGroupEventDataSource implements GroupEventDataSource {
  final SupabaseClient _client;

  SupabaseGroupEventDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select()
          .eq('group_id', groupId)
          .order('priority', ascending: false)
          .order('start_datetime', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching group events: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select()
          .eq('event_id', eventId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching event by ID: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId) async {
    try {
      // Get all votes from going_users, not_going_users, and no_response_users
      final event = await getEventById(eventId);
      if (event == null) return [];

      final goingUsers = event['going_users'] as List? ?? [];
      final notGoingUsers = event['not_going_users'] as List? ?? [];
      final noResponseUsers = event['no_response_users'] as List? ?? [];

      final allVotes = <Map<String, dynamic>>[];

      // Add going votes
      for (final user in goingUsers) {
        allVotes.add({
          'user_id': user['user_id'],
          'user_name': user['display_name'],
          'user_avatar': user['avatar_url'],
          'status': 'going',
          'voted_at': user['voted_at'],
        });
      }

      // Add not going votes
      for (final user in notGoingUsers) {
        allVotes.add({
          'user_id': user['user_id'],
          'user_name': user['display_name'],
          'user_avatar': user['avatar_url'],
          'status': 'notGoing',
          'voted_at': user['voted_at'],
        });
      }

      // Add pending votes
      for (final user in noResponseUsers) {
        allVotes.add({
          'user_id': user['user_id'],
          'user_name': user['display_name'],
          'user_avatar': user['avatar_url'],
          'status': 'pending',
          'voted_at': null,
        });
      }

      return allVotes;
    } catch (e) {
      print('❌ Error fetching event RSVPs: $e');
      return [];
    }
  }
}
