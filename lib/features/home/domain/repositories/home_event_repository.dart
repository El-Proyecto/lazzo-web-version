import '../entities/home_event.dart';

/// Repository interface for home events
/// Provides methods to fetch next event, confirmed events, and pending events
abstract class HomeEventRepository {
  /// Get the next upcoming event (highest priority event)
  Future<HomeEventEntity?> getNextEvent();

  /// Get list of confirmed events (limited to 10 for home page)
  Future<List<HomeEventEntity>> getConfirmedEvents();

  /// Get list of pending events (limited to 10 for home page)
  Future<List<HomeEventEntity>> getPendingEvents();

  /// Get all living and recap events sorted by time remaining
  Future<List<HomeEventEntity>> getLivingAndRecapEvents();

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNT & PAGINATION METHODS (for "See All" functionality)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total count of confirmed events
  Future<int> getConfirmedEventsCount();

  /// Get total count of pending events
  Future<int> getPendingEventsCount();

  /// Get paginated confirmed events
  Future<List<HomeEventEntity>> getConfirmedEventsPaginated({
    required int limit,
    required int offset,
  });

  /// Get paginated pending events
  Future<List<HomeEventEntity>> getPendingEventsPaginated({
    required int limit,
    required int offset,
  });
}
