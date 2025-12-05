import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group_details_entity.dart';
import '../../domain/repositories/group_details_repository.dart';
import '../data_sources/group_details_data_source.dart';
import '../models/group_details_model.dart';
import '../../domain/entities/group_member_entity.dart';

/// Implementation of GroupDetailsRepository using Supabase
class GroupDetailsRepositoryImpl implements GroupDetailsRepository {
  final GroupDetailsDataSource _dataSource;
  final SupabaseClient _supabase;

  GroupDetailsRepositoryImpl(this._dataSource, this._supabase);

  @override
  Future<GroupDetailsEntity> getGroupDetails(String groupId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _dataSource.getGroupDetails(groupId),
        _dataSource.getGroupMemberCount(groupId),
        _dataSource.isCurrentUserAdmin(groupId, currentUserId),
        _dataSource.isGroupMuted(groupId, currentUserId),
      ]);

      final groupData = results[0] as Map<String, dynamic>;
      final memberCount = results[1] as int;
      final isAdmin = results[2] as bool;
      final isMuted = results[3] as bool;

      final model = GroupDetailsModel.fromJson(
        groupData,
        memberCount: memberCount,
        isCurrentUserAdmin: isAdmin,
        isMuted: isMuted,
      );

      // Convert storage path to signed URL for group photo
      String? photoUrl = model.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
        try {
          // Normalize path - remove leading slash if present
          final normalizedPath = photoUrl.startsWith('/') ? photoUrl.substring(1) : photoUrl;
          photoUrl = await _supabase.storage
              .from('group-photos')
              .createSignedUrl(normalizedPath, 3600); // 1 hour
        } catch (e) {
          print('⚠️ Failed to generate signed URL for group photo: $e');
          photoUrl = null;
        }
      }

      return GroupDetailsEntity(
        id: model.id,
        name: model.name,
        photoUrl: photoUrl,
        memberCount: model.memberCount,
        isCurrentUserAdmin: model.isCurrentUserAdmin,
        isMuted: model.isMuted,
        permissions: model.permissions,
      );
    } catch (e) {
      throw Exception('Failed to load group details: $e');
    }
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('group_members')
          .select('''
            id,
            user_id,
            role,
            users:user_id (
              name,
              avatar_url
            )
          ''')
          .eq('group_id', groupId)
          .order('role', ascending: false); // Admins first

      print('🔍 [GROUP MEMBERS] Raw response: $response');

      final members = <GroupMemberEntity>[];
      
      for (final json in response as List) {
        final userId = json['user_id'] as String;
        final isCurrentUser = userId == currentUserId;
        final role = json['role'] as String;
        final isAdmin = role == 'admin';
        
        print('👤 [MEMBER] userId: $userId, isCurrentUser: $isCurrentUser');
        print('   users field: ${json['users']}');
        
        // Handle nested users join
        String? name;
        String? profileImageUrl;
        final users = json['users'];
        if (users != null) {
          if (users is Map<String, dynamic>) {
            name = users['name'] as String?;
            final avatarPath = users['avatar_url'] as String?;
            
            print('   🔍 DEBUG avatarPath from DB: "$avatarPath" (starts with /: ${avatarPath?.startsWith('/')})');
            
            // Convert storage path to signed URL (works with private buckets)
            if (avatarPath != null && avatarPath.isNotEmpty) {
              // Check if it's already a full URL
              if (avatarPath.startsWith('http')) {
                profileImageUrl = avatarPath;
              } else {
                // Create signed URL (valid for 1 hour)
                // Normalize path - remove leading slash if present
                try {
                  final normalizedPath = avatarPath.startsWith('/') ? avatarPath.substring(1) : avatarPath;
                  print('   🔍 DEBUG normalized: "$normalizedPath"');
                  profileImageUrl = await _supabase.storage
                      .from('users-profile-pic')
                      .createSignedUrl(normalizedPath, 3600); // 1 hour
                  print('   🔍 DEBUG signed URL: "$profileImageUrl"');
                } catch (e) {
                  print('   ⚠️ Error creating signed URL: $e');
                  profileImageUrl = null;
                }
              }
            }
            
            print('   ✅ Map: name=$name, avatarPath=$avatarPath → url=$profileImageUrl');
          } else if (users is List && users.isNotEmpty) {
            final firstUser = users[0] as Map<String, dynamic>;
            name = firstUser['name'] as String?;
            final avatarPath = firstUser['avatar_url'] as String?;
            
            // Convert storage path to signed URL (works with private buckets)
            if (avatarPath != null && avatarPath.isNotEmpty) {
              if (avatarPath.startsWith('http')) {
                profileImageUrl = avatarPath;
              } else {
                // Normalize path - remove leading slash if present
                try {
                  final normalizedPath = avatarPath.startsWith('/') ? avatarPath.substring(1) : avatarPath;
                  profileImageUrl = await _supabase.storage
                      .from('users-profile-pic')
                      .createSignedUrl(normalizedPath, 3600); // 1 hour
                } catch (e) {
                  print('   ⚠️ Error creating signed URL: $e');
                  profileImageUrl = null;
                }
              }
            }
            
            print('   ✅ List: name=$name, avatarPath=$avatarPath → url=$profileImageUrl');
          }
        } else {
          print('   ❌ users field is null!');
        }

        members.add(GroupMemberEntity(
          id: userId,
          name: name ?? 'Unknown',
          profileImageUrl: profileImageUrl,
          isAdmin: isAdmin,
          isCurrentUser: isCurrentUser,
        ));
      }

      // Sort: current user first, then admins, then members
      members.sort((a, b) {
        if (a.isCurrentUser) return -1;
        if (b.isCurrentUser) return 1;
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return 0;
      });

      return members;
    } catch (e) {
      throw Exception('Failed to load group members: $e');
    }
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('group_user_settings')
          .upsert({
            'group_id': groupId,
            'user_id': currentUserId,
            'is_muted': isMuted,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to toggle mute: $e');
    }
  }

  @override
  Future<void> updateMemberRole(String groupId, String userId, bool isAdmin) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      print('🔐 [UPDATE ROLE] Starting update...');
      print('   Group ID: $groupId');
      print('   User ID to update: $userId');
      print('   New role: ${isAdmin ? "admin" : "member"}');
      print('   Current user ID: $currentUserId');
      
      // Check if current user is admin of this group
      print('   🔍 Checking current user permissions...');
      final currentUserMembership = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', currentUserId)
          .single();
      
      final currentUserRole = currentUserMembership['role'] as String;
      print('   Current user role: $currentUserRole');
      
      if (currentUserRole != 'admin') {
        throw Exception('Only admins can change member roles');
      }
      
      // Validate: cannot demote if this is the last admin
      if (!isAdmin) {
        print('   🔍 Checking if this is the last admin...');
        final members = await getGroupMembers(groupId);
        final adminCount = members.where((m) => m.isAdmin).length;
        print('   Current admin count: $adminCount');
        
        if (adminCount <= 1) {
          throw Exception('Cannot demote the last admin. Promote another member first.');
        }
      }

      final newRole = isAdmin ? 'admin' : 'member';
      
      print('   📝 Executing UPDATE query with RLS context...');
      
      // Try using RPC function if available, otherwise direct update
      try {
        // Check if RPC function exists
        await _supabase.rpc('update_group_member_role', params: {
          'p_group_id': groupId,
          'p_user_id': userId,
          'p_new_role': newRole,
        });
        print('   ✅ Update via RPC completed');
      } catch (rpcError) {
        print('   ⚠️ RPC not available, trying direct update: $rpcError');
        
        // Fallback to direct update
        await _supabase
            .from('group_members')
            .update({'role': newRole})
            .eq('group_id', groupId)
            .eq('user_id', userId);
        
        print('   ✅ Direct update completed');
      }
      
      // Verify the update worked
      print('   🔍 Verifying role change...');
      final verifyResponse = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .single();
      
      final actualRole = verifyResponse['role'] as String;
      print('   Current role in database: $actualRole');
      
      if (actualRole != newRole) {
        throw Exception('Role update failed: expected $newRole but got $actualRole. This may be a Row Level Security (RLS) policy issue. Check Supabase dashboard for policies on group_members table.');
      }
      
      print('✅ [UPDATE ROLE] Role successfully changed to $newRole');
    } catch (e) {
      print('❌ [UPDATE ROLE] Failed: $e');
      throw Exception('Failed to update member role: $e');
    }
  }
}
