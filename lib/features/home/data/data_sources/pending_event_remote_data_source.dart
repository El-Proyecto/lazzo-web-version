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
    final rows = await client.from(_view).select('''
      event_id, event_name, emoji,
      start_datetime, end_datetime,
      location_id, location_name,
      group_id,
      organizer_id,
      event_status,
      participant_role, vote_status,
      participants_total, voters_total,
      no_response_count, going_count, interested_count, not_going_count,
      voters, no_response_voters
      ''')
      .eq('user_id', userId)
      .order('start_datetime', ascending: true);

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
        {
          'pevent_id': eventId,               // ⚠️ FK no teu schema
          'user_id': userId,
          'rsvp': isYes ? 'yes' : 'no',
        },
        onConflict: 'pevent_id,user_id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
