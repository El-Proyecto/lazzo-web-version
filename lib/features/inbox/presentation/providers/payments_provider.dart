import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

// Selected payment user ID provider (for navigation from home to inbox)
final selectedPaymentUserIdProvider = StateProvider<String?>((ref) => null);

// State providers
final paymentsOwedToUserProvider = StateNotifierProvider<
    PaymentsOwedToUserControllerProvider,
    AsyncValue<List<PaymentEntity>>>((ref) {
  return PaymentsOwedToUserControllerProvider(
    ref.watch(getPaymentsOwedToUserUseCaseProvider),
  );
});

final paymentsUserOwesProvider = StateNotifierProvider<
    PaymentsUserOwesControllerProvider, AsyncValue<List<PaymentEntity>>>((ref) {
  return PaymentsUserOwesControllerProvider(
    ref.watch(getPaymentsUserOwesUseCaseProvider),
  );
});

class PaymentsOwedToUserControllerProvider
    extends StateNotifier<AsyncValue<List<PaymentEntity>>> {
  final GetPaymentsOwedToUser _getPaymentsOwedToUser;

  PaymentsOwedToUserControllerProvider(this._getPaymentsOwedToUser)
      : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      print(
          '🔍 [PaymentsOwedToUserController] Loading payments owed to user: $userId');
      final payments = await _getPaymentsOwedToUser(userId);
      print(
          '✅ [PaymentsOwedToUserController] Got ${payments.length} payments owed to user');
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      print('❌ [PaymentsOwedToUserController] Error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPayments();
  }
}

class PaymentsUserOwesControllerProvider
    extends StateNotifier<AsyncValue<List<PaymentEntity>>> {
  final GetPaymentsUserOwes _getPaymentsUserOwes;

  PaymentsUserOwesControllerProvider(this._getPaymentsUserOwes)
      : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      print(
          '🔍 [PaymentsUserOwesController] Loading payments user owes: $userId');
      final payments = await _getPaymentsUserOwes(userId);
      print(
          '✅ [PaymentsUserOwesController] Got ${payments.length} payments user owes');
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      print('❌ [PaymentsUserOwesController] Error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPayments();
  }
}
