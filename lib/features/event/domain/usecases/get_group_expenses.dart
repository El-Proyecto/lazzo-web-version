import '../entities/group_expense_entity.dart';
import '../repositories/group_expense_repository.dart';

/// Use case for getting group expenses
class GetGroupExpenses {
  final GroupExpenseRepository _repository;

  GetGroupExpenses(this._repository);

  Future<List<GroupExpenseEntity>> call(String groupId) async {
    return await _repository.getGroupExpenses(groupId);
  }
}
