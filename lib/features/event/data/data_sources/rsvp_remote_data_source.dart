import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rsvp_model.dart';

/// Remote data source for RSVP operations
/// Handles all Supabase queries related to RSVPs
class RsvpRemoteDataSource {
  final SupabaseClient _supabaseClient;

  RsvpRemoteDataSource(this._supabaseClient);

  /// Get all RSVPs for an event
  /// Includes user data via join
  /// Uses existing event_participants table
  Future<List<RsvpModel>> getEventRsvps(String eventId) async {
    try {
      final response = await _supabaseClient
          .from('event_participants')
          .select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, profile_picture_url)
          ''')
          .eq('pevent_id', eventId)
          .order('confirmed_at', ascending: false);

      return (response as List)
          .map((json) => RsvpModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get event RSVPs: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get event RSVPs: $e');
    }
  }

  /// Get user's RSVP for an event
  Future<RsvpModel?> getUserRsvp(String eventId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('event_participants')
          .select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, profile_picture_url)
          ''')
          .eq('pevent_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return RsvpModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user RSVP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user RSVP: $e');
    }
  }

  /// Create or update RSVP (UPSERT)
  /// Uses event_participants table
  Future<RsvpModel> submitRsvp(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      final response = await _supabaseClient
          .from('event_participants')
          .upsert({
            'pevent_id': eventId,
            'user_id': userId,
            'rsvp': status,
            'confirmed_at': DateTime.now().toIso8601String(),
          })
          .select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, profile_picture_url)
          ''')
          .single();

      return RsvpModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit RSVP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit RSVP: $e');
    }
  }

  /// Get RSVPs by status
  Future<List<RsvpModel>> getRsvpsByStatus(
    String eventId,
    String status,
  ) async {
    try {
      final response = await _supabaseClient
          .from('event_participants')
          .select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, profile_picture_url)
          ''')
          .eq('pevent_id', eventId)
          .eq('rsvp', status)
          .order('confirmed_at', ascending: false);

      return (response as List)
          .map((json) => RsvpModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get RSVPs by status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get RSVPs by status: $e');
    }
  }

  /// Reset RSVP votes based on suggestion voters
  /// Sets suggestion voters to 'yes' and all others to 'pending'
  Future<void> resetRsvpVotesFromSuggestion(
    String eventId,
    List<String> suggestionVoterUserIds,
  ) async {
    try {
      // Set voters to 'yes' (rsvp_status enum: pending, yes, no, maybe)
      if (suggestionVoterUserIds.isNotEmpty) {
        await _supabaseClient
            .from('event_participants')
            .update({'rsvp': 'yes'})
            .eq('pevent_id', eventId)
            .inFilter('user_id', suggestionVoterUserIds);
      }

      // Set all others to 'pending'
      await _supabaseClient
          .from('event_participants')
          .update({'rsvp': 'pending'})
          .eq('pevent_id', eventId)
          .not('user_id', 'in', '(${suggestionVoterUserIds.join(',')})');
    } on PostgrestException catch (e) {
      throw Exception('Failed to reset RSVP votes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reset RSVP votes: $e');
    }
  }
}
