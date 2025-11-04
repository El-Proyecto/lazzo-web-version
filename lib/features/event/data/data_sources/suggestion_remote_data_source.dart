import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/suggestion_model.dart';

/// Remote data source for suggestion operations (datetime and location)
/// Handles all Supabase queries related to suggestions
class SuggestionRemoteDataSource {
  final SupabaseClient _supabaseClient;

  SuggestionRemoteDataSource(this._supabaseClient);

  // ============================================================================
  // DATETIME SUGGESTIONS
  // ============================================================================

  /// Get all datetime suggestions for an event
  Future<List<SuggestionModel>> getEventSuggestions(String eventId) async {
    try {
      print('🔍 [SuggestionDataSource.getEventSuggestions] Fetching suggestions for event: $eventId');
      
      final response = await _supabaseClient
          .from('event_date_options') // Table: event_date_options
          .select('''
            id,
            event_id,
            created_by,
            starts_at,
            ends_at,
            created_at,
            user:created_by(id, name, avatar_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      print('📊 [SuggestionDataSource.getEventSuggestions] Found ${(response as List).length} suggestions');
      
      final suggestions = (response as List)
          .map((json) {
            print('   📅 Suggestion: ${json['id']} - ${json['starts_at']} to ${json['ends_at']}');
            return SuggestionModel.fromJson(json);
          })
          .toList();
      
      return suggestions;
    } on PostgrestException catch (e) {
      print('❌ [SuggestionDataSource.getEventSuggestions] Postgrest error: ${e.message}');
      throw Exception('Failed to get event suggestions: ${e.message}');
    } catch (e) {
      print('❌ [SuggestionDataSource.getEventSuggestions] Error: $e');
      throw Exception('Failed to get event suggestions: $e');
    }
  }

  /// Create a new datetime suggestion
  /// If currentEventStartDateTime is provided, creates a "current" suggestion first
  Future<SuggestionModel> createSuggestion({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
    DateTime? currentEventStartDateTime,
    DateTime? currentEventEndDateTime,
  }) async {
    try {
      // Check if this is the first suggestion
      final existingCount = await _supabaseClient
          .from('event_date_options') // Table: event_date_options
          .select('id')
          .eq('event_id', eventId)
          .count(CountOption.exact);

      // If first suggestion AND current event datetime provided, create "current" first
      if (existingCount.count == 0 && currentEventStartDateTime != null) {
        await _supabaseClient.from('event_date_options').insert({
          'event_id': eventId,
          'created_by': userId, // Field: created_by
          'starts_at': currentEventStartDateTime.toIso8601String(), // Field: starts_at
          'ends_at': currentEventEndDateTime?.toIso8601String(), // Field: ends_at
        });
      }

      // Create the new suggestion
      final response = await _supabaseClient
          .from('event_date_options') // Table: event_date_options
          .insert({
            'event_id': eventId,
            'created_by': userId, // Field: created_by
            'starts_at': startDateTime.toIso8601String(), // Field: starts_at
            'ends_at': endDateTime?.toIso8601String(), // Field: ends_at
          })
          .select('''
            id,
            event_id,
            created_by,
            starts_at,
            ends_at,
            created_at,
            user:created_by(id, name, avatar_url)
          ''')
          .single();

      return SuggestionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create suggestion: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create suggestion: $e');
    }
  }

  /// Get all votes for event datetime suggestions
  Future<List<SuggestionVoteModel>> getEventSuggestionVotes(
    String eventId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('event_date_votes') // Table: event_date_votes
          .select('''
            option_id,
            user_id,
            voted_at,
            event_id,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId);

      return (response as List)
          .map((json) => SuggestionVoteModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get suggestion votes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get suggestion votes: $e');
    }
  }

  /// Vote on a datetime suggestion
  Future<SuggestionVoteModel> voteOnSuggestion({
    required String suggestionId,
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('event_date_votes') // Table: event_date_votes
          .insert({
            'option_id': suggestionId, // Field: option_id
            'user_id': userId,
            'event_id': eventId,
          })
          .select('''
            option_id,
            user_id,
            voted_at,
            event_id,
            user:user_id(id, name, avatar_url)
          ''')
          .single();

      return SuggestionVoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to vote on suggestion: ${e.message}');
    } catch (e) {
      throw Exception('Failed to vote on suggestion: $e');
    }
  }

  /// Remove vote from a datetime suggestion
  Future<void> removeVoteFromSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    try {
      await _supabaseClient
          .from('event_date_votes') // Table: event_date_votes
          .delete()
          .eq('option_id', suggestionId) // Field: option_id
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove vote: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove vote: $e');
    }
  }

