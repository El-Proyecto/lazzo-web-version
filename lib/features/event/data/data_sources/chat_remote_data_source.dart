import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// Remote data source for chat operations
/// Handles all Supabase queries related to event chat messages
class ChatRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ChatRemoteDataSource(this._supabaseClient);

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
            user:user_id(id, name, profile_picture_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
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
            user:user_id(id, name, profile_picture_url)
          ''')
          .single();

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
            user:user_id(id, name, profile_picture_url)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get all messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get all messages: $e');
    }
  }
}
