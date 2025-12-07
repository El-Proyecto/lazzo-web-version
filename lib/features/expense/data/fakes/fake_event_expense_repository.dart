import '../../domain/entities/event_expense_entity.dart';
import '../../domain/repositories/event_expense_repository.dart';

class FakeEventExpenseRepository implements EventExpenseRepository {
  final List<EventExpenseEntity> _expenses = [
    EventExpenseEntity(
      id: '1',
      eventId: 'event-1', // ✅ event_id
      description: 'Dinner at Restaurant',
      amount: 120.50,
      paidBy: 'user-1',
      participantsOwe: ['user-2', 'user-3'],
      participantsPaid: [],
      date: DateTime.now().subtract(const Duration(days: 1)),
      isSettled: false,
    ),
    EventExpenseEntity(
      id: '2',
      eventId: 'event-1',
      description: 'Concert Tickets',
      amount: 45.00,
      paidBy: 'user-2',
      participantsOwe: [],
      participantsPaid: ['user-1', 'user-3'],
      date: DateTime.now().subtract(const Duration(days: 3)),
      isSettled: true,
    ),
  ];

  @override
  Future<List<EventExpenseEntity>> getEventExpenses(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _expenses.where((e) => e.eventId == eventId).toList();
  }

  @override
  Future<EventExpenseEntity?> getExpenseById(String expenseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _expenses.firstWhere((e) => e.id == expenseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<EventExpenseEntity> createExpense({
    required String eventId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newExpense = EventExpenseEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: eventId,
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

  @override
  Future<void> markExpenseAsPaid({
    required String expenseId,
    required String userId,
  }) async {
    // Simular delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock implementation para testes
  }
}
