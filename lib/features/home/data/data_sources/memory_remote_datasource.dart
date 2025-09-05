//chama Supabase
//FIXME: Rever

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory_summary_model.dart';

class MemoryRemoteDataSource {
  final SupabaseClient client;
  MemoryRemoteDataSource(this.client);

  Future<MemorySummaryModel?> fetchLastReady(String userId) async {
    final r = await client
      .from('memories')
      .select('id,title,emoji,created_at')
      .eq('owner_id', userId)         // ou membership/group logic conforme o teu esquema
      .eq('status', 'ready')
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();                 // null se não houver

    if (r == null) return null;
    return MemorySummaryModel.fromMap(r);
  }
}
