enum PaymentType { expense, split, debt, request }

enum PaymentStatus { pending, paid, overdue, cancelled }

class PaymentEntity {
  final String id;
  final String title;
  final String description;
  final PaymentType type;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? fromUserId;
  final String? toUserId;
  final String? groupId;
  final String? eventId;
  final List<String>? participantIds;

  const PaymentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.amount,
    this.currency = 'EUR',
    required this.createdAt,
    this.dueDate,
    this.fromUserId,
    this.toUserId,
    this.groupId,
    this.eventId,
    this.participantIds,
  });

  bool get isOwed => fromUserId != null && toUserId != null;
  bool get isDebt => toUserId != null && fromUserId == null;

  PaymentEntity copyWith({
    String? id,
    String? title,
    String? description,
    PaymentType? type,
    PaymentStatus? status,
    double? amount,
    String? currency,
    DateTime? createdAt,
    DateTime? dueDate,
    String? fromUserId,
    String? toUserId,
    String? groupId,
    String? eventId,
    List<String>? participantIds,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}
