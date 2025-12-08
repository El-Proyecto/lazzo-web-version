import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching other user profiles and shared data from Supabase
/// Queries users table, events, and group_members to find shared context
class OtherProfileDataSource {
  final SupabaseClient _client;

  OtherProfileDataSource(this._client);

  /// Get other user's profile information from users table
  /// Returns raw profile data including avatar_url
  Future<Map<String, dynamic>> getOtherUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select('id, name, avatar_url, city, birth_date')
        .eq('id', userId)
        .single();

    return response;
  }

  /// Get shared memories between current user and target user
  /// Logic:
  /// 1. Find all groups where both users are members
  /// 2. Get events from those shared groups with status='recap'
  /// 3. Return events with cover photos as memories
  Future<List<Map<String, dynamic>>> getSharedMemories({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Step 1: Get groups where current user is member
    final currentUserGroups = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', currentUserId);

    final currentGroupIds = (currentUserGroups as List)
        .map((g) => g['group_id'] as String)
        .toSet();

    if (currentGroupIds.isEmpty) {
      return [];
    }

    // Step 2: Get groups where target user is also member (intersection)
    final targetUserGroups = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', targetUserId)
        .inFilter('group_id', currentGroupIds.toList());

    final sharedGroupIds = (targetUserGroups as List)
        .map((g) => g['group_id'] as String)
        .toList();

    if (sharedGroupIds.isEmpty) {
      return [];
    }

    // Step 3: Get recap events from shared groups with cover photos
    final events = await _client
        .from('events')
        .select('id, name, emoji, end_datetime, cover_photo_id, locations!inner(display_name), group_photos!cover_photo_id(storage_path)')
        .inFilter('group_id', sharedGroupIds)
        .eq('status', 'recap')
        .not('cover_photo_id', 'is', null)
        .order('end_datetime', ascending: false)
        .limit(50);

    // Map to include storage path for cover photos
    return (events as List).map((event) {
      return {
        'id': event['id'],
        'title': event['name'],
        'emoji': event['emoji'],
        'date': event['end_datetime'],
        'location': event['locations']?['display_name'],
        'cover_storage_path': event['group_photos']?['storage_path'],
      };
    }).toList();
  }

  /// Get upcoming events in shared groups
  /// Returns events with status='confirmed' or 'living' from mutual groups
  Future<List<Map<String, dynamic>>> getSharedUpcomingEvents({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Get shared group IDs (same logic as memories)
    final currentUserGroups = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', currentUserId);

    final currentGroupIds = (currentUserGroups as List)
        .map((g) => g['group_id'] as String)
        .toSet();

    if (currentGroupIds.isEmpty) {
      return [];
    }

    final targetUserGroups = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', targetUserId)
        .inFilter('group_id', currentGroupIds.toList());

    final sharedGroupIds = (targetUserGroups as List)
        .map((g) => g['group_id'] as String)
        .toList();

    if (sharedGroupIds.isEmpty) {
      return [];
    }

    // Get confirmed/living events
    final events = await _client
        .from('events')
        .select('id, name, emoji, start_datetime, end_datetime, status, locations(display_name)')
        .inFilter('group_id', sharedGroupIds)
        .inFilter('status', ['confirmed', 'living'])
        .gte('start_datetime', DateTime.now().toIso8601String())
        .order('start_datetime', ascending: true)
        .limit(20);

    return (events as List).cast<Map<String, dynamic>>();
  }

  /// Get groups where current user can invite target user
  /// Returns groups where:
  /// - Current user is member
  /// - Target user is NOT member
  /// - Current user has permission to invite (members_can_invite=true OR current user is admin)
  Future<List<Map<String, dynamic>>> getInvitableGroups({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Get groups where current user is member
    final currentUserGroups = await _client
        .from('group_members')
        .select('group_id, role')
        .eq('user_id', currentUserId);

    if ((currentUserGroups as List).isEmpty) {
      return [];
    }

    final currentGroupIds = currentUserGroups
        .map((g) => g['group_id'] as String)
        .toList();

    // Get groups where target user is already member
    final targetUserGroups = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', targetUserId)
        .inFilter('group_id', currentGroupIds);

    final targetGroupIds = (targetUserGroups as List)
        .map((g) => g['group_id'] as String)
        .toSet();

    // Filter out groups where target is already member
    final eligibleGroupIds = currentGroupIds
        .where((id) => !targetGroupIds.contains(id))
        .toList();

    if (eligibleGroupIds.isEmpty) {
      return [];
    }

    // Get group details for eligible groups
    final groups = await _client
        .from('groups')
        .select('id, name, photo_url, members_can_invite')
        .inFilter('id', eligibleGroupIds);

    // Filter based on permissions
    final invitableGroups = <Map<String, dynamic>>[];
    for (final group in groups as List) {
      final groupId = group['id'] as String;
      
      // Check if members can invite or current user is admin
      final membersCanInvite = group['members_can_invite'] as bool? ?? false;
      
      if (membersCanInvite) {
        invitableGroups.add(group);
      } else {
        // Check if current user is admin
        final membership = currentUserGroups.firstWhere(
          (m) => m['group_id'] == groupId,
          orElse: () => {},
        );
        
        if (membership['role'] == 'admin') {
          invitableGroups.add(group);
        }
      }
    }

    return invitableGroups;
  }

  /// Send group invitation
  /// Creates entry in group_invites table
  Future<void> inviteToGroup({
    required String userId,
    required String groupId,
    required String invitedBy,
  }) async {
    await _client.from('group_invites').insert({
      'group_id': groupId,
      'invited_id': userId,
      'invited_by': invitedBy,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
