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
            group_id, group_name,
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
      // Pass callback to persist status changes
      final events = data.map((e) => homeEventFromMap(
        e as Map<String, dynamic>,
        onStatusMismatch: (eventId, newStatus) {
          // Persist status change asynchronously (fire and forget)
          updateEventStatus(eventId, newStatus).catchError((error) {
            print('❌ Failed to persist status for event $eventId: $error');
            return false;
          });
        },
      )).toList();

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
      print(
          '   📍 Group: ${nextEvent.groupName ?? 'No group'} (ID: ${nextEvent.groupId ?? 'null'})');
      print('   📍 Location: ${nextEvent.location ?? 'No location'}');
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
            group_id, group_name,
            start_datetime, end_datetime,
            location_name, event_status,
            user_rsvp, voted_at,
            going_count, going_users,
            not_going_users, no_response_users,
            participants_total, voters_total
          ''')
          .eq('user_id', userId)
          .eq('event_status', 'confirmed') // ✅ Only confirmed events
          .limit(20); // Increased to get both dated and null dated events

      final data = response as List<dynamic>;
      print('📦 [CONFIRMED] Raw data from Supabase: ${data.length} events');

      // Debug each raw event
      for (var i = 0; i < data.length; i++) {
        final event = data[i] as Map<String, dynamic>;
        print(
            '   [$i] ${event['event_name']} | start_datetime: ${event['start_datetime']} | location: ${event['location_name']}');
      }

      // Convert to entities with status persistence
      print(
          '🔄 [CONFIRMED] Converting ${data.length} raw events to entities...');
      final events = data.map((e) => homeEventFromMap(
        e as Map<String, dynamic>,
        onStatusMismatch: (eventId, newStatus) {
          updateEventStatus(eventId, newStatus).catchError((error) {
            print('❌ Failed to persist status for event $eventId: $error');
            return false;
          });
        },
      )).toList();
      print('✅ [CONFIRMED] Converted to ${events.length} entities');

      // Debug entities before filtering
      for (var i = 0; i < events.length; i++) {
        print(
            '   Entity[$i]: ${events[i].name} | date: ${events[i].date} | status: ${events[i].status}');
      }

      // Filter out past events (keep future and null dates)
      final now = DateTime.now();
      print('⏰ [CONFIRMED] Current time: $now');
      final filteredEvents = events.where((event) {
        if (event.date == null) {
          print('   ✅ Keeping ${event.name} (null date)');
          return true; // Keep events without date
        }
        final isFuture = event.date!.isAfter(now);
        print(
            '   ${isFuture ? "✅" : "❌"} ${event.name} (date: ${event.date}, future: $isFuture)');
        return isFuture; // Keep future events
      }).toList();

      print('🔍 [CONFIRMED] After filtering: ${filteredEvents.length} events');

      // Sort: future dates first (ascending), null dates last
      filteredEvents.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a
        return a.date!.compareTo(b.date!); // Normal date comparison
      });

      print('📊 [CONFIRMED] After sorting:');
      for (var i = 0; i < filteredEvents.length; i++) {
        print(
            '   [$i] ${filteredEvents[i].name} | date: ${filteredEvents[i].date}');
      }

      print(
          '✅ [CONFIRMED] Final result: ${filteredEvents.length} events (taking max 10)');

      return filteredEvents.take(10).toList();
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
            group_id, group_name,
            start_datetime, end_datetime,
            location_name, event_status,
            user_rsvp, voted_at,
            going_count, going_users,
            not_going_users, no_response_users,
            participants_total, voters_total
          ''')
          .eq('user_id', userId)
          .eq('event_status', 'pending') // ✅ Backend status (pending/confirmed)
          .limit(20); // Increased to get both dated and null dated events

      final data = response as List<dynamic>;
      print('📦 [PENDING] Raw data from Supabase: ${data.length} events');

      // Debug each raw event
      for (var i = 0; i < data.length; i++) {
        final event = data[i] as Map<String, dynamic>;
        print(
            '   [$i] ${event['event_name']} | start_datetime: ${event['start_datetime']} | location: ${event['location_name']}');
      }

      // Convert to entities with status persistence
      print('🔄 [PENDING] Converting ${data.length} raw events to entities...');
      final events = data.map((e) => homeEventFromMap(
        e as Map<String, dynamic>,
        onStatusMismatch: (eventId, newStatus) {
          updateEventStatus(eventId, newStatus).catchError((error) {
            print('❌ Failed to persist status for event $eventId: $error');
            return false;
          });
        },
      )).toList();
      print('✅ [PENDING] Converted to ${events.length} entities');

      // Debug entities before sorting
      for (var i = 0; i < events.length; i++) {
        print(
            '   Entity[$i]: ${events[i].name} | date: ${events[i].date} | status: ${events[i].status}');
      }

      // Sort: future dates first (ascending), null dates last
      events.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a
        return a.date!.compareTo(b.date!); // Normal date comparison
      });

      print('📊 [PENDING] After sorting:');
      for (var i = 0; i < events.length; i++) {
        print('   [$i] ${events[i].name} | date: ${events[i].date}');
      }

      print(
          '✅ [PENDING] Final result: ${events.length} events (taking max 10)');

      return events.take(10).toList();
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

  /// Update event status in Supabase
  /// Called when calculated status differs from DB status
  Future<bool> updateEventStatus(String eventId, String newStatus) async {
    try {
      print('🔄 [STATUS UPDATE] Updating event $eventId to status: $newStatus');
      
      await client
          .from('events')
          .update({'status': newStatus})
          .eq('id', eventId);
      
      print('✅ [STATUS UPDATE] Event status updated successfully in DB');
      return true;
    } catch (e) {
      print('❌ [STATUS UPDATE] Error updating event status: $e');
      return false;
    }
  }
}
