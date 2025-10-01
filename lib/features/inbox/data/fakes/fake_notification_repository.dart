import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  final List<NotificationEntity> _notifications = [
    NotificationEntity(
      id: '1',
      title: 'Welcome to Lazzo!',
      description: 'Start organizing your events and groups',
      type: NotificationType.general,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      actionText: 'Get Started',
      actionUrl: '/groups',
    ),
    NotificationEntity(
      id: '2',
      title: 'Group Invitation',
      description: 'João invited you to join "Summer Trip Planning"',
      type: NotificationType.groupInvite,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      actionText: 'Accept',
      groupId: 'group1',
    ),
    NotificationEntity(
      id: '3',
      title: 'Event Update',
      description: 'Beach BBQ location has been changed',
      type: NotificationType.eventUpdate,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      actionText: 'View Details',
      eventId: 'event1',
      isRead: true,
    ),
    NotificationEntity(
      id: '4',
      title: 'Payment Request',
      description: 'Ana requested €25.50 for restaurant bill',
      type: NotificationType.paymentRequest,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      actionText: 'Pay Now',
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    var notifications = _notifications;
    if (unreadOnly) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    return notifications.skip(offset).take(limit).toList();
  }

  @override
  Future<NotificationEntity?> getNotificationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _notifications.where((n) => n.id == id).firstOrNull;
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> deleteNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.removeWhere((n) => n.id == id);
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications() {
    return Stream.periodic(const Duration(seconds: 5), (_) => _notifications);
  }
}
