import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  final List<NotificationEntity> _notifications = [
    // PUSH notifications (with in-app feed entry)
    NotificationEntity(
      id: '1',
      title: 'Group Invitation',
      description: '{user} invited you to join **{group}**.',
      type: NotificationType.groupInviteReceived,
      category: NotificationCategory.push,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      userName: 'João',
      groupName: 'Summer Trip Planning',
      groupId: 'group1',
      eventEmoji: '🏖️',
    ),

    NotificationEntity(
      id: '2',
      title: 'Event Starting Soon',
      description: '**{event}** starts in {mins} min.',
      type: NotificationType.eventStartsSoon,
      category: NotificationCategory.push,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      eventName: 'Beach BBQ',
      mins: '15',
      eventId: 'event1',
      eventEmoji: '🏖️',
    ),

    NotificationEntity(
      id: '3',
      title: 'Event Live',
      description: '**{event}** is live now.',
      type: NotificationType.eventLive,
      category: NotificationCategory.push,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      eventName: 'Concert Night',
      eventId: 'event2',
      eventEmoji: '🎵',
    ),

    NotificationEntity(
      id: '4',
      title: 'Add Photos',
      description: 'Add your photos to **{event}** · {hours}h left.',
      type: NotificationType.uploadsOpen,
      category: NotificationCategory.push,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      eventName: 'Movie Night',
      hours: '2',
      eventId: 'event3',
      eventEmoji: '�',
    ),

    NotificationEntity(
      id: '5',
      title: 'Payment Request',
      description: '{user} requested **{amount}** for {note}.',
      type: NotificationType.paymentsRequest,
      category: NotificationCategory.push,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      userName: 'Ana',
      amount: '€25.50',
      note: 'restaurant bill',
      eventEmoji: '🍽️',
    ),

    NotificationEntity(
      id: '6',
      title: 'Payment Added',
      description: '{user} added an expense in **{event}**. You owe {amount}.',
      type: NotificationType.paymentsAddedYouOwe,
      category: NotificationCategory.push,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      userName: 'Pedro',
      eventName: 'Football Match',
      amount: '€12.00',
      eventId: 'event4',
      eventEmoji: '⚽',
    ),

    NotificationEntity(
      id: '7',
      title: 'Payment Received',
      description: '{user} paid you **{amount}**.',
      type: NotificationType.paymentsPaidYou,
      category: NotificationCategory.push,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      userName: 'Maria',
      amount: '€15.00',
      eventEmoji: '💰',
    ),

    NotificationEntity(
      id: '8',
      title: 'Memory Ready',
      description: 'Your memory for **{event}** is ready to share.',
      type: NotificationType.memoryReady,
      category: NotificationCategory.push,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      eventName: 'Birthday Party',
      eventId: 'event5',
      eventEmoji: '�',
    ),

    // NOTIFICATIONS (feed) - Informational updates
    NotificationEntity(
      id: '9',
      title: 'User Joined',
      description: '{user} joined **{group}**.',
      type: NotificationType.groupInviteAccepted,
      category: NotificationCategory.notifications,
      priority: NotificationPriority.low,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      userName: 'Carlos',
      groupName: 'Weekend Hikers',
      groupId: 'group2',
      isRead: true,
    ),

    NotificationEntity(
      id: '10',
      title: 'Event Created',
      description: 'New event **{event}** in **{group}**.',
      type: NotificationType.eventCreated,
      category: NotificationCategory.notifications,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      eventName: 'Hiking Trip',
      groupName: 'Weekend Hikers',
      eventId: 'event6',
      groupId: 'group2',
      eventEmoji: '🥾',
      isRead: true,
    ),

    NotificationEntity(
      id: '11',
      title: 'Date Confirmed',
      description: 'Date confirmed for **{event}**: {date}, {time}.',
      type: NotificationType.eventDateSet,
      category: NotificationCategory.notifications,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      eventName: 'Hiking Trip',
      date: 'Saturday, Oct 5',
      time: '9:00 AM',
      eventId: 'event6',
      eventEmoji: '🥾',
      isRead: true,
    ),

    // Removed: eventLocationSet and eventDetailsUpdated per NOTIFICATIONS_REFERENCE.md
  ];

  @override
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    NotificationCategory? category,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    var notifications = _notifications;

    if (unreadOnly) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    if (category != null) {
      notifications =
          notifications.where((n) => n.category == category).toList();
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
