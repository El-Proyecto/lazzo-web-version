/// Group expense entity for display in group hub
/// Simple entity for tracking group expenses
class GroupExpenseEntity {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final bool isSettled;

  const GroupExpenseEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.isSettled,
  });

  GroupExpenseEntity copyWith({
    String? id,
    String? description,
    double? amount,
    String? paidBy,
    DateTime? date,
    bool? isSettled,
  }) {
    return GroupExpenseEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
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
        other.isSettled == isSettled;
  }

  @override
  int get hashCode {
    return Object.hash(id, description, amount, paidBy, date, isSettled);
  }
}
