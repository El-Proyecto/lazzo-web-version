import '../entities/group_event_entity.dart';
import '../repositories/group_event_repository.dart';

/// Use case for getting paginated group events
class GetGroupEvents {
  final GroupEventRepository _repository;

  GetGroupEvents(this._repository);

  Future<List<GroupEventEntity>> call(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  }) async {
    return await _repository.getGroupEvents(
      groupId,
      pageSize: pageSize,
      offset: offset,
    );
  }

  /// Get total count of non-ended events in group
  Future<int> getCount(String groupId) async {
    return await _repository.getGroupEventsCount(groupId);
  }
}
