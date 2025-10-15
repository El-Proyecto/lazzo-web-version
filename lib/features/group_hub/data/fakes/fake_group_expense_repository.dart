import '../../domain/entities/group_expense_entity.dart';
import '../../domain/repositories/group_expense_repository.dart';

/// Fake implementation of GroupExpenseRepository for development
class FakeGroupExpenseRepository implements GroupExpenseRepository {
  final List<GroupExpenseEntity> _expenses = [];

  @override
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _expenses; // Empty list for now
  }

  @override
  Future<GroupExpenseEntity?> getExpenseById(String expenseId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _expenses.firstWhere((expense) => expense.id == expenseId);
    } catch (e) {
      return null;
    }
  }
}
