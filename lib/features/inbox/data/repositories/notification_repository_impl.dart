import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../data_sources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final String _userId;

  NotificationRepositoryImpl(
    this._remoteDataSource,
    this._userId,
  );

  @override
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = true, // ✅ P2: Default to unread only
    NotificationCategory? category,
  }) async {
                
    try {
            final models = await _remoteDataSource.getNotifications(
        userId: _userId,
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
        category: category?.name,
      );

                  
      final entities = models.map((model) => model.toEntity()).toList();
      
            return entities;
    } catch (e, stackTrace) {
                  throw Exception('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(String id) async {
    try {
      final model = await _remoteDataSource.getNotificationById(
        id: id,
        userId: _userId,
      );

      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to fetch notification by ID: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _remoteDataSource.markAsRead(
        id: id,
        userId: _userId,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead(userId: _userId);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await _remoteDataSource.getUnreadCount(userId: _userId);
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _remoteDataSource.deleteNotification(
        id: id,
        userId: _userId,
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications() {
    try {
      return _remoteDataSource
          .watchNotifications(userId: _userId)
          .map((models) => models.map((model) => model.toEntity()).toList());
    } catch (e) {
      throw Exception('Failed to watch notifications: $e');
    }
  }
}