  /// Get user's votes for event datetime suggestions
  Future<List<SuggestionVoteModel>> getUserSuggestionVotes({
    required String eventId,
    required String userId,
  }) async {
    try {
      // Get user votes directly using event_id
      final response = await _supabaseClient
          .from('event_date_votes') // Table: event_date_votes
          .select('''
            option_id,
            user_id,
            voted_at,
            event_id,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId)
          .eq('user_id', userId);

      return (response as List)
          .map((json) => SuggestionVoteModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user suggestion votes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user suggestion votes: $e');
    }
  }

  /// Clear all datetime suggestions and votes for an event
  Future<void> clearEventSuggestions(String eventId) async {
    try {
      // Delete suggestions (CASCADE will delete votes)
      await _supabaseClient
          .from('event_date_options') // Table: event_date_options
          .delete()
          .eq('event_id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to clear suggestions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to clear suggestions: $e');
    }
  }

  // ============================================================================
  // LOCATION SUGGESTIONS
  // ============================================================================

  /// Get all location suggestions for an event
  Future<List<LocationSuggestionModel>> getEventLocationSuggestions(
    String eventId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('location_suggestions')
          .select('''
            id,
            event_id,
            user_id,
            location_name,
            address,
            latitude,
            longitude,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LocationSuggestionModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get location suggestions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get location suggestions: $e');
    }
  }

  /// Create a new location suggestion
  /// If currentEventLocationName is provided, creates a "current" suggestion first
  Future<LocationSuggestionModel> createLocationSuggestion({
    required String eventId,
    required String userId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? currentEventLocationName,
    String? currentEventAddress,
  }) async {
    try {
      // Check if this is the first location suggestion
      final existingCount = await _supabaseClient
          .from('location_suggestions')
          .select('id')
          .eq('event_id', eventId)
          .count(CountOption.exact);

      // If first suggestion AND current event location provided, create "current" first
      if (existingCount.count == 0 && currentEventLocationName != null) {
        await _supabaseClient.from('location_suggestions').insert({
          'event_id': eventId,
          'user_id': userId,
          'location_name': currentEventLocationName,
          'address': currentEventAddress,
          'latitude': null,
          'longitude': null,
        });
      }

      // Create the new location suggestion
      final response = await _supabaseClient
          .from('location_suggestions')
          .insert({
            'event_id': eventId,
            'user_id': userId,
            'location_name': locationName,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
          })
          .select('''
            id,
            event_id,
            user_id,
            location_name,
            address,
            latitude,
            longitude,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .single();

      return LocationSuggestionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create location suggestion: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create location suggestion: $e');
    }
  }

  /// Get all votes for event location suggestions
  Future<List<SuggestionVoteModel>> getEventLocationSuggestionVotes(
    String eventId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('location_suggestion_votes') // Table: location_suggestion_votes
          .select('''
            id,
            suggestion_id,
            user_id,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId);

      return (response as List)
          .map((json) => SuggestionVoteModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get location suggestion votes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get location suggestion votes: $e');
    }
  }

  /// Vote on a location suggestion
  Future<SuggestionVoteModel> voteOnLocationSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('location_suggestion_votes')
          .insert({
            'suggestion_id': suggestionId,
            'user_id': userId,
          })
          .select('''
            id,
            suggestion_id,
            user_id,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .single();

      return SuggestionVoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to vote on location suggestion: ${e.message}');
    } catch (e) {
      throw Exception('Failed to vote on location suggestion: $e');
    }
  }

  /// Remove vote from a location suggestion
  Future<void> removeVoteFromLocationSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    try {
      await _supabaseClient
          .from('location_suggestion_votes')
          .delete()
          .eq('suggestion_id', suggestionId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove location vote: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove location vote: $e');
    }
  }

  /// Get user's votes for event location suggestions
  Future<List<SuggestionVoteModel>> getUserLocationSuggestionVotes({
    required String eventId,
    required String userId,
  }) async {
    try {
      // Get all location suggestion IDs for this event
      final suggestions = await _supabaseClient
          .from('location_suggestions')
          .select('id')
          .eq('event_id', eventId);

      final suggestionIds =
          (suggestions as List).map((s) => s['id'] as String).toList();

      if (suggestionIds.isEmpty) return [];

      // Get user votes for these location suggestions
      final response = await _supabaseClient
          .from('location_suggestion_votes')
          .select('''
            id,
            suggestion_id,
            user_id,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .inFilter('suggestion_id', suggestionIds)
          .eq('user_id', userId);

      return (response as List)
          .map((json) => SuggestionVoteModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
          'Failed to get user location suggestion votes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user location suggestion votes: $e');
    }
  }

  /// Clear all location suggestions and votes for an event
  Future<void> clearEventLocationSuggestions(String eventId) async {
    try {
      // Delete location suggestions (CASCADE will delete votes)
      await _supabaseClient
          .from('location_suggestions')
          .delete()
          .eq('event_id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to clear location suggestions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to clear location suggestions: $e');
    }
  }
}
