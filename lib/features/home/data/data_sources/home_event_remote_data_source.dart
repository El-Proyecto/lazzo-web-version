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
  /// Priority: living (4) > recap (3) > confirmed (2) > pending (1)
  Future<HomeEventEntity?> fetchNextEvent(String userId) async {
    try {
      print('🔍 Fetching next event for userId: $userId');

      // ✅ Fetch multiple events and choose highest priority on frontend
      // This allows proper priority calculation: living > recap > confirmed
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
          .order('start_datetime', ascending: true)
          .limit(10); // Fetch top 10 to find highest priority

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        print('ℹ️ No events found for user $userId');
        return null;
      }

      // ✅ Convert all events and find highest priority
      final events =
          data.map((e) => homeEventFromMap(e as Map<String, dynamic>)).toList();

      // Priority order: living (4) > recap (3) > confirmed (2) > pending (1)
      final priorityMap = {
        HomeEventStatus.living: 4,
        HomeEventStatus.recap: 3,
        HomeEventStatus.confirmed: 2,
        HomeEventStatus.pending: 1,
      };

      events.sort((a, b) {
        final aPriority = priorityMap[a.status] ?? 0;
        final bPriority = priorityMap[b.status] ?? 0;
        return bPriority.compareTo(aPriority); // Descending (highest first)
      });

      final nextEvent = events.first;
      print(
          '✅ Next event selected: ${nextEvent.name} (status: ${nextEvent.status})');
      return nextEvent;
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
          .eq('event_status', 'confirmed') // ✅ Only confirmed events
          // ✅ Filtrar por start_datetime futura (confirmed = não começou ainda)
          .gte('start_datetime', DateTime.now().toIso8601String())
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
          .eq('event_status', 'pending') // ✅ Backend status (pending/confirmed)
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
      print(
          '🗳️ Voting on event: eventId=$eventId, userId=$userId, isGoing=$isGoing');

      await client.from('event_participants').upsert(
        {
          'pevent_id': eventId,
          'user_id': userId,
          'rsvp': isGoing ? 'going' : 'not_going',
          'confirmed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'pevent_id,user_id',
      );

      print('✅ Vote successful');
      return true;
    } catch (e) {
      print('❌ Vote error: $e');
      return false;
    }
  }
}
