import '../../domain/entities/payment_summary_entity.dart';
import '../../domain/repositories/payment_summary_repository.dart';

/// Fake repository for payment summaries - used for UI development
/// Returns mock data without backend calls
class FakePaymentSummaryRepository implements PaymentSummaryRepository {
  @override
  Future<List<PaymentSummaryEntity>> getPaymentSummaries() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final summaries = [
      const PaymentSummaryEntity(
        userId: 'user_1',
        userName: 'João Silva',
        amount: 45.0, // They owe you
        expenseCount: 3,
        currency: 'EUR',
      ),
      const PaymentSummaryEntity(
        userId: 'user_2',
        userName: 'Maria Costa',
        amount: -12.0, // You owe them
        expenseCount: 1,
        currency: 'EUR',
      ),
      const PaymentSummaryEntity(
        userId: 'user_3',
        userName: 'Pedro Santos',
        amount: 28.0, // They owe you
        expenseCount: 2,
        currency: 'EUR',
      ),
      const PaymentSummaryEntity(
        userId: 'user_4',
        userName: 'Ana Oliveira',
        amount: -8.5, // You owe them
        expenseCount: 1,
        currency: 'EUR',
      ),
    ];

    // Sort by impact (highest absolute amount first)
    summaries.sort((a, b) => b.absoluteAmount.compareTo(a.absoluteAmount));

    return summaries;
  }

  @override
  Future<double> getTotalBalance() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final summaries = await getPaymentSummaries();
    return summaries.fold<double>(
      0.0,
      (total, summary) => total + summary.amount,
    );
  }
}
