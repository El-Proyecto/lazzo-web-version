import '../entities/payment_summary_entity.dart';
import '../repositories/payment_summary_repository.dart';

/// Use case to get payment summaries
class GetPaymentSummaries {
  final PaymentSummaryRepository repository;

  const GetPaymentSummaries(this.repository);

  Future<List<PaymentSummaryEntity>> call() async {
    return await repository.getPaymentSummaries();
  }
}
