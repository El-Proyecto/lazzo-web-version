import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/avatar_cache_service.dart';

/// Data source for group events from Supabase
abstract class GroupEventDataSource {
  /// Get all events for a specific group using optimized view
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId);

  /// Get a specific event by ID with all RSVP details
  Future<Map<String, dynamic>?> getEventById(String eventId);

  /// Get all RSVP votes for a specific event
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId);
}

/// Supabase implementation using group_hub_events_view
class SupabaseGroupEventDataSource implements GroupEventDataSource {
  final SupabaseClient _client;
  final AvatarCacheService _avatarCache = AvatarCacheService();

  SupabaseGroupEventDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select()
          .eq('group_id', groupId)
          .neq('computed_status', 'ended')
          .order('priority', ascending: false)
          .order('start_datetime', ascending: true);

      final events = List<Map<String, dynamic>>.from(response as List);

      // Get current user ID to determine their vote status
      final currentUserId = _client.auth.currentUser?.id;

      // ✅ OPTIMIZATION: Collect all unique avatar paths first
      final avatarPaths = <String>{};
      for (final event in events) {
        _collectAvatarPaths(event, 'going_users', avatarPaths);
        _collectAvatarPaths(event, 'not_going_users', avatarPaths);
        _collectAvatarPaths(event, 'no_response_users', avatarPaths);
      }

      // ✅ Batch fetch all avatar signed URLs in parallel
      final signedUrls = await _avatarCache.batchGetAvatarUrls(
        _client,
        avatarPaths.toList(),
      );

      // Enrich each event with current_user_rsvp field and apply cached avatar URLs
      for (final event in events) {
        if (currentUserId != null) {
          event['current_user_rsvp'] =
              _getCurrentUserRsvp(event, currentUserId);
        }

        // ✅ Apply cached signed URLs to all user arrays
        _applyAvatarUrls(event, 'going_users', signedUrls);
        _applyAvatarUrls(event, 'not_going_users', signedUrls);
        _applyAvatarUrls(event, 'no_response_users', signedUrls);
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Collect unique avatar paths from a user array
  void _collectAvatarPaths(
      Map<String, dynamic> event, String arrayKey, Set<String> paths) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic>) {
        final avatarPath = user['avatar_url'] as String?;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          paths.add(avatarPath);
        }
      }
    }
  }

  /// Apply cached signed URLs to a user array
  void _applyAvatarUrls(Map<String, dynamic> event, String arrayKey,
      Map<String, String> signedUrls) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic>) {
        final avatarPath = user['avatar_url'] as String?;
        if (avatarPath != null && signedUrls.containsKey(avatarPath)) {
          user['avatar_url'] = signedUrls[avatarPath];
        }
      }
    }
  }

  /// Helper to determine current user's RSVP status from event arrays
  String _getCurrentUserRsvp(Map<String, dynamic> event, String userId) {
    // Check going_users
    final goingUsers = event['going_users'] as List? ?? [];
    for (final user in goingUsers) {
      if (user['user_id'] == userId) {
        return 'yes';
      }
    }

    // Check not_going_users
    final notGoingUsers = event['not_going_users'] as List? ?? [];
    for (final user in notGoingUsers) {
      if (user['user_id'] == userId) {
        return 'no';
      }
    }

    // Check no_response_users
    final noResponseUsers = event['no_response_users'] as List? ?? [];
    for (final user in noResponseUsers) {
      if (user['user_id'] == userId) {
        return 'pending';
      }
    }

    // User not found in any array
    return 'pending';
  }

  /// Helper to get current user's avatar URL from event arrays
  String? getCurrentUserAvatar(Map<String, dynamic> event, String userId) {
    // Check all user arrays for current user's avatar
    final allUserArrays = [
      event['going_users'] as List? ?? [],
      event['not_going_users'] as List? ?? [],
      event['no_response_users'] as List? ?? [],
    ];

    for (final users in allUserArrays) {
      for (final user in users) {
        if (user['user_id'] == userId) {
          return user['avatar_url'];
        }
      }
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select()
          .eq('event_id', eventId)
          .maybeSingle();

      if (response != null) {
        // Get current user ID to determine their vote status
        final currentUserId = _client.auth.currentUser?.id;
        if (currentUserId != null) {
          response['current_user_rsvp'] =
              _getCurrentUserRsvp(response, currentUserId);
        }

        // ✅ OPTIMIZATION: Batch convert avatar URLs
        final avatarPaths = <String>{};
        _collectAvatarPaths(response, 'going_users', avatarPaths);
        _collectAvatarPaths(response, 'not_going_users', avatarPaths);
        _collectAvatarPaths(response, 'no_response_users', avatarPaths);

        final signedUrls = await _avatarCache.batchGetAvatarUrls(
          _client,
          avatarPaths.toList(),
        );

        _applyAvatarUrls(response, 'going_users', signedUrls);
        _applyAvatarUrls(response, 'not_going_users', signedUrls);
        _applyAvatarUrls(response, 'no_response_users', signedUrls);
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId) async {
    try {
      // Get all votes from going_users, not_going_users, and no_response_users
      final event = await getEventById(eventId);
      if (event == null) return [];

      final goingUsers = event['going_users'] as List? ?? [];
      final notGoingUsers = event['not_going_users'] as List? ?? [];
      final noResponseUsers = event['no_response_users'] as List? ?? [];

      // ✅ OPTIMIZATION: Avatar URLs are already converted by getEventById batch processing
      // No need to call _getAuthenticatedAvatarUrl here
      final allVotes = <Map<String, dynamic>>[];

      // Add going votes
      for (final user in goingUsers) {
        final userId = user['user_id'];
        final userName =
            user['name'] ?? user['full_name'] ?? user['display_name'] ?? 'User';
        final userAvatar = user['avatar_url']; // ✅ Already signed URL

        allVotes.add({
          'user_id': userId,
          'user_name': userName,
          'user_avatar': userAvatar,
          'status': 'yes',
          'voted_at': user['voted_at'],
        });
      }

      // Add not going votes
      for (final user in notGoingUsers) {
        final userName =
            user['name'] ?? user['full_name'] ?? user['display_name'] ?? 'User';
        final userAvatar = user['avatar_url']; // ✅ Already signed URL

        allVotes.add({
          'user_id': user['user_id'],
          'user_name': userName,
          'user_avatar': userAvatar,
          'status': 'notGoing',
          'voted_at': user['voted_at'],
        });
      }

      // Add pending votes
      for (final user in noResponseUsers) {
        final userName =
            user['name'] ?? user['full_name'] ?? user['display_name'] ?? 'User';
        final userAvatar = user['avatar_url']; // ✅ Already signed URL

        allVotes.add({
          'user_id': user['user_id'],
          'user_name': userName,
          'user_avatar': userAvatar,
          'status': 'pending',
          'voted_at': null,
        });
      }

      return allVotes;
    } catch (e) {
      return [];
    }
  }
}
