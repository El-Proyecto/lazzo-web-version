import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_event_model.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../../../services/storage_service.dart';

/// Remote data source for calendar events
/// Queries home_events_view and enriches with cover photo data
class CalendarRemoteDataSource {
  static const String _eventsView = 'home_events_view';
  static const String _columns =
      'event_id, event_name, emoji, start_datetime, end_datetime, location_name, event_status';

  final SupabaseClient client;
  final StorageService _storageService;

  CalendarRemoteDataSource(this.client)
      : _storageService = StorageService(client);

  /// Fetch events for a specific month
  /// Includes events whose start OR end date falls within the month
  Future<List<CalendarEventEntity>> fetchEventsForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final startOfMonth = DateTime.utc(year, month, 1);
    final endOfMonth = DateTime.utc(year, month + 1, 0, 23, 59, 59);

    try {
      final response = await client
          .from(_eventsView)
          .select(_columns)
          .eq('user_id', userId)
          .lte('start_datetime', endOfMonth.toIso8601String())
          .or('end_datetime.gte.${startOfMonth.toIso8601String()},end_datetime.is.null,start_datetime.gte.${startOfMonth.toIso8601String()}');

      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();

      // Deduplicate by event_id (view can return multiple rows per event)
      final Map<String, Map<String, dynamic>> uniqueEvents = {};
      for (final row in data) {
        final eventId = row['event_id'] as String;
        uniqueEvents.putIfAbsent(eventId, () => row);
      }

      // Also include past events with cover photos (memories) not in view
      final pastModels = await _fetchPastMemoryEvents(
        userId,
        startOfMonth,
        endOfMonth,
        uniqueEvents.keys.toList(),
      );
      for (final m in pastModels) {
        uniqueEvents.putIfAbsent(m.id, () => {});
      }

      // Merge: view models + past memory models (deduped)
      final viewModels = uniqueEvents.keys
          .map((id) {
            final raw = uniqueEvents[id]!;
            return raw.isNotEmpty ? CalendarEventModel.fromMap(raw) : null;
          })
          .whereType<CalendarEventModel>()
          .toList();

      final allModels = [...viewModels];
      for (final pm in pastModels) {
        if (!allModels.any((m) => m.id == pm.id)) {
          allModels.add(pm);
        }
      }

      // Batch fetch cover photos
      return await _enrichWithCoverPhotos(
        allModels,
        allModels.map((m) => m.id).toList(),
      );
    } catch (e) {
      return [];
    }
  }

  /// Fetch all upcoming events for the user
  Future<List<CalendarEventEntity>> fetchAllUpcomingEvents(
      String userId) async {
    try {
      final response = await client
          .from(_eventsView)
          .select(_columns)
          .eq('user_id', userId)
          .order('start_datetime', ascending: true)
          .limit(100);

      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();

      // Deduplicate by event_id
      final Map<String, Map<String, dynamic>> uniqueEvents = {};
      for (final row in data) {
        final eventId = row['event_id'] as String;
        uniqueEvents.putIfAbsent(eventId, () => row);
      }

      final models =
          uniqueEvents.values.map(CalendarEventModel.fromMap).toList();

      return await _enrichWithCoverPhotos(models, uniqueEvents.keys.toList());
    } catch (e) {
      return [];
    }
  }

  /// Fetch past events with cover photos (memories) that have fallen outside the
  /// 24-h window of home_events_view. Queries the events table directly via
  /// participant membership.
  Future<List<CalendarEventModel>> _fetchPastMemoryEvents(
    String userId,
    DateTime startOfMonth,
    DateTime endOfMonth,
    List<String> alreadyFetchedIds,
  ) async {
    try {
      // Step 1: get all event IDs user participates in
      final partRes = await client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', userId)
          .limit(500);

      final allIds = (partRes as List<dynamic>)
          .map((r) => r['pevent_id'] as String)
          .toList();

      if (allIds.isEmpty) return [];

      // Step 2: query past events in month with cover_photo_id set,
      //         excluding ids already returned by the view
      final filterIds =
          allIds.where((id) => !alreadyFetchedIds.contains(id)).toList();
      if (filterIds.isEmpty) return [];

      final evtRes = await client
          .from('events')
          .select(
              'id, name, emoji, start_datetime, end_datetime, status, cover_photo_id, locations(display_name)')
          .inFilter('id', filterIds)
          .gte('start_datetime', startOfMonth.toIso8601String())
          .lte('start_datetime', endOfMonth.toIso8601String())
          .not('cover_photo_id', 'is', null);

      final rows = (evtRes as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(CalendarEventModel.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  /// Enrich events with cover photo signed URLs
  Future<List<CalendarEventEntity>> _enrichWithCoverPhotos(
    List<CalendarEventModel> models,
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return models.map((m) => m.toEntity()).toList();

    // Fetch cover photo storage paths for these events
    Map<String, String> coverPhotoUrls = {};
    try {
      final coverResponse = await client
          .from('events')
          .select('id, cover_photo_id')
          .inFilter('id', eventIds)
          .not('cover_photo_id', 'is', null);

      final coverData =
          (coverResponse as List<dynamic>).cast<Map<String, dynamic>>();

      if (coverData.isNotEmpty) {
        final photoIds =
            coverData.map((e) => e['cover_photo_id'] as String).toList();

        final photosResponse = await client
            .from('event_photos')
            .select('id, storage_path')
            .inFilter('id', photoIds);

        final photosData =
            (photosResponse as List<dynamic>).cast<Map<String, dynamic>>();

        // Map photoId -> storagePath
        final Map<String, String> photoPathMap = {};
        for (final photo in photosData) {
          photoPathMap[photo['id'] as String] = photo['storage_path'] as String;
        }

        // Map eventId -> storagePath
        final Map<String, String> eventCoverPaths = {};
        for (final cover in coverData) {
          final photoId = cover['cover_photo_id'] as String;
          final path = photoPathMap[photoId];
          if (path != null) {
            eventCoverPaths[cover['id'] as String] = path;
          }
        }

        // Generate signed URLs in parallel
        final futures = eventCoverPaths.entries.map((entry) async {
          try {
            final url = await _storageService.getSignedUrl(entry.value);
            return MapEntry(entry.key, url);
          } catch (_) {
            return null;
          }
        });

        final results = await Future.wait(futures);
        for (final result in results) {
          if (result != null) {
            coverPhotoUrls[result.key] = result.value;
          }
        }
      }
    } catch (_) {
      // Best-effort cover photo enrichment
    }

    // Convert models to entities with cover photo URLs
    return models.map((m) {
      final coverUrl = coverPhotoUrls[m.id];
      return m.toEntity(coverPhotoUrl: coverUrl);
    }).toList();
  }
}
