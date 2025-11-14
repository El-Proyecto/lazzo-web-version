import '../entities/group_expense_entity.dart';

/// Repository interface for group expenses data access
abstract class GroupExpenseRepository {
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId);
  Future<GroupExpenseEntity?> getExpenseById(String expenseId);
  
  /// Create a new expense
  Future<GroupExpenseEntity> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  });
}
