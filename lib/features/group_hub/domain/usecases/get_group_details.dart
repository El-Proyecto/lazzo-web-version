import '../entities/group_details_entity.dart';
import '../repositories/group_details_repository.dart';

/// Use case to get group details
class GetGroupDetails {
  final GroupDetailsRepository _repository;

  const GetGroupDetails(this._repository);

  Future<GroupDetailsEntity> call(String groupId) {
    return _repository.getGroupDetails(groupId);
  }
}
