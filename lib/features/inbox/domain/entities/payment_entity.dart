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
  final String? fromUserName; // Name of the person who owes
  final String? toUserId;
  final String? toUserName; // Name of the person being owed
  final String? groupId;
  final String? groupName; // Name of the group
  final String? eventId;
  final String? eventName; // Name of the event
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
    this.fromUserName,
    this.toUserId,
    this.toUserName,
    this.groupId,
    this.groupName,
    this.eventId,
    this.eventName,
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
    String? fromUserName,
    String? toUserId,
    String? toUserName,
    String? groupId,
    String? groupName,
    String? eventId,
    String? eventName,
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
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}
