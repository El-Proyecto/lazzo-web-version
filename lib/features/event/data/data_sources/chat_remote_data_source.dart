import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// Remote data source for chat operations
/// Handles all Supabase queries related to event chat messages
class ChatRemoteDataSource {
  final SupabaseClient _supabaseClient;
  static const String _profileBucket = 'users-profile-pic';

  ChatRemoteDataSource(this._supabaseClient);

  /// Convert avatar storage path to signed URL (private bucket)
  Future<String?> _getSignedUrlForAvatar(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    
    // Already a URL
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }
    
    // Create signed URL for storage path
    try {
      return await _supabaseClient.storage
          .from(_profileBucket)
          .createSignedUrl(avatarPath, 3600); // 1 hour validity
    } catch (e) {
      print('⚠️ [ChatDataSource] Failed to create signed URL: $e');
      return null;
    }
  }

  /// Get recent messages for an event (default: 2 messages)
  Future<List<ChatMessageModel>> getRecentMessages(
    String eventId, {
    int limit = 2,
  }) async {
    try {
      final response = await _supabaseClient
          .from('chat_messages')
          .select('''
            id,
            event_id,
            user_id,
            content,
            read,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Convert storage paths to signed URLs for avatar_url (private bucket)
      final messages = response as List;
      for (var json in messages) {
        if (json['user'] != null && json['user']['avatar_url'] != null) {
          json['user']['avatar_url'] = await _getSignedUrlForAvatar(json['user']['avatar_url']);
        }
      }
      return messages.map((json) => ChatMessageModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get recent messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get recent messages: $e');
    }
  }

  /// Send a message
  Future<ChatMessageModel> sendMessage(
    String eventId,
    String userId,
    String content,
  ) async {
    try {
      final response = await _supabaseClient
          .from('chat_messages')
          .insert({
            'event_id': eventId,
            'user_id': userId,
            'content': content,
            'read': false,
          })
          .select('''
            id,
            event_id,
            user_id,
            content,
            read,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .single();

      // Convert avatar storage path to signed URL
      if (response['user'] != null && response['user']['avatar_url'] != null) {
        response['user']['avatar_url'] = await _getSignedUrlForAvatar(response['user']['avatar_url']);
      }

      return ChatMessageModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all messages for an event
  Future<List<ChatMessageModel>> getAllMessages(String eventId) async {
    try {
      final response = await _supabaseClient
          .from('chat_messages')
          .select('''
            id,
            event_id,
            user_id,
            content,
            read,
            created_at,
            user:user_id(id, name, avatar_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      // Convert storage paths to signed URLs for avatar_url (private bucket)
      final messages = response as List;
      for (var json in messages) {
        if (json['user'] != null && json['user']['avatar_url'] != null) {
          json['user']['avatar_url'] = await _getSignedUrlForAvatar(json['user']['avatar_url']);
        }
      }
      return messages.map((json) => ChatMessageModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get all messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get all messages: $e');
    }
  }
}
