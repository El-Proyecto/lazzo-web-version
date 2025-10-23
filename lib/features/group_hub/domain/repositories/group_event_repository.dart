import '../entities/group_event_entity.dart';

/// Repository interface for group events data access
abstract class GroupEventRepository {
  /// Get all events for a specific group
  Future<List<GroupEventEntity>> getGroupEvents(String groupId);

  /// Get a single event by ID
  Future<GroupEventEntity?> getEventById(String eventId);
}
