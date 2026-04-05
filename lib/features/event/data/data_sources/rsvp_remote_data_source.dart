import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rsvp_model.dart';

/// Remote data source for RSVP operations
/// Handles all Supabase queries related to RSVPs
class RsvpRemoteDataSource {
  final SupabaseClient _supabaseClient;
  static const String _avatarBucketName = 'users-profile-pic';

  RsvpRemoteDataSource(this._supabaseClient);

  /// Convert storage path to signed URL (for private buckets)
  Future<String> _getSignedAvatarUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) {
      return '';
    }

    // Already a full URL
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    try {
      // Normalize path - remove leading slash if present
      final normalizedPath =
          storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;

      // Create signed URL (valid for 1 hour)
      final signedUrl = await _supabaseClient.storage
          .from(_avatarBucketName)
          .createSignedUrl(normalizedPath, 3600);

      return signedUrl;
    } catch (e) {
      return '';
    }
  }

  /// Helper to convert avatar_url in user data to signed URL
  Future<void> _convertAvatarUrl(Map<String, dynamic> json) async {
    if (json['user'] != null && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      if (user['avatar_url'] != null) {
        user['avatar_url'] =
            await _getSignedAvatarUrl(user['avatar_url'] as String);
      }
    }
  }

  /// Get all RSVPs for an event
  /// Includes user data via join
  /// Uses existing event_participants table
  Future<List<RsvpModel>> getEventRsvps(String eventId) async {
    try {
      final response =
          await _supabaseClient.from('event_participants').select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, avatar_url, email)
          ''').eq('pevent_id', eventId).order('confirmed_at', ascending: false);

      // Convert avatar URLs from storage paths to signed URLs
      for (final json in response as List) {
        await _convertAvatarUrl(json as Map<String, dynamic>);
      }

      final models =
          (response as List).map((json) => RsvpModel.fromJson(json)).toList();

      return models;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get event RSVPs: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get event RSVPs: $e');
    }
  }

  /// Get user's RSVP for an event
  Future<RsvpModel?> getUserRsvp(String eventId, String userId) async {
    try {
      final response =
          await _supabaseClient.from('event_participants').select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, avatar_url, email)
          ''').eq('pevent_id', eventId).eq('user_id', userId).maybeSingle();

      if (response == null) return null;

      // Convert avatar URL from storage path to signed URL
      await _convertAvatarUrl(response);

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
      final response = await _supabaseClient.from('event_participants').upsert({
        'pevent_id': eventId,
        'user_id': userId,
        'rsvp': status,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).select('''
            user_id,
            pevent_id,
            rsvp,
            confirmed_at,
            user:user_id(id, name, avatar_url, email)
          ''').single();

      // Convert avatar URL from storage path to signed URL
      await _convertAvatarUrl(response);

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
            user:user_id(id, name, avatar_url, email)
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
