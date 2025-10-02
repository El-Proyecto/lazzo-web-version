import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    NotificationCategory? category,
  });

  Future<NotificationEntity?> getNotificationById(String id);

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<int> getUnreadCount();

  Future<void> deleteNotification(String id);

  Stream<List<NotificationEntity>> watchNotifications();
}
