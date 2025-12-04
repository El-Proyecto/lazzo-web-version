import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';

/// Remote data source for chat operations
/// Handles all Supabase queries related to event chat messages
class ChatRemoteDataSource {
  final SupabaseClient _supabaseClient;
  static const String _profileBucket = 'users-profile-pic';
  final Map<String, StreamController<List<ChatMessageModel>>> _messageStreams = {};
  final Map<String, Timer?> _debounceTimers = {};  // ⚡ Debounce timers

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
      if (kDebugMode) {
        print('⚠️ [ChatDataSource] Failed to create signed URL: $e');
      }
      return null;
    }
  }

  /// Watch messages in real-time for an event
  Stream<List<ChatMessageModel>> watchMessages(String eventId) async* {
    
    // Create stream controller if not exists
    if (!_messageStreams.containsKey(eventId)) {
      _messageStreams[eventId] = StreamController<List<ChatMessageModel>>.broadcast();
      
      // Initial fetch
      _fetchAndEmitMessages(eventId);
      
      // Subscribe to realtime updates
      _supabaseClient
          .channel('chat_messages_$eventId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'event_id', value: eventId),
            callback: (payload) {
              // Refetch all messages on any change
              _fetchAndEmitMessages(eventId);
            },
          )
          .subscribe();
      
    }
    
    yield* _messageStreams[eventId]!.stream;
  }
  
  /// Fetch and emit messages to stream
  void _fetchAndEmitMessages(String eventId) {
    // ⚡ Debounce: cancel previous timer and set new one
    _debounceTimers[eventId]?.cancel();
    _debounceTimers[eventId] = Timer(const Duration(milliseconds: 150), () async {
      try {
        final response = await _supabaseClient
            .from('chat_messages')
            .select('''
              id,
              event_id,
              user_id,
              content,
              read,
              reply_to_id,
              is_pinned,
              is_deleted,
              created_at,
              user:user_id(id, name, avatar_url)
            ''')
            .eq('event_id', eventId)
            .order('created_at', ascending: false)
            .limit(50);  // ⚡ LIMIT to 50 messages for performance
      
      // Convert storage paths to signed URLs for avatar_url
      final messages = response as List;
      for (var json in messages) {
        if (json['user'] != null && json['user']['avatar_url'] != null) {
          json['user']['avatar_url'] = await _getSignedUrlForAvatar(json['user']['avatar_url']);
        }
      }
      
        final models = messages.map((json) => ChatMessageModel.fromJson(json)).toList();
        _messageStreams[eventId]?.add(models);
      } catch (e) {
        if (kDebugMode) {
          print('❌ [ChatDataSource] Error fetching messages: $e');
        }
        _messageStreams[eventId]?.addError(e);
      }
    });
  }

  /// Get recent messages for an event (default: 2 messages)
  /// DEPRECATED: Use watchMessages instead for real-time updates
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
            reply_to_id,
            is_pinned,
            is_deleted,
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
    String content, {
    String? replyToId,
  }) async {
    
    try {
      final insertData = {
        'event_id': eventId,
        'user_id': userId,
        'content': content,
        'read': false,
      };
      
      // Only add reply_to_id if it's provided
      if (replyToId != null) {
        insertData['reply_to_id'] = replyToId;
      }
      
      
      final response = await _supabaseClient
          .from('chat_messages')
          .insert(insertData)
          .select('''
            id,
            event_id,
            user_id,
            content,
            read,
            reply_to_id,
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
            reply_to_id,
            is_pinned,
            is_deleted,
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

  /// Pin or unpin a message
  /// Uses RPC function to ensure atomic unpin-others + pin-target
  Future<void> pinMessage(String messageId, String eventId, bool isPinned) async {
    try {
      if (isPinned) {
        // Call RPC to ensure only 1 pinned message per event
        await _supabaseClient.rpc('pin_chat_message', params: {
          'message_id': messageId,
          'event_id': eventId,
          'should_pin': true,
        });
      } else {
        // Simple update to unpin
        await _supabaseClient
            .from('chat_messages')
            .update({'is_pinned': false, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', messageId);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to pin message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to pin message: $e');
    }
  }

  /// Soft delete a message
  /// Marks message as deleted but preserves it for reply chains
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabaseClient.rpc('soft_delete_chat_message', params: {
        'message_id': messageId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
