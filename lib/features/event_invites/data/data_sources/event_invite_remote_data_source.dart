import 'package:lazzo/core/utils/date_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_invite_link_model.dart';

class EventInviteRemoteDataSource {
  final SupabaseClient _client;

  // In-memory cache: eventId -> (model, timestamp)
  final Map<String, ({EventInviteLinkModel model, DateTime cachedAt})> _cache =
      {};

  EventInviteRemoteDataSource(this._client);

  Future<EventInviteLinkModel> createInviteLink({
    required String eventId,
    int expiresInHours = 48,
    String? shareChannel,
  }) async {
    // Check cache first (valid for 5 minutes to reduce RPC calls)
    final cached = _cache[eventId];
    if (cached != null) {
      final cacheAge = DateTime.now().difference(cached.cachedAt);
      if (cacheAge.inMinutes < 5 &&
          cached.model.expiresAt.isAfter(DateTime.now())) {
        return cached.model;
      }
    }

    try {
      final params = <String, dynamic>{
        'p_event_id': eventId,
        'p_expires_in_hours': expiresInHours,
      };
      if (shareChannel != null) {
        params['p_share_channel'] = shareChannel;
      }

      final response = await _client.rpc(
        'get_or_create_event_invite_link',
        params: params,
      );

      Map<String, dynamic>? data;

      // Parse response – the RPC may return different shapes depending
      // on PostgREST version / function signature.
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
                  .toSupabaseIso8601String(),
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
                .toSupabaseIso8601String(),
          };
        }
      } catch (e) {
        throw Exception('Failed to parse event invite link response: $e');
      }

      if (data != null && data.containsKey('token')) {
        final model = EventInviteLinkModel.fromJson(data);

        // Validate token is URL-safe
        if (model.token.contains('/') ||
            model.token.contains('+') ||
            model.token.contains('=')) {
          throw Exception(
              'Invalid token format: contains non-URL-safe characters');
        }

        // Cache the result
        _cache[eventId] = (model: model, cachedAt: DateTime.now());

        return model;
      }

      throw Exception(
          'Failed to get or create event invite link — unexpected RPC response: $response');
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cache for a specific event (useful after revoking invite)
  void clearCache(String eventId) {
    _cache.remove(eventId);
  }

  /// Clear all cached invites
  void clearAllCache() {
    _cache.clear();
  }
}
