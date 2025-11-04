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

class CreateExpense {
  final GroupExpenseRepository _repository;

  CreateExpense(this._repository);

  Future<GroupExpenseEntity> call({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    return await _repository.createExpense(
      groupId: groupId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
    );
  }
}
