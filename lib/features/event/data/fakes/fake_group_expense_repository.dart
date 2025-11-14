import '../../domain/entities/group_expense_entity.dart';
import '../../domain/repositories/group_expense_repository.dart';

/// Fake implementation of GroupExpenseRepository for development
class FakeGroupExpenseRepository implements GroupExpenseRepository {
  final List<GroupExpenseEntity> _expenses = [
    GroupExpenseEntity(
      id: '1',
      groupId: 'fake-group-id',
      description: 'Dinner at Restaurant',
      amount: 120.50,
      paidBy: 'user-1', // ✅ ID único
      participantsOwe: ['user-2', 'user-3'], // Ainda devem
      participantsPaid: [], // Ninguém pagou ainda
      date: DateTime.now().subtract(const Duration(days: 1)),
      isSettled: false,
<<<<<<< HEAD:lib/features/group_hub/data/fakes/fake_group_expense_repository.dart
    ),
    GroupExpenseEntity(
      id: '2',
      groupId: 'fake-group-id',
      description: 'Concert Tickets',
      amount: 45.00,
      paidBy: 'user-2',
      participantsOwe: [],
      participantsPaid: ['user-1', 'user-3'], // Todos pagaram
      date: DateTime.now().subtract(const Duration(days: 3)),
      isSettled: true,
    ),
    GroupExpenseEntity(
      id: '3',
      groupId: 'fake-group-id',
      description: 'Gas for Trip',
      amount: 35.75,
      paidBy: 'user-3',
      participantsOwe: ['user-1'],
      participantsPaid: ['user-2'],
      date: DateTime.now().subtract(const Duration(days: 7)),
      isSettled: false,
=======
      participantIds: ['current_user', 'Ana', 'João'],
>>>>>>> origin/main:lib/features/event/data/fakes/fake_group_expense_repository.dart
    ),
    GroupExpenseEntity(
      id: '4',
      groupId: 'fake-group-id',
      description: 'Groceries for BBQ',
      amount: 84.20,
      paidBy: 'current_user', // User lançou
      participantsOwe: ['user-1', 'user-2', 'user-3'], // Todos devem
      participantsPaid: [],
      date: DateTime.now().subtract(const Duration(days: 2)),
      isSettled: false,
      participantIds: ['Marco', 'Ana', 'João'],
    ),
    GroupExpenseEntity(
      id: '3',
      description: 'Gas for Trip',
      amount: 35.75,
      paidBy: 'João',
      date: DateTime.now().subtract(const Duration(days: 7)),
      isSettled: false,
      participantIds: ['current_user', 'Marco'],
    ),
    GroupExpenseEntity(
      id: '5',
      description: 'Beach Parking',
      amount: 15.00,
      paidBy: 'Ana',
      date: DateTime.now().subtract(const Duration(days: 5)),
      isSettled: false,
      participantIds: ['current_user', 'Marco', 'João'],
    ),
    // Settled expenses go last
    GroupExpenseEntity(
      id: '2',
      description: 'Concert Tickets',
      amount: 45.00,
      paidBy: 'Ana',
      date: DateTime.now().subtract(const Duration(days: 3)),
      isSettled: true,
      participantIds: ['current_user', 'Marco'],
    ),
  ];

  @override
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _expenses;
  }

  @override
  Future<GroupExpenseEntity?> getExpenseById(String expenseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _expenses.firstWhere((expense) => expense.id == expenseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<GroupExpenseEntity> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy, // ✅ ID único
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newExpense = GroupExpenseEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
      date: DateTime.now(),
      isSettled: false,
    );
    
    _expenses.insert(0, newExpense);
    return newExpense;
  }
}