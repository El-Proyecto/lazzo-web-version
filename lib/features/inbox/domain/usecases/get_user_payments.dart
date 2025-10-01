import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class GetUserPayments {
  final PaymentRepository repository;

  const GetUserPayments(this.repository);

  Future<List<PaymentEntity>> call({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) {
    return repository.getPayments(
      limit: limit,
      offset: offset,
      groupId: groupId,
      eventId: eventId,
    );
  }
}

class GetPaymentsOwedToUser {
  final PaymentRepository repository;

  const GetPaymentsOwedToUser(this.repository);

  Future<List<PaymentEntity>> call(String userId) {
    return repository.getPaymentsOwedToUser(userId);
  }
}

class GetPaymentsUserOwes {
  final PaymentRepository repository;

  const GetPaymentsUserOwes(this.repository);

  Future<List<PaymentEntity>> call(String userId) {
    return repository.getPaymentsUserOwes(userId);
  }
}

class MarkPaymentAsPaid {
  final PaymentRepository repository;

  const MarkPaymentAsPaid(this.repository);

  Future<void> call(String id) {
    return repository.markAsPaid(id);
  }
}
