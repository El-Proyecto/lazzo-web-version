import '../repositories/payment_summary_repository.dart';

/// Use case to get total payment balance
class GetTotalBalance {
  final PaymentSummaryRepository repository;

  const GetTotalBalance(this.repository);

  Future<double> call() async {
    return await repository.getTotalBalance();
  }
}
