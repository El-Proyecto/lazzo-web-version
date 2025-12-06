/// Event expense entity (despesa associada a um evento específico)
class EventExpenseEntity {
  final String id;
  final String eventId; // ✅ Mudou de groupId para eventId
  final String description;
  final double amount;
  final String paidBy; // ID do participante que lançou
  final List<String> participantsOwe; // IDs dos que ainda devem
  final List<String> participantsPaid; // IDs dos que já pagaram
  final DateTime date;
  final bool isSettled;

  const EventExpenseEntity({
    required this.id,
    required this.eventId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.participantsOwe,
    required this.participantsPaid,
    required this.date,
    required this.isSettled,
  });

  EventExpenseEntity copyWith({
    String? id,
    String? eventId,
    String? description,
    double? amount,
    String? paidBy,
    List<String>? participantsOwe,
    List<String>? participantsPaid,
    DateTime? date,
    bool? isSettled,
  }) {
    return EventExpenseEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      participantsOwe: participantsOwe ?? this.participantsOwe,
      participantsPaid: participantsPaid ?? this.participantsPaid,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventExpenseEntity &&
        other.id == id &&
        other.eventId == eventId &&
        other.description == description &&
        other.amount == amount &&
        other.paidBy == paidBy &&
        other.date == date &&
        other.isSettled == isSettled;
  }

  @override
  int get hashCode {
    return Object.hash(id, eventId, description, amount, paidBy, date, isSettled);
  }
}