import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSource(this._client);

  /// Get paginated notifications with optional filters
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    String? category,
  }) async {
    try {
      var query = _client
          .from('notifications')
          .select()
          .eq('recipient_user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final models = (response as List)
          .map((json) =>
              NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return models;
    } catch (e) {
      rethrow;
    }
  }

  /// Get single notification by ID
  Future<NotificationModel?> getNotificationById({
    required String id,
    required String userId,
  }) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('id', id)
        .eq('recipient_user_id', userId)
        .maybeSingle();

    return response != null ? NotificationModel.fromJson(response) : null;
  }

  /// Mark single notification as read
  Future<void> markAsRead({
    required String id,
    required String userId,
  }) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('recipient_user_id', userId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({required String userId}) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_user_id', userId)
        .eq('is_read', false)
        .eq('category',
            'notifications'); // ✅ Only mark inbox notifications, not ephemeral push
  }

  /// Get unread notification count
  Future<int> getUnreadCount({required String userId}) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_user_id', userId)
        .eq('is_read', false)
        .eq('category',
            'notifications') // ✅ CRITICAL: Exclude ephemeral 'push' notifications
        .count();

    return response.count;
  }

  /// Delete single notification
  Future<void> deleteNotification({
    required String id,
    required String userId,
  }) async {
    await _client
        .from('notifications')
        .delete()
        .eq('id', id)
        .eq('recipient_user_id', userId);
  }

  /// Real-time stream of notifications
  Stream<List<NotificationModel>> watchNotifications({
    required String userId,
    int limit = 50,
  }) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) =>
            data.map((json) => NotificationModel.fromJson(json)).toList());
  }
}
