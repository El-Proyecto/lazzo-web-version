//chama Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory_summary_model.dart';

class MemoryRemoteDataSource {
  final SupabaseClient client;
  MemoryRemoteDataSource(this.client);

  Future<MemorySummaryModel?> fetchLastReady(String userId) async {
    try {
      final r = await client
          .from('events')
          .select('id, name, emoji, created_at')
          .eq('status', 'ended')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return r == null ? null : MemorySummaryModel.fromMap(r);
    } catch (e) {
      rethrow;
    }
  }
}
