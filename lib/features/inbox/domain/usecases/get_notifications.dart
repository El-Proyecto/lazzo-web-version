import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  const GetNotifications(this.repository);

  Future<List<NotificationEntity>> call({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    return repository.getNotifications(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
  }
}

class MarkNotificationAsRead {
  final NotificationRepository repository;

  const MarkNotificationAsRead(this.repository);

  Future<void> call(String id) {
    return repository.markAsRead(id);
  }
}

class GetUnreadNotificationCount {
  final NotificationRepository repository;

  const GetUnreadNotificationCount(this.repository);

  Future<int> call() {
    return repository.getUnreadCount();
  }
}
