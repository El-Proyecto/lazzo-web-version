import '../../domain/entities/payment_entity.dart';

/// DTO that maps from Supabase user_payment_debts_view to domain PaymentEntity
class PaymentDebtDto {
  final String paymentId;
  final String expenseId;
  final String expenseTitle;
  final double debtAmount;
  final bool hasPaid;
  final DateTime createdAt;

  final String paidByUserId;
  final String paidByUserName;
  final String? paidByAvatarUrl;

  final String debtorUserId;
  final String debtorUserName;
  final String? debtorAvatarUrl;

  final String eventId;
  final String? eventName;
  final String? eventEmoji;

  final String groupId;
  final String? groupName;

  const PaymentDebtDto({
    required this.paymentId,
    required this.expenseId,
    required this.expenseTitle,
    required this.debtAmount,
    required this.hasPaid,
    required this.createdAt,
    required this.paidByUserId,
    required this.paidByUserName,
    this.paidByAvatarUrl,
    required this.debtorUserId,
    required this.debtorUserName,
    this.debtorAvatarUrl,
    required this.eventId,
    this.eventName,
    this.eventEmoji,
    required this.groupId,
    this.groupName,
  });

  /// Factory from Supabase JSON row
  factory PaymentDebtDto.fromJson(Map<String, dynamic> json) {
    return PaymentDebtDto(
      paymentId: json['payment_id'] as String,
      expenseId: json['expense_id'] as String,
      expenseTitle: json['expense_title'] as String,
      debtAmount: (json['debt_amount'] as num).toDouble(),
      hasPaid: json['has_paid'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidByUserId: json['paid_by_user_id'] as String,
      paidByUserName: json['paid_by_user_name'] as String,
      paidByAvatarUrl: json['paid_by_avatar_url'] as String?,
      debtorUserId: json['debtor_user_id'] as String,
      debtorUserName: json['debtor_user_name'] as String,
      debtorAvatarUrl: json['debtor_avatar_url'] as String?,
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String?,
      eventEmoji: json['event_emoji'] as String?,
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String?,
    );
  }

  /// Convert to PaymentEntity (domain layer)
  ///
  /// View semantics:
  /// - paid_by_user_id = person who PAID (creditor) - money is OWED TO them
  /// - debtor_user_id = person who OWES (debtor) - they OWE money
  ///
  /// PaymentEntity semantics:
  /// - fromUserId = person who OWES money (debtor)
  /// - toUserId = person who is OWED money (creditor)
  PaymentEntity toEntity({required String currentUserId}) {
    print('🔍 [PaymentDebtDto.toEntity] Converting:');
    print('   expense: $expenseTitle, amount: €$debtAmount');
    print('   paidBy: $paidByUserName ($paidByUserId) ← CREDITOR');
    print('   debtor: $debtorUserName ($debtorUserId) ← DEBTOR');
    print('   currentUser: $currentUserId');

    // View semantics are clear: paid_by is creditor, debtor is debtor
    // So in PaymentEntity: fromUserId = debtor, toUserId = creditor (paid_by)
    final entity = PaymentEntity(
      id: paymentId,
      title: expenseTitle,
      description: eventName ?? expenseTitle,
      type: PaymentType.split,
      status: hasPaid ? PaymentStatus.paid : PaymentStatus.pending,
      amount: debtAmount,
      createdAt: createdAt,
      // Fixed mapping: debtor owes TO creditor
      fromUserId: debtorUserId, // Who owes
      fromUserName: debtorUserName,
      toUserId: paidByUserId, // Who is owed
      toUserName: paidByUserName,
      groupId: groupId,
      groupName: groupName,
      eventId: eventId,
      eventName: eventName,
    );

    print('   → Entity: from $debtorUserName TO $paidByUserName');
    return entity;
  }
}
