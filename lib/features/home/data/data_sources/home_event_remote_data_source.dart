import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_event_model.dart';
import '../../domain/entities/home_event.dart';
import '../../../../services/avatar_cache_service.dart';

/// Remote data source for home events
/// Fetches events from Supabase and maps to entities
class HomeEventRemoteDataSource {
  static const String _eventsView = 'home_events_view';

  final SupabaseClient client;
  final AvatarCacheService _avatarCache = AvatarCacheService();

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

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      // ✅ Convert all events and find highest priority
      // Pass callback to persist status changes
      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
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

      // ✅ Filter out expired pending events (should only appear in Pending Events section)
      final now = DateTime.now();
      final nonExpiredEvents = events.where((event) {
        // Keep confirmed/living/recap events always
        if (event.status != HomeEventStatus.pending) return true;

        // For pending events: exclude if date is in the past (expired)
        if (event.date == null) return true; // Keep pending without date
        return event.date!.isAfter(now); // Only keep future pending events
      }).toList();

      if (nonExpiredEvents.isEmpty) {
        return null;
      }

      // Priority order: living (4) > recap (3) > confirmed (2) > pending (1)
      final priorityMap = {
        HomeEventStatus.living: 4,
        HomeEventStatus.recap: 3,
        HomeEventStatus.confirmed: 2,
        HomeEventStatus.pending: 1,
      };

      nonExpiredEvents.sort((a, b) {
        final aPriority = priorityMap[a.status] ?? 0;
        final bPriority = priorityMap[b.status] ?? 0;
        return bPriority.compareTo(aPriority); // Descending (highest first)
      });

      final nextEvent = nonExpiredEvents.first;
      return nextEvent;
    } catch (e) {
      return null;
    }
  }

  /// Fetch confirmed events (user voted yes OR hasn't voted yet, not next event)
  /// Excludes events where user voted "Can't" (no)
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
          .neq('user_rsvp', 'no') // ✅ Exclude events where user voted "Can't"
          .limit(50); // Increased limit to show all events

      final data = response as List<dynamic>;

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
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

      // ✅ Return ALL events - home.dart will handle the .take(10) and "See All" logic
      return filteredEvents;
    } catch (e) {
      return [];
    }
  }

  /// Fetch pending events (awaiting user vote or date confirmation)
  /// Shows ALL pending events regardless of user vote status
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
          // ❌ No RSVP filter - show ALL pending events regardless of user vote
          .limit(50); // Increased limit to show all events

      final data = response as List<dynamic>;

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      // Convert to entities with status persistence
      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus).catchError((error) {
                return false;
              });
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

      // Sort: future dates first (ascending), expired dates last, null dates at end
      final now = DateTime.now();
      events.sort((a, b) {
        // Handle null dates - put at the end
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a

        // Check if events are expired
        final aExpired = a.date!.isBefore(now);
        final bExpired = b.date!.isBefore(now);

        // Future events come before expired events
        if (!aExpired && bExpired) return -1; // a (future) before b (expired)
        if (aExpired && !bExpired) return 1; // a (expired) after b (future)

        // Both future or both expired - sort by date ascending
        return a.date!.compareTo(b.date!);
      });

      // ✅ Return ALL events including expired - UI will handle display
      return events;
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
          'rsvp': isGoing ? 'yes' : 'no',
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
            participants_total, voters_total
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

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      // Convert to entities with status persistence
      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNT METHODS (for "See All" button visibility)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total count of confirmed events for user
  /// Excludes events where user voted "Can't" (no)
  Future<int> getConfirmedEventsCount(String userId) async {
    try {
      final response = await client
          .from(_eventsView)
          .select('event_id')
          .eq('user_id', userId)
          .eq('event_status', 'confirmed')
          .neq('user_rsvp', 'no'); // ✅ Exclude events where user voted "Can't"

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total count of pending events for user
  /// Shows ALL pending events regardless of user vote status
  Future<int> getPendingEventsCount(String userId) async {
    try {
      final response = await client
          .from(_eventsView)
          .select('event_id')
          .eq('user_id', userId)
          .eq('event_status', 'pending');
      // ❌ No RSVP filter - count ALL pending events

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGINATED METHODS (for "See All" page with infinite scroll)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch confirmed events with pagination
  /// Excludes events where user voted "Can't" (no)
  Future<List<HomeEventEntity>> fetchConfirmedEventsPaginated(
    String userId, {
    required int limit,
    required int offset,
  }) async {
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
          .eq('event_status', 'confirmed')
          .neq('user_rsvp', 'no') // ✅ Exclude events where user voted "Can't"
          .order('start_datetime', ascending: true)
          .range(offset, offset + limit - 1);

      final data = response as List<dynamic>;
      if (data.isEmpty) return [];

      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus)
                  .catchError((error) => false);
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      final events = await Future.wait(eventsFutures);

      // Filter out past events
      final now = DateTime.now();
      return events.where((event) {
        if (event.date == null) return true;
        return event.date!.isAfter(now);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch pending events with pagination
  /// Shows ALL pending events regardless of user vote status
  Future<List<HomeEventEntity>> fetchPendingEventsPaginated(
    String userId, {
    required int limit,
    required int offset,
  }) async {
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
          .eq('event_status', 'pending')
          // ❌ No RSVP filter - show ALL pending events
          .order('start_datetime', ascending: true)
          .range(offset, offset + limit - 1);

      final data = response as List<dynamic>;
      if (data.isEmpty) return [];

      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);

      final eventsFutures = rawData.map((e) => homeEventFromMap(
            e,
            onStatusMismatch: (eventId, newStatus) {
              updateEventStatus(eventId, newStatus)
                  .catchError((error) => false);
            },
            currentUserId: userId,
            supabaseClient: client,
          ));

      return await Future.wait(eventsFutures);
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR BATCH PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Batch process avatar URLs for all events
  /// Collects all unique avatar paths and fetches them in parallel
  /// Much more efficient than fetching one by one
  Future<void> _batchConvertAvatarUrls(
      List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;

    // 1. Collect all unique avatar paths from all events
    final allPaths = <String>{};

    for (final event in events) {
      _collectAvatarPaths(event, 'going_users', allPaths);
      _collectAvatarPaths(event, 'not_going_users', allPaths);
      _collectAvatarPaths(event, 'no_response_users', allPaths);
    }

    if (allPaths.isEmpty) return;

    // 2. Batch fetch all URLs in parallel (from cache or storage)
    final urlMap = await _avatarCache.batchGetAvatarUrls(
      client,
      allPaths.toList(),
    );

    // 3. Apply fetched URLs back to all events
    for (final event in events) {
      _applyAvatarUrls(event, 'going_users', urlMap);
      _applyAvatarUrls(event, 'not_going_users', urlMap);
      _applyAvatarUrls(event, 'no_response_users', urlMap);
    }
  }

  /// Collect avatar paths from a user array into the set
  void _collectAvatarPaths(
    Map<String, dynamic> event,
    String arrayKey,
    Set<String> paths,
  ) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic>) {
        final avatarUrl = user['avatar_url'];
        if (avatarUrl != null && avatarUrl is String && avatarUrl.isNotEmpty) {
          paths.add(avatarUrl);
        }
      }
    }
  }

  /// Apply fetched avatar URLs to a user array
  void _applyAvatarUrls(
    Map<String, dynamic> event,
    String arrayKey,
    Map<String, String> urlMap,
  ) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic>) {
        final avatarUrl = user['avatar_url'];
        if (avatarUrl != null && avatarUrl is String) {
          user['avatar_url'] = urlMap[avatarUrl] ?? '';
        }
      }
    }
  }
}
