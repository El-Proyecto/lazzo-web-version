import '../entities/event_expense_entity.dart';

/// Repository interface for event expenses
abstract class EventExpenseRepository {
  /// Busca despesas de um evento específico
  Future<List<EventExpenseEntity>> getEventExpenses(String eventId);
  
  /// Busca uma despesa específica por ID
  Future<EventExpenseEntity?> getExpenseById(String expenseId);
  
  /// Cria nova despesa associada a um evento
  Future<EventExpenseEntity> createExpense({
    required String eventId, // ✅ event_id
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  });

  Future<void> markExpenseAsPaid({
    required String expenseId,
    required String userId,
  });
}