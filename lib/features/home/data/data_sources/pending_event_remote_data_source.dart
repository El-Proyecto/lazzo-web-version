// TODO P2: Remove this file - old pending events data source replaced by new home event structure
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pending_event_model.dart';
import '../../domain/entities/pending_event.dart';

class PendingEventRemoteDataSource {
  static const String _view = 'pending_events_by_user_view';
  static const String _participantsTable = 'event_participants';

  final SupabaseClient client;
  PendingEventRemoteDataSource(this.client);

  Future<List<PendingEvent>> fetchPending(String userId) async {
    final rows = await client.from(_view).select('''
          user_id, participant_role, vote_status,
          event_id, event_name, emoji,
          start_datetime, end_datetime,
          location_id, location_name,
          group_id, organizer_id, event_status,
          participants_total, voters_total,
          no_response_count, going_count, not_going_count,
          going_users, not_going_users, no_response_users,
          voters, no_response_voters
        ''').eq('user_id', userId).order('start_datetime', ascending: true);

    final data = rows as List<dynamic>;
    return data
        .map((e) => pendingEventFromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> vote(String eventId, String userId, bool isYes) async {
    if (eventId.isEmpty || userId.isEmpty) {
      print('❌ Vote failed: empty eventId or userId');
      return false;
    }

    try {
      print('🗳️ Voting: eventId=$eventId, userId=$userId, isYes=$isYes');

      await client.from(_participantsTable).upsert(
        {
          'pevent_id': eventId,
          'user_id': userId,
          'rsvp': isYes ? 'yes' : 'no',
          'confirmed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'pevent_id,user_id',
      );

      print('✅ Vote successful');
      return true;
    } catch (e, stackTrace) {
      // ✅ MELHORADO: Log detalhado do erro
      print('❌ Vote error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
