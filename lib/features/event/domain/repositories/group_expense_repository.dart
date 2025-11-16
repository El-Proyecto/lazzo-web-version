import '../entities/group_expense_entity.dart';

/// Repository interface for group expenses data access
abstract class GroupExpenseRepository {
  /// Get all expenses for a specific group
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId);

  /// Get a single expense by ID
  Future<GroupExpenseEntity?> getExpenseById(String expenseId);
}
