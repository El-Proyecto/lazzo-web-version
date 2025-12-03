import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for problem reports
class ReportRemoteDataSource {
  final SupabaseClient _client;

  ReportRemoteDataSource(this._client);

  /// Submit a new problem report to Supabase
  Future<Map<String, dynamic>> submitReport({
    required String category,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    print(
        '📝 [ReportDataSource] Submitting report: category=$category, user=$userId');

    try {
      final response = await _client
          .from('problem_reports')
          .insert({
            'user_id': userId,
            'category': category,
            'description': description,
            'status': 'pending',
          })
          .select(
              'id, user_id, category, description, status, created_at, updated_at')
          .single();

      print('✅ [ReportDataSource] Report submitted: id=${response['id']}');
      return response;
    } catch (e) {
      print('❌ [ReportDataSource] Failed to submit report: $e');
      rethrow;
    }
  }
}
