import '../entities/event_expense_entity.dart';
import '../repositories/event_expense_repository.dart';

class GetEventExpenses {
  final EventExpenseRepository _repository;

  GetEventExpenses(this._repository);

  Future<List<EventExpenseEntity>> call(String eventId) async {
    return await _repository.getEventExpenses(eventId);
  }
}