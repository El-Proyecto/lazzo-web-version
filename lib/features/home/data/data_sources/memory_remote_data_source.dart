//chama Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory_summary_model.dart';

class MemoryRemoteDataSource {
  final SupabaseClient client;
  MemoryRemoteDataSource(this.client);

  Future<MemorySummaryModel?> fetchLastReady(String userId) async {
    try {
      print('fetchLastReadybefore: $userId');
      
      final r = await client
          .from('events')
          .select('event_id, title, emoji, created_at')
          .eq('suggested_by', userId)
          .eq('state', 'ended')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      print('fetchLastReady response: $r');
      return r == null ? null : MemorySummaryModel.fromMap(r);
    } catch (e, st) {
      print('Error in fetchLastReady: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}
