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
  final List<String>? participantIds; // IDs of participants who owe money

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
    this.participantIds,
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
    List<String>? participantIds,
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
      participantIds: participantIds ?? this.participantIds,
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
        other.isSettled == isSettled &&
        _listEquals(other.participantIds, participantIds);
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
<<<<<<< HEAD:lib/features/group_hub/domain/entities/group_expense_entity.dart
    return Object.hash(id, groupId, description, amount, paidBy, date, isSettled);
=======
    return Object.hash(
      id,
      description,
      amount,
      paidBy,
      date,
      isSettled,
      participantIds,
    );
>>>>>>> origin/main:lib/features/event/domain/entities/group_expense_entity.dart
  }
}