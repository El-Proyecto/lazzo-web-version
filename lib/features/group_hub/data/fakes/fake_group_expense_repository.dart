import '../../domain/entities/group_expense_entity.dart';
import '../../domain/repositories/group_expense_repository.dart';

/// Fake implementation of GroupExpenseRepository for development
class FakeGroupExpenseRepository implements GroupExpenseRepository {
  final List<GroupExpenseEntity> _expenses = [
    GroupExpenseEntity(
      id: '1',
      description: 'Dinner at Restaurant',
      amount: 120.50,
      paidBy: 'Marco',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isSettled: false,
    ),
    GroupExpenseEntity(
      id: '2',
      description: 'Concert Tickets',
      amount: 45.00,
      paidBy: 'Ana',
      date: DateTime.now().subtract(const Duration(days: 3)),
      isSettled: true,
    ),
    GroupExpenseEntity(
      id: '3',
      description: 'Gas for Trip',
      amount: 35.75,
      paidBy: 'João',
      date: DateTime.now().subtract(const Duration(days: 7)),
      isSettled: false,
    ),
    GroupExpenseEntity(
      id: '4',
      description: 'Groceries for BBQ',
      amount: 84.20,
      paidBy: 'current_user', // User paid this one and others owe
      date: DateTime.now().subtract(const Duration(days: 2)),
      isSettled: false,
    ),
  ];

  @override
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _expenses;
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
