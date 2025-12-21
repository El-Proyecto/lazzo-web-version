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
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
            return models;
    } catch (e, stackTrace) {
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

    return response != null
        ? NotificationModel.fromJson(response)
        : null;
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
        .eq('is_read', false);
  }

  /// Get unread notification count
  Future<int> getUnreadCount({required String userId}) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_user_id', userId)
        .eq('is_read', false)
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
        .map((data) => data
            .map((json) => NotificationModel.fromJson(json))
            .toList());
  }

  /// Create notification manually (programmatic usage)
  /// Note: Most notifications should be created via DB triggers
  Future<String?> createNotification({
    required String recipientUserId,
    required String title,
    required String description,
    required String type,
    required String category,
    String priority = 'medium',
    String? actionText,
    String? actionUrl,
    String? deeplink,
    String? groupId,
    String? eventId,
    String? eventEmoji,
    String? userName,
    String? groupName,
    String? eventName,
    String? amount,
    String? hours,
    String? mins,
    String? date,
    String? time,
    String? place,
    String? device,
    String? note,
  }) async {
    try {
      // Use RPC function that includes deduplication check
      final response = await _client.rpc('create_notification_if_not_duplicate',
          params: {
            'p_recipient_user_id': recipientUserId,
            'p_type': type,
            'p_title': title,
            'p_description': description,
            'p_category': category,
            'p_priority': priority,
            'p_action_text': actionText,
            'p_action_url': actionUrl,
            'p_deeplink': deeplink,
            'p_group_id': groupId,
            'p_event_id': eventId,
            'p_event_emoji': eventEmoji,
            'p_user_name': userName,
            'p_group_name': groupName,
            'p_event_name': eventName,
            'p_amount': amount,
            'p_hours': hours,
            'p_mins': mins,
            'p_date': date,
            'p_time': time,
            'p_place': place,
            'p_device': device,
            'p_note': note,
          });

      return response as String?; // Returns notification ID or null if duplicate
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }
}
