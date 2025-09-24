// data/data_sources/pending_event_remote_data_source.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pending_event_model.dart';

class PendingEventRemoteDataSource {
  static const String _view = 'pending_events_by_user_view';
  static const String _participantsTable = 'event_participants';

  final SupabaseClient client;
  PendingEventRemoteDataSource(this.client);

  /// Buscar todos os eventos pendentes de um utilizador
  Future<List<PendingEventModel>> fetchPending(String userId) async {
    final rows = await client
        .from(_view)
        .select('''
          event_id,
          title,
          emoji,
          start_time,
          location_name,
          vote_status,
          total_voters,
          voters,
          no_response_voters,
          no_response_count
        ''')
        .eq('user_id', userId)
        .order('start_time', ascending: true);

    final data = rows as List<dynamic>;
    return data.map((e) => PendingEventModel.fromMap(e)).toList();
  }

  /// Registar (ou atualizar) o RSVP do utilizador num evento
  ///
  /// isYes=true  => rsvp = 'yes'
  /// isYes=false => rsvp = 'no'
  Future<bool> vote(String eventId, String userId, bool isYes) async {
    try {
      await client.from(_participantsTable).upsert(
        {'event_id': eventId, 'user_id': userId, 'rsvp': isYes ? 'yes' : 'no'},
        // garante que atualiza a linha deste (event_id,user_id) se já existir
        onConflict: 'event_id,user_id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
