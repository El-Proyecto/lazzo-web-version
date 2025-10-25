import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poll_model.dart';

/// Remote data source for poll operations
/// Handles all Supabase queries related to polls
class PollRemoteDataSource {
  final SupabaseClient _supabaseClient;

  PollRemoteDataSource(this._supabaseClient);

  /// Get all polls for an event with their options
  Future<List<PollModel>> getEventPolls(String eventId) async {
    try {
      // Get polls
      final pollsResponse = await _supabaseClient
          .from('polls')
          .select('''
            id,
            event_id,
            type,
            question,
            created_at,
            created_by
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      final polls = (pollsResponse as List);

      // Get options for all polls
      final List<PollModel> pollModels = [];

      for (final pollJson in polls) {
        final pollId = pollJson['id'] as String;

        final optionsResponse = await _supabaseClient
            .from('poll_options')
            .select('''
              id,
              poll_id,
              value,
              vote_count
            ''')
            .eq('poll_id', pollId);

        // Add options to poll json
        pollJson['options'] = optionsResponse;

        pollModels.add(PollModel.fromJson(pollJson));
      }

      return pollModels;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get event polls: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get event polls: $e');
    }
  }

  /// Create a new poll with options
  Future<PollModel> createPoll({
    required String eventId,
    required String type,
    required String question,
    required List<String> options,
    required String createdBy,
  }) async {
    try {
      // Create poll
      final pollResponse = await _supabaseClient
          .from('polls')
          .insert({
            'event_id': eventId,
            'type': type,
            'question': question,
            'created_by': createdBy,
          })
          .select('''
            id,
            event_id,
            type,
            question,
            created_at,
            created_by
          ''')
          .single();

      final pollId = pollResponse['id'] as String;

      // Create poll options
      final optionInserts = options.map((option) => {
            'poll_id': pollId,
            'value': option,
            'vote_count': 0,
          }).toList();

      final optionsResponse = await _supabaseClient
          .from('poll_options')
          .insert(optionInserts)
          .select('''
            id,
            poll_id,
            value,
            vote_count
          ''');

      // Build complete poll
      pollResponse['options'] = optionsResponse;

      return PollModel.fromJson(pollResponse);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create poll: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  /// Vote on a poll option
  /// Uses upsert to prevent duplicate votes
  Future<void> voteOnPoll(
    String pollId,
    String optionId,
    String userId,
  ) async {
    try {
      // Remove existing vote for this poll (if any)
      final existingVote = await _supabaseClient
          .from('poll_votes')
          .select('id, poll_option_id')
          .eq('user_id', userId);

      if (existingVote.isNotEmpty) {
        for (final vote in existingVote) {
          // Check if this vote is for the same poll
          final voteOptionId = vote['poll_option_id'] as String;
          final optionPoll = await _supabaseClient
              .from('poll_options')
              .select('poll_id')
              .eq('id', voteOptionId)
              .single();

          if (optionPoll['poll_id'] == pollId) {
            // Delete existing vote for this poll
            await _supabaseClient
                .from('poll_votes')
                .delete()
                .eq('id', vote['id']);

            // Decrement old option vote count
            await _supabaseClient.rpc('decrement_poll_vote_count', params: {
              'option_id': voteOptionId,
            });
          }
        }
      }

      // Insert new vote
      await _supabaseClient.from('poll_votes').insert({
        'poll_option_id': optionId,
        'user_id': userId,
      });

      // Increment vote count using RPC
      await _supabaseClient.rpc('increment_poll_vote_count', params: {
        'option_id': optionId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to vote on poll: ${e.message}');
    } catch (e) {
      throw Exception('Failed to vote on poll: $e');
    }
  }

  /// Pick final option (host only) - marks poll as decided
  /// This is a placeholder - actual implementation depends on business logic
  Future<void> pickFinalOption(String pollId, String optionId) async {
    try {
      // For now, just verify the option exists
      await _supabaseClient
          .from('poll_options')
          .select('id')
          .eq('id', optionId)
          .eq('poll_id', pollId)
          .single();

      // TODO: Add logic to mark poll as "decided" (needs schema update)
      // Could add a `picked_option_id` field to polls table
    } on PostgrestException catch (e) {
      throw Exception('Failed to pick final option: ${e.message}');
    } catch (e) {
      throw Exception('Failed to pick final option: $e');
    }
  }
}
