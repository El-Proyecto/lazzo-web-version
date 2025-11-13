/// Participant in a group expense with payment status
class ExpenseParticipant {
  final String id;
  final String name;
  final String? avatarUrl;
  final double amount;
  final bool hasPaid;
  final DateTime? paidAt;

  const ExpenseParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.amount,
    required this.hasPaid,
    this.paidAt,
  });

  ExpenseParticipant copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? amount,
    bool? hasPaid,
    DateTime? paidAt,
  }) {
    return ExpenseParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      amount: amount ?? this.amount,
      hasPaid: hasPaid ?? this.hasPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseParticipant &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.amount == amount &&
        other.hasPaid == hasPaid &&
        other.paidAt == paidAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, avatarUrl, amount, hasPaid, paidAt);
  }
}
