import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_event_model.dart';
import '../../domain/entities/home_event.dart';

/// Remote data source for home events
/// Fetches events from Supabase and maps to entities
class HomeEventRemoteDataSource {
  static const String _eventsView = 'home_events_view';
  
  final SupabaseClient client;
  
  HomeEventRemoteDataSource(this.client);

  /// Fetch next event (highest priority event user is attending)
  /// Priority: living > recap > confirmed (nearest date) > pending (nearest date)
  Future<HomeEventEntity?> fetchNextEvent(String userId) async {
    try {
      print('🔍 Fetching next event for userId: $userId');

      final response = await client
          .from(_eventsView)
          .select('''
            event_id, event_name, emoji,
            start_datetime, end_datetime,
            location_name, event_status,
            user_rsvp, voted_at,
            going_count, going_users,
            not_going_users, no_response_users,
            participants_total, voters_total
          ''')
          .eq('user_id', userId) // ✅ Filtrar por user_id
          .order('start_datetime', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('ℹ️ No next event found for user $userId');
        return null;
      }

      print('✅ Next event fetched: ${response['event_name']}');
      return homeEventFromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching next event: $e');
      return null;
    }
  }

  /// Fetch confirmed events (user voted yes, not next event)
  Future<List<HomeEventEntity>> fetchConfirmedEvents(String userId) async {
    try {
      print('🔍 Fetching confirmed events for userId: $userId');

      final response = await client
          .from(_eventsView)
          .select('''
            event_id, event_name, emoji,
            start_datetime, end_datetime,
            location_name, event_status,
            user_rsvp, voted_at,
            going_count, going_users,
            not_going_users, no_response_users,
            participants_total, voters_total
          ''')
          .eq('user_id', userId)
          .eq('event_status', 'confirmed') // ✅ Apenas eventos confirmados
          .order('start_datetime', ascending: true)
          .limit(10);

      final data = response as List<dynamic>;
      
      print('✅ Fetched ${data.length} confirmed events');
      
      return data
          .map((e) => homeEventFromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching confirmed events: $e');
      return [];
    }
  }

  /// Fetch pending events (awaiting user vote or date confirmation)
  Future<List<HomeEventEntity>> fetchPendingEvents(String userId) async {
    try {
      print('🔍 Fetching pending events for userId: $userId');

      final response = await client
          .from(_eventsView)
          .select('''
            event_id, event_name, emoji,
            start_datetime, end_datetime,
            location_name, event_status,
            user_rsvp, voted_at,
            going_count, going_users,
            not_going_users, no_response_users,
            participants_total, voters_total
          ''')
          .eq('user_id', userId)
          .eq('event_status', 'pending') // ✅ Apenas eventos pendentes
          .order('start_datetime', ascending: true)
          .limit(10);

      final data = response as List<dynamic>;
      
      print('✅ Fetched ${data.length} pending events');
      
      return data
          .map((e) => homeEventFromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching pending events: $e');
      return [];
    }
  }

  /// Vote on event RSVP
  Future<bool> voteOnEvent(String eventId, String userId, bool isGoing) async {
    try {
      print('🗳️ Voting on event: eventId=$eventId, userId=$userId, isGoing=$isGoing');

      await client.from('event_participants').upsert(
        {
          'pevent_id': eventId, // ✅ Corrigido: pevent_id (não event_id)
          'user_id': userId,
          'rsvp': isGoing ? 'going' : 'not_going', // ✅ Usar valores corretos da enum
          'confirmed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'pevent_id,user_id', // ✅ Corrigido: pevent_id
      );

      print('✅ Vote successful');
      return true;
    } catch (e) {
      print('❌ Vote error: $e');
      return false;
    }
  }
}