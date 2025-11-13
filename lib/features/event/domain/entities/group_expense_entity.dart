/// Group expense entity for display in group hub
/// Simple entity for tracking group expenses
class GroupExpenseEntity {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final bool isSettled;
  final List<String>? participantIds; // IDs of participants who owe money

  const GroupExpenseEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.isSettled,
    this.participantIds,
  });

  GroupExpenseEntity copyWith({
    String? id,
    String? description,
    double? amount,
    String? paidBy,
    DateTime? date,
    bool? isSettled,
    List<String>? participantIds,
  }) {
    return GroupExpenseEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
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
    return Object.hash(
      id,
      description,
      amount,
      paidBy,
      date,
      isSettled,
      participantIds,
    );
  }
}
