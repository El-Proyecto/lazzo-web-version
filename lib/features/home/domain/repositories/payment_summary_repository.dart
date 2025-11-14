import '../entities/payment_summary_entity.dart';

/// Repository interface for payment summaries
abstract class PaymentSummaryRepository {
  /// Get list of payment summaries grouped by person
  Future<List<PaymentSummaryEntity>> getPaymentSummaries();

  /// Get total balance (positive = owed to you, negative = you owe)
  Future<double> getTotalBalance();
}
