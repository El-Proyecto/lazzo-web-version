import 'payment_entity.dart';

/// Represents a group of payments from/to the same user
class PaymentGroup {
  final String userId;
  final String userName;
  final List<PaymentEntity> payments;
  final double totalAmount;
  final bool isOwedToUser;

  const PaymentGroup({
    required this.userId,
    required this.userName,
    required this.payments,
    required this.totalAmount,
    required this.isOwedToUser,
  });

  /// Returns the primary expense title if only one, or count if multiple
  String get displaySubtitle {
    if (payments.length == 1) {
      return payments.first.title;
    } else {
      return '${payments.length} expenses';
    }
  }

  /// Returns the display text for the main description
  String get displayDescription {
    if (payments.length == 1) {
      final payment = payments.first;
      return '$userName ${isOwedToUser ? 'owes you' : 'you owe'} €${payment.amount.toStringAsFixed(2)}';
    } else {
      return '$userName ${isOwedToUser ? 'owes you' : 'you owe'} €${totalAmount.toStringAsFixed(2)}';
    }
  }

  /// Groups payments by user, calculating net amounts for bidirectional payments
  static List<PaymentGroup> groupByUser(
    List<PaymentEntity> allPayments,
    bool isOwedToUser,
    Function(String) getUserName,
  ) {
    final Map<String, PaymentGroup> groups = {};

    // Get all unique user IDs that have any payment relationship
    final Set<String> allUserIds = {};
    for (final payment in allPayments) {
      if (payment.fromUserId != null && payment.fromUserId != 'current_user') {
        allUserIds.add(payment.fromUserId!);
      }
      if (payment.toUserId != null && payment.toUserId != 'current_user') {
        allUserIds.add(payment.toUserId!);
      }
    }

    // For each user, calculate net amounts
    for (final userId in allUserIds) {
      final owedToUs = allPayments
          .where(
            (p) =>
                p.fromUserId == userId &&
                p.toUserId == 'current_user' &&
                p.status != PaymentStatus.paid,
          )
          .toList();

      final weOwe = allPayments
          .where(
            (p) =>
                p.fromUserId == 'current_user' &&
                p.toUserId == userId &&
                p.status != PaymentStatus.paid,
          )
          .toList();

      final owedToUsTotal = owedToUs.fold(0.0, (sum, p) => sum + p.amount);
      final weOweTotal = weOwe.fold(0.0, (sum, p) => sum + p.amount);

      final netAmount = owedToUsTotal - weOweTotal;
      final netIsOwedToUser = netAmount > 0;
      final netAbsAmount = netAmount.abs();

      // Only include if there's a net amount and it matches the requested direction
      if (netAbsAmount > 0 && netIsOwedToUser == isOwedToUser) {
        final allUserPayments = [...owedToUs, ...weOwe];

        groups[userId] = PaymentGroup(
          userId: userId,
          userName: getUserName(userId),
          payments: allUserPayments,
          totalAmount: netAbsAmount,
          isOwedToUser: netIsOwedToUser,
        );
      }
    }

    return groups.values.toList();
  }
}
