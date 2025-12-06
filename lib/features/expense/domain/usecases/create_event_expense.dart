import '../entities/event_expense_entity.dart';
import '../repositories/event_expense_repository.dart';

class CreateEventExpense {
  final EventExpenseRepository _repository;

  CreateEventExpense(this._repository);

  Future<EventExpenseEntity> call({
    required String eventId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    return await _repository.createExpense(
      eventId: eventId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
    );
  }
}