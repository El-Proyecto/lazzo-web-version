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
          .eq('user_rsvp', 'yes') // Only show events where user voted "yes"
          .order('start_datetime', ascending: true)
          .limit(10); // Fetch top 10 to find highest priority

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        return null;
      }

      // ✅ Convert all events and find highest priority
      // Pass callback to persist status changes
      final eventsFutures = data.map((e) => homeEventFromMap(
            e as Map<String, dynamic>,
            onStatusMismatch: (eventId, newStatus) {
              // Persist status change asynchronously (fire and forget)
              updateEventStatus(eventId, newStatus).catchError((error) {
                return false;
              });
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

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
      return nextEvent;
    } catch (e) {
      return null;
    }
  }

  /// Fetch confirmed events (user voted yes, not next event)
  Future<List<HomeEventEntity>> fetchConfirmedEvents(String userId) async {
    try {
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
          .eq('user_rsvp', 'yes') // Only show events where user voted "yes"
          .limit(20); // Increased to get both dated and null dated events

      final data = response as List<dynamic>;

      final eventsFutures = data.map((e) => homeEventFromMap(
            e as Map<String, dynamic>,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus).catchError((error) {
                return false;
              });
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

      // Filter out past events (keep future and null dates)
      final now = DateTime.now();
      final filteredEvents = events.where((event) {
        if (event.date == null) {
          return true; // Keep events without date
        }
        final isFuture = event.date!.isAfter(now);
        return isFuture; // Keep future events
      }).toList();

      // Sort: future dates first (ascending), null dates last
      filteredEvents.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a
        return a.date!.compareTo(b.date!); // Normal date comparison
      });

      return filteredEvents.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch pending events (awaiting user vote or date confirmation)
  Future<List<HomeEventEntity>> fetchPendingEvents(String userId) async {
    try {
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

      // Convert to entities with status persistence
      final eventsFutures = data.map((e) => homeEventFromMap(
            e as Map<String, dynamic>,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus).catchError((error) {
                return false;
              });
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

      // Sort: future dates first (ascending), null dates last
      events.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a
        return a.date!.compareTo(b.date!); // Normal date comparison
      });

      return events.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Vote on event RSVP
  Future<bool> voteOnEvent(String eventId, String userId, bool isGoing) async {
    try {
      await client.from('event_participants').upsert(
        {
          'pevent_id': eventId,
          'user_id': userId,
          'rsvp': isGoing ? 'going' : 'not_going',
          'confirmed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'pevent_id,user_id',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update event status in Supabase
  /// Called when calculated status differs from DB status
  Future<bool> updateEventStatus(String eventId, String newStatus) async {
    try {
      await client
          .from('events')
          .update({'status': newStatus}).eq('id', eventId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all living and recap events sorted by time remaining (soonest to end first)
  Future<List<HomeEventEntity>> fetchLivingAndRecapEvents(String userId) async {
    try {
      // Fetch events with status 'living' or 'recap'
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
            participants_total, voters_total,
            photo_count, max_photos
          ''')
          .eq('user_id', userId)
          .inFilter('event_status', ['living', 'recap'])
          .eq('user_rsvp', 'yes') // Only show events where user voted "yes"
          .not('end_datetime', 'is', null) // Only events with end_datetime
          .order('end_datetime', ascending: true)
          .limit(20);

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        return [];
      }

      // Convert to entities with status persistence
      final eventsFutures = data.map((e) => homeEventFromMap(
            e as Map<String, dynamic>,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus).catchError((error) {
                return false;
              });
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

      // Sort by end_datetime (soonest to end first)
      events.sort((a, b) {
        if (a.endDate == null && b.endDate == null) return 0;
        if (a.endDate == null) return 1;
        if (b.endDate == null) return -1;
        return a.endDate!.compareTo(b.endDate!);
      });

      return events;
    } catch (e) {
      return [];
    }
  }
}
