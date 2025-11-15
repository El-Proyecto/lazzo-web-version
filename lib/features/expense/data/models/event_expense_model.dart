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
      eventId: json['event_id'] as String, // ✅ Mudou de group_id
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      participantsOwe: List<String>.from(json['participants_owe'] ?? []),
      participantsPaid: List<String>.from(json['participants_paid'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      isSettled: json['is_settled'] as bool? ?? false,
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