import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const String _avatarBucketName = 'users-profile-pic';

  SupabaseGroupEventDataSource(this._client);

  /// Convert storage path to authenticated URL for private bucket
  /// Returns empty string if path is null/empty
  /// Uses createSignedUrl for private bucket access with 1 hour expiry
  /// Normalizes storage path by removing leading slashes
  Future<String> _getAuthenticatedAvatarUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) {
      return '';
    }

    // Already a full URL, return as is
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    try {
      // Normalize path - remove leading slash if present
      final normalizedPath = storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;
      
      // Storage path - convert to signed URL for private bucket
      // Valid for 1 hour (3600 seconds)
      final url = await _client.storage
          .from(_avatarBucketName)
          .createSignedUrl(normalizedPath, 3600);
      return url;
    } catch (e) {
      return '';
    }
  }

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

      // Enrich each event with current_user_rsvp field and convert avatar URLs
      for (final event in events) {
        if (currentUserId != null) {
          event['current_user_rsvp'] =
              _getCurrentUserRsvp(event, currentUserId);
        }

        // Convert avatar URLs in all user arrays
        await _convertAvatarUrlsInUserArray(event, 'going_users');
        await _convertAvatarUrlsInUserArray(event, 'not_going_users');
        await _convertAvatarUrlsInUserArray(event, 'no_response_users');
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Helper to convert avatar URLs in a user array within an event
  Future<void> _convertAvatarUrlsInUserArray(
      Map<String, dynamic> event, String arrayKey) async {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic> && user['avatar_url'] != null) {
        user['avatar_url'] =
            await _getAuthenticatedAvatarUrl(user['avatar_url']);
      }
    }
  }

  /// Helper to determine current user's RSVP status from event arrays
  String _getCurrentUserRsvp(Map<String, dynamic> event, String userId) {
    // Check going_users
    final goingUsers = event['going_users'] as List? ?? [];
    for (final user in goingUsers) {
      if (user['user_id'] == userId) {
        return 'going';
      }
    }

    // Check not_going_users
    final notGoingUsers = event['not_going_users'] as List? ?? [];
    for (final user in notGoingUsers) {
      if (user['user_id'] == userId) {
        return 'not_going';
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

        // Convert avatar URLs in all user arrays (same as getGroupEvents)
        await _convertAvatarUrlsInUserArray(response, 'going_users');
        await _convertAvatarUrlsInUserArray(response, 'not_going_users');
        await _convertAvatarUrlsInUserArray(response, 'no_response_users');
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

      final allVotes = <Map<String, dynamic>>[];

      // Add going votes
      for (final user in goingUsers) {
        final userId = user['user_id'];
        final userName =
            user['name'] ?? user['full_name'] ?? user['display_name'] ?? 'User';
        final rawAvatar = user['avatar_url'];

        // Convert storage path to authenticated URL
        final userAvatar = await _getAuthenticatedAvatarUrl(rawAvatar);

        allVotes.add({
          'user_id': userId,
          'user_name': userName,
          'user_avatar': userAvatar,
          'status': 'going',
          'voted_at': user['voted_at'],
        });
      }

      // Add not going votes
      for (final user in notGoingUsers) {
        final userName =
            user['name'] ?? user['full_name'] ?? user['display_name'] ?? 'User';
        final rawAvatar = user['avatar_url'];
        final userAvatar = await _getAuthenticatedAvatarUrl(rawAvatar);

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
        final rawAvatar = user['avatar_url'];
        final userAvatar = await _getAuthenticatedAvatarUrl(rawAvatar);

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
