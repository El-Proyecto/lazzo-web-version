import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';

class FakePaymentRepository implements PaymentRepository {
  final List<PaymentEntity> _payments = [
    PaymentEntity(
      id: '1',
      title: 'Restaurant dinner',
      description: 'Split bill from Friday night dinner',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 25.50,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      fromUserId: 'ana',
      toUserId: 'current_user',
      groupId: 'group1',
      eventId: 'event1',
    ),
    PaymentEntity(
      id: '2',
      title: 'Concert tickets',
      description: 'Payment for concert tickets',
      type: PaymentType.debt,
      status: PaymentStatus.overdue,
      amount: 45.00,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      fromUserId: 'current_user',
      toUserId: 'maria',
      groupId: 'group2',
    ),
    PaymentEntity(
      id: '3',
      title: 'Gas money',
      description: 'Fuel cost for road trip',
      type: PaymentType.request,
      status: PaymentStatus.pending,
      amount: 15.75,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      fromUserId: 'current_user',
      toUserId: 'joao',
      groupId: 'group1',
    ),
    PaymentEntity(
      id: '4',
      title: 'Coffee meetup',
      description: 'Coffee and pastries',
      type: PaymentType.split,
      status: PaymentStatus.paid,
      amount: 12.30,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      fromUserId: 'sofia',
      toUserId: 'current_user',
      groupId: 'group3',
    ),
    // Additional payments for multiple expenses per person testing
    PaymentEntity(
      id: '5',
      title: 'Uber ride',
      description: 'Shared transport',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 8.20,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      fromUserId: 'ana',
      toUserId: 'current_user',
      groupId: 'group1',
      eventId: 'event1',
    ),
    PaymentEntity(
      id: '6',
      title: 'Movie tickets',
      description: 'Cinema outing',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 18.00,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      fromUserId: 'maria',
      toUserId: 'current_user',
      groupId: 'group2',
    ),
    PaymentEntity(
      id: '7',
      title: 'Pizza delivery',
      description: 'Shared meal',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 22.50,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      fromUserId: 'maria',
      toUserId: 'current_user',
      groupId: 'group2',
    ),
    // Additional PaymentEntity for testing multiple expenses
    PaymentEntity(
      id: '8',
      title: 'Coffee meetup',
      description: 'Coffee and pastries',
      type: PaymentType.split,
      status: PaymentStatus.paid,
      amount: 12.30,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      fromUserId: 'sofia',
      toUserId: 'current_user',
      groupId: 'group3',
      eventId: 'event3',
    ),
    // Mixed expenses with Ana (positive and negative)
    PaymentEntity(
      id: '9',
      title: 'Taxi to restaurant',
      description: 'Shared ride',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 15.00,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      fromUserId: 'current_user', // We paid for Ana
      toUserId: 'ana',
      groupId: 'group1',
      eventId: 'event1',
    ),
    // Mixed expenses with Maria (she owes us and we owe her)
    PaymentEntity(
      id: '10',
      title: 'Snacks for movie',
      description: 'Popcorn and drinks',
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: 12.50,
      currency: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      fromUserId: 'current_user', // We paid for Maria
      toUserId: 'maria',
      groupId: 'group2',
      eventId: 'event2',
    ),
  ];

  @override
  Future<List<PaymentEntity>> getPayments({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var payments = _payments;
    if (groupId != null) {
      payments = payments.where((p) => p.groupId == groupId).toList();
    }
    if (eventId != null) {
      payments = payments.where((p) => p.eventId == eventId).toList();
    }

    return payments.skip(offset).take(limit).toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentsOwedToUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments
        .where((p) => p.fromUserId == userId && p.status != PaymentStatus.paid)
        .toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentsUserOwes(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments
        .where((p) => p.toUserId == userId && p.status != PaymentStatus.paid)
        .toList();
  }

  @override
  Future<PaymentEntity?> getPaymentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _payments.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<void> markAsPaid(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _payments.indexWhere((p) => p.id == id);
    if (index != -1) {
      _payments[index] = _payments[index].copyWith(status: PaymentStatus.paid);
    }
  }

  @override
  Future<double> getTotalOwedToUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final owedPayments = _payments.where(
      (p) => p.fromUserId == userId && p.status != PaymentStatus.paid,
    );

    double total = 0.0;
    for (final payment in owedPayments) {
      total += payment.amount;
    }
    return total;
  }

  @override
  Future<double> getTotalUserOwes(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final owedPayments = _payments.where(
      (p) => p.toUserId == userId && p.status != PaymentStatus.paid,
    );

    double total = 0.0;
    for (final payment in owedPayments) {
      total += payment.amount;
    }
    return total;
  }

  @override
  Stream<List<PaymentEntity>> watchPayments() {
    return Stream.periodic(const Duration(seconds: 5), (_) => _payments);
  }
}
