import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_invite_link_model.dart';

class GroupInviteRemoteDataSource {
  final SupabaseClient _client;
  
  // In-memory cache: groupId -> (model, timestamp)
  final Map<String, ({GroupInviteLinkModel model, DateTime cachedAt})> _cache = {};

  GroupInviteRemoteDataSource(this._client);

  Future<GroupInviteLinkModel> createInviteLink({
    required String groupId,
    int? maxUses,
    int expiresInHours = 48,
  }) async {
    // Check cache first (valid for 5 minutes to reduce RPC calls)
    final cached = _cache[groupId];
    if (cached != null) {
      final cacheAge = DateTime.now().difference(cached.cachedAt);
      if (cacheAge.inMinutes < 5 && cached.model.expiresAt.isAfter(DateTime.now())) {
        return cached.model;
      }
    }

    // Call RPC to get or create token
    final response = await _client.rpc(
      'get_or_create_group_invite_link',
      params: {
        'p_group_id': groupId,
        'p_expires_in_hours': expiresInHours,
      },
    );

    Map<String, dynamic>? data;

    // Parse response
    try {
      if (response is List && response.isNotEmpty) {
        final first = response.first;
        if (first is Map<String, dynamic>) {
          data = first;
        } else if (first is Map) {
          data = Map<String, dynamic>.from(first);
        } else if (first is String) {
          data = {
            'token': first,
            'expires_at': DateTime.now()
                .add(Duration(hours: expiresInHours))
                .toIso8601String()
          };
        }
      } else if (response is Map<String, dynamic>) {
        data = response;
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response);
      } else if (response is String && response.isNotEmpty) {
        data = {
          'token': response,
          'expires_at': DateTime.now()
              .add(Duration(hours: expiresInHours))
              .toIso8601String()
        };
      }
    } catch (e) {
      throw Exception('Failed to parse invite link response: $e');
    }

    if (data != null && data.containsKey('token')) {
      final model = GroupInviteLinkModel.fromJson(data);
      
      // Validate token is URL-safe
      if (model.token.contains('/') || model.token.contains('+') || model.token.contains('=')) {
        throw Exception('Invalid token format: contains non-URL-safe characters');
      }
      
      // Cache the result
      _cache[groupId] = (model: model, cachedAt: DateTime.now());
      
      return model;
    }

    throw Exception('Failed to get or create invite link — unexpected RPC response: $response');
  }
  
  /// Clear cache for a specific group (useful after revoking invite)
  void clearCache(String groupId) {
    _cache.remove(groupId);
  }
  
  /// Clear all cached invites
  void clearAllCache() {
    _cache.clear();
  }

  Future<String> acceptInviteByToken(String token) async {
    
    try {
      final response = await _client.rpc(
        'accept_group_invite_by_token',
        params: {'p_token': token},
      );


      // Common shapes: plain string groupId, list with map, or map
      if (response is String && response.isNotEmpty) {
        return response;
      }

      if (response is List && response.isNotEmpty) {
        final first = response.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
        if (first is Map && first.containsKey('group_id')) {
          final groupId = first['group_id'] as String;
          return groupId;
        }
      }

      if (response is Map && response.containsKey('group_id')) {
        final groupId = response['group_id'] as String;
        return groupId;
      }

      throw Exception('Failed to accept invite — unexpected RPC response');
    } catch (e) {
      rethrow;
    }
  }
}
