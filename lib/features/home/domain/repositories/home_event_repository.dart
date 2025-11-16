import '../entities/home_event.dart';

/// Repository interface for home events
/// Provides methods to fetch next event, confirmed events, and pending events
abstract class HomeEventRepository {
  /// Get the next upcoming event (highest priority event)
  Future<HomeEventEntity?> getNextEvent();

  /// Get list of confirmed events
  Future<List<HomeEventEntity>> getConfirmedEvents();

  /// Get list of pending events
  Future<List<HomeEventEntity>> getPendingEvents();
}
