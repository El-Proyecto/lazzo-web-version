import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/get_user_payments.dart';
import '../../data/fakes/fake_payment_repository.dart';

// Repository provider - defaults to fake
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return FakePaymentRepository();
});

// Use case providers
final getUserPaymentsUseCaseProvider = Provider<GetUserPayments>((ref) {
  return GetUserPayments(ref.watch(paymentRepositoryProvider));
});

final getPaymentsOwedToUserUseCaseProvider = Provider<GetPaymentsOwedToUser>((
  ref,
) {
  return GetPaymentsOwedToUser(ref.watch(paymentRepositoryProvider));
});

final getPaymentsUserOwesUseCaseProvider = Provider<GetPaymentsUserOwes>((ref) {
  return GetPaymentsUserOwes(ref.watch(paymentRepositoryProvider));
});

final markPaymentAsPaidUseCaseProvider = Provider<MarkPaymentAsPaid>((ref) {
  return MarkPaymentAsPaid(ref.watch(paymentRepositoryProvider));
});

// State providers
final paymentsOwedToUserProvider =
    StateNotifierProvider<
      PaymentsOwedToUserController,
      AsyncValue<List<PaymentEntity>>
    >((ref) {
      return PaymentsOwedToUserController(
        ref.watch(getPaymentsOwedToUserUseCaseProvider),
      );
    });

final paymentsUserOwesProvider =
    StateNotifierProvider<
      PaymentsUserOwesController,
      AsyncValue<List<PaymentEntity>>
    >((ref) {
      return PaymentsUserOwesController(
        ref.watch(getPaymentsUserOwesUseCaseProvider),
      );
    });

class PaymentsOwedToUserController
    extends StateNotifier<AsyncValue<List<PaymentEntity>>> {
  final GetPaymentsOwedToUser _getPaymentsOwedToUser;

  PaymentsOwedToUserController(this._getPaymentsOwedToUser)
    : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      // Using a dummy user ID for fake data
      final payments = await _getPaymentsOwedToUser('current_user');
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPayments();
  }
}

class PaymentsUserOwesController
    extends StateNotifier<AsyncValue<List<PaymentEntity>>> {
  final GetPaymentsUserOwes _getPaymentsUserOwes;

  PaymentsUserOwesController(this._getPaymentsUserOwes)
    : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      // Using a dummy user ID for fake data
      final payments = await _getPaymentsUserOwes('current_user');
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPayments();
  }
}
