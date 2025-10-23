import '../entities/group_event_entity.dart';
import '../repositories/group_event_repository.dart';

/// Use case for getting group events
class GetGroupEvents {
  final GroupEventRepository _repository;

  GetGroupEvents(this._repository);

  Future<List<GroupEventEntity>> call(String groupId) async {
    return await _repository.getGroupEvents(groupId);
  }
}
