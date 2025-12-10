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
    print('\n🔴 [OtherProfileDataSource] ====== DATA SOURCE CALLED ======');
    print('🔴 [OtherProfileDataSource] Current user: $currentUserId');
    print('🔴 [OtherProfileDataSource] Target user: $targetUserId');
    
    try {
      // Step 1: Get groups where current user is member
      final currentUserGroups = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUserId);

      if ((currentUserGroups as List).isEmpty) {
        print('[OtherProfile] Current user has no groups');
        return [];
      }

      final currentGroupIds = currentUserGroups
          .map((g) => g['group_id'] as String)
          .toList();

      print('[OtherProfile] Current user is in ${currentGroupIds.length} groups');

      // Step 2: Get groups where target user is also member (intersection)
      final targetUserGroups = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', targetUserId)
          .inFilter('group_id', currentGroupIds);

      final sharedGroupIds = (targetUserGroups as List)
          .map((g) => g['group_id'] as String)
          .toList();

      if (sharedGroupIds.isEmpty) {
        print('[OtherProfile] No shared groups found');
        return [];
      }

      print('[OtherProfile] Found ${sharedGroupIds.length} shared groups');

      // Step 3: Query events for shared groups with status 'recap' or 'ended'
      // Following EXACT same logic as profile_memory_data_source.dart
      final eventsResponse = await _client
          .from('events')
          .select('''
            id,
            name,
            end_datetime,
            locations (
              display_name
            ),
            cover_photo_id
          ''')
          .inFilter('group_id', sharedGroupIds)
          .inFilter('status', ['recap', 'ended'])
          .order('end_datetime', ascending: false);

      if ((eventsResponse as List).isEmpty) {
        print('[OtherProfile] No recap/ended events found in shared groups');
        return [];
      }

      print('[OtherProfile] Found ${eventsResponse.length} recap/ended events');

      // Step 4: Process each event to add cover photo (same logic as profile)
      final List<Map<String, dynamic>> memoriesWithCovers = [];
      
      for (final event in eventsResponse) {
        final eventMap = Map<String, dynamic>.from(event);
        String? coverStoragePath;

        final eventId = eventMap['id'] as String;
        final coverPhotoId = eventMap['cover_photo_id'] as String?;

        // Try 1: Use cover_photo_id if set
        if (coverPhotoId != null) {
          try {
            final coverResponse = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('id', coverPhotoId)
                .maybeSingle();

            if (coverResponse != null) {
              coverStoragePath = coverResponse['storage_path'] as String?;
            }
          } catch (e) {
            // Cover photo not found, will try fallback
          }
        }

        // Try 2: Get first portrait photo if no cover set
        if (coverStoragePath == null) {
          try {
            final portraitResponse = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('event_id', eventId)
                .eq('is_portrait', true)
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();

            if (portraitResponse != null) {
              coverStoragePath = portraitResponse['storage_path'] as String?;
            }
          } catch (e) {
            // No portrait photos found
          }
        }

        // Try 3: Get any photo if still no cover found
        if (coverStoragePath == null) {
          try {
            final anyPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('event_id', eventId)
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();

            if (anyPhoto != null) {
              coverStoragePath = anyPhoto['storage_path'] as String?;
            }
          } catch (e) {
            // No photos found at all
          }
        }

        // Only add event if we found a valid cover photo
        if (coverStoragePath != null) {
          print('  ✅ Event: ${eventMap['name']}, path: $coverStoragePath');
          memoriesWithCovers.add({
            'id': eventId,
            'title': eventMap['name'] as String? ?? 'Untitled',
            'date': eventMap['end_datetime'],
            'location': (eventMap['locations'] as Map?)?['display_name'] as String?,
            'cover_storage_path': coverStoragePath,
          });
        } else {
          print('  ❌ Event: ${eventMap['name']}, no cover photo found');
        }
      }

      print('[OtherProfile] Returning ${memoriesWithCovers.length} memories with covers\n');
      return memoriesWithCovers;
    } catch (e) {
      print('[OtherProfile] ERROR: $e');
      rethrow;
    }
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
    print('\n[InvitableGroups] Finding groups where $currentUserId can invite $targetUserId');
    
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

    // Get member counts for all eligible groups
    final memberCounts = <String, int>{};
    for (final groupId in eligibleGroupIds) {
      final membersResponse = await _client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);
      memberCounts[groupId] = (membersResponse as List).length;
    }

    // Filter based on permissions
    print('[InvitableGroups] Checking permissions for ${(groups as List).length} eligible groups');
    final invitableGroups = <Map<String, dynamic>>[];
    for (final group in groups) {
      final groupId = group['id'] as String;
      final groupName = group['name'] as String;
      
      // Check if members can invite or current user is admin
      final membersCanInvite = group['members_can_invite'] as bool? ?? false;
      
      if (membersCanInvite) {
        print('  ✅ $groupName - members_can_invite=true');
        final groupWithCount = Map<String, dynamic>.from(group);
        groupWithCount['member_count'] = memberCounts[groupId] ?? 0;
        invitableGroups.add(groupWithCount);
      } else {
        // Check if current user is admin
        final membership = currentUserGroups.firstWhere(
          (m) => m['group_id'] == groupId,
          orElse: () => {},
        );
        
        if (membership['role'] == 'admin') {
          print('  ✅ $groupName - user is admin');
          final groupWithCount = Map<String, dynamic>.from(group);
          groupWithCount['member_count'] = memberCounts[groupId] ?? 0;
          invitableGroups.add(groupWithCount);
        } else {
          print('  ❌ $groupName - no permission');
        }
      }
    }

    print('[InvitableGroups] Found ${invitableGroups.length} invitable groups\n');
    return invitableGroups;
  }
  Future<void> inviteToGroup({
    required String userId,
    required String groupId,
    required String invitedBy,
  }) async {
    print('[InviteToGroup] Sending invite: user=$userId, group=$groupId, by=$invitedBy');
    try {
      await _client.from('group_invites').insert({
        'group_id': groupId,
        'invited_id': userId,
        'invited_by': invitedBy,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('[InviteToGroup] ✅ Invite sent successfully');
    } catch (e) {
      print('[InviteToGroup] ❌ Error: $e');
      rethrow;
    }
  }
}
