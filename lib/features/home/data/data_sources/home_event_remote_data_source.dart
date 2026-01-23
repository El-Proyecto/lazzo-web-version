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

  /// Reset votes for expired events using Supabase RPC
  /// RPC checks if event is expired and resets votes if needed
  Future<void> _resetExpiredPendingVotes(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    
    try {
      // Call RPC for each event (RPC handles expired check internally)
      await Future.wait(
        eventIds.map((id) => client.rpc(
          'reset_event_votes_if_expired',
          params: {'p_event_id': id},
        )),
      );
    } catch (e) {
      // Best-effort cleanup - don't throw
    }
  }

  /// Fetch next event (highest priority event user is attending)
  /// Priority: living (4) > recap (3) > confirmed (2) > pending (1)
  Future<HomeEventEntity?> fetchNextEvent(String userId) async {
    try {
      // ✅ Fetch multiple events and choose highest priority on frontend
      // Order by priority (DESC) first, then by date (ASC)
      // This ensures living/recap/confirmed events come before pending
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
            priority
          ''')
          .eq('user_id', userId)
          .neq('user_rsvp',
              'no') // Exclude events where user voted "Can't" - same logic as fetchConfirmedEvents
          .order('priority',
              ascending:
                  false) // ✅ Priority first: living(4) > recap(3) > confirmed(2) > pending(1)
          .order('start_datetime',
              ascending: true) // Then by date (soonest first)
          .limit(10); // Fetch top 10 highest priority events

      final data = response as List<dynamic>;

      // Debug: Show first 3 events to see what's being returned
      if (data.isNotEmpty) {
        for (var i = 0; i < data.length && i < 3; i++) {
          final e = data[i] as Map<String, dynamic>;
        }
      }

      if (data.isEmpty) {
        return null;
      }

      // Count events by status from raw data
      final rawData = data.cast<Map<String, dynamic>>();
      final statusCount = <String, int>{};
      for (var raw in rawData) {
        final status = raw['event_status'] as String?;
        statusCount[status ?? 'null'] =
            (statusCount[status ?? 'null'] ?? 0) + 1;
      }

      if (statusCount['confirmed'] == 0) {}

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
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

      // Count confirmed events after conversion
      final confirmedCount =
          events.where((e) => e.status == HomeEventStatus.confirmed).length;
      if (confirmedCount > 0) {
        for (var e
            in events.where((e) => e.status == HomeEventStatus.confirmed)) {}
      }

      // ✅ Filter out expired pending events (should only appear in Pending Events section)
      final now = DateTime.now().toUtc();
      final nonExpiredEvents = events.where((event) {
        // Keep confirmed/living/recap events always
        if (event.status != HomeEventStatus.pending) return true;

        // For pending events: exclude if date is in the past (expired)
        if (event.date == null) return true;
        return event.date!.toUtc().isAfter(now);
      }).toList();

      final confirmedAfterFilter = nonExpiredEvents
          .where((e) => e.status == HomeEventStatus.confirmed)
          .length;

      if (confirmedCount > 0 && confirmedAfterFilter == 0) {}

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

        // First sort by priority (highest first)
        final priorityComparison = bPriority.compareTo(aPriority);
        if (priorityComparison != 0) return priorityComparison;

        // If same priority, sort by date (soonest first)
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // Events without date go last
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!); // Ascending (soonest first)
      });

      final nextEvent = nonExpiredEvents.first;

      if (nextEvent.status != HomeEventStatus.confirmed &&
          confirmedAfterFilter > 0) {}

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
      if (data.isNotEmpty) {
        for (int i = 0; i < data.length && i < 3; i++) {
          final row = data[i] as Map<String, dynamic>;
        }
      }

      // ✅ OPTIMIZATION: Batch convert avatar paths to signed URLs BEFORE entity creation
      final rawData = data.cast<Map<String, dynamic>>();
      await _batchConvertAvatarUrls(rawData);
      // Identify expired events (pending + date passed)
      final now = DateTime.now();
      final expiredEventIds = <String>[];
      
      for (final event in data) {
        final startDateStr = event['start_datetime'] as String?;
        if (startDateStr != null) {
          final startDate = DateTime.parse(startDateStr);
          if (startDate.isBefore(now)) {
            expiredEventIds.add(event['event_id'] as String);
          }
        }
      }
      
      // Reset votes for expired events (fire-and-forget)
      if (expiredEventIds.isNotEmpty) {
        _resetExpiredPendingVotes(expiredEventIds);
      }

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

      // Check for expired events
      final now = DateTime.now();
      final expiredEvents =
          events.where((e) => e.date != null && e.date!.isBefore(now)).toList();
      if (expiredEvents.isNotEmpty) {}

      // ✅ DO NOT filter out past events - show expired pending events with "Event date expired!" label
      // Sort: future dates first (ascending), past dates last, null dates at the end
      events.sort((a, b) {
        final aIsPast = a.date != null && a.date!.isBefore(now);
        final bIsPast = b.date != null && b.date!.isBefore(now);

        // Both null dates go to the end
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // a (null) goes after b
        if (b.date == null) return -1; // b (null) goes after a

        // Future events before past events
        if (!aIsPast && bIsPast) return -1;
        if (aIsPast && !bIsPast) return 1;

        // Within same category, sort by date
        return a.date!.compareTo(b.date!);
      });

      // ✅ Return ALL events - home.dart will handle the .take(10) and "See All" logic
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
