/// Payment summary entity for home page
/// Represents a person and the total amount owed/to receive
class PaymentSummaryEntity {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double amount; // Positive if they owe you, negative if you owe them
  final int expenseCount; // Number of expenses with this person
  final String currency;

  const PaymentSummaryEntity({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.amount,
    required this.expenseCount,
    this.currency = 'EUR',
  });

  /// Whether this person owes you money
  bool get isOwedToYou => amount > 0;

  /// Whether you owe this person money
  bool get youOwe => amount < 0;

  /// Absolute amount for sorting by impact
  double get absoluteAmount => amount.abs();

  /// Formatted amount with sign
  String get formattedAmount {
    final sign = amount >= 0 ? '+' : '';
    return '$sign€${amount.abs().toStringAsFixed(2)}';
  }
}
