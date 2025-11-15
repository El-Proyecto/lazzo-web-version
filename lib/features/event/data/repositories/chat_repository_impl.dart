import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/chat_remote_data_source.dart';

/// Implementation of ChatRepository using Supabase
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);
  
  @override
  Stream<List<ChatMessage>> watchMessages(String eventId) async* {
    if (kDebugMode) {
      print('🔄 [ChatRepository] watchMessages stream started for event: $eventId');
    }
    
    await for (final models in _remoteDataSource.watchMessages(eventId)) {
      if (kDebugMode) {
        print('📨 [ChatRepository] Received ${models.length} models from data source');
      }
      
      // Build a map of all messages by ID for fast lookup (for replyTo)
      final messagesById = <String, ChatMessage>{};
      
      // First pass: convert all models to entities (without replyTo)
      for (final model in models) {
        messagesById[model.id] = model.toEntity();
      }
      
      // Second pass: populate replyTo references
      final messagesWithReplies = <ChatMessage>[];
      for (final model in models) {
        final baseMessage = messagesById[model.id]!;
        
        // If this message has a reply_to_id, find the referenced message
        final replyTo = model.replyToId != null 
            ? messagesById[model.replyToId]
            : null;
        
        messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
      }
      
      if (kDebugMode) {
        print('✅ [ChatRepository] Yielding ${messagesWithReplies.length} entities to provider');
      }
      yield messagesWithReplies;
    }
  }

  /// DEPRECATED: Use watchMessages instead
  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 2,
  }) async {
    if (kDebugMode) {
      print('🔍 DEBUG ChatRepository: Getting recent messages for eventId=$eventId, limit=$limit');
    }
    final models = await _remoteDataSource.getRecentMessages(
      eventId,
      limit: limit,
    );
    
    if (kDebugMode) {
      print('📊 DEBUG: getRecentMessages returned ${models.length} models');
    }
    
    // Build a map of all messages by ID for fast lookup (for replyTo)
    final messagesById = <String, ChatMessage>{};
    
    // First pass: convert all models to entities (without replyTo)
    for (final model in models) {
      messagesById[model.id] = model.toEntity();
      if (kDebugMode) {
        print('  - Message ${model.id.substring(0, 8)}: isPinned=${model.isPinned}, isDeleted=${model.isDeleted}, replyToId=${model.replyToId?.substring(0, 8) ?? "null"}');
      }
    }
    
    // Second pass: populate replyTo references
    final messagesWithReplies = <ChatMessage>[];
    for (final model in models) {
      final baseMessage = messagesById[model.id]!;
      
      // If this message has a reply_to_id, find the referenced message
      final replyTo = model.replyToId != null 
          ? messagesById[model.replyToId]
          : null;
      
      if (replyTo != null) {
        if (kDebugMode) {
          print('  ✅ Populated replyTo for message ${model.id.substring(0, 8)}');
        }
      }
      
      messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
    }
    
    if (kDebugMode) {
      print('✅ DEBUG ChatRepository: Returning ${messagesWithReplies.length} messages with replies populated');
    }
    return messagesWithReplies;
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  }) async {
    if (kDebugMode) {
      print('🔍 DEBUG ChatRepository: Sending message to eventId=$eventId, userId=$userId, content="$content", replyToId=${replyTo?.id}');
    }
    final model = await _remoteDataSource.sendMessage(
      eventId,
      userId,
      content,
      replyToId: replyTo?.id,
    );
    final message = model.toEntity();
    if (kDebugMode) {
      print('✅ DEBUG ChatRepository: Message sent with id=${message.id}');
    }
    return message;
  }

  /// DEPRECATED: Use watchMessages instead
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    if (kDebugMode) {
      print('🔍 DEBUG ChatRepository: Getting ALL messages for eventId=$eventId');
    }
    final models = await _remoteDataSource.getAllMessages(eventId);
    
    if (kDebugMode) {
      print('📊 DEBUG: getAllMessages returned ${models.length} models');
    }
    
    // Build a map of all messages by ID for fast lookup
    final messagesById = <String, ChatMessage>{};
    
    // First pass: convert all models to entities (without replyTo)
    for (final model in models) {
      messagesById[model.id] = model.toEntity();
      if (kDebugMode) {
        print('  - Message ${model.id.substring(0, 8)}: isPinned=${model.isPinned}, isDeleted=${model.isDeleted}, replyToId=${model.replyToId?.substring(0, 8) ?? "null"}');
      }
    }
    
    // Second pass: populate replyTo references
    final messagesWithReplies = <ChatMessage>[];
    for (final model in models) {
      final baseMessage = messagesById[model.id]!;
      
      // If this message has a reply_to_id, find the referenced message
      final replyTo = model.replyToId != null 
          ? messagesById[model.replyToId]
          : null;
      
      if (replyTo != null) {
        if (kDebugMode) {
          print('  ✅ Populated replyTo for message ${model.id.substring(0, 8)} -> ${model.replyToId!.substring(0, 8)}');
        }
      }
      
      messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
    }
    
    if (kDebugMode) {
      print('✅ DEBUG ChatRepository: Returning ${messagesWithReplies.length} messages with replies populated');
    }
    return messagesWithReplies;
  }

  @override
  Future<ChatMessage> pinMessage(String eventId, String messageId, bool isPinned) async {
    if (kDebugMode) {
      print('🔍 DEBUG ChatRepository: Pinning message $messageId, isPinned=$isPinned');
    }
    
    await _remoteDataSource.pinMessage(messageId, eventId, isPinned);
    
    // Reload the message to get updated state
    final updatedMessages = await _remoteDataSource.getAllMessages(eventId);
    final updatedMessage = updatedMessages.firstWhere((m) => m.id == messageId);
    
    if (kDebugMode) {
      print('✅ DEBUG ChatRepository: Message pinned');
    }
    return updatedMessage.toEntity();
  }

  @override
  Future<ChatMessage> deleteMessage(String eventId, String messageId) async {
    if (kDebugMode) {
      print('🔍 DEBUG ChatRepository: Deleting message $messageId');
    }
    
    await _remoteDataSource.deleteMessage(messageId);
    
    // Reload to get updated state
    final updatedMessages = await _remoteDataSource.getAllMessages(eventId);
    final updatedMessage = updatedMessages.firstWhere((m) => m.id == messageId);
    
    if (kDebugMode) {
      print('✅ DEBUG ChatRepository: Message deleted');
    }
    return updatedMessage.toEntity();
  }
}
