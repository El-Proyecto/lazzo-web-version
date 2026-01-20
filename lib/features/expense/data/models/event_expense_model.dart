import '../../domain/entities/event_expense_entity.dart';

class EventExpenseDto {
  final String id;
  final String eventId; // ✅ Mudou
  final String description;
  final double amount;
  final String paidBy;
  final List<String> participantsOwe;
  final List<String> participantsPaid;
  final DateTime createdAt;
  final bool isSettled;

  const EventExpenseDto({
    required this.id,
    required this.eventId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.participantsOwe,
    required this.participantsPaid,
    required this.createdAt,
    required this.isSettled,
  });

  factory EventExpenseDto.fromJson(Map<String, dynamic> json) {
    return EventExpenseDto(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      description: json['title'] as String, // ✅ DB column is 'title'
      amount: (json['total_amount'] as num)
          .toDouble(), // ✅ DB column is 'total_amount'
      paidBy: json['paid_by'] as String, // ✅ DB column is 'paid_by' (who paid)
      participantsOwe: [], // ✅ Not in event_expenses table, loaded separately
      participantsPaid: [], // ✅ Not in event_expenses table, loaded separately
      createdAt: DateTime.parse(json['created_at'] as String),
      isSettled: false, // ✅ No is_settled column yet, default to false
    );
  }

  EventExpenseEntity toEntity() {
    return EventExpenseEntity(
      id: id,
      eventId: eventId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
      date: createdAt,
      isSettled: isSettled,
    );
  }

  static Map<String, dynamic> fromEntity(EventExpenseEntity entity) {
    return {
      'event_id': entity.eventId, // ✅ Mudou
      'description': entity.description,
      'amount': entity.amount,
      'paid_by': entity.paidBy,
      'participants_owe': entity.participantsOwe,
      'participants_paid': entity.participantsPaid,
      'is_settled': entity.isSettled,
    };
  }
}
