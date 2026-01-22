import '../entities/group_event_entity.dart';

/// Repository interface for group events data access
abstract class GroupEventRepository {
  /// Get paginated events for a specific group
  Future<List<GroupEventEntity>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  });

  /// Get total count of non-ended events in group
  Future<int> getGroupEventsCount(String groupId);

  /// Get a single event by ID
  Future<GroupEventEntity?> getEventById(String eventId);
}
