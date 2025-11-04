/// Group expense entity for display in group hub
/// Simple entity for tracking group expenses
class GroupExpenseEntity {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy; // ✅ ID único de quem LANÇOU a despesa
  final List<String> participantsOwe; // ✅ IDs de quem ainda NÃO pagou
  final List<String> participantsPaid; // ✅ IDs de quem JÁ pagou
  final DateTime date;
  final bool isSettled;

  const GroupExpenseEntity({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.participantsOwe,
    required this.participantsPaid,
    required this.date,
    required this.isSettled,
  });

  GroupExpenseEntity copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? paidBy,
    List<String>? participantsOwe,
    List<String>? participantsPaid,
    DateTime? date,
    bool? isSettled,
  }) {
    return GroupExpenseEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
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
    return other is GroupExpenseEntity &&
        other.id == id &&
        other.groupId == groupId &&
        other.description == description &&
        other.amount == amount &&
        other.paidBy == paidBy &&
        other.date == date &&
        other.isSettled == isSettled;
  }

  @override
  int get hashCode {
    return Object.hash(id, groupId, description, amount, paidBy, date, isSettled);
  }
}