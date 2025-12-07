import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for user suggestions
class SuggestionRemoteDataSource {
  final SupabaseClient _client;

  SuggestionRemoteDataSource(this._client);

  /// Submit a new suggestion to Supabase
  Future<Map<String, dynamic>> submitSuggestion({
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    
    try {
      final response = await _client
          .from('user_suggestions')
          .insert({
            'user_id': userId,
            'description': description,
            'status': 'pending',
          })
          .select('id, user_id, description, status, created_at, updated_at')
          .single();

            return response;
    } catch (e) {
            rethrow;
    }
  }
}
