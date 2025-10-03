import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<List<PaymentEntity>> getPayments({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  });

  Future<List<PaymentEntity>> getPaymentsOwedToUser(String userId);

  Future<List<PaymentEntity>> getPaymentsUserOwes(String userId);

  Future<PaymentEntity?> getPaymentById(String id);

  Future<void> markAsPaid(String id);

  Future<double> getTotalOwedToUser(String userId);

  Future<double> getTotalUserOwes(String userId);

  Stream<List<PaymentEntity>> watchPayments();
}
